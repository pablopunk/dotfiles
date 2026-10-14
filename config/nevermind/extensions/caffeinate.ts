import type { NevermindExtension, ExtensionActionResult } from './nevermind-extension-api'

export default {
  id: 'caffeinate',
  title: 'Caffeinate',
  subtitle: 'Keep your Mac awake',
  permissions: ['system'],
  commands: [
    {
      id: 'caffeinate',
      title: 'Caffeinate Mac',
      subtitle: 'Keep your Mac awake indefinitely',
      icon: 'coffee',
      dismissAfterRun: 'auto',
      async run(ctx): Promise<ExtensionActionResult> {
        try {
          // Keep display and idle sleep awake
          await ctx.desktop.shell?.script('nohup /usr/bin/caffeinate -di > /dev/null 2>&1 &')
        } catch (err) {
          ctx.logs.error('Failed to run caffeinate', err)
          return {
            toast: { message: 'Failed to caffeinate Mac.', tone: 'error' }
          }
        }
        return {
          toast: { message: 'Mac will stay awake indefinitely ☕' }
        }
      },
    },
    {
      id: 'decaffeinate',
      title: 'Decaffeinate Mac',
      subtitle: 'Allow your Mac to sleep normally',
      icon: 'moon',
      dismissAfterRun: 'auto',
      async run(ctx): Promise<ExtensionActionResult> {
        try {
          await ctx.desktop.shell?.exec('/usr/bin/killall', ['caffeinate'])
        } catch (err) {
          // Ignored if caffeinate wasn't running
        }
        return {
          toast: { message: 'Sleep enabled. Caffeinate deactivated.' }
        }
      },
    },
  ],
} satisfies NevermindExtension
