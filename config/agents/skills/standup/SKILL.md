---
name: Standup
description: Creates a quick summary of the user's activity on Linear and Github, usually for yesterday and today, but not limited.
---

# Standup

Today is `date` (use bash)

Use the Linear MCP and Github's gh cli to get context on the user's activity.

Focus on what they did and what they're working on.

A simple Done & Doing list is enough.

Ignore all github activity that is not related to mazedesignhq org. But it can be multiple repos under mazedesignhq. My gh user is pablopunk.

Everything in Linear is relevant.

Reply in markdown text, and include all links from PRs and Issues.

## Flow

Before creating your standup summary, ask the user ONE BY ONE of the issues/PRs (if a PR links to one issue, should be one item):

- Status: Done, Doing, Ready for review, Next, Postponed (not worth mentioning on standup)
- Notes: Anything relevant worth mentioning in the summary.


## Format

Should be:

```
:emoji: Status
- Task with link to issue/PR. Notes if any.
```

Status would be either Done, Doing, Ready for review, or Next.

Example:

```
✅ Done:
- Fixed [flaky tests](https://linear.app/...)

👀 Ready for review:
- Fixed [stuck participants](https://linear.app/...). There's a loom in the description of the PR.

⌛ Doing:
- Implemented [new feature xyz](https://linear.app/...)
- Improved [docs on github](https://github.com/...). I was struggling with this so I made a PR for it.

🔜 Next:
- Implemented [new feature xyz123](https://linear.app/...)
```
