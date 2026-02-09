import { basename } from "path";

export const NotificationPlugin = async ({
  project,
  client,
  $,
  directory,
  worktree,
}) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        const sessionName =
          event.session?.name ||
          event.session?.title ||
          project?.name ||
          (directory ? basename(directory) : null) ||
          (worktree ? basename(worktree) : null) ||
          "Session";

        await Promise.all([
          $`osascript -e 'display notification "Completed!" with title "${sessionName}"'`,
          $`afplay -v 2 /System/Library/Sounds/Bottle.aiff`,
        ]);
      }
    },
  };
};
