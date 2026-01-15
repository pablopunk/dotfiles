# Neovim LSP Configuration Refactor - January 2026

## 🎯 Overview

Refactored the LSP configuration in `config/neovim/init.lua` to optimize for **full-stack React + Node.js development** with TypeScript/JavaScript, using modern Neovim 0.11 features and best practices from 2025-2026.

## ✨ What Changed

### 1. **Added Tailwind CSS Support**
- ✅ Added `tailwindcss` to mason's `ensure_installed`
- ✅ Configured for JSX/TSX class name completions
- ✅ Experimental support for `cn()`, `clsx()`, `cva()` class detection
- ✅ Linting for Tailwind conflicts and errors

### 2. **Enhanced TypeScript/JavaScript (vtsls)**
Previously: Minimal configuration, relying on defaults
Now: Comprehensive settings for:
- **Auto-imports**: Smart import suggestions and auto-add missing imports
- **Inlay hints**: Show parameter names, types, and return types inline
- **Performance**: 8GB max memory for large projects
- **Better completions**: Function call completions, JSDoc suggestions
- **Import organization**: Prefer non-relative imports, smart sorting

### 3. **Improved ESLint Configuration**
- ✅ Code actions for ESLint rules (disable rule comments, documentation)
- ✅ Explicit filetype support (JS, JSX, TS, TSX, Vue, Astro)
- ✅ Keeps formatting disabled (conform.nvim handles it)

### 4. **Better Project Detection**
Previously: Only `.git`
Now: Multiple root markers with priority:
- `package.json`, `tsconfig.json`, `jsconfig.json` (JS/TS projects)
- `biome.json`, `.eslintrc.*` (linter configs)
- `tailwind.config.*` (Tailwind projects)
- `.git` (fallback)

### 5. **Inlay Hints Auto-Enabled**
- ✅ Inlay hints now enabled by default on LSP attach
- ✅ Toggle still available with `<leader>lh`

### 6. **New Keymap: Organize Imports**
- ✅ `<leader>oi` - Automatically organize imports (TypeScript/JavaScript)
- Uses LSP code actions to sort and remove unused imports

### 7. **Better Code Organization**
Restructured into clear sections:
1. Plugin Setup
2. Global LSP Configuration
3. Server-Specific Configurations
4. Enable All Servers
5. LSP Attach Autocmd
6. Keymaps

## 📝 Configuration Details

### vtsls Settings (TypeScript/JavaScript)

```lua
{
  -- Auto-imports
  autoUseWorkspaceTsdk = true,
  experimental.completion.enableServerSideFuzzyMatch = true,
  
  -- Inlay hints (all enabled)
  inlayHints.includeInlayParameterNameHints = "all",
  inlayHints.includeInlayFunctionParameterTypeHints = true,
  inlayHints.includeInlayVariableTypeHints = true,
  
  -- Import preferences
  preferences.importModuleSpecifier = "non-relative",
  preferences.includePackageJsonAutoImports = "auto",
  
  -- Suggestions
  suggest.completeFunctionCalls = true,
}
```

### Tailwind CSS Settings

```lua
{
  classAttributes = ["class", "className", "classList", ...],
  experimental.classRegex = {
    -- Matches: cn("..."), clsx("..."), cva("...")
  },
  lint = {
    cssConflict = "warning",
    invalidApply = "error",
    invalidTailwindDirective = "error",
  },
}
```

## 🔑 Key Features Now Available

### For React Development:
✅ JSX/TSX auto-closing tags (via vtsls)
✅ Component prop completions
✅ Tailwind class completions in className attributes
✅ Import path intelligence
✅ Inlay hints showing prop types

### For TypeScript/JavaScript:
✅ Auto-import suggestions as you type
✅ Organize imports with one keypress
✅ Parameter name hints in function calls
✅ Variable type hints
✅ Return type hints

### For Full-Stack:
✅ Works with both frontend (React) and backend (Node) code
✅ Biome for fast projects, ESLint for legacy projects
✅ Project-aware (detects package.json, tsconfig.json)
✅ Astro support for modern meta-frameworks

## 🎮 Keymaps Reference

### Existing Keymaps (unchanged):
- `K` - Hover documentation (built-in default)
- `E` - Show line diagnostics
- `]d` / `[d` - Next/previous diagnostic
- `<leader>ca` - Code actions
- `gd` - Go to definition (Telescope)
- `gr` - Go to references (Telescope)
- `gi` - Go to implementations (Telescope)
- `<leader>lo` - Document symbols
- `<leader>lO` - Workspace symbols
- `<leader>rn` - Rename variable
- `<leader>ls` - Start LSP
- `<leader>lx` - Stop LSP
- `<leader>lr` - Restart LSP
- `<leader>li` - LSP info (checkhealth)
- `<leader>lh` - Toggle inlay hints

### New Keymaps:
- `<leader>oi` - **Organize imports** (TypeScript/JavaScript)

## 🔧 How to Use

### First Time Setup:
1. Open Neovim: `nvim`
2. Mason will auto-install all LSP servers
3. Wait for installation to complete (check with `:Mason`)
4. Restart Neovim or run `:LspRestart`

### Install Additional Tools:
```bash
# Formatters (if not already installed)
npm install -g @biomejs/biome
npm install -g eslint_d

# For Lua formatting
brew install stylua
```

### Verify LSP is Working:
1. Open a TypeScript/JavaScript file
2. Run `:checkhealth vim.lsp`
3. Look for attached clients: vtsls, eslint, tailwindcss

### Toggle Features:
- **Inlay hints**: `<leader>lh` (on by default now)
- **Formatting**: Use `:BiomeFormat`, `:EslintFormat`, or `:NoFormat`

## 🚀 Performance Notes

### Fast Startup:
- Using `mini.deps` lazy loading
- LSP servers only start when needed (filetype detection)
- Snacks.nvim bigfile detection prevents LSP on huge files

### Memory:
- vtsls configured with 8GB max memory (good for large monorepos)
- Auto-cleanup of unused imports keeps project lean

## 🐛 Troubleshooting

### Inlay Hints Too Verbose?
Toggle off with `<leader>lh`. Consider using less aggressive settings:
```lua
-- In vtsls config, change "all" to "literals"
includeInlayParameterNameHints = "literals",
```

### Tailwind Not Working?
1. Ensure project has `tailwind.config.js` or `tailwind.config.ts`
2. Check `:LspInfo` - tailwindcss should be attached
3. Restart LSP: `<leader>lr`

### Auto-imports Not Showing?
1. Ensure `package.json` exists in project root
2. For TypeScript: ensure `tsconfig.json` exists
3. Try organizing imports: `<leader>oi`

### ESLint Conflicts with Biome?
Your `conform.nvim` setup already handles this:
- Project with `mobile-app` in name → uses ESLint
- All other projects → uses Biome
- Switch manually: `:BiomeFormat` or `:EslintFormat`

## 📚 References

Based on best practices from:
- Neovim 0.11 official LSP docs
- nvim-lspconfig documentation
- mason-lspconfig.nvim docs
- Modern React + TypeScript development patterns (2024-2026)
- Blog posts from Takuya Matsuyama, Chris Arderne, Vineeth Voruganti

## 🔮 Future Enhancements

Consider adding later:
- [ ] `typescript-tools.nvim` for enhanced TS features
- [ ] React-specific snippets via LuaSnip
- [ ] GraphQL language server for full-stack projects
- [ ] Prisma language server for database schemas

## ✅ Testing Checklist

After the refactor, test these scenarios:

- [ ] Open a `.tsx` file - vtsls should attach
- [ ] Type a component - see Tailwind completions in className
- [ ] Hover over a function - see inlay hints for parameters
- [ ] Import a module - auto-import suggestions appear
- [ ] Press `<leader>oi` - imports get organized
- [ ] Use `<leader>ca` - ESLint fixes appear
- [ ] Toggle `<leader>lh` - inlay hints disappear/reappear

---

**Date**: January 2026  
**Neovim Version**: 0.11+  
**Config Location**: `~/.dotfiles/config/neovim/init.lua`  
**Lines Modified**: 701-799 (lsp function)
