import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

interface GitHubIssue {
  number: number
  title: string
  url: string
  author?: { login?: string } | null
  updatedAt: string
  labels?: Array<{ name?: string; color?: string }> | null
  repository?: { nameWithOwner?: string } | null
}

interface GitHubSearchResponse {
  items?: Array<{
    number?: number
    title?: string
    html_url?: string
    user?: { login?: string } | null
    updated_at?: string
    labels?: Array<{ name?: string; color?: string }> | null
    repository_url?: string
  }>
}

async function findGhPath(ctx: ExtensionContext): Promise<string> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable, so GitHub CLI cannot be used.')

  const candidates: string[] = []
  const located = await shell.which('gh')
  if (located.exitCode === 0 && located.stdout.trim()) candidates.push(located.stdout.trim())

  // Nevermind is a GUI app and may not inherit Terminal's PATH. Query the
  // user's login shell so tools installed by a shell/plugin manager are found.
  const loginShell = await shell.exec('/bin/zsh', ['-lic', 'command -v gh'], {
    timeout: 10_000,
    outputLimit: 20_000,
  })
  if (loginShell.exitCode === 0 && loginShell.stdout.trim()) {
    const lines = loginShell.stdout.trim().split('\n')
    candidates.push(lines[lines.length - 1])
  }

  candidates.push('/opt/homebrew/bin/gh', '/usr/local/bin/gh', '/usr/bin/gh')

  for (const path of [...new Set(candidates.map((value) => value.trim()).filter(Boolean))]) {
    const check = await shell.exec('/bin/test', ['-x', path])
    if (check.exitCode === 0) {
      ctx.logs.info('GitHub CLI located', { path })
      return path
    }
  }

  ctx.logs.error('GitHub CLI discovery failed', {
    whichExitCode: located.exitCode,
    whichOutput: located.stdout.trim(),
    loginShellExitCode: loginShell.exitCode,
    loginShellOutput: loginShell.stdout.trim(),
    loginShellError: loginShell.stderr.trim(),
  })
  throw new Error('Nevermind could not locate the GitHub CLI used by Terminal. Restart Nevermind once so it reloads your login environment, then try again.')
}

async function currentRepository(ctx: ExtensionContext): Promise<string> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable.')

  const result = await shell.exec('/usr/bin/git', ['config', '--get', 'remote.origin.url'])
  if (result.exitCode !== 0 || !result.stdout.trim()) {
    throw new Error('No GitHub repository could be detected from Nevermind’s current working directory.')
  }

  const remote = result.stdout.trim()
  const match = remote.match(/github\.com[/:]([^/]+\/[^/]+?)(?:\.git)?$/i)
  if (!match) throw new Error(`The current Git remote is not a GitHub repository: ${remote}`)
  return match[1]
}

function searchQualifier(queryType: string, repository?: string): string {
  if (queryType === 'assigned') return 'is:issue is:open assignee:@me'
  if (queryType === 'authored') return 'is:issue is:open author:@me'
  if (queryType === 'repo-all' && repository) return `is:issue is:open repo:${repository}`
  return 'is:issue is:open user:pablopunk'
}

function explainGhFailure(detail: string): Error {
  if (/auth|login|token|401|credentials/i.test(detail)) {
    return new Error('GitHub CLI is installed, but Nevermind could not access its login. Restart Nevermind and try again.')
  }
  if (/rate limit|403/i.test(detail)) return new Error(`GitHub API rate limit reached. ${detail}`)
  return new Error(`GitHub issue search failed: ${detail || 'Unknown GitHub CLI error'}`)
}

async function fetchIssuesWithApi(
  ctx: ExtensionContext,
  ghPath: string,
  queryType: string,
): Promise<GitHubIssue[]> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable.')

  const auth = await shell.exec(ghPath, ['auth', 'status', '--hostname', 'github.com'], {
    timeout: 15_000,
    outputLimit: 100_000,
  })
  if (auth.exitCode !== 0) {
    const detail = (auth.stderr || auth.stdout).trim()
    ctx.logs.error('GitHub CLI authentication unavailable', { ghPath, detail })
    throw explainGhFailure(detail)
  }

  const repository = queryType === 'repo-all' ? await currentRepository(ctx) : undefined
  const result = await shell.exec(ghPath, [
    'api', '--method', 'GET', 'search/issues',
    '-f', `q=${searchQualifier(queryType, repository)}`,
    '-f', 'sort=updated',
    '-f', 'order=desc',
    '-f', 'per_page=50',
  ], { timeout: 30_000, outputLimit: 2_000_000 })

  if (result.exitCode !== 0) {
    const detail = (result.stderr || result.stdout || `gh exited with code ${result.exitCode}`).trim()
    ctx.logs.error('GitHub API issue search failed', { ghPath, queryType, exitCode: result.exitCode, detail })
    throw explainGhFailure(detail)
  }

  let response: GitHubSearchResponse
  try {
    response = JSON.parse(result.stdout) as GitHubSearchResponse
  } catch (error) {
    throw new Error(`GitHub returned invalid JSON: ${error instanceof Error ? error.message : String(error)}`)
  }
  if (!Array.isArray(response.items)) throw new Error('GitHub returned an unexpected issue-search response.')

  return response.items.flatMap((item) => {
    if (!item.html_url || typeof item.number !== 'number' || !item.title || !item.updated_at) return []
    return [{
      number: item.number,
      title: item.title,
      url: item.html_url,
      author: item.user,
      updatedAt: item.updated_at,
      labels: item.labels,
      repository: { nameWithOwner: item.repository_url?.split('/repos/')[1] || 'Unknown repository' },
    }]
  })
}

function issueToItem(ctx: ExtensionContext, issue: GitHubIssue): ExtensionItem {
  const repository = issue.repository?.nameWithOwner || 'Unknown repository'
  const author = issue.author?.login || 'ghost'
  const labels = Array.isArray(issue.labels) ? issue.labels : []
  const updated = Date.parse(issue.updatedAt)

  return {
    id: issue.url,
    title: issue.title,
    subtitle: `${repository} #${issue.number}`,
    keywords: [repository, author, ...labels.flatMap((label) => label.name ? [label.name] : [])],
    accessories: [
      ...(Number.isNaN(updated) ? [] : [{ text: new Date(updated).toLocaleDateString(), tooltip: 'Last updated' }]),
      ...labels.slice(0, 2).flatMap((label) => label.name ? [{ text: label.name, tooltip: 'Label' }] : []),
    ],
    icon: 'circle-dot',
    primaryAction: ctx.actions.openUrl(issue.url, 'Open in Browser'),
    actions: [
      ctx.actions.copyText(issue.url, 'Copy URL'),
      ctx.actions.copyText(repository, 'Copy Repository Name'),
    ],
  }
}

async function loadIssues(ctx: ExtensionContext, queryType: string): Promise<ExtensionItem[]> {
  try {
    const ghPath = await findGhPath(ctx)
    const issues = await fetchIssuesWithApi(ctx, ghPath, queryType)
    ctx.logs.info('GitHub Issues loaded', { queryType, count: issues.length, ghPath })
    return issues.map((issue) => issueToItem(ctx, issue))
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    ctx.logs.error('GitHub Issues failed to load', { queryType, message })
    throw new Error(message)
  }
}

async function issuesView(ctx: ExtensionContext, selectedType?: string) {
  const queryType = selectedType || (typeof ctx.state.queryType === 'string' ? ctx.state.queryType : 'pablopunk')
  ctx.state.queryType = queryType
  const items = await loadIssues(ctx, queryType)

  return ctx.ui.list({
    title: 'GitHub Issues',
    items,
    searchAccessory: {
      value: queryType,
      items: [
        { title: 'My repos (pablopunk/*)', value: 'pablopunk' },
        { title: 'Assigned to me', value: 'assigned' },
        { title: 'Authored by me', value: 'authored' },
        { title: 'Current repository', value: 'repo-all' },
      ],
      onChange: ctx.actions.run('Change Filter', async (innerCtx, action) => {
        const nextType = typeof action.value === 'string' ? action.value : 'pablopunk'
        return innerCtx.navigation.replace(await issuesView(innerCtx, nextType))
      }),
    },
    emptyView: { title: 'No open issues', subtitle: 'No results found for this filter.' },
    searchBarPlaceholder: 'Filter issues…',
  })
}

export default {
  id: 'github.issues',
  title: 'GitHub Issues',
  capabilities: ['system'],
  commands: [{
    id: 'show-my-issues',
    title: 'Show GitHub Issues',
    subtitle: 'Open issues across pablopunk repositories, newest first',
    icon: 'circle-dot',
    async run(ctx) {
      return issuesView(ctx)
    },
  }],
} satisfies NevermindExtension
