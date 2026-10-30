import type { ExtensionContext, ExtensionView, NevermindExtension } from './nevermind-extension-api';

const SECRET_KEY = 'github-token';
const REPO_CACHE_KEY = 'pablopunk-repos-v1';
const REPO_LIMIT = 20;
const API_URL = 'https://api.github.com/user/repos';

type GitHubRepo = {
  id: number;
  name: string;
  full_name: string;
  html_url: string;
  description: string | null;
  private: boolean;
  fork: boolean;
  language: string | null;
  updated_at: string;
};

function formatUpdated(value: string): string {
  const timestamp = new Date(value).getTime();
  if (!Number.isFinite(timestamp)) return 'Updated time unavailable';

  const delta = timestamp - Date.now();
  const minutes = Math.round(delta / 60_000);
  const hours = Math.round(delta / 3_600_000);
  const days = Math.round(delta / 86_400_000);
  const relative = new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' });

  if (Math.abs(minutes) < 60) return `Updated ${relative.format(minutes, 'minute')}`;
  if (Math.abs(hours) < 24) return `Updated ${relative.format(hours, 'hour')}`;
  if (Math.abs(days) < 30) return `Updated ${relative.format(days, 'day')}`;
  return `Updated ${new Date(timestamp).toLocaleDateString()}`;
}

function isAuthenticationError(error: unknown): boolean {
  return error instanceof Error && error.message.includes('GITHUB_AUTH_REQUIRED');
}

async function requestRepos(ctx: ExtensionContext, token: string): Promise<GitHubRepo[]> {
  const shell = ctx.desktop.shell;
  if (!shell) throw new Error('GitHub access is unavailable because local shell support is missing.');

  const url = `${API_URL}?affiliation=owner&sort=updated&direction=desc&per_page=${REPO_LIMIT}&page=1`;
  let result;
  try {
    result = await shell.exec('curl', [
      '--silent', '--show-error', '--fail', '--location',
      '--connect-timeout', '8', '--max-time', '25',
      '--header', 'Accept: application/vnd.github+json',
      '--header', 'X-GitHub-Api-Version: 2022-11-28',
      '--header', `Authorization: Bearer ${token}`,
      url,
    ], { timeout: 30_000, outputLimit: 1_000_000 });
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    throw new Error(`Could not reach GitHub. Check your internet connection and try again. ${detail}`);
  }

  if (result.exitCode !== 0) {
    const detail = `${result.stderr}\n${result.stdout}`;
    if (/returned error: 401|\b401\b/i.test(detail)) {
      throw new Error('GITHUB_AUTH_REQUIRED: GitHub rejected the saved token. Enter a valid token with repository metadata read access.');
    }
    if (/returned error: 403|\b403\b/i.test(detail)) {
      throw new Error('GitHub denied the request. Check that your token can read repository metadata; GitHub may also be rate-limiting API requests.');
    }
    if (/not found|enoent|could not resolve|failed to connect/i.test(detail)) {
      throw new Error('Could not run curl or connect to GitHub. Check your internet connection and try again.');
    }
    throw new Error(`GitHub request failed: ${detail.trim() || `curl exited with code ${result.exitCode}`}`);
  }

  let payload: unknown;
  try {
    payload = JSON.parse(result.stdout);
  } catch {
    throw new Error('GitHub returned an unreadable response. Please try again.');
  }
  if (!Array.isArray(payload)) {
    const message = payload && typeof payload === 'object' && 'message' in payload
      ? String((payload as { message?: unknown }).message ?? '')
      : '';
    throw new Error(message ? `GitHub API error: ${message}` : 'GitHub returned an unexpected repository response.');
  }

  return (payload as GitHubRepo[])
    .filter((repo) => repo && typeof repo.full_name === 'string' && repo.full_name.toLowerCase().startsWith('pablopunk/'))
    .sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())
    .slice(0, REPO_LIMIT);
}

function repoItems(ctx: ExtensionContext, repos: GitHubRepo[]) {
  return repos
    .filter((repo) => /^https:\/\/github\.com\//i.test(repo.html_url))
    .map((repo) => ({
      id: String(repo.id ?? repo.full_name),
      title: repo.name || repo.full_name,
      subtitle: `${repo.full_name} · ${formatUpdated(repo.updated_at)}`,
      icon: 'github',
      keywords: [repo.full_name, repo.description ?? '', repo.language ?? ''],
      accessories: [
        { text: repo.private ? 'Private' : 'Public', tone: 'muted' as const },
        ...(repo.language ? [{ text: repo.language, tone: 'muted' as const }] : []),
        ...(repo.fork ? [{ text: 'Fork', tone: 'muted' as const }] : []),
      ],
      primaryAction: ctx.actions.openUrl(repo.html_url, `Open ${repo.full_name} on GitHub`),
    }));
}

function listView(ctx: ExtensionContext, items: ExtensionView['items']) {
  return ctx.ui.list({
    title: 'My GitHub Repos',
    subtitle: 'pablopunk · newest updates first · showing up to 20',
    searchBarPlaceholder: 'Filter repositories',
    emptyView: { title: 'No pablopunk repositories found', subtitle: 'Check that your GitHub token belongs to pablopunk and can read repository metadata.' },
    items,
    actions: [
      ctx.actions.run('Change GitHub token', (actionCtx) => tokenPrompt(actionCtx)),
    ],
  });
}

function repoView(ctx: ExtensionContext, token: string) {
  const items = ctx.data.staleWhileRevalidate({
    cacheKey: REPO_CACHE_KEY,
    ttlMs: 30_000,
    staleTtlMs: 30 * 60_000,
    retry: true,
    loader: async () => repoItems(ctx, await requestRepos(ctx, token)),
  });
  return listView(ctx, items);
}

function tokenPrompt(ctx: ExtensionContext, message?: string) {
  return ctx.input.prompt({
    title: 'Connect GitHub',
    message: message ?? 'Enter a GitHub token for the pablopunk account. Grant repository Metadata read access. The token is stored in your OS secure storage.',
    fields: [{
      id: 'token',
      label: 'GitHub access token',
      type: 'password',
      placeholder: 'Paste token',
      required: true,
    }],
    submitTitle: 'Show Repositories',
    action: ctx.actions.run('Load GitHub repositories', async (actionCtx, action) => {
      const token = String(action.formValues?.token ?? '').trim();
      if (!token) throw new Error('Enter a GitHub access token to continue.');
      try {
        const repos = await requestRepos(actionCtx, token);
        await actionCtx.secrets.set(SECRET_KEY, token);
        return listView(actionCtx, repoItems(actionCtx, repos));
      } catch (error) {
        if (isAuthenticationError(error)) {
          throw new Error('GitHub rejected that token. Check that it is valid and has repository Metadata read access, then try again.');
        }
        throw error;
      }
    }),
  });
}

async function githubCliToken(ctx: ExtensionContext): Promise<string | undefined> {
  try {
    const result = await ctx.desktop.shell?.exec('gh', ['auth', 'token'], { timeout: 5_000, outputLimit: 10_000 });
    if (result?.exitCode === 0 && result.stdout.trim()) return result.stdout.trim();
  } catch {
    // GitHub CLI is optional; the secure token prompt is the fallback.
  }
  return undefined;
}

export default {
  id: 'my-github-repos',
  title: 'My GitHub Repos',
  subtitle: 'Browse pablopunk repositories by most recently updated',
  capabilities: ['system'],
  commands: [{
    id: 'show-repos',
    title: 'My GitHub Repos',
    subtitle: 'Open the latest pablopunk repositories',
    aliases: ['my repos', 'github repos', 'repos'],
    icon: 'github',
    async run(ctx) {
      const savedToken = await ctx.secrets.get(SECRET_KEY);
      const token = savedToken || await githubCliToken(ctx);
      if (!token) return tokenPrompt(ctx);
      return repoView(ctx, token);
    },
  }],
} satisfies NevermindExtension;
