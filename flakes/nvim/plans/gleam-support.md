# Plan: Add Gleam Language Support to Neovim

**Date:** 2025-11-02
**Status:** Planning Phase (READ-ONLY)

## Overview

Add comprehensive Gleam language support to the Neovim configuration following the established patterns for language-specific tooling. Gleam is a statically typed language for the Erlang VM, requiring LSP, formatting, and treesitter support.

## Available Packages in nixpkgs

Based on nix search results, the following Gleam-related packages are available:

1. **gleam** (1.13.0) - The Gleam compiler, CLI tools, formatter, and LSP server
2. **tree-sitter-gleam** (0.25.10) - Treesitter grammar for Gleam
3. **vimPlugins.gleam-vim** - Vim plugin for Gleam (may not be needed with treesitter)
4. **vimPlugins.nvim-treesitter-parsers.gleam** - Treesitter parser

## Gleam Tooling Best Practices

From Gleam documentation (https://gleam.run/language-server):
- **LSP**: The official Gleam Language Server is built into the `gleam` binary (run with `gleam lsp`)
- **Formatting**: `gleam format` (built into the Gleam CLI) is the standard formatter
- **Linting**: No dedicated linter; Gleam's compiler provides comprehensive diagnostics
- **Syntax Highlighting**: Treesitter grammar available
- **File Extension**: `.gleam`

## Implementation Plan

### 1. Add Gleam Category to flake.nix

**File:** `flakes/nvim/flake.nix`

#### Changes in `categoryDefinitions`:

**lspsAndRuntimeDeps section** (around line 57):
```nix
gleam = with pkgs; [
  gleam  # Compiler, CLI tools, formatter (gleam format), and LSP (gleam lsp)
];
```

**optionalPlugins section** (around line 162):
```nix
# No gleam-specific plugins needed, treesitter already has gleam parser
# in nvim-treesitter.withAllGrammars
```

**Note:** The `nvim-treesitter.withAllGrammars` already includes the Gleam parser, so no additional plugin configuration is needed.

#### Changes in `packageDefinitions`:

**defaultCategories section** (around line 294):
```nix
defaultCategories = {
  general = true;
  lint = true;
  format = true;

  shell = true;
  markdown = true;
  lua = true;
  neonixdev = true;
  
  gleam = true;  # ADD THIS LINE

  snacks = false;
  # ... rest unchanged
};
```

### 2. Add LSP Configuration

**File:** `flakes/nvim/lua/myLuaConf/lsp.lua`

**Location:** After the nixd LSP configuration (around line 196), add:

```lua
{
  "gleam",
  for_cat = "gleam",
  lsp = {
    -- Official Gleam LSP is built into the gleam binary
    -- Run with: gleam lsp
    -- filetypes will be auto-detected as { "gleam" }
  },
},
```

**Rationale:** 
- Uses `for_cat = "gleam"` to enable only when gleam category is active
- The official Gleam LSP is built into the gleam binary and runs via `gleam lsp`
- Minimal configuration as the official LSP works well with defaults
- LSP will auto-detect `.gleam` files

### 3. Add Formatter Configuration ✨ SIMPLIFIED

**File:** `flakes/nvim/lua/myLuaConf/format.lua`

**Location:** In the `formatters_by_ft` table (around line 32), add:

```lua
formatters_by_ft = {
  -- ... existing formatters
  gleam = { "gleam" },  -- ADD THIS LINE
  -- lua = { "stylua" },
  -- ... rest unchanged
},
```

**✨ SIMPLIFIED: No custom formatter configuration needed!**

**Rationale:**
- **conform.nvim already includes built-in support for Gleam formatter** 🎉
- The built-in configuration is exactly what we need:
  - `command = "gleam"`
  - `args = { "format", "--stdin" }`
- Simply adding `gleam = { "gleam" }` to `formatters_by_ft` is sufficient
- Gleam's formatter is intentionally zero-config, so no customization needed
- See built-in config: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/gleam.lua

### 4. Update non_nix_download.lua (Optional)

**File:** `flakes/nvim/lua/myLuaConf/non_nix_download.lua`

**Action:** Check if Gleam tools need to be added to the Mason fallback configuration for non-Nix environments.

**Expected Change:** Add to the Mason installation list if the file manages LSP installations outside Nix:
```lua
-- Somewhere in the Mason LSP list:
"gleam",  -- Official Gleam LSP (included in gleam binary)
```

**Note:** Mason should automatically handle the Gleam LSP when requested by lspconfig outside of Nix environments.

### 5. No Linting Configuration Needed

**File:** `flakes/nvim/lua/myLuaConf/lint.lua`

**Action:** NONE - Gleam doesn't have a separate linter. The compiler provides comprehensive diagnostics through the LSP.

**Rationale:**
- Gleam's design philosophy includes comprehensive compile-time checking
- The LSP (glas) will surface all compiler diagnostics
- Adding a linter would be redundant

### 6. Treesitter Configuration

**File:** Already handled by `nvim-treesitter.withAllGrammars`

**Action:** NONE - The Gleam treesitter grammar is already included in `withAllGrammars`.

**Verification:** After implementation, can verify with `:TSInstallInfo` in Neovim that Gleam parser is available.

## Testing Plan

### Build Test
```bash
cd /Users/tapani/project/github/tapppi/nix-config/flakes/nvim
nix flake check
nix build .#testNvim
```

### Runtime Tests
```bash
./result/bin/testNvim
```

**Within Neovim:**
1. Create a test file: `test.gleam`
2. Verify LSP loads: `:LspInfo` should show glas attached
3. Test formatting: `<leader>ff` should format the file
4. Verify syntax highlighting works (treesitter)
5. Test LSP features: hover, go-to-definition, diagnostics

**Sample Gleam code for testing:**
```gleam
import gleam/io

pub fn main() {
  io.println("Hello, Gleam!")
}
```

### Expected Behavior After Implementation
- `.gleam` files automatically trigger glas LSP attachment
- Syntax highlighting via treesitter
- Format command (`<leader>ff`) runs `gleam format`
- LSP features available: hover, completion, go-to-definition, diagnostics
- No separate linting (diagnostics via LSP only)

## Files to Modify

1. ✅ `/Users/tapani/project/github/tapppi/nix-config/flakes/nvim/flake.nix`
   - Add `gleam` category to `lspsAndRuntimeDeps`
   - Enable `gleam = true` in `defaultCategories`

2. ✅ `/Users/tapani/project/github/tapppi/nix-config/flakes/nvim/lua/myLuaConf/lsp.lua`
   - Add official Gleam LSP configuration (uses `gleam lsp` command)

3. ✅ `/Users/tapani/project/github/tapppi/nix-config/flakes/nvim/lua/myLuaConf/format.lua`
   - Add gleam formatter to `formatters_by_ft` (built-in formatter, no custom config needed!)

4. ⚠️  `/Users/tapani/project/github/tapppi/nix-config/flakes/nvim/lua/myLuaConf/non_nix_download.lua` (OPTIONAL)
   - May need to add gleam to Mason fallback if configured

5. ❌ No changes needed:
   - `lint.lua` - No Gleam linter available/needed
   - Treesitter - Already included in withAllGrammars
   - `plugins/init.lua` - No new plugin files to load

## Implementation Checklist

- [x] Add `gleam` to `lspsAndRuntimeDeps` in flake.nix (only gleam binary needed, no glas)
- [x] Enable `gleam = true` in `defaultCategories` in flake.nix
- [x] Add official Gleam LSP spec to lsp.lua (uses `gleam lsp`)
- [x] Add gleam to format.lua `formatters_by_ft` (uses built-in conform.nvim formatter)
- [ ] Check and update non_nix_download.lua if needed
- [x] Run `nix flake check`
- [ ] Build testNvim
- [ ] Test with sample Gleam code
- [ ] Verify LSP, formatting, and syntax highlighting work

## Notes

- **Zero configuration philosophy**: Gleam tooling is intentionally minimal and opinionated. No custom configuration should be needed beyond basic setup.
- **No plugin needed**: Unlike some languages, Gleam doesn't require a dedicated vim plugin since treesitter handles syntax and LSP handles intelligence.
- **All-in-one binary**: The `gleam` binary includes the compiler, formatter (`gleam format`), and LSP server (`gleam lsp`).
- **Official LSP**: The Gleam Language Server is an official part of the Gleam project, built into the main binary.

## References

- [Gleam Official Website](https://gleam.run/)
- [Gleam Language Server Documentation](https://gleam.run/language-server)
- [Gleam Format Documentation](https://gleam.run/writing-gleam/command-line-reference/#format)
- [nixpkgs Gleam package](https://search.nixos.org/packages?query=gleam)
