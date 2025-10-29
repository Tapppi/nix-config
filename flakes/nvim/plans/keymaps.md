# Neovim Keymaps Centralization Plan

## Overview

This plan outlines centralizing all Neovim keybindings in `lua/myLuaConf/remap.lua` with a simplified structure focusing on practical implementation.

- Do NOT add new or modify existing keymaps other than what is explicitly instructed, only move the existing keymaps and keymap groups.

## Current Keymap Inventory

### Global Remaps (myLuaConf/remap.lua)
- Navigation: `<C-d>`, `<C-u>`, `n`, `N` (with centering)
- Buffer management: `<leader><leader>[`, `]`, `l`, `d`, `o`
- Word wrap: `j`, `k`
- Diagnostics: `[d`, `]d`, `<leader>e`, `<leader>q`
- Clipboard: `<leader>y`, `Y`, `p`, `P`, `<C-p>`
- Selection: `<leader><C-a>`
- Line movement: `J`, `K` (visual, conditional on mini not enabled)

### Plugin Keymaps

**plugins/init.lua:**
- Notify: `<Esc>` (dismiss + nohlsearch)
- Markdown: `<leader>mp`, `ms`, `mt`
- Undotree: `<leader>u`
- Gitsigns (buffer-local):
  - Navigation: `]c`, `[c`
  - Actions: `<leader>gs`, `gr`, `gS`, `gR`, `gu`, `gp`, `gb`, `gd`, `gD`
  - Toggles: `<leader>gtb`, `gtd`
  - Text object: `ih`

**plugins/telescope.lua:**
- All `<leader>s*` search bindings
- `<leader>/`, `<leader><leader>s`
- Helper functions: `find_git_root`, `live_grep_git_root`

**plugins/oil.lua:**
- Entry: `-`, `<leader>-`
- Internal keymaps (in config)

**plugins/completion.lua:**
- Luasnip: `<M-n>` (choice navigation)

**plugins/mini.lua:**
- Move: `H`, `L`, `J`, `K` (visual), `<M-h>`, `<M-l>`, `<M-j>`, `<M-k>`

**plugins/treesitter.lua:**
- Incremental selection: `<C-space>`, `<M-space>`, `<C-s>`
- Text objects: `aa`, `ia`, `af`, `if`, `ac`, `ic`
- Movement: `]m`, `[m`, etc.
- Swap: `<leader>a`, `<leader>A`

**LSPs/on_attach.lua:**
- LSP: `gd`, `gr`, `gI`, `K`, `<C-k>`, `gD`, `<leader>rn`, `ca`, `D`, `fF`, `wa`, `wr`, `wl`, `ds`, `ws`

### Which-Key Groups
- `<leader><leader>` - buffer commands
- `<leader>c` - [c]ode
- `<leader>d` - [d]ocument
- `<leader>f` - [f]ile (NEW)
- `<leader>g` - [g]it
- `<leader>m` - [m]arkdown
- `<leader>r` - [r]ename
- `<leader>s` - [s]earch
- `<leader>t` - [t]oggles
- `<leader>w` - [w]orkspace

## Implementation Structure

### File: lua/myLuaConf/remap.lua

The remap module will have the following structure:

```lua
-- lua/myLuaConf/remap.lua
-- Centralized keybinding configuration

local M = {}
local catUtils = require("nixCatsUtils")

-- ============================================================================
-- Global Remaps Function
-- ============================================================================
-- Sets all global (non-plugin) keymaps
function M.setup_global_remaps()
  -- Current Global_remaps() content unchanged
end

-- ============================================================================
-- Which-Key Setup Function
-- ============================================================================
-- Registers which-key groups and documents keymaps
-- NOTE: Only documents keymaps, does NOT set them
function M.setup_which_key_groups()
  local wk = require("which-key")

  -- Register groups
  -- Document notify/esc handling
  -- Document luasnip keymaps (conditional on blink category)
end

-- ============================================================================
-- LSP Keymaps Function (buffer-local)
-- ============================================================================
function M.setup_lsp_keymaps(bufnr)
  -- All LSP keymaps with buffer = bufnr
  -- Telescope-based keymaps (conditional on telescope category)
  -- Create LSPFormat command
end

-- ============================================================================
-- Plugin-Specific Setup Functions
-- ============================================================================

-- Gitsigns buffer-local keymaps
function M.setup_gitsigns_keymaps(bufnr)
  -- Navigation: ]c, [c (with expr mode)
  -- Actions: <leader>g* variants
  -- Toggles: <leader>gt* variants
  -- Text object: ih
end

-- Telescope keymaps setup
function M.setup_telescope_keymaps()
  -- Sets all <leader>s* keymaps
  -- Sets <leader>/, <leader><leader>s
  -- Uses helpers for git root search
end

-- Telescope lze keys (for lazy loading)
function M.telescope_lze_keys()
  return {
    -- All telescope key specs for lze
  }
end

-- Oil lze keys (for lazy loading)
function M.oil_lze_keys()
  return {
    { "-", "<cmd>Oil<CR>", mode = "n", desc = "Open Parent Directory" },
    { "<leader>-", "<cmd>Oil .<CR>", mode = "n", desc = "Open nvim root directory" },
  }
end

-- Markdown preview lze keys (for lazy loading)
function M.markdown_lze_keys()
  return {
    { "<leader>mp", "<cmd>MarkdownPreview<CR>", mode = "n", desc = "markdown preview" },
    { "<leader>ms", "<cmd>MarkdownPreviewStop<CR>", mode = "n", desc = "markdown preview stop" },
    { "<leader>mt", "<cmd>MarkdownPreviewToggle<CR>", mode = "n", desc = "markdown preview toggle" },
  }
end

-- Undotree lze keys (for lazy loading)
function M.undotree_lze_keys()
  return {
    { "<leader>u", "<cmd>UndotreeToggle<CR>", mode = "n", desc = "[U]ndo Tree" },
  }
end

-- ============================================================================
-- Plugin Configuration Getters
-- ============================================================================

-- Returns oil internal keymaps config
function M.get_oil_keymaps()
  return {
    -- Oil buffer-local keymaps
  }
end

-- Returns treesitter keymaps config
function M.get_treesitter_keymaps()
  return {
    incremental_selection = {},
    textobjects = { select = {}, move = {}, swap = {} },
  }
end

-- Returns mini.move mappings config
function M.get_mini_move_mappings()
  return {
    left = "H", right = "L", down = "J", up = "K",
    line_left = "<M-h>", line_right = "<M-l>",
    line_down = "<M-j>", line_up = "<M-k>",
  }
end

return M
```

### File: lua/myLuaConf/helpers.lua (NEW)

```lua
-- lua/myLuaConf/helpers.lua
-- Helper functions for various plugins

local M = {}

-- ============================================================================
-- Git Helpers
-- ============================================================================

function M.find_git_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()

  if current_file == "" then
    current_dir = cwd
  else
    current_dir = vim.fn.fnamemodify(current_file, ":h")
  end

  local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("Not a git repository. Searching on current working directory")
    return cwd
  end
  return git_root
end

-- ============================================================================
-- Telescope Helpers
-- ============================================================================

function M.telescope_live_grep_git_root()
  local git_root = M.find_git_root()
  if git_root then
    require('telescope.builtin').live_grep({
      search_dirs = { git_root },
    })
  end
end

return M
```

### File: lua/myLuaConf/lsp.lua (RENAMED from LSPs/init.lua)

Simplified by removing the on_attach.lua file and using remap directly:

```lua
-- The on_attach function will simply call:
local on_attach = function(_, bufnr)
  require("myLuaConf.remap").setup_lsp_keymaps(bufnr)
end
```

## Implementation Steps

### Step 1: Create helpers.lua
- Extract `find_git_root` and `live_grep_git_root` from telescope.lua
- Rename to `telescope_live_grep_git_root` for clarity
- Place in new `myLuaConf/helpers.lua` file

### Step 2: Restructure remap.lua
- Convert to module with `local M = {}`
- Rename `Global_remaps()` to `M.setup_global_keymaps()`
- Add skeleton functions for all sections
- Keep existing global remap logic unchanged

### Step 3: Implement notify dismissal function
- Create `M.setup_esc_keymap(notify_dismiss_fn)` function
- Takes optional notify.dismiss function as argument
- Sets `<Esc>` to call both notify dismiss (if provided) and nohlsearch
- Called from plugins/init.lua when setting up notify

### Step 4: Implement which-key groups function
- Create `M.setup_which_key_groups()`
- Register all which-key groups including new `<leader>f` for [F]ile
- Add `<leader>fw` - write file (":w")
- Add `<leader>fW` - force write file (":w!")
- Does NOT set keymaps through which-key, only documents groups and "abnormal" keymaps

### Step 5: Implement LSP keymaps function
- Create `M.setup_lsp_keymaps(bufnr)`
- Move all keymaps from LSPs/on_attach.lua
- Use direct `vim.keymap.set()` with buffer option
- Include conditional telescope keymaps
- Create LSPFormat command

### Step 6: Implement gitsigns keymaps function
- Create `M.setup_gitsigns_keymaps(bufnr)`
- Move all keymaps from plugins/init.lua gitsigns on_attach
- Preserve expr mode navigation keymaps
- Use direct `vim.keymap.set()` with buffer option

### Step 7: Implement telescope functions
- Create `M.setup_telescope_keymaps()` - sets telescope keymaps using normal vim.keymap.set
- Create `M.telescope_lze_keys()` - returns lze key specs for lazy loading
- Use helpers.telescope_live_grep_git_root for git root search

### Step 8: Implement lze keys functions
- Create functions returning lze key specs for:
  - Oil: `M.oil_lze_keys()`
  - Markdown: `M.markdown_lze_keys()`
  - Undotree: `M.undotree_lze_keys()`

### Step 9: Implement plugin config getters
- Create `M.get_oil_keymaps()` - returns oil internal keymaps config
- Create `M.get_treesitter_keymaps()` - returns treesitter keymaps config
- Create `M.get_mini_move_mappings()` - returns mini.move mappings config

### Step 10: Update plugins/init.lua
- Load remaps early in the file
- Setup notify first, then call `M.setup_esc_keymap()` with notify.dismiss
- Update which-key after function to:
  1. Call `M.setup_global_keymaps()` first (sets keymaps)
  2. Call `M.setup_which_key_groups()` (documents groups and abnormal keymaps)
- Update gitsigns on_attach to call `M.setup_gitsigns_keymaps(bufnr)`
- Update markdown, undotree specs to use respective lze keys functions
- Remove all inline keymap definitions

### Step 11: Update plugins/telescope.lua
- Reference `helpers` module for git root functions
- Update keys spec to use `M.telescope_lze_keys()`
- Call `M.setup_telescope_keymaps()` in after function
- Update LiveGrepGitRoot command to use helpers

### Step 12: Update plugins/oil.lua
- Update keys spec to use `M.oil_lze_keys()`
- Update setup to use `M.get_oil_keymaps()`
- Remove inline keymap definitions

### Step 13: Update plugins/completion.lua
- Remove luasnip keymap setup (will be in which-key setup)
- Keep only plugin configuration

### Step 14: Update plugins/treesitter.lua
- Update setup to use `M.get_treesitter_keymaps()`
- Keep only plugin configuration

### Step 15: Update plugins/mini.lua
- Update setup to use `M.get_mini_move_mappings()`
- Keep only plugin configuration

### Step 16: Reorganize LSP files
- Rename `myLuaConf/LSPs/init.lua` to `myLuaConf/lsp.lua`
- Delete `myLuaConf/LSPs/on_attach.lua` (functionality moved to remap.lua)
- Delete `myLuaConf/LSPs/` directory
- Update on_attach to simply call `M.setup_lsp_keymaps(bufnr)`

### Step 17: Update init.lua
- Keep remap loading as-is (don't move to plugins/init.lua per changes.md)

## Testing Checklist

After implementation, verify all keymaps work:

### Global Navigation
- [ ] `<C-d>`, `<C-u>` - scroll and center
- [ ] `n`, `N` - search and center
- [ ] `<Esc>` - dismiss notify and clear highlight
- [ ] `j`, `k` - word wrap navigation
- [ ] `[d`, `]d` - diagnostic navigation
- [ ] `<leader>e` - diagnostic float
- [ ] `<leader>q` - diagnostic list

### Buffer Management
- [ ] `<leader><leader>[` - previous buffer
- [ ] `<leader><leader>]` - next buffer
- [ ] `<leader><leader>l` - last buffer
- [ ] `<leader><leader>d` - delete buffer
- [ ] `<leader><leader>o` - close other buffers

### Clipboard Operations
- [ ] `<leader>y` - yank to clipboard
- [ ] `<leader>Y` - yank line to clipboard
- [ ] `<leader>p` - paste from clipboard
- [ ] `<C-p>` - paste in insert mode
- [ ] `<leader>P` - paste over selection
- [ ] `<leader><C-a>` - select all

### File Operations (NEW)
- [ ] `<leader>fw` - write file
- [ ] `<leader>fW` - force write file

### LSP (when attached)
- [ ] `gd` - goto definition
- [ ] `gD` - goto declaration
- [ ] `gr` - goto references (telescope)
- [ ] `gI` - goto implementation (telescope)
- [ ] `K` - hover
- [ ] `<C-k>` - signature help
- [ ] `<leader>D` - type definition
- [ ] `<leader>rn` - rename
- [ ] `<leader>ca` - code action
- [ ] `<leader>fF` - format buffer
- [ ] `<leader>ds` - document symbols (telescope)
- [ ] `<leader>ws` - workspace symbols (telescope)
- [ ] `<leader>wa`, `wr`, `wl` - workspace folder management

### Gitsigns (in git repo)
- [ ] `]c`, `[c` - hunk navigation
- [ ] `<leader>gs`, `gr` - stage/reset hunk
- [ ] `<leader>gS`, `gR` - stage/reset buffer
- [ ] `<leader>gu` - undo stage
- [ ] `<leader>gp` - preview hunk
- [ ] `<leader>gb` - blame line
- [ ] `<leader>gd`, `gD` - diff
- [ ] `<leader>gtb`, `gtd` - toggles
- [ ] `ih` - hunk text object

### Telescope/Search (if nosnacks)
- [ ] `<leader>sf` - find files
- [ ] `<leader>sg` - live grep
- [ ] `<leader>sw` - grep word
- [ ] `<leader>sh` - help tags
- [ ] `<leader>sk` - keymaps
- [ ] `<leader>sd` - diagnostics
- [ ] `<leader>sr` - resume
- [ ] `<leader>s.` - oldfiles
- [ ] `<leader>sM` - messages
- [ ] `<leader>ss` - select telescope
- [ ] `<leader>sp` - grep git root (uses helpers)
- [ ] `<leader><leader>s` - buffers
- [ ] `<leader>/` - fuzzy find buffer
- [ ] `<leader>s/` - grep open files

### Oil
- [ ] `-` - open parent directory
- [ ] `<leader>-` - open nvim root
- [ ] Internal oil keymaps work in oil buffers

### Other Plugins
- [ ] `<leader>u` - undotree
- [ ] `<leader>mp`, `ms`, `mt` - markdown preview (if enabled)
- [ ] `<M-n>` - luasnip choice cycle
- [ ] `H`, `L`, `J`, `K` - mini.move visual (if mini enabled)
- [ ] `<M-h>`, `<M-l>`, `<M-j>`, `<M-k>` - mini.move normal (if mini enabled)
- [ ] `<C-space>`, `<M-space>` - treesitter selection
- [ ] `aa`, `ia`, `af`, `if`, `ac`, `ic` - treesitter text objects
- [ ] `]m`, `[m`, etc. - treesitter movement
- [ ] `<leader>a`, `<leader>A` - treesitter swap

### Which-Key Integration
- [ ] `<leader>` - shows all groups
- [ ] `<leader>s` - search group
- [ ] `<leader>g` - git group
- [ ] `<leader>f` - file group (NEW)
- [ ] `<leader>c` - code group
- [ ] All descriptions clear and helpful

### Lazy Loading
- [ ] Telescope loads on first `<leader>s` keypress
- [ ] Oil loads on `-` keypress
- [ ] Undotree loads on `<leader>u`
- [ ] Markdown loads on `<leader>m` keypresses

## Key Design Principles

1. **Single source of truth**: All keymaps visible in rremapsemap.lua
2. **No which-key keymap setting**: Only use which-key for documenting groups and abnormal keymaps that aren't set normally
3. **Separation of concerns**:
   - Global keymaps set first
   - Which-key documents groups
   - Plugin-specific functions called when plugins load
   - LSP/gitsigns use buffer-local setup
4. **Lazy loading preserved**: lze keys functions return specs for lazy loading
5. **Plugin config returned**: Functions return config tables for plugins that need them
6. **Helper functions centralized**: Shared helpers in helpers.lua
7. **Simplified LSP setup**: Remove on_attach.lua file, use remap directly from lsp.lua

## Files Changed Summary

### Created
- `lua/myLuaConf/helpers.lua` (telescope helpers)
- `lua/myLuaConf/lsp.lua` (renamed from LSPs/init.lua)

### Modified
- `lua/myLuaConf/remap.lua` (restructured with all functions)
- `lua/myLuaConf/plugins/init.lua` (use remap functions)
- `lua/myLuaConf/plugins/telescope.lua` (use remap + helpers)
- `lua/myLuaConf/plugins/oil.lua` (use remap functions)
- `lua/myLuaConf/plugins/completion.lua` (remove keymaps)
- `lua/myLuaConf/plugins/treesitter.lua` (use remap function)
- `lua/myLuaConf/plugins/mini.lua` (use remap function)

### Deleted
- `lua/myLuaConf/LSPs/on_attach.lua` (moved to remap.lua)
- `lua/myLuaConf/LSPs/` directory (no longer needed)

### Unchanged
- `lua/myLuaConf/init.lua` (keeps remap loading)
