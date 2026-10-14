import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

interface GitHubPullRequest {
  number: number
  title: string
  url: string
  author: { login: string }
  updatedAt: string
  labels: Array<{ name: string; color: string }>
  repository: { nameWithOwner: string }
}

async function findGhPath(ctx: ExtensionContext): Promise<string> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable, so GitHub CLI cannot be used.')

  const candidates: string[] = []
  const located = await shell.which('gh')
  if (located.exitCode === 0 && located.stdout.trim()) candidates.push(located.stdout.trim())

  // Nevermind is a GUI app and may not inherit Terminal's PATH. Query the
  // user's login shell so tools installed by Homebrew or a shell manager are found.
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

function explainGhFailure(detail: string): Error {
  if (/auth|login|token|401|credentials/i.test(detail)) {
    return new Error('GitHub CLI is installed, but Nevermind could not access its login. Restart Nevermind and try again.')
  }
  if (/rate limit|403/i.test(detail)) return new Error(`GitHub API rate limit reached. ${detail}`)
  return new Error(`GitHub pull request search failed: ${detail || 'Unknown GitHub CLI error'}`)
}

async function fetchPRs(ctx: ExtensionContext, ghPath: string, queryType: string): Promise<GitHubPullRequest[]> {
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

  const args = [
    'search', 'prs', '--state', 'open', '--limit', '50',
    '--json', 'number,title,url,author,updatedAt,labels,repository',
  ]

  if (queryType === 'authored') args.push('--author', '@me')
  else if (queryType === 'involved') args.push('--involved', '@me')
  else if (queryType === 'review-requested') args.push('--review-requested', '@me')
  else if (queryType === 'repo-all') args.push('--repo', await currentRepository(ctx))

  const result = await shell.exec(ghPath, args, {
    timeout: 30_000,
    outputLimit: 2_000_000,
  })

  if (result.exitCode !== 0) {
    const detail = (result.stderr || result.stdout || `gh exited with code ${result.exitCode}`).trim()
    ctx.logs.error('GitHub pull request search failed', {
      ghPath,
      queryType,
      exitCode: result.exitCode,
      detail,
    })
    throw explainGhFailure(detail)
  }

  try {
    const response = JSON.parse(result.stdout) as unknown
    if (!Array.isArray(response)) throw new Error('GitHub returned an unexpected pull-request response.')
    return response as GitHubPullRequest[]
  } catch (error) {
    throw new Error(`GitHub returned invalid JSON: ${error instanceof Error ? error.message : String(error)}`)
  }
}

function prToItem(ctx: ExtensionContext, pr: GitHubPullRequest): ExtensionItem {
  const labels = Array.isArray(pr.labels) ? pr.labels : []
  const repository = pr.repository?.nameWithOwner || 'Unknown repository'
  const author = pr.author?.login || 'ghost'
  const updated = Date.parse(pr.updatedAt)

  return {
    id: pr.url,
    title: pr.title,
    subtitle: `${repository} #${pr.number}`,
    keywords: [repository, author, ...labels.map((label) => label.name)],
    accessories: [
      ...(Number.isNaN(updated) ? [] : [{ text: new Date(updated).toLocaleDateString(), tooltip: 'Last updated' }]),
      ...labels.slice(0, 2).map((label) => ({ text: label.name, tooltip: 'Label' })),
    ],
    icon: 'git-pull-request',
    primaryAction: ctx.actions.openUrl(pr.url, 'Open in Browser'),
    actions: [
      ctx.actions.copyText(pr.url, 'Copy URL'),
      ctx.actions.copyText(repository, 'Copy Repository Name'),
    ],
  }
}

async function loadPRs(ctx: ExtensionContext, queryType: string): Promise<ExtensionItem[]> {
  try {
    const ghPath = await findGhPath(ctx)
    const prs = await fetchPRs(ctx, ghPath, queryType)
    ctx.logs.info('GitHub pull requests loaded', { queryType, count: prs.length, ghPath })
    return prs.map((pr) => prToItem(ctx, pr))
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    ctx.logs.error('GitHub pull requests failed to load', { queryType, message })
    throw new Error(message)
  }
}

export default {
  id: 'github.prs',
  title: 'GitHub Pull Requests',
  capabilities: ['system'],
  commands: [
    {
      id: 'show-my-prs',
      title: 'Show My Pull Requests',
      subtitle: 'List open pull requests across repos or current repo',
      icon: 'git-pull-request',
      async run(ctx) {
        const queryType = typeof ctx.state.queryType === 'string' ? ctx.state.queryType : 'authored'

        return ctx.ui.list({
          title: 'My Pull Requests',
          items: ctx.data.staleWhileRevalidate({
            cacheKey: `gh-prs-v2-${queryType}`,
            ttlMs: 60_000,
            staleTtlMs: 300_000,
            loader: () => loadPRs(ctx, queryType),
          }),
          searchAccessory: {
            value: queryType,
            items: [
              { title: 'Authored by me', value: 'authored' },
              { title: 'Involving me', value: 'involved' },
              { title: 'Review requested', value: 'review-requested' },
              { title: 'All in current repository', value: 'repo-all' },
            ],
            onChange: ctx.actions.run('Change Filter', async (innerCtx, action) => {
              innerCtx.state.queryType = typeof action.value === 'string' ? action.value : 'authored'
              return innerCtx.views.refresh()
            }),
          },
          emptyView: {
            title: 'No open pull requests',
            subtitle: 'No results found. Try changing the dropdown filter.',
          },
          searchBarPlaceholder: 'Filter results…',
        })
      },
    },
  ],
} satisfies NevermindExtension
