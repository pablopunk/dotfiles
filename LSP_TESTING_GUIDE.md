# LSP Configuration Testing Guide

## Quick Start

```bash
# 1. Open Neovim
nvim

# 2. Check Mason installation status
:Mason

# 3. Wait for all servers to install (you'll see progress)
# Look for: vtsls, eslint, biome, tailwindcss, lua_ls, etc.

# 4. Restart Neovim
:qa
nvim
```

## Test Each Feature

### 1. TypeScript/JavaScript Auto-Imports

**Test File**: Create `test.tsx`

```typescript
// Type this and see auto-import suggestions:
import React from 'react';

function MyComponent() {
  // Start typing "useState" - should suggest auto-import
  const [count, setCount] = use
  //                         ^ Type "useState" and accept the suggestion
  //                           It should auto-add: import { useState } from 'react'
  
  return <div>Count: {count}</div>;
}
```

**Expected**: Auto-import suggestion appears, imports added automatically

---

### 2. Inlay Hints

**Test File**: Continue in `test.tsx`

```typescript
// You should see inline hints like:
function greet(name: string, age: number) {
  //     ^name: string  ^age: number  (shown inline)
  console.log(`Hello ${name}, you are ${age}`);
}

greet("Alice", 30);
//    ^name:    ^age:  (hints show what each parameter is)
```

**Expected**: See parameter names and types shown inline as gray text

**Toggle**: Press `<leader>lh` to turn hints on/off

---

### 3. Tailwind CSS Completions

**Test File**: In `test.tsx`

```typescript
function TailwindTest() {
  return (
    <div className="flex 
    {/*            ^ Start typing tailwind classes */}
    {/*              Should see: flex-col, flex-row, etc. */}
  );
}
```

**Expected**: 
- Tailwind class suggestions appear
- Hover over a class to see docs (e.g., hover "flex" shows CSS it generates)

---

### 4. Organize Imports

**Test File**: Create messy imports

```typescript
import React from 'react';
import { useState } from 'react';
import { useEffect } from 'react';
import axios from 'axios';
import { Button } from './components/Button';

// Press <leader>oi here
```

**Expected**: Imports get sorted and duplicates merged:

```typescript
import React, { useEffect, useState } from 'react';

import axios from 'axios';

import { Button } from './components/Button';
```

**Keymap**: `<leader>oi`

---

### 5. Code Actions

**Test File**: Add ESLint-fixable code

```typescript
// Make sure you have an .eslintrc or biome.json in your project

const unused = 123;  // Unused variable

function test() {
  var old = 'use const';  // var instead of const
}
```

**Expected**:
- Diagnostics appear (warnings/errors)
- Press `<leader>ca` on the issue
- See suggestions: "Remove unused variable", "Convert to const", etc.

**Keymap**: `<leader>ca`

---

### 6. Go to Definition

**Test File**:

```typescript
// file: utils.ts
export function multiply(a: number, b: number) {
  return a * b;
}

// file: test.tsx
import { multiply } from './utils';

const result = multiply(2, 3);
//            ^ Put cursor here, press 'gd'
```

**Expected**: 
- Opens `utils.ts` in Telescope picker
- Shows definition of `multiply`

**Keymap**: `gd`

---

### 7. Rename Symbol

**Test File**:

```typescript
function calculateTotal(items) {
  //      ^ Put cursor on "calculateTotal"
  return items.reduce((sum, item) => sum + item.price, 0);
}

const total = calculateTotal(myItems);
//           ^ Will update automatically
```

**Expected**:
- Press `<leader>rn`
- Type new name: `computeSum`
- All references update across files

**Keymap**: `<leader>rn`

---

### 8. JSX/TSX Features

**Test File**:

```typescript
interface ButtonProps {
  onClick: () => void;
  label: string;
  disabled?: boolean;
}

function MyButton(props: ButtonProps) {
  return <button onClick={props.on
  {/*                          ^ Auto-complete shows: onClick */}
  {/*                            Type hints show types */}
}

// Usage:
<MyButton 
  on
  {/* ^ Auto-complete shows onClick with type signature */}
  label="Click me"
/>
```

**Expected**: 
- Prop completions work
- Type checking warns on missing required props
- Inlay hints show prop types

---

## Verification Checklist

Run `:checkhealth vim.lsp` and verify:

```
✓ vtsls attached
✓ eslint attached  
✓ tailwindcss attached (if tailwind.config.* exists)
✓ No errors or warnings
```

Run `:LspInfo` to see active clients for current buffer.

---

## Common Issues

### Inlay Hints Too Verbose?

**Solution 1**: Toggle them off with `<leader>lh`

**Solution 2**: Make them less aggressive (edit `config/neovim/init.lua`):

```lua
-- In vtsls config, change:
includeInlayParameterNameHints = "literals",  -- Instead of "all"
```

---

### Tailwind Not Working?

**Check 1**: Ensure you have `tailwind.config.js` or `tailwind.config.ts` in project root

**Check 2**: Run `:LspInfo` - should see `tailwindcss` client

**Check 3**: Restart LSP: `<leader>lr`

**Check 4**: Mason installed it: `:Mason` and look for `tailwindcss`

---

### Auto-imports Not Appearing?

**Check 1**: Ensure `package.json` exists (Node project)

**Check 2**: For TypeScript, ensure `tsconfig.json` exists

**Check 3**: Try manually organizing imports: `<leader>oi`

**Check 4**: Check LSP is running: `:LspInfo`

---

### ESLint/Biome Conflicts?

Your conform.nvim is already smart:
- Projects with "mobile-app" in name → ESLint
- All other projects → Biome

**Override manually**:
```vim
:BiomeFormat   " Switch to Biome
:EslintFormat  " Switch to ESLint  
:NoFormat      " Disable formatting
```

---

## Performance Test

Open a large TypeScript file (1000+ lines):

1. Should load without lag
2. Completions appear quickly
3. Diagnostics update in real-time
4. `:LspInfo` shows memory usage

If slow:
- Check `:checkhealth vim.lsp`
- Consider disabling inlay hints for large files
- vtsls has 8GB memory limit configured

---

## Success Indicators

After testing, you should see:

✅ Auto-imports work in TS/JS files  
✅ Inlay hints show parameter/type info  
✅ Tailwind completions in className  
✅ `<leader>oi` organizes imports  
✅ `<leader>ca` shows code actions  
✅ `gd` navigates to definitions  
✅ `<leader>rn` renames across files  
✅ Format on save works (biome/eslint)

---

## Advanced: Project-Specific Overrides

If you want different settings per project, create `lsp/vtsls.lua` in project root:

```lua
-- .config/nvim/after/lsp/vtsls.lua (takes precedence)
return {
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "none", -- Disable for this project
      },
    },
  },
}
```

This overrides the global vtsls config for that specific project.

---

**Happy coding with your supercharged LSP setup!** 🚀
