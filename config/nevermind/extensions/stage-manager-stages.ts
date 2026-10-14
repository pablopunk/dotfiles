import type { NevermindExtension, ExtensionContext, ExtensionItem, ExtensionApp } from './nevermind-extension-api'

// Stage Manager has no public stage-list API. On this macOS setup, its shelf
// appears as AXButtons inside an AXList under WindowManager's AXGroup.
const helpers = `
on cleanText(t)
  set t to t as text
  set AppleScript's text item delimiters to {tab, return, linefeed, "|"}
  set pieces to text items of t
  set AppleScript's text item delimiters to " "
  return pieces as text
end cleanText

on labelOf(el)
  set n to ""
  tell application "System Events"
    try
      set n to name of el as text
    end try
    if n is "" or n is "missing value" then
      try
        set n to description of el as text
      end try
    end if
  end tell
  if n is "missing value" then set n to ""
  return my cleanText(n)
end labelOf
`

// Only collect the exact WindowManager group → list → button structure shown
// by the user's accessibility diagnosis. Never confuse Dock apps with stages.
const scanScript = helpers + `
set outputText to ""
tell application "System Events"
  try
    set wm to first application process whose name is "WindowManager"
    set groupIndex to 0
    repeat with grp in UI elements of wm
      set groupIndex to groupIndex + 1
      if groupIndex > 20 then exit repeat
      try
        if role of grp is "AXGroup" then
          set listIndex to 0
          repeat with lst in UI elements of grp
            set listIndex to listIndex + 1
            if listIndex > 20 then exit repeat
            try
              if role of lst is "AXList" then
                set buttonIndex to 0
                repeat with btn in UI elements of lst
                  set buttonIndex to buttonIndex + 1
                  if buttonIndex > 40 then exit repeat
                  try
                    if role of btn is "AXButton" then
                      set buttonName to my labelOf(btn)
                      if buttonName is not "" then set outputText to outputText & "WindowManager." & (groupIndex as text) & "." & (listIndex as text) & "." & (buttonIndex as text) & "|" & buttonName & linefeed
                    end if
                  end try
                end repeat
              end if
            end try
          end repeat
        end if
      end try
    end repeat
  end try
end tell
return outputText
`

// Read-only, bounded correlation: title of an AXWindow -> owning process name.
// This does not activate stages or assume an installed app belongs to a stage.
const windowScript = helpers + `
set outputText to ""
tell application "System Events"
  set processCount to 0
  repeat with proc in application processes
    set processCount to processCount + 1
    if processCount > 120 then exit repeat
    try
      set procName to my cleanText(name of proc)
      if procName is not "WindowManager" and procName is not "Dock" then
        set windowCount to 0
        repeat with win in windows of proc
          set windowCount to windowCount + 1
          if windowCount > 25 then exit repeat
          try
            set windowName to my labelOf(win)
            if windowName is not "" then set outputText to outputText & procName & "|" & windowName & linefeed
          end try
        end repeat
      end if
    end try
  end repeat
end tell
return outputText
`

// Bounded, read-only diagnostic for layouts that differ from the observed one.
const inspectScript = helpers + `
property seenCount : 0
on inspect(el, depth, pathText)
  if depth > 5 or seenCount > 110 then return ""
  set resultText to ""
  tell application "System Events"
    try
      set kids to UI elements of el
    on error errText
      return pathText & " — cannot read children: " & my cleanText(errText) & linefeed
    end try
    set k to 0
    repeat with child in kids
      set k to k + 1
      if k > 40 or seenCount > 110 then exit repeat
      set seenCount to seenCount + 1
      set childPath to pathText & "." & (k as text)
      set roleText to "?"
      set descText to ""
      try
        set roleText to role of child as text
      end try
      try
        set descText to description of child as text
      end try
      set resultText to resultText & childPath & "  " & my cleanText(roleText) & "  name=" & my labelOf(child) & "  description=" & my cleanText(descText) & linefeed
      set resultText to resultText & my inspect(child, depth + 1, childPath)
    end repeat
  end tell
  return resultText
end inspect

set outputText to ""
tell application "System Events"
  repeat with procName in {"Dock", "WindowManager"}
    try
      set proc to first application process whose name is (procName as text)
      set outputText to outputText & "## " & (procName as text) & linefeed & my inspect(proc, 0, procName as text)
    on error errText
      set outputText to outputText & "## " & (procName as text) & ": " & my cleanText(errText) & linefeed
    end try
  end repeat
end tell
return outputText
`

function scriptString(s: string): string {
  return `"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"`
}

function activateScript(path: string, label: string): string {
  const match = /^WindowManager\.([1-9]\d?)\.([1-9]\d?)\.([1-9]\d?)$/.exec(path)
  if (!match) throw new Error('Invalid Stage Manager element path. Refresh the list.')
  const [, groupIndex, listIndex, buttonIndex] = match
  return helpers + `
tell application "System Events"
  set wm to first application process whose name is "WindowManager"
  set grp to UI element ${Number(groupIndex)} of wm
  if role of grp is not "AXGroup" then error "Stage Manager layout changed. Refresh the list."
  set lst to UI element ${Number(listIndex)} of grp
  if role of lst is not "AXList" then error "Stage Manager layout changed. Refresh the list."
  set btn to UI element ${Number(buttonIndex)} of lst
  if role of btn is not "AXButton" or my labelOf(btn) is not ${scriptString(label)} then error "Stage Manager stages changed. Refresh the list."
  try
    perform action "AXPress" of btn
  on error
    click btn
  end try
end tell
return "OK"
`
}

async function runAppleScript(ctx: ExtensionContext, script: string, timeout = 10000): Promise<string> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('System scripting is unavailable on this machine.')
  const result = await shell.appleScript(script, { timeout, outputLimit: 30000 })
  if (result.exitCode !== 0) {
    const detail = result.stderr.trim()
    throw new Error(`Could not access Stage Manager UI. ${detail || 'Check Nevermind Accessibility and System Events permissions.'}`)
  }
  return result.stdout
}

async function inspectView(ctx: ExtensionContext) {
  const tree = await runAppleScript(ctx, inspectScript, 15000)
  return ctx.ui.preview({
    title: 'Stage Manager Accessibility Diagnosis',
    content: 'Read-only Dock / WindowManager accessibility tree (first 110 elements). Names may include open apps.\n\n' + (tree.trim() || 'Neither process returned any accessible UI elements. Check Nevermind Accessibility permissions.'),
    actions: [ctx.actions.copyText(tree, 'Copy Accessibility Diagnosis')],
  })
}

function key(text: string): string { return text.trim().toLocaleLowerCase() }

// Only accept an exact window-title match if all matching windows have the same
// owner. A shared title like "Untitled" must not get a guessed icon.
function ownerForTitle(label: string, windows: Array<{ app: string; title: string }>): string | undefined {
  const owners = new Set(windows.filter(w => key(w.title) === key(label)).map(w => key(w.app)))
  return owners.size === 1 ? windows.find(w => owners.has(key(w.app)))?.app : undefined
}

// Fall back to the older app-name prefix heuristic for labels like "Zen Twilight".
function appForLabel(label: string, apps: ExtensionApp[]): ExtensionApp | undefined {
  const normalized = key(label)
  return apps
    .filter(app => {
      const name = key(app.name)
      if (!name || !app.path || !normalized.startsWith(name)) return false
      const next = normalized.slice(name.length, name.length + 1)
      return !next || /[\s,:;–—-]/.test(next)
    })
    .sort((a, b) => b.name.length - a.name.length)[0]
}

async function stageItems(ctx: ExtensionContext): Promise<ExtensionItem[]> {
  const raw = await runAppleScript(ctx, scanScript)
  const seen = new Set<string>()
  const stages: Array<{ path: string; name: string }> = []
  for (const line of raw.split(/\r?\n/)) {
    const split = line.indexOf('|')
    if (split < 0) continue
    const path = line.slice(0, split)
    const name = line.slice(split + 1).trim()
    if (!/^WindowManager\.\d{1,2}\.\d{1,2}\.\d{1,2}$/.test(path) || !name || seen.has(path)) continue
    seen.add(path)
    stages.push({ path, name })
    if (stages.length >= 32) break
  }
  if (!stages.length) return [{
    id: 'inspect-stage-accessibility',
    title: 'Inspect Stage Manager access',
    subtitle: 'No shelf buttons found; see what macOS exposes',
    icon: 'scan-search',
    primaryAction: ctx.actions.run('Inspect Stage Manager access', inspectView),
  }]

  const appApi = ctx.desktop.apps
  const apps = appApi?.list() ?? []
  let windows: Array<{ app: string; title: string }> = []
  try {
    const windowRaw = await runAppleScript(ctx, windowScript, 15000)
    windows = windowRaw.split(/\r?\n/).flatMap(line => {
      const split = line.indexOf('|')
      return split > 0 && line.slice(split + 1).trim() ? [{ app: line.slice(0, split), title: line.slice(split + 1) }] : []
    })
  } catch (error) {
    // Stage discovery and switching still work if a process denies window access.
    ctx.logs.warn('Could not correlate stage labels with app windows', { error: String(error) })
  }
  const matches = stages.map(stage => {
    const owner = ownerForTitle(stage.name, windows)
    const ownerApp = owner && apps.find(app => key(app.name) === key(owner) && app.path)
    return ownerApp || appForLabel(stage.name, apps)
  })
  const uniqueApps = [...new Map(matches.filter((app): app is ExtensionApp => !!app).map(app => [app.path, app])).values()]
  const icons = new Map<string, string>()
  if (appApi) await Promise.all(uniqueApps.map(async app => {
    try {
      const image = await appApi.icon(app.path)
      if (image) icons.set(app.path, image)
    } catch {
      // App icon lookup is optional: retain the working stage switcher.
    }
  }))
  return stages.map(({ path, name }, index) => {
    const app = matches[index]
    const image = app && icons.get(app.path)
    return {
      id: path,
      title: name,
      subtitle: app ? `${app.name} · Stage Manager shelf` : 'Stage Manager shelf',
      ...(image ? { image } : { icon: 'panels-top-left' }),
      primaryAction: ctx.actions.run(`Switch to ${name}`, async actionCtx => {
        await runAppleScript(actionCtx, activateScript(path, name))
      }, { dismissAfterRun: 'auto' }),
    }
  })
}

export default {
  id: 'local.stage-manager-stages',
  title: 'Stage Manager Stages',
  capabilities: ['system', 'desktop.apps'],
  commands: [{
    id: 'list-stages',
    title: 'Stage Manager Stages',
    subtitle: 'List WindowManager shelf stages and switch to one',
    icon: 'panels-top-left',
    run(ctx) {
      if (ctx.system.os !== 'macOS') return ctx.ui.error('Stage Manager Stages', 'This command requires macOS.')
      return ctx.ui.list({
        title: 'Stage Manager Stages',
        searchBarPlaceholder: 'Search stages…',
        items: ctx.data.loader(() => stageItems(ctx)),
        emptyView: { title: 'No accessible stages', subtitle: 'Stage Manager must be on with Recent Apps visible.' },
        actions: [ctx.views.refresh()],
        refresh: { mode: 'replace' },
      })
    },
  }],
} satisfies NevermindExtension
