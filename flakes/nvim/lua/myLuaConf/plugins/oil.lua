-- Oil.nvim is a buffer-based file explorer for Neovim.
-- It's more "vimmy" than netrw.

local keymap = require("myLuaConf.keymap")

return {
  {
    "oil.nvim",
    for_cat = "general.extra",
    lazy = false,
    keys = keymap.oil_lze_keys(),
    before = function()
      vim.g.loaded_netrwPlugin = 1
    end,
    after = function()
      require("oil").setup({
        default_file_explorer = true,
        view_options = {
          show_hidden = true,
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        columns = {
          "icon",
          "permissions",
          "size",
          "mtime",
        },
        keymaps = keymap.get_oil_keymaps(),
      })
    end,
  },
}
