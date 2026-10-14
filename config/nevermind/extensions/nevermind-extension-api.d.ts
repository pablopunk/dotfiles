// biome-ignore-all lint: This canonical declaration intentionally favors extension-author-readable aliases and established public API shapes while preserving released type-alias and void compatibility contracts.
/**
 * Nevermind Extension API
 *
 * This declaration file is the canonical public contract for generated Nevermind
 * extensions and the API reference returned by the AI builder's `read_extension_api`
 * tool. Keep extension-author guidance here, next to the types the host copies into
 * the user extension directory for validation.
 *
 * Extensions are local TypeScript files that use erasable TypeScript only: type
 * imports, interfaces, generics, and `satisfies` are fine; runtime TypeScript
 * features such as enums, decorators, parameter properties, and value namespaces
 * are not supported by Electron's native type stripping.
 *
 * @example
 * ```ts
 * import type { NevermindExtension } from './nevermind-extension-api'
 *
 * export default {
 *   id: 'my.images',
 *   title: 'My Images',
 *   capabilities: ['desktop.files'],
 *   commands: [{
 *     id: 'recent-images',
 *     title: 'Recent Images',
 *     icon: 'image',
 *     async run(ctx) {
 *       const files = await ctx.desktop.files?.findImages(['~/Downloads'], { sortBy: 'added', limit: 48 }) || []
 *       return ctx.ui.grid({
 *         title: 'Recent Images',
 *         items: files.map((file) => ({
 *           id: file.path,
 *           title: file.name,
 *           subtitle: file.displayPath,
 *           image: file.url,
 *           primaryAction: ctx.actions.quickLook(file.path),
 *           actions: [ctx.actions.revealPath(file.path), ctx.actions.copyText(file.path, 'Copy Path')],
 *         })),
 *       })
 *     },
 *   }],
 * } satisfies NevermindExtension
 * ```
 */

/** Intent an extension declares for review; it does not restrict enabled local code. */
export type ExtensionCapability =
  | 'desktop.apps'
  | 'desktop.files'
  | 'clipboard.history'
  | 'ai'
  | 'extensions.ownership'
  | 'shortcuts'
  /** Declares intent to use shell execution, system actions, or `ctx.desktop.shell`. */
  | 'system'
  | 'places'
  | 'updates'
  | 'settings.write'
  | 'dictation'
  | 'camera'
  /** Declares intent to use `ctx.ocr` image/screen/region text recognition helpers. */
  | 'ocr';

/** @deprecated Use `ExtensionCapability`; retained for existing source files. */
export type ExtensionPermission = ExtensionCapability;

/** Action panels can be visible, menu-only, or hidden while still allowing local shortcuts. */
export type ActionPanelVisibility = 'visible' | 'menu' | 'hidden';
export type ViewSize = 'default' | 'large';
/**
 * Controls palette framing; side-preview pairs a selectable list with its detail pane.
 * A view-producing global command invoked while another palette view is open is
 * presented below that view. Dismissing the command restores its parent without
 * reopening it: chat drafts, attachments, and ongoing streams remain live.
 * This host-owned nesting applies independently of the view's framing.
 */
export type ViewPresentation = 'root' | 'stacked' | 'preview' | 'side-preview';
export type PatchMode = 'patch' | 'replace' | 'prepend' | 'append';
/** Independent-window behavior reported by the host OS/session capability layer. */
export type ExtensionWindowCapability =
  | 'windows.always-on-top'
  | 'windows.all-spaces'
  | 'windows.frame-restore'
  | 'windows.display-recovery';
export type ForegroundColor =
  | 'yellow'
  | 'blue'
  | 'purple'
  | 'green'
  | 'red'
  | 'orange'
  | 'pink';
/**
 * Shortcut scope for compatibility with older extensions. New extensions should
 * use `shortcut` for an action available on the selected item and
 * `globalShortcut` on commands or durable action contributions for an action
 * available from anywhere.
 */
export type ShortcutScope = 'local' | 'global';
export type ExtensionEditorFormat = 'text' | 'markdown';
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';
export type LogSource = 'main' | 'renderer' | 'extension' | 'host';
export type ExtensionFormValue = string | boolean | string[];
export type ExtensionFormFieldType =
  | 'text'
  | 'textarea'
  | 'password'
  | 'email'
  | 'url'
  | 'number'
  | 'date'
  | 'checkbox'
  | 'dropdown'
  | 'select'
  | 'multiselect'
  | 'file'
  | 'files'
  | 'folder'
  | 'description'
  | 'separator';
export type ExtensionFormOption = { title: string; value: string };

export type ExtensionActionPlacement = 'search' | 'root' | 'hidden';
export type ExtensionBackgroundMode = 'view' | 'noView' | 'background';
export type ExtensionBackgroundTrigger =
  | { type: 'startup'; delayMs?: number }
  | { type: 'interval'; every: string | number; delayMs?: number }
  /** Declare `desktop.files` for review; roots are watched by the host with debouncing, no-overlap, and bounded launch context. The host resolves `~` and `~/...` paths to absolute paths so use `~/Desktop`, `~/Downloads`, etc. directly without manual resolution. */
  | {
      type: 'files.changed';
      roots: string | string[];
      debounceMs?: number;
      includeHidden?: boolean;
      extensions?: string[];
      kind?: 'file' | 'image' | 'video' | 'media';
      ignore?: string[];
    }
  /** Declare `clipboard.history` for review; fires after Nevermind records a changed clipboard item. */
  | { type: 'clipboard.changed'; debounceMs?: number }
  /** Declare `desktop.apps` for review; backed by a host frontmost-app poller. */
  | { type: 'app.frontmost.changed'; debounceMs?: number }
  | { type: 'wake' | 'login' };

export type ExtensionLaunchContext = {
  /** Declarative trigger that started this run, when known. */
  trigger?: ExtensionBackgroundTrigger;
  /** Host event name, primarily for diagnostics. File watcher events are scoped per job. */
  event?: string;
  /** Changed file metadata for `files.changed` triggers. Bounded by the host. */
  files?: ExtensionFile[];
  /** Absolute changed paths for `files.changed` triggers. Bounded by the host. */
  changedPaths?: string[];
  /** True when a host-owned view refresh is re-running the command after the initial view was shown. */
  refresh?: boolean;
  /** Run reason such as `manual`, `startup`, `interval`, `event:*`, or `refresh`. */
  reason?: string;
  /** Epoch milliseconds for when the host started this action/job. */
  startedAt: number;
};

export type ExtensionActionContribution = {
  /** Stable local id. Global shortcuts, aliases, recents, and action refs depend on this. */
  id: string;
  /** Optional stable global action id. Defaults to `extension-action:${extension.id}:${id}`. */
  actionId?: string;
  title: string;
  subtitle?: string;
  aliases?: string[];
  keywords?: string[];
  icon?: string;
  image?: string;
  score?: number;
  /** Shortcut that opens/runs this durable action from anywhere. */
  globalShortcut?: string;
  dismissAfterRun?: 'auto';
  background?: boolean;
  customizable?: boolean;
  /** Semantic visual treatment for the action result. */
  appearance?: ExtensionItemAppearance;
  /** Durable actions are searchable and visible at the palette root by default. Use `['hidden']` only when a `rootItems()` or `searchItems()` row references the action and owns discovery. `search` and `root` are retained as discoverable legacy values. */
  placement?: ExtensionActionPlacement[];
  /** Execution lifecycle. `background`/`noView` actions are eligible for host-managed jobs and diagnostics. */
  mode?: ExtensionBackgroundMode;
  /** Declarative host-owned trigger intents. The host owns scheduling, enablement, no-overlap, backoff, and diagnostics. */
  triggers?: ExtensionBackgroundTrigger[];
  /** Declarative action to run, commonly `ctx.windows.toggle(...)`, `ctx.actions.pasteText(...)`, or `ctx.actions.push(...)`. */
  action?: ExtensionAction;
  /** Handler to run when a simple declarative action is not enough. */
  run?: (
    ctx: ExtensionContext,
    action: ExtensionAction,
  ) => ExtensionActionResult | Promise<ExtensionActionResult>;
};

export type ExtensionPasteTextOptions = {
  /** Keep the palette visible after dispatching paste. Defaults to false unless the action also overrides dismiss behavior. */
  keepPaletteOpen?: boolean;
  /** Restore the previous clipboard contents shortly after paste is dispatched. */
  restoreClipboard?: boolean;
  /** Write only plain text for paste, omitting HTML/RTF flavors. Defaults to true. */
  plainText?: boolean;
  /** Prevent temporary paste contents from being added to Nevermind clipboard history. Implies history suppression for the paste write. */
  concealed?: boolean;
  /** Delay before restoring clipboard contents, in milliseconds. Defaults to 250. */
  restoreDelayMs?: number;
  /** Only paste while this app id, bundle id, path, or name is still frontmost. */
  expectedFrontmostAppId?: string;
};

export type ExtensionTypeTextOptions = {
  /** Delay between typed characters in milliseconds where supported. */
  delayMs?: number;
};

export type ExtensionClipboardContent =
  | { type: 'text'; text: string; html?: string; concealed?: boolean }
  | { type: 'html'; html: string; text?: string; concealed?: boolean }
  | {
      type: 'image';
      imageDataUrl?: string;
      image?: string;
      path?: string;
      concealed?: boolean;
    }
  | { type: 'files'; paths: string[]; concealed?: boolean };

export type ExtensionClipboardWriteOptions = {
  /** Prevent this write from being retained by Nevermind clipboard history where possible. */
  concealed?: boolean;
};

export type ExtensionPasteOptions = ExtensionClipboardWriteOptions & {
  /** Restore the previous clipboard contents shortly after paste is dispatched. */
  restoreClipboard?: boolean;
  /** Delay before restoring clipboard contents, in milliseconds. Defaults to 250. */
  restoreDelayMs?: number;
};

export type ExtensionClipboardReadOptions = {
  formats?: Array<'text' | 'html' | 'image' | 'files'>;
};

export type ExtensionClipboardReadResult =
  | (ExtensionClipboardContent & { files?: ExtensionFile[] })
  | { type: 'empty' };

export type ExtensionWindowOptions = {
  /** Stable id local to the current extension owner. Defaults to `view.id`, then a deterministic hash. It is not a relaunch restore key. */
  id?: string;
  /** Stable key passed back to this extension's `restoreWindow` callback after relaunch. It does not identify the live window. */
  restoreKey?: string;
  /** Native window title. Defaults to the view title, then `Nevermind`. */
  title?: string;
  /** Native window title bar. Defaults to `default`; use `hidden` for title-less floating companion windows. */
  titleBar?: 'default' | 'hidden';
  /** Host chrome around the view. Defaults to `default`; use `none` for edge-to-edge companion tools. */
  chrome?: 'default' | 'none';
  /** Window width. Defaults to 560 (`size: 'large'`: 900) and is clamped to 320–1600; explicit zero is accepted and clamps to 320. */
  width?: number;
  /** Window height. Defaults to 420 (`size: 'large'`: 680) and is clamped to 240–1200; passive non-focusable windows may use 64–1200. */
  height?: number;
  /** Named dimension preset. Defaults to `default`. Explicit width/height take precedence. */
  size?: ViewSize;
  /** Keep the window above normal windows. Defaults to true. Check `windows.always-on-top` for native support. */
  alwaysOnTop?: boolean;
  /** Show the window on every workspace where supported. Defaults to false. Check `windows.all-spaces`. */
  visibleOnAllSpaces?: boolean;
  /** Hide the live window when it loses focus. Defaults to false. */
  hideOnBlur?: boolean;
  /** Do not allow this companion window to receive keyboard focus. */
  focusable?: boolean;
  /** Show without activating the application. Useful for passive indicators. */
  showInactive?: boolean;
  /** Ignore mouse input so the window cannot intercept the user's current target. */
  ignoreMouseEvents?: boolean;
  /** Position a passive companion relative to the current display work area. */
  position?: 'center' | 'top-center' | 'bottom-center';
  /**
   * Retain the window for relaunch restoration. Defaults to false.
   *
   * Relaunch restoration requires `restoreKey`. For backward compatibility,
   * `persistent: true` without a restore key remains fully functional for the
   * current session but is not restored after relaunch; results report
   * `persistence: 'session-only'` and diagnostics report `missing-restore-key`.
   */
  persistent?: boolean;
  /** Remember the owner-local id's frame after close where supported. Defaults to false. Check `windows.frame-restore` and `windows.display-recovery`. */
  remembersFrame?: boolean;
};

/** Host-owned autosave settings for an editor draft. Drafts are scoped to the owning extension and key, persisted by the host, and recovered on reopen. */
export type ExtensionEditorDraftOptions = {
  /** Stable draft key within the owning extension, e.g. the record id being edited. */
  key: string;
  /**
   * Version of the content the view was opened with (e.g. the record's
   * `updatedAt`). Opening with a different version than the stored draft
   * triggers conflict handling; a matching version recovers unsaved content.
   */
  version: string | number;
  /**
   * Debounced host autosave. The host stores every change as a draft. When
   * `action` is supplied the host also runs it with `editorContent` injected
   * so the extension can persist the record itself; its result is discarded,
   * so keep it silent and call `ctx.drafts.commit(key, newVersion)` after
   * writing.
   */
  autosave?: { debounceMs?: number; action?: ExtensionAction };
  /**
   * Runs when an existing draft has a different version than the view. The
   * host injects `draftConflict`; return a choice view or an
   * `ExtensionDraftResolution` (optionally with a follow-up `view`).
   */
  onConflict?: ExtensionAction;
};

/** Version conflict injected by the host into an editor draft's configured conflict action. */
export type ExtensionDraftConflict = {
  key: string;
  storedVersion: string | number;
  storedContent: string;
  currentVersion: string | number;
  currentContent: string;
};

/** Follow-up rendered after the host applies a draft resolution. */
export type ExtensionDraftResolutionFollowUp = {
  view?: ExtensionView;
  navigation?: 'root' | 'push' | 'replace' | 'pop';
};

/** Resolve an editor draft conflict. Migration must supply replacement content. */
export type ExtensionDraftResolution =
  | ({
      type: 'draftResolution';
      key: string;
      resolution: 'reset' | 'restore-old';
      content?: never;
    } & ExtensionDraftResolutionFollowUp)
  | ({
      type: 'draftResolution';
      key: string;
      resolution: 'migrate';
      content: string;
    } & ExtensionDraftResolutionFollowUp);

/** Fresh descriptor returned by the current extension when the host restores a persistent window. */
export type ExtensionWindowRestoreDescriptor = {
  view: ExtensionView;
  options?: ExtensionWindowOptions;
};

export type ExtensionIndicatorStatus =
  | 'recording'
  | 'transcribing'
  | 'loading'
  | 'success'
  | 'error';

export type ExtensionIndicatorInput = {
  id?: string;
  title: string;
  subtitle?: string;
  status?: ExtensionIndicatorStatus;
  value?: number;
  total?: number;
  /** Hide this indicator after the given duration. Omit it for status that remains until `hide`. */
  durationMs?: number;
};

/** In-place list/grid update returned from an action handler. */
export type ExtensionViewPatch = {
  /** How to apply item changes. Defaults to host behavior, usually patch. */
  mode?: PatchMode;
  /** Items to patch, replace, prepend, or append. Existing items are matched by stable `id`. */
  items?: Array<Partial<Omit<ExtensionItem, 'id'>> & { id: string }>;
  /** Stable item ids to remove from the current view. */
  removeItemIds?: string[];
  /** Loading state; renders the host's perimeter loading sweep. */
  isLoading?: boolean;
  /** Only set when intentionally moving focus to a visible item id; host otherwise preserves selection. */
  selectedItemId?: string;
};

/** Return shape accepted by `ctx.actions.run` handlers and command handlers. */
export type ExtensionNavigationMode = 'root' | 'push' | 'replace' | 'pop';

export type ExtensionActionResult =
  | ExtensionView
  | ExtensionAction
  | ExtensionDraftResolution
  | {
      view?: ExtensionView | null;
      action?: ExtensionAction;
      patch?: ExtensionViewPatch;
      navigation?: ExtensionNavigationMode;
    }
  | void;

/** A declarative action. Helpers under `ctx.actions.*` create these; they do not execute them. */
export type ExtensionAction = {
  /** Host action type. Prefer `ctx.actions.*` helpers instead of spelling this manually. */
  type?: string;
  title?: string;
  icon?: string;
  subtitle?: string;
  /** Shortcut for this action while its owning item is selected. */
  shortcut?: string;
  /** @deprecated Global action shortcuts belong on `globalShortcut`. */
  shortcutScope?: ShortcutScope;
  style?: 'regular' | 'destructive';
  requiresConfirmation?: boolean;
  confirmMessage?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  dismissAfterRun?: 'auto';
  /** Nested Cmd+K action panel. */
  submenu?: ExtensionActionPanel;
  /** Field values injected by the host when a form's `submitAction` runs. */
  formValues?: Record<string, ExtensionFormValue>;
  /** Current text injected by the host when an editor view's `submitAction` runs. */
  editorContent?: string;
  /** Draft-version conflict injected only into the configured editor conflict action. */
  draftConflict?: ExtensionDraftConflict;
  /** Id of the focused item injected by the host when a view's `onSelectionChange` runs. */
  selectedItemId?: string;
  /** Selected accessory value injected by the host when a search accessory's `onChange` runs. */
  value?: string;
  /** Legacy payload carrier for selection id / accessory value. Prefer `selectedItemId` or `value`. */
  text?: string;
  /** Prompt fields carried by `ctx.input.prompt(...)`. */
  /** Fields collected one at a time through prompt views or rendered as controls in legacy form views. */
  fields?: ExtensionFormField[];
  promptMessage?: string;
  submitTitle?: string;
  [key: string]: unknown;
};

export type ExtensionActionSection = {
  title?: string;
  actions: ExtensionAction[];
  lazyActions?: ExtensionAction[];
  isLoading?: boolean;
};

/** Grouped actions exposed through Cmd+K, selected-item shortcuts, and host-owned action UI. */
export type ExtensionActionPanel = {
  title?: string;
  sections: ExtensionActionSection[];
};

export type ExtensionAccessoryTone =
  | 'default'
  | 'muted'
  | 'accent'
  | 'success'
  | 'warning'
  | 'danger';
export type ExtensionItemAccessory = {
  text?: string;
  icon?: string;
  tone?: ExtensionAccessoryTone;
  tooltip?: string;
};
export type ExtensionImage =
  | string
  | {
      /** Default image used when a theme-specific image is not available. */
      src?: string;
      /** Image used while the operating system uses a light appearance. */
      light?: string;
      /** Image used while the operating system uses a dark appearance. */
      dark?: string;
      /** Final fallback when no default or theme-specific image is available. */
      fallback?: string;
      alt?: string;
      fit?: 'cover' | 'contain';
      shape?: 'square' | 'rounded' | 'circle';
      tint?: ForegroundColor | string;
      mask?: 'none' | 'rounded' | 'circle';
    };
export type ExtensionMetadataItem =
  | { type?: 'text'; label: string; value: string; copyable?: boolean }
  | { type: 'link'; label: string; value: string; url: string }
  | {
      type: 'tag';
      label?: string;
      value: string;
      tone?: ExtensionAccessoryTone;
    }
  | { type: 'separator' };
export type ExtensionDetail = {
  title?: string;
  subtitle?: string;
  /** Plain text content rendered in an opt-in side detail/preview pane. */
  text?: string;
  markdown?: string;
  metadata?: ExtensionMetadataItem[];
  image?: ExtensionImage;
  /** Video URL rendered in an opt-in side detail/preview pane. */
  video?: string;
  actions?: ExtensionAction[];
};
export type ExtensionItemAppearance = {
  /** Muted semantic color applied to the item title and Lucide/fallback icon. Images keep their original colors. */
  foreground?: ForegroundColor;
  /** Subtle accent-tinted row background for a result that should stand out without replacing selection state. */
  background?: 'accent';
  /** Elevate one consequential action as the primary result on a list, root, or grid surface. Keep other actions at normal prominence. The host owns its focus, selection, and depth; do not use this for decoration. */
  prominence?: 'primary';
};

/** Item displayed in root/search providers, list views, and grid views. */
export type ExtensionItem = {
  /** Stable id used for ranking, recents, patching, and shortcut ownership. */
  id: string;
  /** Optional stable action id for shortcuts/aliases when promoted into a persistent action. */
  actionId?: string;
  title: string;
  subtitle?: string;
  accessories?: ExtensionItemAccessory[];
  keywords?: string[];
  aliases?: string[];
  text?: string;
  /** Any Lucide icon name in camel/Pascal/kebab case, e.g. `camera`, `volume-2`, `audio-lines`. */
  icon?: string;
  /** A single text glyph rendered natively as the visual for a grid tile. Use for emoji, symbols, and characters instead of generating image data URLs. */
  glyph?: string;
  /** Display image URL/data URL or image descriptor. For local files use `file.url` or `ctx.desktop.files.toFileUrl(path)`, not raw paths. */
  image?: ExtensionImage;
  video?: string;
  videoUrl?: string;
  path?: string;
  filePath?: string;
  fileUrl?: string;
  /** Enter/default behavior. For a stable root action, reference a durable `actions(ctx)` contribution with `ctx.actions.ref(...)` so the host can expose aliases, shortcuts, and Options. */
  primaryAction?: ExtensionAction;
  /** Secondary actions shown by Cmd+K. Do not repeat `primaryAction`; the host removes duplicate primary entries. */
  actions?: ExtensionAction[];
  actionPanel?: ExtensionActionPanel;
  actionPanelVisibility?: ActionPanelVisibility;
  appearance?: ExtensionItemAppearance;
  /** Show contextual information without making it selectable. */
  disabled?: boolean;
  /** Optional detail/inspector content rendered by list views with `view.detail.visible`. */
  detail?: ExtensionDetail;
  /** Local shortcut for this item's action; shown only while this item is selected. */
  shortcut?: string;
  /** @deprecated Use `globalShortcut` for durable global actions. */
  shortcutScope?: ShortcutScope;
  /** Global shortcut for this durable/root action. */
  globalShortcut?: string;
  /** Set false when an item should be searchable but not user-customizable. */
  customizable?: boolean;
  /** Dismiss immediately for fire-and-forget persistent actions. */
  background?: boolean;
  /** Ranking hint. The host caps provider scores and combines them with usage signals. */
  score?: number;
  /** Milliseconds since epoch. The host treats this as an intrinsic recency signal alongside recorded use. */
  lastUsed?: number;
  dismissAfterRun?: 'auto';
  [key: string]: unknown;
};

export type ExtensionItemSection = {
  title?: string;
  subtitle?: string;
  items: ExtensionItem[];
};

/** One record in a reusable host-rendered CRUD collection. Supply only the operations your data model supports. Item ids must not start with the host-reserved `__nvm:` prefix. */
export type ExtensionCrudItem = Omit<
  ExtensionItem,
  'primaryAction' | 'actions' | 'actionPanel'
> & {
  /** Opens a read-only or rich preview for this record. Becomes the default Enter action. */
  preview?: ExtensionAction;
  /** Opens an editor or prompt for this record. Defaults to the `⌘E` shortcut; becomes Enter when no preview is set. */
  edit?: ExtensionAction;
  /**
   * Removes this record. The host defaults to the `⌘⌫` shortcut, destructive
   * styling, and a confirmation prompt (`Remove “<title>”?`); override any of
   * them on the action itself.
   */
  remove?: ExtensionAction;
};

/** A generic, host-owned CRUD collection: list/search chrome plus consistent add, preview, edit, and remove actions. */
export type ExtensionCrudCollection = {
  id?: string;
  title: string;
  subtitle?: string;
  searchBarPlaceholder?: string;
  emptyView?: { title?: string; subtitle?: string };
  /** Creates a new record. The host renders this as the always-visible first collection row and in the collection action panel. */
  add?: ExtensionAction;
  items: ExtensionCrudItem[];
};

export type ExtensionPagination = {
  hasMore?: boolean;
  pageSize?: number;
  onLoadMore?: ExtensionAction;
};

export type ExtensionSearchAccessory = {
  id?: string;
  tooltip?: string;
  value?: string;
  items: Array<{ title: string; value: string }>;
  onChange?: ExtensionAction;
};

export type ExtensionWebviewPermission =
  | 'autoplay'
  | 'camera'
  | 'microphone'
  | 'display-capture'
  | 'clipboard-read'
  | 'clipboard-write';

/** Host-rendered view. Prefer helpers such as `ctx.ui.list(...)` so the `type` is set for you. */
export type ExtensionView = {
  id?: string;
  type?:
    | 'list'
    | 'grid'
    | 'preview'
    | 'chat'
    | 'prompt'
    | 'form'
    | 'editor'
    | 'progress'
    | 'webview'
    | 'camera';
  title: string;
  size?: ViewSize;
  /** List views only: `fit` wraps a short status-style list instead of filling the palette. Defaults to `fill`. */
  contentSizing?: 'fill' | 'fit';
  presentation?: ViewPresentation;
  subtitle?: string;
  content?: string;
  /** Optional host-owned draft lifecycle for editor views only. */
  draft?: ExtensionEditorDraftOptions;
  /** Placeholder for editable text surfaces such as `ctx.ui.editor(...)`. */
  placeholder?: string;
  /** Text format for editable text surfaces. Markdown editors render rich headings, emphasis, links, code, lists, and checklists in place while preserving Markdown storage. */
  format?: ExtensionEditorFormat;
  /** Markdown editors only: render a split host-rendered live preview next to the text. Defaults to false. */
  preview?: boolean;
  /** Editor views only: derive and live-update the visible title from the first non-empty content line. Markdown heading markers are stripped. */
  titleFromContent?: boolean;
  /** Optional language hint for text/code editors. */
  language?: string;
  /** Render an editor as read-only while preserving selection/copy behavior. */
  readOnly?: boolean;
  html?: string;
  /** Sandboxed webview iframe permissions. Defaults to `['autoplay']`; camera, microphone, display capture, and clipboard access are explicit opt-ins. */
  webviewPermissions?: ExtensionWebviewPermission[];
  image?: ExtensionImage;
  video?: string;
  videoUrl?: string;
  deviceId?: string;
  showDeviceSwitcher?: boolean;
  muted?: boolean;
  controls?: boolean;
  /** View items or a lazy loader handle from `ctx.data.loader()` or `ctx.data.staleWhileRevalidate()`. When a loader handle is used, the host owns the loading lifecycle and `emptyView` is required. */
  items?: ExtensionItem[] | ExtensionDataLoaderHandle;
  sections?: ExtensionItemSection[];
  /** Loading state; renders the host's perimeter loading sweep. */
  isLoading?: boolean;
  emptyView?: { title?: string; subtitle?: string };
  /** Optional item detail pane for richer list views. `presentation: 'side-preview'` uses this as the selected-item preview. */
  detail?: { placement?: 'side' | 'bottom'; visible?: boolean };
  searchBarPlaceholder?: string;
  /** Initial focused item for list/grid views. Must match a stable visible item id; sorting remains independent. */
  selectedItemId?: string;
  /** Maximum filtered items rendered at once for an item-backed grid. Keep the complete item set searchable while bounding large grid DOM work; use search or category filters to reach items beyond the visible cap. */
  maxVisibleItems?: number;
  onSelectionChange?: ExtensionAction;
  pagination?: ExtensionPagination;
  searchAccessory?: ExtensionSearchAccessory;
  /** Host-owned visible-view refresh. Use `immediate: true` to render a cheap persisted/snapshot cache first, then refresh after paint and update that cache for the next open; the renderer receives an opaque host handle, never an executable action. */
  refresh?: {
    intervalMs?: number;
    mode?: PatchMode;
    immediate?: boolean /** @deprecated Refresh is host-owned; omit `action` for new extensions. */;
    action?: ExtensionAction;
  };
  actions?: ExtensionAction[];
  actionPanel?: ExtensionActionPanel;
  actionPanelVisibility?: ActionPanelVisibility;
  /** @deprecated Action menus and nested submenus are compact on every surface; this property is ignored. Independent-window confirmations stay in the compact menu, while prompts use the full palette. */
  actionPanelPresentation?: 'default' | 'compact';
  /** Independent windows only: render this result as a compact overlay while preserving the current base view. Other surfaces render it normally. */
  windowPresentation?: 'default' | 'compact';
  layout?: 'square' | 'wide' | 'compact';
  aspectRatio?: string | number;
  columns?: number;
  messages?: Array<{ role: 'user' | 'assistant' | 'system'; content: string }>;
  fields?: ExtensionFormField[];
  submitAction?: ExtensionAction;
  steps?: Array<{ title: string; status?: string }>;
  /** Current progress value for progress views. Pair with `total` for a determinate bar. */
  value?: number;
  /** Total progress value for progress views. Pair with `value` for a determinate bar. */
  total?: number;
  /** Human-readable progress label rendered in compact progress surfaces. */
  label?: string;
  /** Human-readable progress summary, e.g. `Downloading assets…`. */
  status?: string;
  [key: string]: unknown;
};

export type ExtensionFormField = {
  id: string;
  label?: string;
  type?: ExtensionFormFieldType;
  value?: ExtensionFormValue;
  placeholder?: string;
  required?: boolean;
  /** Prevent interaction while keeping the field and its explanation visible. */
  disabled?: boolean;
  options?: ExtensionFormOption[];
  description?: string;
  error?: string;
  rows?: number;
  /** File extensions allowed by file/files fields, e.g. ['png', 'jpg'] or ['.md']. */
  extensions?: string[];
  /** Display name for extension filters in native file pickers. */
  filterName?: string;
  /** Picker button label for file/files/folder fields. */
  buttonLabel?: string;
  /** Optional starting path for file/files/folder fields. Supports ~ expansion. */
  defaultPath?: string;
  /** Whether folder pickers should allow creating folders. Defaults to true. */
  canCreateDirectories?: boolean;
};

export type ExtensionFileKind = 'image' | 'video' | 'file' | string;

/** File object returned by `ctx.desktop.files.*` helpers. */
export type ExtensionFile = {
  path: string;
  name: string;
  displayPath?: string;
  /** Thumbnail-safe display URL for Electron views. */
  url?: string;
  fileUrl?: string;
  videoUrl?: string;
  thumbnailUrl?: string;
  kind?: ExtensionFileKind;
  extension?: string;
  mimeType?: string;
  width?: number;
  height?: number;
  mtime?: string;
  mtimeMs?: number;
  birthtime?: string;
  birthtimeMs?: number;
  dateAdded?: string;
  dateAddedMs?: number;
  size?: number;
};

export type ExtensionFindFilesOptions = {
  limit?: number;
  depth?: number;
  extensions?: string[];
  kind?: 'image' | 'video' | 'media' | 'file' | string;
  pattern?: string | string[];
  /** `added` is usually best for Downloads/screenshots; `recent`/`modified` use filesystem mtime. */
  sortBy?: 'recent' | 'modified' | 'added' | 'created' | 'name' | 'size';
  order?: 'asc' | 'desc';
  /** Loads image dimensions during scans. Defaults false because native image metadata can block large media grids; use `metadata(path)` for one-off detail hydration. */
  includeDimensions?: boolean;
  /** Maximum matching candidates to inspect before sorting. Defaults to the host cap; lower this for huge roots when approximate newest results are acceptable. */
  scanLimit?: number;
};

export type ExtensionFileIndexOptions = ExtensionFindFilesOptions & {
  /** Roots to scan or filter, e.g. ['~/Downloads']. Defaults to Desktop/Documents/Downloads. */
  roots?: string | string[];
  /** Include hidden dotfiles during explicit reindex scans. Defaults to false. */
  includeHidden?: boolean;
  /** Ignore basenames or simple wildcard patterns such as '*.tmp'. Defaults include node_modules, .git, Library, and Applications. */
  ignore?: string | string[];
  /** Filter an existing snapshot by query. `searchIndex(query)` sets this for you. */
  query?: string;
};

export type ExtensionOcrBlock = {
  text: string;
  confidence?: number;
  boundingBox?: { x: number; y: number; width: number; height: number };
};
export type ExtensionOcrResult = {
  text: string;
  confidence?: number | null;
  language?: string | null;
  blocks?: ExtensionOcrBlock[];
};
export type ExtensionOcrOptions = {
  language?: string;
  languages?: string[];
  timeoutMs?: number;
};
export type ExtensionOcrRegion = {
  x: number;
  y: number;
  width: number;
  height: number;
};

export type ExtensionShellResult = {
  stdout: string;
  stderr: string;
  exitCode: number;
};
export type ExtensionShellOptions = {
  cwd?: string;
  env?: Record<string, string>;
  timeout?: number;
  shell?: boolean;
  outputLimit?: number;
};
/** An installed application from `ctx.desktop.apps.list/search`. Use `id` for item identity and `name` for display titles. */
export type ExtensionApp = {
  id: string;
  name: string;
  path: string;
  /** When Nevermind first observed this app after its initial app-index baseline. Replacements at the same app identity keep their original timestamp. */
  firstSeenAt?: number;
  [key: string]: unknown;
};
/** An app that can open a specific file. Returned by `ctx.desktop.files.openWithApps(filePath)`. */
export type ExtensionOpenWithApp = ExtensionApp;
/** A host-indexed file from `ctx.desktop.files.indexSnapshot/recent/searchIndex`. */
export type ExtensionIndexedFile = {
  id: string;
  name: string;
  path: string;
  displayPath?: string;
  extension?: string;
  kind?: ExtensionFileKind;
  url?: string;
  fileUrl?: string;
  videoUrl?: string | null;
  thumbnailUrl?: string | null;
  mtimeMs?: number;
  birthtimeMs?: number;
  dateAddedMs?: number;
  size?: number;
};

export type RecentLogOptions = {
  limit?: number;
  level?: LogLevel;
  source?: LogSource;
  sinceMs?: number;
  query?: string;
  extensionId?: string;
};
export type LogEntry = {
  timestamp: string;
  level: LogLevel;
  source: LogSource;
  scope?: string;
  extensionId?: string;
  commandId?: string;
  message: string;
  data?: unknown;
};

export type ExtensionStorage = {
  /** Persistent per-extension JSON state stored in app data. Use it for first-paint snapshots that lazy refreshes revalidate for the next open. */
  get<T = unknown>(key: string, fallback?: T): Promise<T | undefined>;
  set<T = unknown>(key: string, value: T): Promise<T>;
  delete(key: string): Promise<void>;
  clear(): Promise<void>;
  /** Persisted OS-cache memo. Use for expensive work that can be recomputed. */
  memo<T = unknown>(
    key: string,
    ttlMs: number,
    loader: () => Promise<T> | T,
  ): Promise<T>;
  /** Returns stale cached data while a background refresh runs when possible. */
  memoStale<T = unknown>(
    key: string,
    ttlMs: number,
    staleTtlMs: number,
    loader: () => Promise<T> | T,
  ): Promise<T>;
};

export type ExtensionRuntimeCache = {
  /** Process-memory cache; not persistent. Entries are scoped to this extension. */
  get<T = unknown>(key: string): T | undefined;
  getStale<T = unknown>(key: string): T | undefined;
  set<T = unknown>(key: string, value: T, options?: { ttlMs?: number }): T;
  has(key: string): boolean;
  invalidate(key?: string): void;
};

export type ExtensionSettings = {
  definitions(): Array<{
    id: string;
    title?: string;
    description?: string;
    type?: string;
    value?: unknown;
    [key: string]: unknown;
  }>;
  get<T = unknown>(id: string): T;
  set<T = unknown>(id: string, value: T): T;
  toggle(id: string): unknown;
};

export type ExtensionDictationDevice = {
  id: string;
  title: string;
  isDefault: boolean;
};

export type ExtensionDictationStatus =
  | 'idle'
  | 'recording'
  | 'transcribing'
  | 'error';

export type ExtensionDictation = {
  status(): Promise<ExtensionDictationStatus>;
  /** Whether authenticated hosted transcription is available for this client. */
  apiAvailable(): Promise<boolean>;
  devices(): Promise<ExtensionDictationDevice[]>;
  /** Resolves after the microphone has delivered usable, stable audio. Audio is transcribed by Nevermind's hosted service after `stop()`. */
  start(options?: {
    deviceId?: string;
    /** Mute system output while recording and restore its prior state before transcription. */
    muteSystemAudioWhileRecording?: boolean;
  }): Promise<void>;
  /** Stops capture and resolves with the hosted transcription. Recorded audio is not exposed to extension code. */
  stop(): Promise<string>;
  cancel(): Promise<void>;
  /** Built-in Dictation only: lists locally saved recordings whose hosted transcription did not complete. Audio stays on this device. */
  recordings?(): Promise<
    Array<{ id: string; createdAt: number; segmentCount: number }>
  >;
  /** Built-in Dictation only: retries transcription of a saved recording. Delete the audio after saving the returned transcript. */
  retry?(id: string): Promise<string>;
  /** Built-in Dictation only: permanently deletes a saved recording from this device. */
  deleteRecording?(id: string): Promise<void>;
};

export type ExtensionShortcutRecord = {
  actionId: string;
  title: string;
  subtitle?: string;
  accelerator: string;
  scope: 'global';
  source: 'user' | 'extension';
};

export type ExtensionPaletteShortcut = {
  title: string;
  accelerator: string;
  scope: 'palette';
};

export type ExtensionLogs = Record<
  LogLevel,
  (message: string, data?: unknown) => void
> & {
  recent(options?: RecentLogOptions): Promise<LogEntry[]>;
};

export type ExtensionAiAttachment =
  | string
  | { type: 'text'; text: string; title?: string }
  | {
      type: 'image';
      path?: string;
      filePath?: string;
      dataUrl?: string;
      imageDataUrl?: string;
      data?: string;
      mimeType?: string;
      title?: string;
      ocr?: boolean;
    }
  | {
      type: 'file';
      path?: string;
      filePath?: string;
      file?: ExtensionFile;
      title?: string;
      as?: 'text' | 'image' | 'metadata' | 'ocr';
      ocr?: boolean;
    };

export type ExtensionAiResolvableAttachment =
  | ExtensionAiAttachment
  | ExtensionAiAttachment[]
  | null
  | Promise<ExtensionAiAttachment | ExtensionAiAttachment[] | null>;

export type ExtensionAiStreamEvent =
  | { type: 'start' }
  | { type: 'delta'; text: string }
  | { type: 'tool_start' | 'tool_end'; name?: string; isError?: boolean }
  | { type: 'done' }
  | { type: 'aborted' }
  | { type: 'error'; message?: string; data?: unknown };

export type ExtensionAiModel = 'smart' | 'fast';

export type ExtensionAiOptions = {
  /** Selects Smart or Fast; the backend applies the user's Pro or Free entitlement. */
  model?: ExtensionAiModel;
  system?: string;
  /** Text, file, image, selected, clipboard, or OCR context. Declare the matching capabilities for review; declarations do not gate attachment helpers. */
  attachments?:
    | ExtensionAiResolvableAttachment
    | ExtensionAiResolvableAttachment[];
  /** Abort the request with a standard AbortController. */
  signal?: AbortSignal;
  onDelta?: (delta: string) => void;
  onEvent?: (event: ExtensionAiStreamEvent) => void;
};

export type ExtensionAiStream = {
  /** Resolves to the full assistant text after streaming completes. */
  result: Promise<string>;
  /** Abort the in-flight request. */
  abort(): void;
};

/** Opaque handle returned by `ctx.data.loader()` or `ctx.data.staleWhileRevalidate()`. The host replaces it with resolved items after the loader completes. */
export type ExtensionDataLoaderHandle = { _loader: true };

/** Lazy data fetching. The host owns the loading/error/empty lifecycle. */
export type ExtensionData = {
  /**
   * Declare items that resolve asynchronously. The view skeleton paints immediately;
   * the loader runs in the background. When it resolves, items are patched into the
   * already-visible view. While it runs, the host shows only the perimeter sweep.
   * On failure, the host shows an error view with an optional retry button.
   *
   * The returned handle is opaque to extensions. Assign it to `view.items`.
   */
  loader(
    fn: () => Promise<ExtensionItem[]>,
    options?: { retry?: boolean },
  ): ExtensionDataLoaderHandle;
  /**
   * Declare items that resolve with stale-while-revalidate semantics.
   * Returns a loader handle assigned to `view.items`; the host owns the
   * cache and loading lifecycle.
   *
   * **Fresh cache** (age < `ttlMs`): Cached items render immediately, no
   * loading indicator, no background refresh.
   *
   * **Stale cache** (between `ttlMs` and `staleTtlMs`): Cached items render
   * immediately with the perimeter sweep. The loader refreshes in the
   * background and patches in fresh items.
   *
   * **No cache or expired** (age > `staleTtlMs`): Behavior matches
   * `loader()` — the host shows the perimeter sweep, then renders items.
   *
   * **Loader failure with stale cache**: Shows stale items as a graceful
   * fallback instead of an error view.
   *
   * The `loader` must return JSON-serializable items. Use `ctx.actions.*`
   * helpers for primary actions — do not attach raw function handlers to
   * cached items.
   *
   * @param cacheKey - Stable key for the extension's persistent cache.
   * @param ttlMs - Items are fresh within this time. Defaults to 60_000 (1 minute).
   * @param staleTtlMs - Stale items shown immediately with loading indicator; background refresh. Defaults to 300_000 (5 minutes).
   * @param loader - Async function returning JSON-serializable items.
   * @param retry - Show a retry button on error (only when no stale cache fallback).
   */
  staleWhileRevalidate(options: {
    cacheKey: string;
    ttlMs?: number;
    staleTtlMs?: number;
    loader: () => Promise<ExtensionItem[]>;
    retry?: boolean;
  }): ExtensionDataLoaderHandle;
};

export type ExtensionAi = {
  /** Whether the user is signed in and can use Nevermind AI features. */
  isAvailable(): Promise<boolean>;
  /** Easy one-shot AI call. Quota-limited per extension; declare the `ai` capability for review. Smart/fast routes are configured by the backend admin. */
  (prompt: string, model?: ExtensionAiModel): Promise<string>;
  (prompt: string, options?: ExtensionAiOptions): Promise<string>;
  /** One-shot AI call. Quota-limited per extension; declare the `ai` capability for review. Supports attachments and AbortController signals. */
  ask(prompt: string, model?: ExtensionAiModel): Promise<string>;
  ask(prompt: string, options?: ExtensionAiOptions): Promise<string>;
  /** Warm the reusable one-shot AI runtime and model route before latency-sensitive work. */
  prepare(options?: ExtensionAiOptions): Promise<void>;
  /** Streaming AI call. Use `onDelta`/`onEvent` for incremental updates and await `result` for the final text. */
  stream(prompt: string, model?: ExtensionAiModel): ExtensionAiStream;
  stream(prompt: string, options?: ExtensionAiOptions): ExtensionAiStream;
  /** Attachment builders normalize host-owned context for AI prompts. */
  attachments: {
    text(text: string, title?: string): ExtensionAiAttachment;
    image(
      pathOrDataUrl: string,
      options?: { title?: string; ocr?: boolean },
    ): ExtensionAiAttachment;
    file(
      pathOrFile: string | ExtensionFile,
      options?: {
        title?: string;
        as?: 'text' | 'image' | 'metadata' | 'ocr';
        ocr?: boolean;
      },
    ): ExtensionAiAttachment;
    selectedText(title?: string): Promise<ExtensionAiAttachment>;
    selectedFiles(options?: {
      title?: string;
      as?: 'text' | 'image' | 'metadata' | 'ocr';
      ocr?: boolean;
    }): Promise<ExtensionAiAttachment[]>;
    clipboard(options?: {
      title?: string;
      as?: 'text' | 'image' | 'metadata' | 'ocr';
      ocr?: boolean;
    }): Promise<ExtensionAiAttachment | ExtensionAiAttachment[] | null>;
    ocrImage(
      pathOrDataUrlOrFile: string | ExtensionFile,
      options?: { title?: string },
    ): Promise<ExtensionAiAttachment>;
  };
  /** Per-extension conversational session. Session ids are scoped to the extension. */
  session(
    id?: string,
    options?: { system?: string; model?: ExtensionAiModel },
  ): {
    ask(prompt: string, model?: ExtensionAiModel): Promise<string>;
    ask(prompt: string, options?: ExtensionAiOptions): Promise<string>;
    stream(prompt: string, model?: ExtensionAiModel): ExtensionAiStream;
    stream(prompt: string, options?: ExtensionAiOptions): ExtensionAiStream;
    reset(): unknown;
  };
};

export type ExtensionOwnership = {
  ownerOf(extensionFile: string): string | undefined;
  filesForChat(chatId: string): string[];
  canWrite(extensionFile: string, chatId: string): boolean;
  /** Host-only mutator exposed to the built-in AI Builder extension. */
  claim?(extensionFile: string, chatId: string): boolean;
  /** Host-only mutator exposed to the built-in AI Builder extension. */
  remove?(extensionFile: string, chatId: string): Promise<boolean>;
  /** Host-only mutator exposed to the built-in AI Builder extension. */
  reload?(): Promise<void>;
};

export type ExtensionTemplateValue =
  | string
  | number
  | boolean
  | string[]
  | null
  | undefined;
export type ExtensionTemplateResult = {
  text: string;
  cursor?: number;
  missingVariables?: string[];
};
export type ExtensionTemplateOptions = {
  variables?: Record<string, ExtensionTemplateValue>;
  /** Return `{ text, cursor, missingVariables }` instead of a string. */
  returnResult?: boolean;
  /** Return cursor position for `{cursor}` placeholders. Alias for `returnResult`. */
  returnCursor?: boolean;
  /** Internal marker used while calculating cursor position. Defaults to a private sentinel. */
  cursorToken?: string;
  /** Include `{clipboard}` when the extension has `clipboard.history`. Defaults to true when permitted. */
  includeClipboard?: boolean;
  /** Include `{selectedText}`. Defaults to true. */
  includeSelectedText?: boolean;
  /** Include missing variable names in the result; pair with `ctx.input.prompt(...)` for prompted arguments. */
  promptMissing?: boolean;
};

export type ExtensionText = {
  /**
   * Expand host-standard text templates. Variables use `{name}` or `{{name}}`.
   * Built-ins include `{date}`, `{time}`, `{datetime}`, `{uuid}`, `{selectedText}`, `{clipboard}`,
   * `{cursor}`, `{argument:name}`, and `{calculator:1 + 2}`. Explicit variables override built-ins.
   */
  template(
    input: string,
    variables?: Record<string, ExtensionTemplateValue>,
  ): Promise<string>;
  template(
    input: string,
    options: ExtensionTemplateOptions & { returnResult: true },
  ): Promise<ExtensionTemplateResult>;
  template(
    input: string,
    options: ExtensionTemplateOptions & { returnCursor: true },
  ): Promise<ExtensionTemplateResult>;
  template(
    input: string,
    options: ExtensionTemplateOptions,
  ): Promise<string | ExtensionTemplateResult>;
};

export type ExtensionAiBuilder = {
  /** Host-only surface: available to the built-in `nevermind.ai-builder` extension. */
  /** Removes expired conversations while preserving builder chats. */
  cleanupExpiredConversations(): Promise<number>;
  startChat(input: {
    prompt: string;
    title?: string;
    options?: Record<string, unknown>;
  }): ExtensionAction;
  openChat(
    chatId: string,
    input?: { title?: string; options?: Record<string, unknown> },
  ): ExtensionAction;
  removeChat(
    chatId: string,
    input?: { title?: string; options?: Record<string, unknown> },
  ): ExtensionAction;
  tweakExtension(input: {
    extensionFile?: string;
    extensionId?: string;
    title?: string;
    prompt?: string;
    options?: Record<string, unknown>;
  }): ExtensionAction;
  openChatsList(input?: {
    title?: string;
    options?: Record<string, unknown>;
  }): ExtensionAction;
  listChats(): Array<{
    id: string;
    title?: string;
    query?: string;
    status?: string;
    createdAt?: number;
    updatedAt?: number;
    extensionFiles: string[];
  }>;
  getChat(chatId: string): {
    id: string;
    title?: string;
    query?: string;
    status?: string;
    messages?: unknown[];
    extensionFiles: string[];
  } | null;
};

/** A clipboard history entry returned by `ctx.clipboard.history.list/search`. */
export type ExtensionClipboardEntry = {
  id: string;
  type?: string;
  text?: string;
  imageDataUrl?: string;
  imagePath?: string;
  videoUrl?: string;
  filePath?: string;
  thumbnailUrl?: string;
  createdAt?: number;
};

/** Clipboard history access for enabled trusted extensions. Declare `clipboard.history` as review metadata. Destructive helpers are host-managed and return counts. */
export type ExtensionClipboardHistory = {
  list(options?: {
    limit?: number;
    query?: string;
    types?: string[];
  }): ExtensionClipboardEntry[];
  search(
    query: string,
    options?: { limit?: number; types?: string[] },
  ): ExtensionClipboardEntry[];
  get(id: string): ExtensionClipboardEntry | null;
  remove(idOrIds: string | string[]): Promise<{ removed: number }>;
  clear(options?: {
    types?: string[];
    olderThanMs?: number;
  }): Promise<{ removed: number }>;
};

/**
 * Read-only OS metadata. Use `capabilities.has(...)` to omit unsupported items from
 * discovery instead of duplicating platform logic, and `labels.*` for OS-appropriate titles.
 */
export type ExtensionSystem = {
  /** Display label for the host OS, e.g. `macOS`. */
  os: string;
  capabilities: { has(id: ExtensionWindowCapability | string): boolean };
  labels: {
    revealInFileManager: string;
    previewFile: string;
    openSystemSettings: string;
    keyboardSettings: string;
  };
};

/** Serializable snapshot of the host update manager, returned by `ctx.updates.getState()`. */
export type ExtensionUpdateState = {
  currentVersion: string;
  status: string;
  supported: boolean;
  checking: boolean;
  downloading: boolean;
  installing: boolean;
  availableVersion: string | null;
  downloadedVersion: string | null;
  errorMessage: string | null;
};

export type ExtensionContext = {
  /** Cooperative cancellation for query providers. Present only while `searchItems` is running; pass it to fetch or other abort-aware work. */
  readonly signal?: AbortSignal;
  /** Runtime metadata for the current extension plus host helpers such as persistent rename. */
  extension: NevermindExtension & {
    rename(
      metadata:
        | string
        | {
            title?: string;
            subtitle?: string;
            commandTitle?: string;
            commandSubtitle?: string;
          },
    ): Promise<unknown>;
  };
  command?: ExtensionCommand;
  /** Host-owned launch context. Populated for: host-owned `refresh:` view refreshes (reason `"refresh"`), all declarative `triggers`-driven runs (startup, interval, clipboard.changed, files.changed, app.frontmost.changed, wake, login), and any action dispatched from a triggered context. Undefined for: manual palette opens (user types command name), `ctx.actions.run()` handler invocations, and `ctx.views.refresh()` handler invocations dispatched from non-triggered contexts. Check `ctx.launch?.refresh` or `ctx.launch?.reason === "refresh"` to distinguish background revalidation from manual opens. */
  launch?: ExtensionLaunchContext;

  /** Declarative host-owned UI primitives. Nevermind owns rendering, navigation, filtering, actions, shortcuts, and errors. */
  ui: {
    list(view: ExtensionView): ExtensionView;
    /** A generic list/search surface that consistently wires supplied add, preview, edit, and remove actions. */
    collection(input: ExtensionCrudCollection): ExtensionView;
    grid(view: ExtensionView): ExtensionView;
    /** Full preview view for markdown/text/media. */
    preview(view: ExtensionView): ExtensionView;
    /** Large media preview from a file helper result. */
    preview(file: ExtensionFile, view?: Partial<ExtensionView>): ExtensionView;
    /** Inline preview action, commonly for clipboard/file items. Its shortcut is local to the selected item. */
    preview(input: {
      kind?: 'clipboard' | 'image' | 'video' | 'file' | 'text';
      title?: string;
      text?: string;
      imageDataUrl?: string;
      imagePath?: string;
      videoUrl?: string;
      filePath?: string;
      thumbnailUrl?: string;
      clipboardType?: string;
      shortcut?: string;
    }): ExtensionAction;
    chat(view: ExtensionView): ExtensionView;
    /** Structured settings form shown as searchable palette rows. Enter edits the selected field through the palette input, choice rows, an editor, or a native picker; Escape returns to the form without discarding other draft values. Select the submit row or press Command+Enter to save. Prefer `ctx.input.prompt` for lightweight arguments. */
    form(view: ExtensionView): ExtensionView;
    /** Editable host-owned text/Markdown surface. Markdown is rendered as single-pane rich text with Markdown shortcuts while remaining the persisted value. The host injects `editorContent` into `submitAction`; use `titleFromContent` for note-like documents instead of a separate rename flow. */
    editor(view: ExtensionView): ExtensionView;
    progress(input?: {
      title?: string;
      label?: string;
      steps?: Array<{ title: string; status?: string }>;
      id?: string;
      value?: number;
      total?: number;
      status?: string;
    }): ExtensionView;
    /** Wrap a declarative action in a host-rendered confirmation step. */
    confirm(input?: {
      title?: string;
      message?: string;
      confirmLabel?: string;
      cancelLabel?: string;
      destructive?: boolean;
      onConfirm?: ExtensionAction;
      action?: ExtensionAction;
    }): ExtensionAction;
    /** Passive always-on-top status indicator that never takes focus. */
    indicator: {
      show(input: ExtensionIndicatorInput): void;
      update(input: ExtensionIndicatorInput): void;
      hide(id?: string): void;
    };
    /** Sandboxed HTML/JS iframe with no Node access. Use only when host-owned primitives do not fit. */
    webview(view: ExtensionView): ExtensionView;
    /** Host-owned live camera view. Declare `camera`; use `ctx.actions.camera.*` for switching/mute controls. */
    camera(view?: ExtensionView): ExtensionView;
    item<T extends ExtensionItem>(item: T): T;
    actions<T extends ExtensionAction[]>(actions: T): T;
    empty(title?: string, subtitle?: string): ExtensionView;
    /** Compact loading-only list surface; the host renders the perimeter sweep instead of an inline spinner or progress screen. */
    loading(title?: string): ExtensionView;
    error(title?: string, message?: string): ExtensionView;
  };

  /** Declarative actions. Creating one does not run it; return it or attach it to an item/view. */
  actions: {
    openPath(
      filePath: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    revealPath(
      filePath: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    quickLook(
      filePath: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    openWith(
      filePath: string,
      app: ExtensionOpenWithApp | string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    openUrl(
      url: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    copyText(
      text: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    pasteText(
      text: string,
      title?: string,
      options?: ExtensionPasteTextOptions & Record<string, unknown>,
    ): ExtensionAction;
    /** Paste text/html/image/files through the host while preserving concealed/restore behavior. */
    paste(
      content: ExtensionClipboardContent,
      title?: string,
      options?: ExtensionPasteOptions & Record<string, unknown>,
    ): ExtensionAction;
    /** Reference a persistent action declared by `actions(ctx)` using its local contribution `id` (`registeredActionId`), not the optional global `actionId`. Use for root `primaryAction` values and inside views so rows share aliases/shortcuts/options with the durable action. */
    ref(
      registeredActionId: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Type text into the frontmost app without touching the clipboard. Check `ctx.system.capabilities.has('keyboard.type-text')` for support. */
    typeText(
      text: string,
      title?: string,
      options?: ExtensionTypeTextOptions & Record<string, unknown>,
    ): ExtensionAction;
    copyImage(
      image: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Destructive by default and confirmation-gated by the host. */
    trash(
      paths: string | string[],
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Replace the palette's current navigation stack with this view. Use for top-level destinations, not drill-down rows. */
    root(
      title: string,
      view: ExtensionView | null,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Drill into a child view and let Escape return to the current view. */
    push(
      title: string,
      view: ExtensionView | null,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Swap the current view without adding a back-stack entry. */
    replace(
      title: string,
      view: ExtensionView | null,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    pop(title?: string, options?: Record<string, unknown>): ExtensionAction;
    run(
      title: string,
      handler: (
        ctx: ExtensionContext,
        action: ExtensionAction,
      ) => ExtensionActionResult | Promise<ExtensionActionResult>,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Fire-and-forget action that dismisses the palette immediately unless options override it. */
    background(
      title: string,
      handler: (
        ctx: ExtensionContext,
        action: ExtensionAction,
      ) => ExtensionActionResult | Promise<ExtensionActionResult>,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Run a shell command. Declare the `system` capability for review. */
    shellExec(
      title: string,
      command: string,
      args?: string[],
      options?: ExtensionShellOptions,
    ): ExtensionAction;
    /** Run a shell script through `/bin/bash -lc` by default. Declare the `system` capability for review. */
    shellScript(
      title: string,
      script: string,
      options?: ExtensionShellOptions,
    ): ExtensionAction;
    toggleSetting(
      settingId: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    recordShortcut(
      input?: {
        actionId?: string;
        scope?: 'palette' | ShortcutScope;
        title?: string;
        action?: ExtensionAction;
      },
      options?: Record<string, unknown>,
    ): ExtensionAction;
    removeShortcut(
      input?: { actionId?: string; title?: string },
      options?: Record<string, unknown>,
    ): ExtensionAction;
    setPaletteShortcut(
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    native(
      title: string,
      nativeAction: unknown,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** OS-owned system actions. Declare the `system` capability for review. Titles default to OS-appropriate labels. `openSystemSettings` accepts `{ paneId, anchor }` to deep-link a settings pane and section. */
    system: Record<
      | 'lockScreen'
      | 'sleep'
      | 'restart'
      | 'openSystemSettings'
      | 'openKeyboardSettings'
      | 'quit',
      (title?: string, options?: Record<string, unknown>) => ExtensionAction
    >;
    /** App update actions; progress is rendered by the host's Updates status view. Declare the `updates` capability for review. */
    updates: Record<
      'check' | 'download' | 'install',
      (title?: string, options?: Record<string, unknown>) => ExtensionAction
    >;
    camera: Record<
      | 'switchDevice'
      | 'nextDevice'
      | 'previousDevice'
      | 'toggleMuted'
      | 'toggleControls',
      (title?: string, options?: Record<string, unknown>) => ExtensionAction
    >;
  };

  /** Read-only host OS metadata: capability checks and intent-named labels. */
  system: ExtensionSystem;

  /** Text and template helpers for snippets, quicklinks, prompts, and selected-text transforms. */
  text: ExtensionText;

  /** Lightweight palette input helpers for command arguments. Fields are collected sequentially through the palette input and injected into the wrapped action as `formValues`. */
  input: {
    prompt(
      input: {
        title?: string;
        message?: string;
        fields: ExtensionFormField[];
        action: ExtensionAction;
        submitTitle?: string;
      },
      options?: Record<string, unknown>,
    ): ExtensionAction;
  };

  /** Independent host-owned windows for floating notes, dashboards, previews, and companions. Helpers return declarative actions. */
  windows: {
    /** Open or update, show, and focus an independent window rendering the given host-owned view. The action title is `options.title`, then `view.title`, then `Open Window`. */
    create(
      view: ExtensionView,
      options?: ExtensionWindowOptions,
    ): ExtensionAction;
    /** Show and focus an existing owner-local window. Missing windows show an error indicator. */
    show(
      id: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Hide an existing owner-local window without destroying it. Missing windows show an error indicator. */
    hide(
      id: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
    /** Toggle an existing owner-local window exactly once. Missing id-only targets show an error indicator. */
    toggle(id: string): ExtensionAction;
    toggle(id: string, title: string): ExtensionAction;
    toggle(id: string, options: ExtensionWindowOptions): ExtensionAction;
    toggle(
      id: string,
      title: string,
      options: ExtensionWindowOptions,
    ): ExtensionAction;
    /** Toggle an existing window resolved from the view/options id, or create it when missing. */
    toggle(view: ExtensionView): ExtensionAction;
    toggle(view: ExtensionView, title: string): ExtensionAction;
    toggle(
      view: ExtensionView,
      options: ExtensionWindowOptions,
    ): ExtensionAction;
    toggle(
      view: ExtensionView,
      title: string,
      options: ExtensionWindowOptions,
    ): ExtensionAction;
    /** Destroy an existing owner-local window. Missing windows show an error indicator. */
    close(
      id: string,
      title?: string,
      options?: Record<string, unknown>,
    ): ExtensionAction;
  };

  /** Clipboard history. Enabled trusted extensions receive this API regardless of declarations. */
  clipboard: { history?: ExtensionClipboardHistory };

  /** OCR helpers. Declarations do not gate this API; check `ctx.system.capabilities.has('ocr')` for OS support. */
  ocr?: {
    /** Recognize text in an image path, file URL, data URL, or `ExtensionFile`. */
    image(
      input:
        | string
        | ExtensionFile
        | { path?: string; filePath?: string; fileUrl?: string; url?: string },
      options?: ExtensionOcrOptions,
    ): Promise<ExtensionOcrResult>;
    /** Capture the screen and recognize visible text when screen recording permission is available. */
    screen(options?: ExtensionOcrOptions): Promise<ExtensionOcrResult>;
    /** Capture a screen region in physical screen coordinates and recognize text. */
    region(
      rect: ExtensionOcrRegion,
      options?: ExtensionOcrOptions,
    ): Promise<ExtensionOcrResult>;
  };

  /** Build a persistent action contribution for `actions(ctx)`. */
  action(action: ExtensionActionContribution): ExtensionActionContribution;

  /** Explicit return helpers from action handlers. Prefer these for imperative handler results. */
  navigation: {
    /** Replace the palette's current navigation stack with this view. Use for top-level destinations. */
    root(view: ExtensionView | null): {
      view: ExtensionView | null;
      navigation: 'root';
    };
    /** Drill into a child view and let Escape return to the current view. */
    push(view: ExtensionView | null): {
      view: ExtensionView | null;
      navigation: 'push';
    };
    /** Swap the current view without adding a back-stack entry. */
    replace(view: ExtensionView | null): {
      view: ExtensionView | null;
      navigation: 'replace';
    };
    pop(): { navigation: 'pop' };
    run(action: ExtensionAction): { action: ExtensionAction };
  };

  /** Desktop APIs for enabled trusted extensions. Capability declarations are review metadata and do not gate namespaces. */
  desktop: {
    keyboard: {
      /** Type text into the frontmost app without touching the clipboard. Check `ctx.system.capabilities.has('keyboard.type-text')` for support. */
      typeText(
        text: string,
        options?: ExtensionTypeTextOptions,
      ): Promise<unknown> | unknown;
    };
    clipboard?: {
      readText(): string;
      writeText(text: string, options?: ExtensionClipboardWriteOptions): void;
      readHtml(): string;
      writeHtml(
        html: string,
        text?: string,
        options?: ExtensionClipboardWriteOptions,
      ): void;
      readImage(): string | null;
      writeImage(
        image: unknown,
        options?: ExtensionClipboardWriteOptions,
      ): unknown;
      readFiles(): Promise<ExtensionFile[]>;
      writeFiles(
        paths: string[],
        options?: ExtensionClipboardWriteOptions,
      ): void;
      read(
        options?: ExtensionClipboardReadOptions,
      ): Promise<ExtensionClipboardReadResult>;
      write(
        value: ExtensionClipboardContent | string,
        options?: ExtensionClipboardWriteOptions,
      ): unknown;
    };
    selection: {
      /** Check desktop access without prompting; distinguishes denied permissions, missing tools, and unsupported desktop sessions. Windows elevated apps can reject access even when the current desktop check succeeds. */
      access(): Promise<{
        state: 'allowed' | 'denied' | 'unavailable' | 'unsupported' | 'unknown';
        message: string;
      }>;
      /**
       * Read selected text after the palette releases focus, with a clipboard-preserving Copy fallback.
       * Returns null when no text can be captured; this does not prove the source app has no selection.
       * Supported on macOS, Windows, Linux X11 (xdotool + xclip), Hyprland (hyprctl), and Sway (swaymsg + wtype).
       * Other Wayland desktops do not expose the required window-control capability.
       * Rejects on denied desktop access, lost source-window focus, missing tools, or native helper failure.
       * Show the error message to the user instead of reporting these failures as an empty selection.
       */
      text(): Promise<string | null> | string | null;
      /** Replace the editable selection without using the clipboard; returns false for an unconfirmed write so callers can fall back to pasting, and rejects on denied access, lost focus, or native helper failure. */
      replaceText(text: string): Promise<boolean> | boolean;
      files(): Promise<string[]> | string[];
      read(): Promise<unknown> | unknown;
    };
    apps?: {
      frontmost(): Promise<unknown> | unknown;
      launch(appPath: string): unknown;
      /** Installed applications from the host index. */
      list(): ExtensionApp[];
      /** Installed applications whose name matches the query. */
      search(query: string): ExtensionApp[];
      /** Icon for an app path as a data URL, or null when unavailable. */
      icon(appPath: string): Promise<string | null>;
    };
    files?: {
      /**
       * Walk one or more directory roots and return matching files.
       *
       * Non-existent roots are skipped (with a warning logged to the host)
       * so that a batch query across multiple roots always returns results
       * from the roots that exist. Callers do not need to iterate roots
       * individually to guard against missing directories.
       */
      find(
        roots: string[],
        options?: ExtensionFindFilesOptions,
      ): Promise<ExtensionFile[]>;
      findImages(
        roots: string[],
        options?: Omit<ExtensionFindFilesOptions, 'kind'>,
      ): Promise<ExtensionFile[]>;
      findVideos(
        roots: string[],
        options?: Omit<ExtensionFindFilesOptions, 'kind'>,
      ): Promise<ExtensionFile[]>;
      findMedia(
        roots: string[],
        options?: Omit<ExtensionFindFilesOptions, 'kind'>,
      ): Promise<ExtensionFile[]>;
      /** Supported apps for this file. When rendering a picker, map each app to `{ id: app.id, title: app.name, primaryAction: ctx.actions.openWith(filePath, app) }`. */
      openWithApps(filePath: string): Promise<ExtensionOpenWithApp[]>;
      open(filePath: string): unknown;
      reveal(filePath: string): unknown;
      preview(filePath: string): unknown;
      readText(filePath: string): Promise<string>;
      toFileUrl(filePath: string): string;
      /** Host-safe thumbnail URL for an image/video/file path when previewable. */
      thumbnail(filePath: string): string | null;
      /** Canonical file metadata with host-safe URLs and image dimensions when available. */
      metadata(filePath: string): Promise<ExtensionFile>;
      /** Configured default roots for the lightweight host file index. */
      indexedRoots(): string[];
      /** Instant snapshot of the host file index, filtered/sorted without rescanning. Use this to open views immediately; refresh lazily for newest data. */
      indexSnapshot(
        options?: ExtensionFileIndexOptions,
      ): ExtensionIndexedFile[];
      /** Rebuild the lightweight host file index with bounded roots/depth/filter controls. Run from background jobs or refreshes, not before first paint. */
      reindex(
        options?: ExtensionFileIndexOptions,
      ): Promise<{ count: number; roots: string[] }>;
      /** Instant newest-first entries from the current host file index snapshot. Never rescans. Use as a fallback seed; prefer extension storage for the last refreshed first-paint cache. */
      recent(options?: ExtensionFileIndexOptions): ExtensionIndexedFile[];
      /** Host file index entries whose name or path matches the query. */
      searchIndex(
        query: string,
        options?: ExtensionFileIndexOptions,
      ): ExtensionIndexedFile[];
    };
    /** Shell and process helpers. Declare the `system` capability for review. */
    shell?: {
      openExternal(url: string): unknown;
      exec(
        command: string,
        args?: string[],
        options?: ExtensionShellOptions,
      ): Promise<ExtensionShellResult>;
      script(
        script: string,
        options?: ExtensionShellOptions,
      ): Promise<ExtensionShellResult>;
      appleScript(
        script: string,
        options?: ExtensionShellOptions,
      ): Promise<ExtensionShellResult>;
      which(command: string): Promise<ExtensionShellResult>;
    };
  };

  storage: ExtensionStorage;
  /**
   * Host-owned editor draft lifecycle for views declaring `draft`. Drafts are
   * unsaved-work buffers the host persists and recovers; they are not the
   * extension's source of truth — keep records in `storage`.
   */
  drafts: {
    /**
     * Mark the draft as persisted at a new version after the extension writes
     * its record. The unsaved content carries over so the next open recovers
     * instead of conflicting. Returns false when no draft exists.
     */
    commit(key: string, version: string | number): Promise<boolean> | boolean;
    /** Drop the draft for a key, e.g. after deleting the record it belongs to. */
    discard(key: string): Promise<void> | void;
  };
  settings: ExtensionSettings;
  /** Cross-platform speech dictation. Declare `dictation` for review. */
  dictation?: ExtensionDictation;
  shortcuts: {
    /** Active global action shortcuts, including user overrides and declared extension shortcuts. */
    list(): ExtensionShortcutRecord[];
    /** Current app-wide shortcut used to open Nevermind. */
    palette(): ExtensionPaletteShortcut;
  };
  logs: ExtensionLogs;
  cache: ExtensionRuntimeCache;
  /** Current-view helpers. `refresh()` may be placed in `view.refresh.action`; the host converts it to an opaque refresh handle before IPC. */
  views: { refresh(): ExtensionAction; invalidate(): void };
  /** App update state. Declare the `updates` capability for review and pair with `ctx.actions.updates.*`. */
  updates?: { getState(): ExtensionUpdateState };
  state: Record<string, unknown>;
  /** Lazy data fetching. Use `ctx.data.loader(fn)` so the view skeleton paints immediately while the loader runs in the background. */
  data: ExtensionData;
  ai?: ExtensionAi;
  aiBuilder?: ExtensionAiBuilder;
  extensions: { ownership?: ExtensionOwnership };
};

export type ExtensionCommand = {
  id: string;
  /** Stable action id for aliases and durable global shortcuts. Defaults to `extension:${extension.id}:${id}` for compatibility. */
  actionId?: string;
  title: string;
  subtitle?: string;
  aliases?: string[];
  icon?: string;
  score?: number;
  /** @deprecated Use `globalShortcut`; command shortcuts are global by nature. */
  shortcut?: string;
  /** @deprecated Use `globalShortcut`. */
  shortcutScope?: ShortcutScope;
  /** Global shortcut for this command. */
  globalShortcut?: string;
  /** Semantic visual treatment for the command result. */
  appearance?: ExtensionItemAppearance;
  /** Dismiss immediately for fire-and-forget commands. Prefer `mode: 'background'` for durable scheduled work. */
  background?: boolean;
  /** Execution lifecycle. `background`/`noView` commands are eligible for host-managed jobs and diagnostics. */
  mode?: ExtensionBackgroundMode;
  /** Declarative host-owned trigger intents. The host owns scheduling, enablement, no-overlap, backoff, and diagnostics. */
  triggers?: ExtensionBackgroundTrigger[];
  dismissAfterRun?: 'auto';
  run(
    ctx: ExtensionContext,
    action: ExtensionAction,
  ): ExtensionActionResult | Promise<ExtensionActionResult>;
};

/**
 * Extension manifest. `actions(ctx)` is the durable action registry. `commands` are
 * ergonomic shorthand for durable actions that appear in search automatically; the
 * host normalizes both into the same shortcut/alias/execution pipeline. For a capability
 * with one primary root surface, prefer one `rootItems()` item and put Settings and
 * secondary actions in its `actionPanel` instead of exposing sibling command launchers.
 */
export type NevermindExtension = {
  id: string;
  title: string;
  subtitle?: string;
  /** Review metadata only; an enabled local extension still has full local access. */
  capabilities?: ExtensionCapability[];
  /** @deprecated Use `capabilities`. Used only when `capabilities` is absent. */
  permissions?: ExtensionPermission[];
  /**
   * Rebuild a persistent window from current extension code after relaunch.
   * The host invokes only the currently enabled extension that owns the saved
   * restore key, freshly normalizes a returned descriptor, and purges saved
   * restoration when this returns null. Views and action handlers are never
   * serialized as restoration state.
   */
  restoreWindow?(
    ctx: ExtensionContext,
    restoreKey: string,
  ): ExtensionWindowRestoreDescriptor | null;
  /** Shorthand for search-visible durable actions with imperative `run(ctx)`. */
  commands?: ExtensionCommand[];
  /**
   * Persistent action registry. Use this for shortcut-worthy static variants such as
   * “Compress 720p”, “Compress 1080p”, “Toggle Floating Note”, or fixed snippets.
   * These actions are searchable, aliasable, global-shortcutable, and runnable without
   * opening a view. Dynamic/state-driven rows such as calendar events, search results,
   * and files belong in views, `rootItems`, or `searchItems` instead.
   */
  actions?(
    ctx: ExtensionContext,
  ): ExtensionActionContribution[] | { actions: ExtensionActionContribution[] };
  /** Empty-query root contributions. Keep small, stable, cached, JSON-serializable, and bounded. Prefer one primary item per capability; expose Settings and secondary actions through that item's `actionPanel` so they appear under Cmd+K. If a secondary action should also be independently searchable, register it with `actions(ctx)` and reference it with `ctx.actions.ref(...)`. Do not duplicate durable actions here just for styling; put `appearance` on the action or command itself. */
  rootItems?(
    ctx: ExtensionContext,
  ):
    | ExtensionItem[]
    | Promise<ExtensionItem[]>
    | { items: ExtensionItem[] }
    | Promise<{ items: ExtensionItem[] }>;
  /** Query-aware root contributions. The host debounces, caps, ranks, caches, and failure-isolates providers. Use for dynamic/query-specific items, not duplicate launchers for durable actions. */
  searchItems?(
    ctx: ExtensionContext,
    query: string,
  ):
    | ExtensionItem[]
    | Promise<ExtensionItem[]>
    | { items: ExtensionItem[] }
    | Promise<{ items: ExtensionItem[] }>;
};

declare global {
  const module: { exports: unknown };
}
