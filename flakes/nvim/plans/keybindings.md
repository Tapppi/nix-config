# Neovim Keybindings Centralization Plan

## Overview

This plan outlines the migration of all Neovim keybindings to a centralized location in `lua/myLuaConf/remap.lua`, using which-key for documentation and maintaining separate lze lazy-loading configurations.

## Current State Analysis

### Keybinding Locations Inventory

1. **lua/myLuaConf/remap.lua** (lines 8-98)
   - Global navigation improvements (C-d, C-u, n, N with centering)
   - Buffer management (<leader><leader>[, ], l, d, o)
   - Word wrap navigation (j, k)
   - Diagnostic navigation ([d, ]d, <leader>e, <leader>q)
   - Clipboard operations (<leader>y, Y, p, P, C-p)
   - Selection operations (<leader>C-a)
   - Conditional line movement (J, K in visual mode)

2. **lua/myLuaConf/plugins/init.lua**
   - Line 9-11: Notify dismiss on <Esc>
   - Lines 29-31: Markdown preview (<leader>mp, ms, mt)
   - Line 41: Undotree toggle (<leader>u)
   - Lines 155-203: Gitsigns (]c, [c, <leader>g* variants)

3. **lua/myLuaConf/plugins/completion.lua**
   - Lines 29-33: Luasnip choice navigation (<M-n>)

4. **lua/myLuaConf/plugins/mini.lua**
   - Lines 17-26: Mini.move mappings (H, L, J, K, M-h, M-l, M-j, M-k)

5. **lua/myLuaConf/plugins/oil.lua**
   - Lines 24-41: Oil internal keymaps (configured in setup)
   - Lines 44-45: Oil entry keymaps (-, <leader>-)

6. **lua/myLuaConf/plugins/telescope.lua**
   - Lines 25-55: Helper functions (find_git_root, live_grep_git_root)
   - Lines 66-104: All telescope search bindings (<leader>s*, <leader>/, <leader><leader>s)

7. **lua/myLuaConf/plugins/treesitter.lua**
   - Lines 27-32: Incremental selection (C-space, M-space, C-s)
   - Lines 38-46: Text object selection (aa, ia, af, if, ac, ic)
   - Lines 51-66: Text object movement (]m, ]M, [m, [M, ]], ][, [[, [])
   - Lines 71-75: Parameter swapping (<leader>a, <leader>A)

8. **lua/myLuaConf/LSPs/on_attach.lua**
   - Lines 13-54: All LSP keybindings (gd, gr, gI, K, C-k, etc.)

### Current Which-Key Groups

Defined in `lua/myLuaConf/plugins/init.lua` (lines 222-241):
- `<leader><leader>` - buffer commands
- `<leader>c` - [c]ode
- `<leader>d` - [d]ocument
- `<leader>g` - [g]it
- `<leader>m` - [m]arkdown
- `<leader>r` - [r]ename
- `<leader>s` - [s]earch
- `<leader>t` - [t]oggles
- `<leader>w` - [w]orkspace

---

## Target Structure

### New remap.lua Module Structure

```lua
-- lua/myLuaConf/remap.lua
-- Centralized keybinding configuration

local M = {}
local catUtils = require("nixCatsUtils")

-- ============================================================================
-- SECTION 1: Global Remaps (non-plugin)
-- ============================================================================
function M.setup_global_remaps()
  -- All current Global_remaps() content
end

-- ============================================================================
-- SECTION 2: Which-Key Remap Definitions (for loaded plugins)
-- ============================================================================
function M.setup_which_key_remaps()
  -- Register all global remaps with which-key for documentation
  -- Register groups, plugin remaps, etc.
  -- NOTE: This only documents remaps, does NOT set them
end

-- ============================================================================
-- SECTION 3: LSP Remaps (buffer-local, applied on_attach)
-- ============================================================================
function M.setup_lsp_remaps(bufnr)
  -- All LSP remaps from on_attach.lua
end

-- ============================================================================
-- SECTION 4: Gitsigns Remaps (buffer-local, applied on_attach)
-- ============================================================================
function M.setup_gitsigns_remaps(bufnr)
  -- All gitsigns remaps
end

-- ============================================================================
-- SECTION 5: Plugin-specific Keybinding Configs (returns for plugin setup)
-- ============================================================================
function M.get_oil_keymaps()
  -- Returns oil internal keymaps config
  return { ... }
end

function M.get_treesitter_keymaps()
  -- Returns treesitter keymaps config
  return { ... }
end

function M.get_mini_move_mappings()
  -- Returns mini.move mappings config
  return { ... }
end

-- ============================================================================
-- SECTION 6: Lazy Loading Key Specs (for lze)
-- ============================================================================
M.lze_keys = {
  markdown_preview = { ... },
  undotree = { ... },
  telescope = { ... },
  oil = { ... },
}

return M
```

### New telescope_helpers.lua Module

```lua
-- lua/myLuaConf/telescope_helpers.lua
-- Telescope helper functions

local M = {}

function M.find_git_root()
  -- Implementation from telescope.lua
end

function M.live_grep_git_root()
  -- Implementation from telescope.lua
end

return M
```

---

## Implementation Steps

### Step 1: Restructure lua/myLuaConf/remap.lua

**Objective**: Convert to modular structure with named exports and document global remaps

**Actions**:
1. Create local module table: `local M = {}`
2. Rename `Global_remaps()` to `M.setup_global_remaps()`
3. Keep all existing keybinding logic identical
4. Add skeleton for new functions:
   - `M.setup_which_key_remaps()` - this will document global remaps AND plugin remaps
   - `M.setup_lsp_remaps(bufnr)`
   - `M.setup_gitsigns_remaps(bufnr)`
   - `M.get_oil_keymaps()`
   - `M.get_treesitter_keymaps()`
   - `M.get_mini_move_mappings()`
5. Create `M.lze_keys` table (empty for now)
6. Add `return M` at end of file

**Note**: In `setup_which_key_remaps()`, we'll document the global remaps that are already set by `setup_global_remaps()`. This ensures all remaps appear in which-key.

**Validation**:
- File should still be valid Lua
- No remaps changed yet
- Module exports properly

---

### Step 2: Create lua/myLuaConf/telescope_helpers.lua

**Objective**: Extract telescope helper functions to separate module for reuse

**Actions**:

1. **Create new file `lua/myLuaConf/telescope_helpers.lua`**:
```lua
-- lua/myLuaConf/telescope_helpers.lua
-- Telescope helper functions

local M = {}

-- Function to find the git root directory based on the current buffer's path
function M.find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == "" then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ":h")
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("Not a git repository. Searching on current working directory")
    return cwd
  end
  return git_root
end

-- Custom live_grep function to search in git root
function M.live_grep_git_root()
  local git_root = M.find_git_root()
  if git_root then
    require('telescope.builtin').live_grep({
      search_dirs = { git_root },
    })
  end
end

return M
```

**Files Created**:
- `lua/myLuaConf/telescope_helpers.lua` - New helper module

**Validation**:
- File is valid Lua
- Module exports properly
- Functions work as before

---

### Step 3: Populate lze_keys for Lazy Loading

**Objective**: Create lazy loading key specifications

**Actions**:

1. **Markdown Preview Keys** (from plugins/init.lua lines 28-32):
```lua
M.lze_keys.markdown_preview = {
  {"<leader>mp", "<cmd>MarkdownPreview<CR>", mode = {"n"}, noremap = true, desc = "markdown preview"},
  {"<leader>ms", "<cmd>MarkdownPreviewStop<CR>", mode = {"n"}, noremap = true, desc = "markdown preview stop"},
  {"<leader>mt", "<cmd>MarkdownPreviewToggle<CR>", mode = {"n"}, noremap = true, desc = "markdown preview toggle"},
}
```

2. **Undotree Keys** (from plugins/init.lua line 41):
```lua
M.lze_keys.undotree = {
  {"<leader>u", "<cmd>UndotreeToggle<CR>", mode = {"n"}, desc = "[U]ndo Tree"},
}
```

3. **Oil Keys** (from plugins/oil.lua lines 44-45):
```lua
M.lze_keys.oil = {
  {"-", "<cmd>Oil<CR>", mode = {"n"}, noremap = true, desc = "Open Parent Directory"},
  {"<leader>-", "<cmd>Oil .<CR>", mode = {"n"}, noremap = true, desc = "Open nvim root directory"},
}
```

4. **Telescope Keys** (from plugins/telescope.lua lines 66-104):
```lua
M.lze_keys.telescope = {
  {"<leader>sM", "<cmd>Telescope notify<CR>", mode = {"n"}, desc = "[S]earch [M]essage"},
  {
    "<leader>sp",
    function()
      require("myLuaConf.telescope_helpers").live_grep_git_root()
    end,
    mode = {"n"},
    desc = "[S]earch git [P]roject root"
  },
  {
    "<leader>/",
    function()
      require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end,
    mode = {"n"},
    desc = "[/] Fuzzily search in current buffer",
  },
  {
    "<leader>s/",
    function()
      require("telescope.builtin").live_grep {
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
      }
    end,
    mode = {"n"},
    desc = "[S]earch [/] in Open Files"
  },
  {"<leader><leader>s", function() return require("telescope.builtin").buffers() end, mode = {"n"}, desc = "[ ] Find existing buffers"},
  {"<leader>s.", function() return require("telescope.builtin").oldfiles() end, mode = {"n"}, desc = "[S]earch Recent Files (\".\" for repeat)"},
  {"<leader>sr", function() return require("telescope.builtin").resume() end, mode = {"n"}, desc = "[S]earch [R]esume"},
  {"<leader>sd", function() return require("telescope.builtin").diagnostics() end, mode = {"n"}, desc = "[S]earch [D]iagnostics"},
  {"<leader>sg", function() return require("telescope.builtin").live_grep() end, mode = {"n"}, desc = "[S]earch by [G]rep"},
  {"<leader>sw", function() return require("telescope.builtin").grep_string() end, mode = {"n"}, desc = "[S]earch current [W]ord"},
  {"<leader>ss", function() return require("telescope.builtin").builtin() end, mode = {"n"}, desc = "[S]earch [S]elect Telescope"},
  {"<leader>sf", function() return require("telescope.builtin").find_files() end, mode = {"n"}, desc = "[S]earch [F]iles"},
  {"<leader>sk", function() return require("telescope.builtin").keymaps() end, mode = {"n"}, desc = "[S]earch [K]eymaps"},
  {"<leader>sh", function() return require("telescope.builtin").help_tags() end, mode = {"n"}, desc = "[S]earch [H]elp"},
}
```

**Files Modified**:
- `lua/myLuaConf/remap.lua` - Add M.lze_keys table

**Validation**:
- All key specs are properly formatted for lze
- Function references work correctly
- Uses telescope_helpers module for git root search

---

### Step 4: Implement setup_which_key_remaps()

**Objective**: Register all remaps with which-key for documentation (including global remaps that are already set)

**Important**: This function ONLY documents global remaps. It does NOT set them. Global remaps are already set by `setup_global_remaps()` which is called before this function.

**Actions**:

1. **Add function skeleton**:
```lua
function M.setup_which_key_remaps()
  local wk = require("which-key")

  -- Register groups (from plugins/init.lua lines 222-241)
  wk.add({
    { "<leader><leader>", group = "buffer commands" },
    { "<leader><leader>_", hidden = true },
    { "<leader>c", group = "[c]ode" },
    { "<leader>c_", hidden = true },
    { "<leader>d", group = "[d]ocument" },
    { "<leader>d_", hidden = true },
    { "<leader>g", group = "[g]it" },
    { "<leader>g_", hidden = true },
    { "<leader>gt", group = "[g]it [t]oggles" },
    { "<leader>gt_", hidden = true },
    { "<leader>m", group = "[m]arkdown" },
    { "<leader>m_", hidden = true },
    { "<leader>r", group = "[r]ename" },
    { "<leader>r_", hidden = true },
    { "<leader>s", group = "[s]earch" },
    { "<leader>s_", hidden = true },
    { "<leader>t", group = "[t]oggles" },
    { "<leader>t_", hidden = true },
    { "<leader>w", group = "[w]orkspace" },
    { "<leader>w_", hidden = true },
  })
end
```

2. **Document Global Remaps** (already set by setup_global_remaps):
```lua
  -- Document global remaps (these are already set via setup_global_remaps)
  wk.add({
    { "<C-d>", desc = "Scroll Down" },
    { "<C-u>", desc = "Scroll Up" },
    { "n", desc = "Next Search Result" },
    { "N", desc = "Previous Search Result" },
    { "<Esc>", desc = "Clear search highlight" },
    { "<leader><leader>[", desc = "Previous buffer" },
    { "<leader><leader>]", desc = "Next buffer" },
    { "<leader><leader>l", desc = "Last buffer" },
    { "<leader><leader>d", desc = "Delete buffer" },
    { "<leader><leader>o", desc = "Close all other buffers" },
    { "k", desc = "Up (word wrap aware)", mode = "n" },
    { "j", desc = "Down (word wrap aware)", mode = "n" },
    { "[d", desc = "Go to previous diagnostic message" },
    { "]d", desc = "Go to next diagnostic message" },
    { "<leader>e", desc = "Open floating diagnostic message" },
    { "<leader>q", desc = "Open diagnostics list" },
    { "<leader>y", desc = "Yank to clipboard", mode = {"v", "x", "n"} },
    { "<leader>Y", desc = "Yank line to clipboard", mode = {"n", "v", "x"} },
    { "<leader>p", desc = "Paste from clipboard", mode = {"n", "v", "x"} },
    { "<C-p>", desc = "Paste from clipboard", mode = "i" },
    { "<leader>P", desc = "Paste over selection without erasing unnamed register", mode = "x" },
    { "<leader><C-a>", desc = "Select all", mode = {"n", "v", "x"} },
  })

  -- Conditional line movement (only if mini not enabled)
  if not catUtils.enableForCategory("mini", true) and catUtils.enableForCategory("nomini", true) then
    wk.add({
      { "J", desc = "Moves Line Down", mode = "v" },
      { "K", desc = "Moves Line Up", mode = "v" },
    })
  end
```

3. **Add Notify keybinding** (if notify is loaded):
```lua
  -- ESC key handling
  -- Note: This is already set in init.lua before which-key loads, we're just documenting it
  local notify_ok = pcall(require, "notify")
  if notify_ok then
    wk.add({
      { "<Esc>", desc = "Dismiss notify and clear search highlight" },
    })
  else
    wk.add({
      { "<Esc>", desc = "Clear search highlight" },
    })
  end
```

4. **Add Luasnip keybinding** (from completion.lua lines 29-33):
```lua
  -- Luasnip choice navigation
  if catUtils.enableForCategory("general.blink", true) then
    wk.add({
      {
        "<M-n>",
        function()
          local ls = require("luasnip")
          if ls.choice_active() then
            ls.change_choice(1)
          end
        end,
        mode = { "i", "s" },
        desc = "Luasnip: cycle choice"
      },
    })
  end
```

5. **Add documentation for plugin-configured keymaps**:
```lua
  -- Document Oil keymaps (configured in oil setup, documented here)
  if catUtils.enableForCategory("general.extra", true) then
    wk.add({
      { "-", desc = "Open Parent Directory" },
      { "<leader>-", desc = "Open nvim root directory" },
    })
  end

  -- Document Undotree
  if catUtils.enableForCategory("general.always", true) then
    wk.add({
      { "<leader>u", desc = "[U]ndo Tree" },
    })
  end

  -- Document Markdown Preview
  if catUtils.enableForCategory("markdown", true) then
    wk.add({
      { "<leader>mp", desc = "markdown preview" },
      { "<leader>ms", desc = "markdown preview stop" },
      { "<leader>mt", desc = "markdown preview toggle" },
    })
  end

  -- Document Telescope (when nosnacks is enabled)
  if catUtils.enableForCategory("nosnacks", true) and not catUtils.enableForCategory("snacks", true) then
    wk.add({
      { "<leader>sM", desc = "[S]earch [M]essage" },
      { "<leader>sp", desc = "[S]earch git [P]roject root" },
      { "<leader>/", desc = "[/] Fuzzily search in current buffer" },
      { "<leader>s/", desc = "[S]earch [/] in Open Files" },
      { "<leader><leader>s", desc = "[ ] Find existing buffers" },
      { "<leader>s.", desc = "[S]earch Recent Files (\".\" for repeat)" },
      { "<leader>sr", desc = "[S]earch [R]esume" },
      { "<leader>sd", desc = "[S]earch [D]iagnostics" },
      { "<leader>sg", desc = "[S]earch by [G]rep" },
      { "<leader>sw", desc = "[S]earch current [W]ord" },
      { "<leader>ss", desc = "[S]earch [S]elect Telescope" },
      { "<leader>sf", desc = "[S]earch [F]iles" },
      { "<leader>sk", desc = "[S]earch [K]eymaps" },
      { "<leader>sh", desc = "[S]earch [H]elp" },
    })
  end

  -- Document Treesitter keymaps (configured in treesitter, documented here)
  if catUtils.enableForCategory("general.treesitter", true) then
    wk.add({
      { "<c-space>", desc = "TS: init/increment selection", mode = "n" },
      { "<c-space>", desc = "TS: node incremental", mode = "v" },
      { "<c-s>", desc = "TS: scope incremental", mode = "n" },
      { "<M-space>", desc = "TS: node decremental", mode = "n" },
      { "aa", desc = "TS: select outer parameter", mode = {"x", "o"} },
      { "ia", desc = "TS: select inner parameter", mode = {"x", "o"} },
      { "af", desc = "TS: select outer function", mode = {"x", "o"} },
      { "if", desc = "TS: select inner function", mode = {"x", "o"} },
      { "ac", desc = "TS: select outer class", mode = {"x", "o"} },
      { "ic", desc = "TS: select inner class", mode = {"x", "o"} },
      { "]m", desc = "TS: next function start", mode = "n" },
      { "]]", desc = "TS: next class start", mode = "n" },
      { "]M", desc = "TS: next function end", mode = "n" },
      { "][", desc = "TS: next class end", mode = "n" },
      { "[m", desc = "TS: prev function start", mode = "n" },
      { "[[", desc = "TS: prev class start", mode = "n" },
      { "[M", desc = "TS: prev function end", mode = "n" },
      { "[]", desc = "TS: prev class end", mode = "n" },
      { "<leader>a", desc = "TS: swap next parameter", mode = "n" },
      { "<leader>A", desc = "TS: swap prev parameter", mode = "n" },
    })
  end

  -- Document Mini.move keymaps (configured in mini, documented here)
  if catUtils.enableForCategory("mini", true) then
    wk.add({
      { "H", desc = "Mini.move: left", mode = "v" },
      { "L", desc = "Mini.move: right", mode = "v" },
      { "J", desc = "Mini.move: down", mode = "v" },
      { "K", desc = "Mini.move: up", mode = "v" },
      { "<M-h>", desc = "Mini.move: line left", mode = "n" },
      { "<M-l>", desc = "Mini.move: line right", mode = "n" },
      { "<M-j>", desc = "Mini.move: line down", mode = "n" },
      { "<M-k>", desc = "Mini.move: line up", mode = "n" },
    })
  end
```

**Files Modified**:
- `lua/myLuaConf/remap.lua` - Implement setup_which_key_remaps()

**Validation**:
- All remaps are documented
- Conditional logic preserves category-based loading
- Uses `catUtils.enableForCategory()` with default `true`
- which-key popup shows descriptions
- Function ONLY documents, does NOT set remaps

---

### Step 5: Implement setup_lsp_remaps()

**Objective**: Move all LSP remaps from on_attach.lua

**Actions**:

1. **Copy all remaps from on_attach.lua lines 13-54**:
```lua
function M.setup_lsp_remaps(bufnr)
  local wk = require("which-key")

  wk.add({
    { "<leader>rn", vim.lsp.buf.rename, buffer = bufnr, desc = "LSP: [R]e[n]ame" },
    { "<leader>ca", vim.lsp.buf.code_action, buffer = bufnr, desc = "LSP: [C]ode [A]ction" },
    { "gd", vim.lsp.buf.definition, buffer = bufnr, desc = "LSP: [G]oto [D]efinition" },
    { "<leader>D", vim.lsp.buf.type_definition, buffer = bufnr, desc = "LSP: Type [D]efinition" },
    { "K", vim.lsp.buf.hover, buffer = bufnr, desc = "LSP: Hover Documentation" },
    { "<C-k>", vim.lsp.buf.signature_help, buffer = bufnr, desc = "LSP: Signature Documentation" },
    { "gD", vim.lsp.buf.declaration, buffer = bufnr, desc = "LSP: [G]oto [D]eclaration" },
    { "<leader>wa", vim.lsp.buf.add_workspace_folder, buffer = bufnr, desc = "LSP: [W]orkspace [A]dd Folder" },
    { "<leader>wr", vim.lsp.buf.remove_workspace_folder, buffer = bufnr, desc = "LSP: [W]orkspace [R]emove Folder" },
    {
      "<leader>wl",
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      buffer = bufnr,
      desc = "LSP: [W]orkspace [L]ist Folders"
    },
    { "<leader>fF", vim.lsp.buf.format, buffer = bufnr, desc = "LSP: Format current buffer with LSP" },
  })

  -- Telescope-based LSP bindings (conditional)
  if catUtils.enableForCategory("general.telescope", true) then
    wk.add({
      {
        "gr",
        function()
          require("telescope.builtin").lsp_references()
        end,
        buffer = bufnr,
        desc = "LSP: [G]oto [R]eferences"
      },
      {
        "gI",
        function()
          require("telescope.builtin").lsp_implementations()
        end,
        buffer = bufnr,
        desc = "LSP: [G]oto [I]mplementation"
      },
      {
        "<leader>ds",
        function()
          require("telescope.builtin").lsp_document_symbols()
        end,
        buffer = bufnr,
        desc = "LSP: [D]ocument [S]ymbols"
      },
      {
        "<leader>ws",
        function()
          require("telescope.builtin").lsp_dynamic_workspace_symbols()
        end,
        buffer = bufnr,
        desc = "LSP: [W]orkspace [S]ymbols"
      },
    })
  end

  -- Create LSPFormat command
  vim.api.nvim_buf_create_user_command(bufnr, "LSPFormat", function(_)
    vim.lsp.buf.format()
  end, { desc = "Format current buffer with LSP" })
end
```

**Files Modified**:
- `lua/myLuaConf/remap.lua` - Implement setup_lsp_remaps()

**Validation**:
- All LSP remaps are defined
- Buffer-local bindings work correctly
- Telescope conditional uses `catUtils.enableForCategory()` with default `true`

---

### Step 6: Implement setup_gitsigns_remaps()

**Objective**: Move all gitsigns remaps from plugins/init.lua

**Actions**:

1. **Copy gitsigns on_attach logic from plugins/init.lua lines 145-204**:
```lua
function M.setup_gitsigns_remaps(bufnr)
  local wk = require("which-key")
  local gs = package.loaded.gitsigns

  -- Navigation
  wk.add({
    {
      "]c",
      function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end,
      buffer = bufnr,
      mode = { "n", "v" },
      expr = true,
      desc = "Jump to next hunk"
    },
    {
      "[c",
      function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end,
      buffer = bufnr,
      mode = { "n", "v" },
      expr = true,
      desc = "Jump to previous hunk"
    },
  })

  -- Actions - visual mode
  wk.add({
    {
      "<leader>gs",
      function()
        gs.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
      end,
      buffer = bufnr,
      mode = "v",
      desc = "stage git hunk"
    },
    {
      "<leader>gr",
      function()
        gs.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
      end,
      buffer = bufnr,
      mode = "v",
      desc = "reset git hunk"
    },
  })

  -- Actions - normal mode
  wk.add({
    { "<leader>gs", gs.stage_hunk, buffer = bufnr, mode = "n", desc = "git stage hunk" },
    { "<leader>gr", gs.reset_hunk, buffer = bufnr, mode = "n", desc = "git reset hunk" },
    { "<leader>gS", gs.stage_buffer, buffer = bufnr, mode = "n", desc = "git Stage buffer" },
    { "<leader>gu", gs.undo_stage_hunk, buffer = bufnr, mode = "n", desc = "undo stage hunk" },
    { "<leader>gR", gs.reset_buffer, buffer = bufnr, mode = "n", desc = "git Reset buffer" },
    { "<leader>gp", gs.preview_hunk, buffer = bufnr, mode = "n", desc = "preview git hunk" },
    {
      "<leader>gb",
      function()
        gs.blame_line { full = false }
      end,
      buffer = bufnr,
      mode = "n",
      desc = "git blame line"
    },
    { "<leader>gd", gs.diffthis, buffer = bufnr, mode = "n", desc = "git diff against index" },
    {
      "<leader>gD",
      function()
        gs.diffthis "~"
      end,
      buffer = bufnr,
      mode = "n",
      desc = "git diff against last commit"
    },
  })

  -- Toggles
  wk.add({
    { "<leader>gtb", gs.toggle_current_line_blame, buffer = bufnr, mode = "n", desc = "toggle git blame line" },
    { "<leader>gtd", gs.toggle_deleted, buffer = bufnr, mode = "n", desc = "toggle git show deleted" },
  })

  -- Text object
  wk.add({
    { "ih", ":<C-U>Gitsigns select_hunk<CR>", buffer = bufnr, mode = { "o", "x" }, desc = "select git hunk" },
  })
end
```

**Files Modified**:
- `lua/myLuaConf/remap.lua` - Implement setup_gitsigns_remaps()

**Validation**:
- All gitsigns remaps work
- Buffer-local bindings apply correctly
- Navigation with expr mode works

---

### Step 7: Implement Plugin-specific Config Functions

**Objective**: Create functions that return plugin-specific keybinding configurations

**Actions**:

1. **Oil keymaps function** (from oil.lua lines 24-41):
```lua
function M.get_oil_keymaps()
  return {
    ["g?"] = "actions.show_help",
    ["<CR>"] = "actions.select",
    ["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
    ["<C-x>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
    ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = "actions.close",
    ["<C-r>"] = "actions.refresh",
    ["-"] = "actions.parent",
    ["_"] = "actions.open_cwd",
    ["`"] = "actions.cd",
    ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
    ["gs"] = "actions.change_sort",
    ["gx"] = "actions.open_external",
    ["g."] = "actions.toggle_hidden",
    ["g\\"] = "actions.toggle_trash",
  }
end
```

2. **Treesitter keymaps function** (from treesitter.lua lines 27-76):
```lua
function M.get_treesitter_keymaps()
  return {
    incremental_selection = {
      init_selection = "<c-space>",
      node_incremental = "<c-space>",
      scope_incremental = "<c-s>",
      node_decremental = "<M-space>",
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ["<leader>a"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>A"] = "@parameter.inner",
        },
      },
    },
  }
end
```

3. **Mini.move mappings function** (from mini.lua lines 17-26):
```lua
function M.get_mini_move_mappings()
  return {
    left = "H",
    right = "L",
    down = "J",
    up = "K",
    line_left = "<M-h>",
    line_right = "<M-l>",
    line_down = "<M-j>",
    line_up = "<M-k>",
  }
end
```

**Files Modified**:
- `lua/myLuaConf/remap.lua` - Add plugin config getter functions

**Validation**:
- Functions return correct config structures
- Configs match plugin requirements

---

### Step 8: Update lua/myLuaConf/init.lua

**Objective**: Remove direct remap loading, delegate to plugins/init.lua

**Actions**:

1. **Remove lines 6-7**:
```lua
-- DELETE THESE LINES:
require("myLuaConf.remap")
Global_remaps()
```

2. **Keep everything else unchanged**

**Files Modified**:
- `lua/myLuaConf/init.lua` - Remove remap loading

**Validation**:
- init.lua still loads all other modules
- No remap loaded yet (will be loaded by plugins/init.lua)

---

### Step 9: Update lua/myLuaConf/plugins/init.lua

**Objective**: Load remap module and call remap setup functions

**Actions**:

1. **Remove notify keymap (lines 9-11)** - Will be in remap.lua

2. **Update markdown-preview spec (lines 24-36)**:
```lua
{
  "markdown-preview.nvim",
  for_cat = "markdown",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  ft = "markdown",
  keys = require("myLuaConf.remap").lze_keys.markdown_preview,
  before = function()
    vim.g.mkdp_auto_close = 0
  end,
},
```

3. **Update undotree spec (lines 37-47)**:
```lua
{
  "undotree",
  for_cat = "general.always",
  cmd = { "UndotreeToggle", "UndotreeHide", "UndotreeShow", "UndotreeFocus", "UndotreePersistUndo" },
  keys = require("myLuaConf.remap").lze_keys.undotree,
  before = function()
    vim.g.undotree_WindowLayout = 1
    vim.g.undotree_SplitWidth = 40
    vim.g.undotree_SetFocusWhenToggle = 1
  end,
},
```

4. **Update gitsigns spec (lines 131-210)**:
   - Remove on_attach keybindings (lines 145-204)
   - Replace with call to remap function:
```lua
{
  "gitsigns.nvim",
  for_cat = "general.always",
  event = "DeferredUIEnter",
  after = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        require("myLuaConf.remap").setup_gitsigns_remaps(bufnr)
      end,
    })
    vim.cmd([[hi GitSignsAdd guifg=#04de21]])
    vim.cmd([[hi GitSignsChange guifg=#83fce6]])
    vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
  end,
},
```

5. **Update which-key spec (lines 211-244)**:
   - Call setup_global_remaps() FIRST (to set remaps)
   - Then call setup_which_key_remaps() to DOCUMENT remaps (does NOT re-run/set them):
```lua
{
  "which-key.nvim",
  for_cat = "general.always",
  event = "DeferredUIEnter",
  after = function()
    require("which-key").setup({})

    -- Load all remaps
    local remaps = require("myLuaConf.remap")
    -- First, set the global remaps
    remaps.setup_global_remaps()
    -- Then, document all remaps (does NOT re-run them, only documents)
    remaps.setup_which_key_remaps()
  end,
},
```

6. **Add notify setup after which-key** (after line 12):
```lua
local ok, notify = pcall(require, "notify")
if ok then
  notify.setup({
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { focusable = false })
    end,
  })
  vim.notify = notify
end
```

**Files Modified**:
- `lua/myLuaConf/plugins/init.lua` - Update plugin specs and load remaps

**Validation**:
- Which-key loads and sets up remaps
- Global remaps are set FIRST, then documented
- setup_which_key_remaps() only documents, does NOT re-run remaps
- Plugin remaps documented
- Markdown, undotree lazy load on keys

---

### Step 10: Update lua/myLuaConf/plugins/telescope.lua

**Objective**: Use lze_keys from remap.lua and reference telescope_helpers module

**Actions**:

1. **Update helper functions to use telescope_helpers module (lines 25-55)**:
```lua
-- Use shared telescope helpers
local telescope_helpers = require("myLuaConf.telescope_helpers")
local find_git_root = telescope_helpers.find_git_root
local live_grep_git_root = telescope_helpers.live_grep_git_root
```

2. **Update keys specification (lines 66-105)**:
```lua
{
  "telescope.nvim",
  enabled = not nixCats("snacks") and nixCats("nosnacks"),
  cmd = { "Telescope", "LiveGrepGitRoot" },
  on_require = { "telescope" },
  keys = require("myLuaConf.remap").lze_keys.telescope,
  load = function(name)
    vim.cmd.packadd(name)
    vim.cmd.packadd("telescope-fzf-native.nvim")
    vim.cmd.packadd("telescope-ui-select.nvim")
  end,
  after = function()
    -- ... rest of setup unchanged
  end,
},
```

3. **Keep after function unchanged** (telescope setup, extensions, command, autocommand)
   - But update the command to reference the helper:
```lua
-- Command for git root (uses shared helper)
local telescope_helpers = require("myLuaConf.telescope_helpers")
vim.api.nvim_create_user_command('LiveGrepGitRoot', telescope_helpers.live_grep_git_root, {})
```

**Files Modified**:
- `lua/myLuaConf/plugins/telescope.lua` - Use remaps.lze_keys.telescope and telescope_helpers

**Validation**:
- Telescope loads on key presses
- All search functions work
- LiveGrepGitRoot command works
- Helper functions work from shared module

---

### Step 11: Update lua/myLuaConf/plugins/oil.lua

**Objective**: Use lze_keys and get_oil_keymaps() from remap.lua

**Actions**:

1. **Remove keymaps from after function (lines 44-45)**:
```lua
-- DELETE THESE LINES:
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { noremap = true, desc = 'Open Parent Directory' })
vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", { noremap = true, desc = 'Open nvim root directory' })
```

2. **Update lze config to use remap functions**:
```lua
{
  "oil.nvim",
  for_cat = "general.extra",
  lazy = false,
  keys = require("myLuaConf.remap").lze_keys.oil,
  before = function()
    vim.g.loaded_netrwPlugin = 1
  end,
  after = function()
    local remaps = require("myLuaConf.remap")
    require("oil").setup({
      keymaps = remaps.get_oil_keymaps(),
      view_options = {
        show_hidden = true,
      },
    })
  end
}
```

**Files Modified**:
- `lua/myLuaConf/plugins/oil.lua` - Use remaps functions

**Validation**:
- Oil opens on `-` and `<leader>-`
- Internal oil keymaps work

---

### Step 12: Update lua/myLuaConf/plugins/completion.lua

**Objective**: Remove luasnip keymap (now in remap.lua)

**Actions**:

1. **Remove keybinding from luasnip after function (lines 29-33)**:
```lua
{
  "luasnip",
  for_cat = "general.blink",
  dep_of = { "blink.cmp" },
  after = function(_)
    local luasnip = require 'luasnip'
    require('luasnip.loaders.from_vscode').lazy_load()
    luasnip.config.setup {}

    -- DELETE THESE LINES:
    -- local ls = require('luasnip')
    -- vim.keymap.set({ "i", "s" }, "<M-n>", function()
    --   if ls.choice_active() then
    --     ls.change_choice(1)
    --   end
    -- end)
  end,
},
```

**Files Modified**:
- `lua/myLuaConf/plugins/completion.lua` - Remove luasnip keymap

**Validation**:
- Luasnip still loads
- <M-n> works (now registered via which-key in remap.lua)

---

### Step 13: Update lua/myLuaConf/plugins/treesitter.lua

**Objective**: Use get_treesitter_keymaps() from remap.lua

**Actions**:

1. **Update treesitter setup to use remap function**:
```lua
after = function()
  local remaps = require("myLuaConf.remap")
  local ts_keymaps = remaps.get_treesitter_keymaps()

  require("nvim-treesitter.configs").setup({
    -- ... other config ...
    incremental_selection = ts_keymaps.incremental_selection,
    textobjects = ts_keymaps.textobjects,
  })
end,
```

**Files Modified**:
- `lua/myLuaConf/plugins/treesitter.lua` - Use remaps function

**Validation**:
- Treesitter keymaps work as before
- Text objects and navigation work

---

### Step 14: Update lua/myLuaConf/plugins/mini.lua

**Objective**: Use get_mini_move_mappings() from remap.lua

**Actions**:

1. **Update mini.move setup to use remap function**:
```lua
after = function()
  local remaps = require("myLuaConf.remap")

  require("mini.move").setup({
    mappings = remaps.get_mini_move_mappings(),
  })
end,
```

**Files Modified**:
- `lua/myLuaConf/plugins/mini.lua` - Use remaps function

**Validation**:
- Mini.move keymaps work as before
- Visual mode H, L, J, K work
- Normal mode Alt+hjkl work

---

### Step 15: Update lua/myLuaConf/LSPs/on_attach.lua

**Objective**: Replace all remaps with call to remap function

**Actions**:

1. **Replace entire function body** (lines 1-55):
```lua
return function(_, bufnr)
  require("myLuaConf.remap").setup_lsp_remaps(bufnr)
end
```

**Files Modified**:
- `lua/myLuaConf/LSPs/on_attach.lua` - Simplify to call remap function

**Validation**:
- LSP remaps work on attach
- Buffer-local bindings apply correctly
- Telescope conditional works

---

### Step 16: Testing and Validation

**Objective**: Verify all remaps work as expected

**Test Checklist**:

1. **Global Remaps**:
   - [ ] `<C-d>`, `<C-u>` scroll and center
   - [ ] `n`, `N` search and center
   - [ ] `<Esc>` clears search highlight
   - [ ] `<leader><leader>[`, `]`, `l`, `d`, `o` buffer management
   - [ ] `j`, `k` word wrap navigation
   - [ ] `[d`, `]d` diagnostic navigation
   - [ ] `<leader>e` open diagnostic float
   - [ ] `<leader>q` open diagnostic list
   - [ ] `<leader>y`, `Y`, `p`, `P` clipboard operations
   - [ ] `<C-p>` paste in insert mode
   - [ ] `<leader>P` paste over selection
   - [ ] `<leader><C-a>` select all

2. **Plugin Remaps**:
   - [ ] `-` opens Oil parent directory
   - [ ] `<leader>-` opens Oil nvim root
   - [ ] `<leader>u` toggles undotree
   - [ ] `<leader>mp`, `ms`, `mt` markdown preview (if enabled)
   - [ ] `<Esc>` dismisses notify popup
   - [ ] `<M-n>` cycles luasnip choices

3. **Telescope/Search** (if nosnacks enabled):
   - [ ] `<leader>sf` find files
   - [ ] `<leader>sg` live grep
   - [ ] `<leader>sw` grep word
   - [ ] `<leader>sh` help tags
   - [ ] `<leader>sk` keymaps
   - [ ] `<leader>sd` diagnostics
   - [ ] `<leader>sr` resume
   - [ ] `<leader>s.` oldfiles
   - [ ] `<leader><leader>s` buffers
   - [ ] `<leader>/` fuzzy find in buffer
   - [ ] `<leader>s/` grep in open files
   - [ ] `<leader>sp` grep git root (uses telescope_helpers)
   - [ ] `<leader>sM` search messages

4. **LSP Remaps** (when LSP attached):
   - [ ] `gd` goto definition
   - [ ] `gD` goto declaration
   - [ ] `gr` goto references (telescope)
   - [ ] `gI` goto implementation (telescope)
   - [ ] `K` hover documentation
   - [ ] `<C-k>` signature help
   - [ ] `<leader>D` type definition
   - [ ] `<leader>rn` rename
   - [ ] `<leader>ca` code action
   - [ ] `<leader>ds` document symbols (telescope)
   - [ ] `<leader>ws` workspace symbols (telescope)
   - [ ] `<leader>wa` workspace add folder
   - [ ] `<leader>wr` workspace remove folder
   - [ ] `<leader>wl` workspace list folders
   - [ ] `<leader>fF` format buffer

5. **Gitsigns Remaps** (in git repository):
   - [ ] `]c` next hunk
   - [ ] `[c` previous hunk
   - [ ] `<leader>gs` stage hunk
   - [ ] `<leader>gr` reset hunk
   - [ ] `<leader>gS` stage buffer
   - [ ] `<leader>gR` reset buffer
   - [ ] `<leader>gu` undo stage
   - [ ] `<leader>gp` preview hunk
   - [ ] `<leader>gb` blame line
   - [ ] `<leader>gd` diff index
   - [ ] `<leader>gD` diff last commit
   - [ ] `<leader>gtb` toggle blame
   - [ ] `<leader>gtd` toggle deleted
   - [ ] `ih` text object (in visual/operator)

6. **Treesitter Remaps**:
   - [ ] `<C-space>` incremental selection
   - [ ] `<M-space>` decremental selection
   - [ ] `aa`, `ia` parameter text objects
   - [ ] `af`, `if` function text objects
   - [ ] `ac`, `ic` class text objects
   - [ ] `]m`, `[m` function navigation
   - [ ] `]]`, `[[` class navigation
   - [ ] `<leader>a`, `<leader>A` swap parameters

7. **Mini.move Remaps** (if mini enabled):
   - [ ] `H`, `L`, `J`, `K` in visual mode
   - [ ] `<M-h>`, `<M-l>`, `<M-j>`, `<M-k>` in normal mode

8. **Which-Key Integration**:
   - [ ] Press `<leader>` and wait - popup shows groups
   - [ ] Press `<leader>s` - shows search group
   - [ ] Press `<leader>g` - shows git group
   - [ ] Press `<leader>c` - shows code group
   - [ ] `:Telescope keymaps` shows all remaps
   - [ ] All descriptions are clear and helpful

9. **Lazy Loading**:
   - [ ] Telescope loads on first `<leader>s` key
   - [ ] Undotree loads on `<leader>u`
   - [ ] Markdown preview loads on `<leader>m` keys
   - [ ] Oil loads immediately (lazy = false)

10. **Conditional Loading & Helper Module**:
    - [ ] Verify telescope keys only when nosnacks enabled
    - [ ] Verify mini.move keys only when mini enabled
    - [ ] Verify markdown keys only when markdown category enabled
    - [ ] All remaps documented even when not using nixCats (default = true)
    - [ ] telescope_helpers module works correctly
    - [ ] LiveGrepGitRoot command uses shared helper

---

## Rollback Plan

If issues occur during migration:

1. **Immediate Rollback**:
   - Revert all files using git: `git checkout HEAD -- lua/myLuaConf/`
   - Restart Neovim

2. **Partial Rollback** (if specific step fails):
   - Identify failing step from test checklist
   - Revert only files modified in that step
   - Skip that step and continue with others

3. **Debug Mode**:
   - Add debug prints to remap.lua functions
   - Check `:messages` for errors
   - Verify which-key registration: `:WhichKey`
   - Check keymaps: `:Telescope keymaps`

---

## Success Criteria

Migration is successful when:

1. ✅ All remaps work exactly as before
2. ✅ Which-key shows all bindings with descriptions
3. ✅ Lazy loading still works (plugins load on keypress)
4. ✅ No Lua errors on startup
5. ✅ `:Telescope keymaps` shows all remaps
6. ✅ Buffer-local bindings (LSP, gitsigns) apply correctly
7. ✅ All plugin features work unchanged
8. ✅ Single source of truth in remap.lua
9. ✅ All remaps documented even outside nixCats (using `catUtils.enableForCategory()` with default `true`)
10. ✅ telescope_helpers module provides shared functionality
11. ✅ setup_which_key_remaps() only documents, does NOT re-run remaps

---

## Notes and Considerations

### Plugin-specific Keybinding Configs

These keybindings are configured within plugin setup via functions that RETURN the config:

1. **Oil.nvim internal keymaps**
   - `M.get_oil_keymaps()` returns config for `require("oil").setup({ keymaps = {...} })`
   - These define behavior within oil buffers
   - Documented in which-key for reference

2. **Treesitter text objects**
   - `M.get_treesitter_keymaps()` returns config for treesitter setup
   - Plugin requires specific format
   - Documented in which-key for reference

3. **Mini.move mappings**
   - `M.get_mini_move_mappings()` returns config for mini.move setup
   - Plugin requires specific format
   - Documented in which-key for reference

4. **Blink.cmp keymap preset** (completion.lua line 50)
   - Configured in `require("blink.cmp").setup({ keymap = { preset = 'default' } })`
   - Uses preset, not individual mappings
   - Internal to completion engine

### Helper Functions

**Telescope helper functions** are externalized to `lua/myLuaConf/telescope_helpers.lua`:
- `find_git_root()` - Finds git repository root
- `live_grep_git_root()` - Live grep in git root directory

This module is shared between:
- `telescope.lua` - For the LiveGrepGitRoot command
- `remap.lua` - For the `<leader>sp` keymap in lze_keys

### Special Handling

1. **Notify <Esc> binding**: Must check if notify is loaded before registering
2. **Telescope conditional**: Only register when `not nixCats("snacks") and nixCats("nosnacks")`
3. **LSP telescope bindings**: Only register when using `catUtils.enableForCategory("general.telescope", true)`
4. **catUtils.enableForCategory**: Always use default value `true` to ensure documentation is complete even outside nixCats
5. **setup_which_key_remaps()**: This function ONLY documents remaps, it does NOT set/run them. Global remaps are already set by `setup_global_remaps()` before this function is called.

### Benefits of Final Structure

1. **Single Source of Truth**: All remaps visible in remap.lua
2. **Discoverability**: Which-key shows all bindings with descriptions
3. **Maintainability**: Easy to see all remaps at once
4. **Documentation**: Descriptions co-located with bindings
5. **Lazy Loading**: Preserved via lze_keys table
6. **Modularity**: Clear separation of concerns (global, LSP, plugins)
7. **Testability**: Easy to verify all remaps work
8. **nixCats Optional**: Works with or without nixCats (default = true)
9. **Code Reuse**: Shared telescope helpers avoid duplication
10. **Clear Separation**: setup_global_remaps() sets, setup_which_key_remaps() documents

---

## Timeline Estimate

- **Step 1-2**: 20 minutes (restructure remap.lua, create telescope_helpers)
- **Step 3**: 15 minutes (populate lze_keys)
- **Step 4-7**: 45 minutes (implement functions)
- **Step 8-15**: 45 minutes (update plugin files)
- **Step 16**: 30 minutes (testing and validation)

**Total**: ~2.5 hours for careful implementation and testing

---

## Post-Migration Tasks

After successful migration:

1. Update documentation (README.md) with new structure
2. Add comments in remap.lua explaining each section
3. Document the telescope_helpers module
4. Consider creating similar centralization for:
   - Autocommands
   - User commands
   - Abbreviations
5. Document the pattern for future plugin additions

---

## Appendix: File Change Summary

### Files to be Created

1. **lua/myLuaConf/telescope_helpers.lua** (NEW)
   - Extract telescope helper functions
   - Provides shared functionality for telescope operations

### Files to be Modified

1. **lua/myLuaConf/remap.lua**
   - Restructure to module format
   - Add lze_keys table (uses telescope_helpers for git root search)
   - Add setup_which_key_remaps() (documents global remaps + plugin remaps, does NOT re-run them)
   - Add setup_lsp_remaps()
   - Add setup_gitsigns_remaps()
   - Add get_oil_keymaps()
   - Add get_treesitter_keymaps()
   - Add get_mini_move_mappings()

2. **lua/myLuaConf/init.lua**
   - Remove remap loading (2 lines deleted)

3. **lua/myLuaConf/plugins/init.lua**
   - Remove notify keymap (3 lines)
   - Update markdown-preview spec (use lze_keys)
   - Update undotree spec (use lze_keys)
   - Update gitsigns spec (call remap function)
   - Update which-key spec (call setup_global_remaps() then setup_which_key_remaps() for documentation only)
   - Move notify setup after require

4. **lua/myLuaConf/plugins/telescope.lua**
   - Update keys spec (use lze_keys)
   - Reference telescope_helpers module instead of local functions
   - Update LiveGrepGitRoot command to use telescope_helpers

5. **lua/myLuaConf/plugins/oil.lua**
   - Remove keymap lines
   - Add keys spec (use lze_keys)
   - Update setup to use get_oil_keymaps()

6. **lua/myLuaConf/plugins/completion.lua**
   - Remove luasnip keymap (5 lines)

7. **lua/myLuaConf/plugins/treesitter.lua**
   - Update setup to use get_treesitter_keymaps()

8. **lua/myLuaConf/plugins/mini.lua**
   - Update setup to use get_mini_move_mappings()

9. **lua/myLuaConf/LSPs/on_attach.lua**
   - Replace entire function body (call remap function)

### Files NOT Modified

- lua/myLuaConf/plugins/snacks.lua (no keymaps)
- lua/myLuaConf/plugins/motions.lua (TODO file, no content)
- All other files in lua/myLuaConf/

---

End of Plan
