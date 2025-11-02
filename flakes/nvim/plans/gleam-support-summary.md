# Gleam Support - Quick Summary

## What Will Be Added

Complete Gleam language support with:
- **LSP**: glas (language server)
- **Formatter**: gleam format (built into Gleam CLI)
- **Syntax Highlighting**: Treesitter (already available in withAllGrammars)
- **Linting**: N/A (compiler diagnostics via LSP are sufficient)

## Changes Required

### 1. flake.nix
- Add `gleam` category with `gleam` and `glas` packages to `lspsAndRuntimeDeps`
- Enable `gleam = true` in `defaultCategories`

### 2. lsp.lua  
- Add glas LSP spec with `for_cat = "gleam"`

### 3. format.lua
- Add `gleam = { "gleam" }` to `formatters_by_ft`
- ✨ No custom configuration needed - conform.nvim has built-in Gleam support!

### 4. non_nix_download.lua (check only)
- Verify Mason fallback handles glas (likely automatic)

## Total Files Modified: 3 files (simplified!)

**Update:** conform.nvim has built-in Gleam formatter support, so no custom formatter configuration is needed in format.lua. This simplifies the implementation.

## Why This Approach?

This follows the established patterns in your Neovim config:
- Language support via categories (like `go`, `rust`, `typescript`)
- LSP via lze specs in lsp.lua
- Formatting via conform.nvim in format.lua
- Minimal configuration (Gleam tooling is intentionally zero-config)

## Test Command

```bash
cd /Users/tapani/project/github/tapppi/nix-config/flakes/nvim
nix build .#testNvim
./result/bin/testNvim test.gleam
```

See full plan in `gleam-support.md` for detailed implementation steps.
