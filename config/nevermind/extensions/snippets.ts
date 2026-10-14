import type { NevermindExtension, ExtensionContext, ExtensionView } from './nevermind-extension-api'

type Snippet = { id: string; text: string; updatedAt: number }
const KEY = 'snippets-v1'

function title(text: string): string {
  return text.split(/\r?\n/).find(line => line.trim())?.trim().slice(0, 80) || 'Untitled Snippet'
}

function copy(ctx: ExtensionContext, snippetId: string) {
  // Put dismissal on the dispatched action itself, not a nested run result.
  return ctx.actions.background('Copy Snippet', async ctx => {
    const current = await find(ctx, snippetId)
    if (!ctx.desktop.clipboard) throw new Error('Clipboard access is unavailable. The snippet was not copied.')
    ctx.desktop.clipboard.writeText(current.text)
    ctx.ui.indicator.show({ id: 'snippet-copied', title: 'Copied', status: 'success', durationMs: 1500 })
  })
}

async function read(ctx: ExtensionContext): Promise<Snippet[]> {
  const value = await ctx.storage.get<unknown>(KEY, [])
  if (!Array.isArray(value) || value.some(item => !item || typeof item.id !== 'string' || typeof item.text !== 'string' || typeof item.updatedAt !== 'number')) {
    throw new Error('Saved snippets could not be read. Your stored data has not been changed.')
  }
  return value as Snippet[]
}

async function find(ctx: ExtensionContext, id: string): Promise<Snippet> {
  const snippet = (await read(ctx)).find(item => item.id === id)
  if (!snippet) throw new Error('This snippet no longer exists. Reopen Snippets to refresh the list.')
  return snippet
}

function editor(ctx: ExtensionContext, snippet?: Snippet): ExtensionView {
  return ctx.ui.editor({
    title: snippet ? 'Edit Snippet' : 'New Snippet',
    content: snippet?.text || '',
    format: 'text',
    placeholder: 'Write the text you want to save…',
    submitAction: ctx.actions.run('Save Snippet', async (ctx, action) => {
      const text = action.editorContent
      if (typeof text !== 'string' || !text.trim()) throw new Error('Enter some text before saving the snippet.')
      const items = await read(ctx)
      const saved = { id: snippet?.id || crypto.randomUUID(), text, updatedAt: Date.now() }
      if (snippet) {
        const index = items.findIndex(item => item.id === snippet.id)
        if (index < 0) throw new Error('This snippet was deleted and cannot be updated.')
        if (items[index].updatedAt !== snippet.updatedAt || items[index].text !== snippet.text) {
          throw new Error('This snippet changed since you opened it. Reopen it before saving to avoid overwriting newer text.')
        }
        items[index] = saved
      } else items.push(saved)
      await ctx.storage.set(KEY, items)
      return ctx.navigation.root(await collection(ctx))
    }, { shortcut: 'Command+Enter' }),
  })
}

async function collection(ctx: ExtensionContext): Promise<ExtensionView> {
  const items = await read(ctx)
  const view = ctx.ui.collection({
    id: 'snippets',
    title: 'Snippets',
    searchBarPlaceholder: 'Search saved text…',
    emptyView: { title: 'No snippets yet', subtitle: 'Add a snippet to save a piece of text.' },
    add: ctx.actions.run('Add Snippet', ctx => ctx.navigation.push(editor(ctx))),
    items: [...items].sort((a, b) => b.updatedAt - a.updatedAt).map(snippet => ({
      id: snippet.id,
      title: title(snippet.text),
      subtitle: snippet.text.replace(/\s+/g, ' ').trim().slice(0, 160),
      keywords: [snippet.text],
      icon: 'text',
      preview: ctx.actions.run('View Snippet', async ctx => {
        const current = await find(ctx, snippet.id)
        return ctx.navigation.push(ctx.ui.editor({
          title: title(current.text),
          content: current.text,
          format: 'text',
          readOnly: true,
          actions: [
            copy(ctx, current.id),
            ctx.actions.pasteText(current.text, 'Paste Snippet', { restoreClipboard: true, concealed: true }),
            ctx.actions.run('Edit Snippet', async ctx => ctx.navigation.replace(editor(ctx, await find(ctx, current.id)))),
          ],
        }))
      }),
      edit: ctx.actions.run('Edit Snippet', async ctx => ctx.navigation.push(editor(ctx, await find(ctx, snippet.id)))),
      remove: ctx.actions.run('Delete Snippet', async ctx => {
        const latest = await read(ctx)
        await ctx.storage.set(KEY, latest.filter(item => item.id !== snippet.id))
        return ctx.navigation.replace(await collection(ctx))
      }, { requiresConfirmation: true, style: 'destructive', confirmMessage: `Delete “${title(snippet.text)}”?`, confirmLabel: 'Delete' }),
    })),
  })
  // Keep the host's CRUD chrome and secondary actions, but make Enter copy.
  if (Array.isArray(view.items)) {
    const ids = new Set(items.map(item => item.id))
    view.items = view.items.map(item => {
      if (!ids.has(item.id)) return item
      const preview = item.primaryAction
      return {
        ...item,
        primaryAction: copy(ctx, item.id),
        actions: [
          ...(preview ? [preview] : []),
          ...(item.actions || []),
          ctx.actions.run('Paste Snippet', async ctx => {
            const current = await find(ctx, item.id)
            return ctx.navigation.run(ctx.actions.pasteText(current.text, 'Paste Snippet', { restoreClipboard: true, concealed: true }))
          }),
        ],
      }
    })
  }
  return view
}

export default {
  id: 'local.text-snippets',
  title: 'Snippets',
  subtitle: 'Save and manage reusable pieces of text',
  capabilities: ['clipboard.history'],
  commands: [{
    id: 'snippets',
    title: 'Snippets',
    subtitle: 'Add, copy, edit, and delete saved text',
    icon: 'text',
    run: ctx => collection(ctx),
  }],
} satisfies NevermindExtension
