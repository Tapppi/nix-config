-- Load remap module early
local remap = require("myLuaConf.remap")

local ok, notify = pcall(require, "notify")
if ok then
  notify.setup({
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { focusable = false })
    end,
  })
  vim.notify = notify
  remap.setup_esc_keymap(notify.dismiss)
else
  remap.setup_esc_keymap()
end

require("lze").load({
  -- non-lazy
  { import = "myLuaConf.plugins.oil" },
  {
    "which-key.nvim",
    for_cat = "general.always",
    -- event = "DeferredUIEnter",
    lazy = false,
    after = function()
      require("which-key").setup({})
      -- Setup global remaps first
      remap.setup_global_remaps()
      -- Then document groups and abnormal keymaps with which-key
      remap.setup_which_key_groups()
    end,
  },
  { import = "myLuaConf.plugins.snacks" },
  -- lazy
  { import = "myLuaConf.plugins.mini" },
  { import = "myLuaConf.plugins.telescope" },
  { import = "myLuaConf.plugins.treesitter" },
  { import = "myLuaConf.plugins.completion" },
  {
    "markdown-preview.nvim",
    for_cat = "markdown",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = "markdown",
    keys = remap.markdown_lze_keys(),
    before = function()
      vim.g.mkdp_auto_close = 0
    end,
  },
  {
    "undotree",
    for_cat = "general.always",
    cmd = { "UndotreeToggle", "UndotreeHide", "UndotreeShow", "UndotreeFocus", "UndotreePersistUndo" },
    keys = remap.undotree_lze_keys(),
    before = function()
      vim.g.undotree_WindowLayout = 2
      vim.g.undotree_SplitWidth = 40
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_DisabledFiletypes = { "TelescopePrompt" }
    end,
  },
  {
    "comment.nvim",
    for_cat = "general.extra",
    event = "DeferredUIEnter",
    after = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
  {
    "nvim-ts-context-commentstring",
    for_cat = "general.extra",
    dep_of = "comment.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })
    end,
  },
  {
    "nvim-surround",
    for_cat = "nomini",
    event = "DeferredUIEnter",
    after = function()
      require("nvim-surround").setup()
    end,
  },
  {
    "vim-startuptime",
    for_cat = "general.extra",
    cmd = { "StartupTime" },
    before = function()
      vim.g.startuptime_event_width = 0
      vim.g.startuptime_tries = 10
      vim.g.startuptime_exe_path = nixCats.packageBinPath
    end,
  },
  -- Unintrusive progress notifications, e.g. LSP
  {
    "fidget.nvim",
    for_cat = "general.extra",
    event = "DeferredUIEnter",
    after = function()
      require("fidget").setup({})
    end,
  },
  {
    "lualine.nvim",
    for_cat = "general.always",
    event = "DeferredUIEnter",
    after = function()
      require("lualine").setup({
        options = {
          icons_enabled = false,
          theme = colorschemeName,
          component_separators = "|",
          section_separators = "",
        },
        sections = {
          lualine_c = {
            {
              "filename",
              path = 1,
              status = true,
            },
          },
        },
        inactive_sections = {
          lualine_b = {
            {
              "filename",
              path = 3,
              status = true,
            },
          },
          lualine_x = { "filetype" },
        },
        tabline = {
          lualine_a = { "buffers" },
          lualine_b = { "lsp_progress" },
          lualine_z = { "tabs" },
        },
      })
    end,
  },
  {
    "gitsigns.nvim",
    for_cat = "general.always",
    event = "DeferredUIEnter",
    after = function()
      require("gitsigns").setup({
        -- See `:help gitsigns.txt`
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          remap.setup_gitsigns_keymaps(bufnr)
        end,
      })
      vim.cmd([[hi GitSignsAdd guifg=#04de21]])
      vim.cmd([[hi GitSignsChange guifg=#83fce6]])
      vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
    end,
  },
})
