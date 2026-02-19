---
name: gogcli
description: Google Suite CLI for Gmail, Calendar, Drive, Contacts, Tasks, Sheets, Docs, and more. Fast, script-friendly tool with JSON output.
---

# gogcli

A single CLI for Google Workspace - Gmail, Calendar, Drive, Contacts, Tasks, Sheets, Docs, Slides, and People.

## Setup

Requires gogcli to be installed. If not installed:

```bash
brew install steipete/tap/gogcli
```

Or build from source:
```bash
git clone https://github.com/steipete/gogcli.git
cd gogcli
make
```

## Authentication

1. Get OAuth2 credentials from Google Cloud Console:
   - Create project: https://console.cloud.google.com/projectcreate
   - Enable APIs (Gmail, Calendar, Drive, etc.)
   - Configure OAuth consent screen
   - Download client_secret.json

2. Set up gogcli:
```bash
gog auth credentials ~/Downloads/client_secret_....json
gog auth add your.email@gmail.com
export GOG_ACCOUNT=your.email@gmail.com
```

## Usage

### Gmail
```bash
gog gmail search 'newer_than:7d' --max 10 --json
gog gmail labels list
gog gmail send --to recipient@example.com --subject "Hello" --body "Message"
```

### Calendar
```bash
gog calendar events --max 10 --json
gog calendar events --from 2024-01-01 --to 2024-12-31
gog calendar freebusy --email you@gmail.com
```

### Drive
```bash
gog drive ls --max 10 --json
gog drive ls --query "mimeType='application/pdf'"
gog drive upload ./file.pdf --parent-folder <folder-id>
```

### Sheets
```bash
gog sheets read <spreadsheet-id>
gog sheets export <spreadsheet-id> --format pdf --out ./sheet.pdf
```

### Contacts
```bash
gog contacts search "John" --json
gog contacts list --max 20
```

### Tasks
```bash
gog tasks lists
gog tasks tasks --list-id <list-id>
gog tasks add --list-id <list-id> --title "New task"
```

## Helper Scripts

Available at: {baseDir}/

- `{baseDir}/gmail-search.js` - Search Gmail with formatted output
- `{baseDir}/calendar-today.js` - Show today's events
- `{baseDir}/drive-recent.js` - List recent Drive files

## Common Patterns

### JSON Output for Scripts
Always use `--json` flag for parsing:
```bash
gog gmail search 'is:unread' --max 5 --json | jq '.threads[].subject'
```

### Set Default Account
```bash
export GOG_ACCOUNT=you@gmail.com
```

### Readonly Mode
Request fewer permissions:
```bash
gog gmail search 'query' --readonly
```
