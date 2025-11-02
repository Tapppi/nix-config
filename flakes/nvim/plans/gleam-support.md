# Plan: Add Gleam Language Support to Neovim

**Date:** 2025-11-02
**Status:** Planning Phase (READ-ONLY)

## Overview

Add comprehensive Gleam language support to the Neovim configuration following the established patterns for language-specific tooling. Gleam is a statically typed language for the Erlang VM, requiring LSP, formatting, and treesitter support.

## Available Packages in nixpkgs

Based on nix search results, the following Gleam-related packages are available:

1. **gleam** (1.13.0) - The Gleam compiler and CLI tools (includes built-in formatter)
2. **glas** (0.2.3) - Language server for the Gleam programming language
3. **tree-sitter-gleam** (0.25.10) - Treesitter grammar for Gleam
4. **vimPlugins.gleam-vim** - Vim plugin for Gleam (may not be needed with treesitter)
5. **vimPlugins.nvim-treesitter-parsers.gleam** - Treesitter parser

## Gleam Tooling Best Practices

From Gleam documentation:
- **LSP**: `glas` is the community-maintained language server
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
  gleam  # Compiler, CLI tools, and formatter (gleam format)
  glas   # Language server
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
  "glas",
  for_cat = "gleam",
  lsp = {
    -- glas uses default configuration
    -- filetypes will be auto-detected as { "gleam" }
  },
},
```

**Rationale:** 
- Uses `for_cat = "gleam"` to enable only when gleam category is active
- Minimal configuration as glas works well with defaults
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
"glas",  -- Gleam LSP
```

**Note:** Mason should automatically install `glas` when requested by lspconfig outside of Nix environments.

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
   - Add glas LSP configuration

3. ✅ `/Users/tapani/project/github/tapppi/nix-config/flakes/nvim/lua/myLuaConf/format.lua`
   - Add gleam formatter to `formatters_by_ft` (built-in formatter, no custom config needed!)

4. ⚠️  `/Users/tapani/project/github/tapppi/nix-config/flakes/nvim/lua/myLuaConf/non_nix_download.lua` (OPTIONAL)
   - May need to add glas to Mason fallback if configured

5. ❌ No changes needed:
   - `lint.lua` - No Gleam linter available/needed
   - Treesitter - Already included in withAllGrammars
   - `plugins/init.lua` - No new plugin files to load

## Implementation Checklist

- [ ] Add `gleam` to `lspsAndRuntimeDeps` in flake.nix
- [ ] Enable `gleam = true` in `defaultCategories` in flake.nix
- [ ] Add glas LSP spec to lsp.lua
- [ ] Add gleam to format.lua `formatters_by_ft` (uses built-in conform.nvim formatter)
- [ ] Check and update non_nix_download.lua if needed
- [ ] Run `nix flake check`
- [ ] Build testNvim
- [ ] Test with sample Gleam code
- [ ] Verify LSP, formatting, and syntax highlighting work

## Notes

- **Zero configuration philosophy**: Gleam tooling is intentionally minimal and opinionated. No custom configuration should be needed beyond basic setup.
- **No plugin needed**: Unlike some languages, Gleam doesn't require a dedicated vim plugin since treesitter handles syntax and LSP handles intelligence.
- **Formatter is built-in**: The `gleam format` command is part of the main Gleam CLI, not a separate tool.
- **Community LSP**: `glas` is maintained by the community, not the Gleam team, but it's the standard LSP server for Gleam.

## References

- [Gleam Official Website](https://gleam.run/)
- [glas LSP Server](https://github.com/gleam-lang/glas)
- [Gleam Format Documentation](https://gleam.run/writing-gleam/command-line-reference/#format)
- [nixpkgs Gleam package](https://search.nixos.org/packages?query=gleam)
