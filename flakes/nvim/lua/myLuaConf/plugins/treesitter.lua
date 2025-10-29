-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`

local remap = require("myLuaConf.remap")

return {
  {
    "nvim-treesitter",
    for_cat = 'general.treesitter',
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    load = function (name)
        vim.cmd.packadd(name)
        vim.cmd.packadd("nvim-treesitter-textobjects")
    end,
    after = function (plugin)
      -- [[ Configure Treesitter ]]
      -- See `:help nvim-treesitter`
      local treesitter_keymaps = remap.get_treesitter_keymaps()
      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = false, },
        incremental_selection = treesitter_keymaps.incremental_selection,
        textobjects = treesitter_keymaps.textobjects,
      }
    end,
  },
}
