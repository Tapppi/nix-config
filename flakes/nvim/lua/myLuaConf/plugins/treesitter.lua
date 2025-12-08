-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`

local keymap = require("myLuaConf.keymap")

return {
  {
    "nvim-treesitter",
    for_cat = "general.treesitter",
    event = "DeferredUIEnter",
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd("nvim-treesitter-textobjects")
    end,
    after = function()
      -- [[ Configure Treesitter ]]
      -- See `:help nvim-treesitter`
      local treesitter_keymaps = keymap.get_treesitter_keymaps()
      require("nvim-treesitter.configs").setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        incremental_selection = treesitter_keymaps.incremental_selection,
        textobjects = treesitter_keymaps.textobjects,
      })
    end,
  },
}
