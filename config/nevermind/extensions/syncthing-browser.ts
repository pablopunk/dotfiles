import type { NevermindExtension } from './nevermind-extension-api'

const DEFAULT_URL = 'http://127.0.0.1:8384/'

export default {
  id: 'local.syncthing-browser',
  title: 'Syncthing Browser',
  subtitle: 'Open Syncthing web UI',
  commands: [
    {
      id: 'syncthing-browser',
      title: 'Syncthing Browser',
      subtitle: 'Open your Syncthing page in the browser',
      aliases: ['Open Syncthing', 'Syncthing UI', 'Syncthing Web UI'],
      icon: 'refresh-cw',
      run(ctx) {
        return ctx.actions.openUrl(DEFAULT_URL, 'Open Syncthing')
      },
    },
  ],
} satisfies NevermindExtension
