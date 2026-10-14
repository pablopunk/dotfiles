import type { NevermindExtension } from './nevermind-extension-api'

export default {
  id: 'system.toggle-theme',
  title: 'Toggle System Theme',
  permissions: ['system'],
  commands: [
    {
      id: 'toggle-theme',
      title: 'Toggle System Theme',
      subtitle: 'Switch between light and dark mode',
      icon: 'circle-lefthalf-fill',
      async run(ctx) {
        await ctx.desktop.shell?.appleScript(`
          tell application "System Events"
            tell appearance preferences
              set dark mode to not dark mode
            end tell
          end tell
        `)
      },
    },
  ],
} satisfies NevermindExtension
