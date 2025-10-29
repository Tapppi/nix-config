-- Centralized keybinding configuration

local M = {}
local catUtils = require("nixCatsUtils")
local helpers = require("myLuaConf.helpers")

-- ============================================================================
-- Global Remaps
-- ============================================================================

function M.setup_global_remaps()
  vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })
  vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up" })
  vim.keymap.set("n", "n", "nzzzv", { desc = "Next Search Result" })
  vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous Search Result" })

  -- Create a command `:BufOnly` for deleting all but the current buffer
  vim.api.nvim_create_user_command("BufOnly", '%bd|e#|bd#|norm `"', { desc = "Close all other buffers" })

  vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = "Previous buffer" })
  vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = "Next buffer" })
  vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = "Last buffer" })
  vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = "delete buffer" })
  vim.keymap.set("n", "<leader><leader>o", "<cmd>BufOnly<CR>", { desc = "Close all other buffers" })

  -- Remap for dealing with word wrap
  vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
  vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

  -- Diagnostic keymaps
  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
  vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

  -- Copy to/from clipboard
  -- In order to not clobber system-wide clipboard, easy-to-use keymaps instead of
  -- vim.o.clipboard = 'unnamedplus'
  vim.keymap.set({ "v", "x", "n" }, "<leader>y", '"+y', { noremap = true, silent = true, desc = "Yank to clipboard" })
  vim.keymap.set(
    { "n", "v", "x" },
    "<leader>Y",
    '"+yy',
    { noremap = true, silent = true, desc = "Yank line to clipboard" }
  )
  vim.keymap.set(
    { "n", "v", "x" },
    "<leader>p",
    '"+p',
    { noremap = true, silent = true, desc = "Paste from clipboard" }
  )
  vim.keymap.set(
    "i",
    "<C-p>",
    "<C-r><C-p>+",
    { noremap = true, silent = true, desc = "Paste from clipboard from within insert mode" }
  )

  -- Better "paste over selection" and "select all"
  vim.keymap.set("x", "<leader>P", '"_dP', {
    noremap = true,
    silent = true,
    desc = "Paste over selection without erasing unnamed register",
  })
  vim.keymap.set({ "n", "v", "x" }, "<leader><C-a>", "gg0vG$", { noremap = true, silent = true, desc = "Select all" })

  -- Move lines
  -- This is replaced by mini.move
  if not catUtils.enableForCategory("mini", true) and catUtils.enableForCategory("nomini", false) then
    vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
    vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })
  end

  -- File operations
  vim.keymap.set("n", "<leader>fw", "<cmd>w<CR>", { desc = "Write file" })
  vim.keymap.set("n", "<leader>fW", "<cmd>w!<CR>", { desc = "Force write file" })
end

-- Sets <Esc> to dismiss notify (if provided) and clear search highlighting
function M.setup_esc_keymap(notify_dismiss_fn)
  if notify_dismiss_fn then
    vim.keymap.set("n", "<Esc>", function()
      notify_dismiss_fn({ silent = true })
      vim.cmd("nohlsearch")
    end, { desc = "Dismiss notify popup and clear search highlight", silent = true })
  else
    vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight", silent = true })
  end
end

-- ============================================================================
-- Which-Key Setup for groups
-- ============================================================================

function M.setup_which_key_groups()
  local wk = require("which-key")

  wk.add({
    { "<leader><leader>", group = "buffer commands" },
    { "<leader><leader>_", hidden = true },
    { "<leader>c", group = "[c]ode" },
    { "<leader>c_", hidden = true },
    { "<leader>d", group = "[d]ocument" },
    { "<leader>d_", hidden = true },
    { "<leader>f", group = "[f]ile" },
    { "<leader>f_", hidden = true },
    { "<leader>g", group = "[g]it" },
    { "<leader>g_", hidden = true },
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

-- ============================================================================
-- LSP Keymaps (buffer-local)
-- ============================================================================

function M.setup_lsp_keymaps(_, bufnr)
  local nmap = function(keys, func, desc)
    if desc then
      desc = "LSP: " .. desc
    end
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end

  nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")

  -- Telescope-based keymaps (conditional on telescope category)
  if nixCats("general.telescope") then
    nmap("gr", function()
      require("telescope.builtin").lsp_references()
    end, "[G]oto [R]eferences")
    nmap("gI", function()
      require("telescope.builtin").lsp_implementations()
    end, "[G]oto [I]mplementation")
    nmap("<leader>ds", function()
      require("telescope.builtin").lsp_document_symbols()
    end, "[D]ocument [S]ymbols")
    nmap("<leader>ws", function()
      require("telescope.builtin").lsp_dynamic_workspace_symbols()
    end, "[W]orkspace [S]ymbols")
  end

  nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")

  -- See `:help K` for why this keymap
  nmap("K", vim.lsp.buf.hover, "Hover Documentation")
  nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

  -- Lesser used LSP functionality
  nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
  nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
  nmap("<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, "[W]orkspace [L]ist Folders")

  -- Create a command `:LSPFormat` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, "LSPFormat", function(_)
    vim.lsp.buf.format()
  end, { desc = "Format current buffer with LSP" })
  nmap("<leader>fF", vim.lsp.buf.format, "Format current buffer with LSP")
end

-- ============================================================================
-- Plugin-Specific Keymaps
-- ============================================================================

-- Luasnip keymaps
function M.setup_luasnip_keymaps(ls)
  vim.keymap.set({ "i", "s" }, "<M-n>", function()
    if ls.choice_active() then
      ls.change_choice(1)
    end
  end)
end

-- Gitsigns buffer-local keymaps
function M.setup_gitsigns_keymaps(bufnr)
  local gs = package.loaded.gitsigns

  local function map(mode, l, r, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
  end

  -- Navigation
  map({ "n", "v" }, "]c", function()
    if vim.wo.diff then
      return "]c"
    end
    vim.schedule(function()
      gs.next_hunk()
    end)
    return "<Ignore>"
  end, { expr = true, desc = "Jump to next hunk" })

  map({ "n", "v" }, "[c", function()
    if vim.wo.diff then
      return "[c"
    end
    vim.schedule(function()
      gs.prev_hunk()
    end)
    return "<Ignore>"
  end, { expr = true, desc = "Jump to previous hunk" })

  -- Actions
  -- visual mode
  map("v", "<leader>gs", function()
    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, { desc = "stage git hunk" })
  map("v", "<leader>gr", function()
    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, { desc = "reset git hunk" })
  -- normal mode
  map("n", "<leader>gs", gs.stage_hunk, { desc = "git stage hunk" })
  map("n", "<leader>gr", gs.reset_hunk, { desc = "git reset hunk" })
  map("n", "<leader>gS", gs.stage_buffer, { desc = "git Stage buffer" })
  map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "undo stage hunk" })
  map("n", "<leader>gR", gs.reset_buffer, { desc = "git Reset buffer" })
  map("n", "<leader>gp", gs.preview_hunk, { desc = "preview git hunk" })
  map("n", "<leader>gb", function()
    gs.blame_line({ full = false })
  end, { desc = "git blame line" })
  map("n", "<leader>gd", gs.diffthis, { desc = "git diff against index" })
  map("n", "<leader>gD", function()
    gs.diffthis("~")
  end, { desc = "git diff against last commit" })

  -- Toggles
  map("n", "<leader>gtb", gs.toggle_current_line_blame, { desc = "toggle git blame line" })
  map("n", "<leader>gtd", gs.toggle_deleted, { desc = "toggle git show deleted" })

  -- Text object
  map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "select git hunk" })
end

-- Telescope lze keys (for lazy loading)
function M.telescope_lze_keys()
  return {
    { "<leader>sM", "<cmd>Telescope notify<CR>", mode = { "n" }, desc = "[S]earch [M]essage" },
    { "<leader>sp", helpers.telescope_live_grep_git_root, mode = { "n" }, desc = "[S]earch git [P]roject root" },
    {
      "<leader>/",
      function()
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end,
      mode = { "n" },
      desc = "[/] Fuzzily search in current buffer",
    },
    {
      "<leader>s/",
      function()
        require("telescope.builtin").live_grep({
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        })
      end,
      mode = { "n" },
      desc = "[S]earch [/] in Open Files",
    },
    {
      "<leader><leader>s",
      function()
        return require("telescope.builtin").buffers()
      end,
      mode = { "n" },
      desc = "[ ] Find existing buffers",
    },
    {
      "<leader>s.",
      function()
        return require("telescope.builtin").oldfiles()
      end,
      mode = { "n" },
      desc = '[S]earch Recent Files ("." for repeat)',
    },
    {
      "<leader>sr",
      function()
        return require("telescope.builtin").resume()
      end,
      mode = { "n" },
      desc = "[S]earch [R]esume",
    },
    {
      "<leader>sd",
      function()
        return require("telescope.builtin").diagnostics()
      end,
      mode = { "n" },
      desc = "[S]earch [D]iagnostics",
    },
    {
      "<leader>sg",
      function()
        return require("telescope.builtin").live_grep()
      end,
      mode = { "n" },
      desc = "[S]earch by [G]rep",
    },
    {
      "<leader>sw",
      function()
        return require("telescope.builtin").grep_string()
      end,
      mode = { "n" },
      desc = "[S]earch current [W]ord",
    },
    {
      "<leader>ss",
      function()
        return require("telescope.builtin").builtin()
      end,
      mode = { "n" },
      desc = "[S]earch [S]elect Telescope",
    },
    {
      "<leader>sf",
      function()
        return require("telescope.builtin").find_files()
      end,
      mode = { "n" },
      desc = "[S]earch [F]iles",
    },
    {
      "<leader>sk",
      function()
        return require("telescope.builtin").keymaps()
      end,
      mode = { "n" },
      desc = "[S]earch [K]eymaps",
    },
    {
      "<leader>sh",
      function()
        return require("telescope.builtin").help_tags()
      end,
      mode = { "n" },
      desc = "[S]earch [H]elp",
    },
  }
end

-- Returns oil internal keymaps config
function M.get_oil_keymaps()
  return {
    ["g?"] = "actions.show_help",
    ["<CR>"] = "actions.select",
    ["<C-s>"] = "actions.select_vsplit",
    ["<C-h>"] = "actions.select_split",
    ["<C-t>"] = "actions.select_tab",
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = "actions.close",
    ["<C-l>"] = "actions.refresh",
    ["-"] = "actions.parent",
    ["_"] = "actions.open_cwd",
    ["`"] = "actions.cd",
    ["~"] = "actions.tcd",
    ["gs"] = "actions.change_sort",
    ["gx"] = "actions.open_external",
    ["g."] = "actions.toggle_hidden",
    ["g\\"] = "actions.toggle_trash",
  }
end

-- Oil lze keys (for lazy loading)
function M.oil_lze_keys()
  return {
    { "-", "<cmd>Oil<CR>", mode = "n", hidden = true, desc = "Open Parent Directory" },
    { "<leader>-", "<cmd>Oil .<CR>", mode = "n", hidden = true, desc = "Open nvim root directory" },
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

-- Returns treesitter keymaps config
function M.get_treesitter_keymaps()
  return {
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<c-space>",
        node_incremental = "<c-space>",
        scope_incremental = "<c-s>",
        node_decremental = "<M-space>",
      },
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

-- Returns mini.move mappings config
function M.get_mini_move_mappings()
  return {
    left = "H",
    right = "L",
    down = "J",
    up = "K",
    line_left = "<M-h>",
    line_right = "<M-l>",
    line_down = "<M-k>",
    line_up = "<M-j>",
  }
end

return M
