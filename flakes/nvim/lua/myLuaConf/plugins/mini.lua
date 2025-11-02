-- mini.nvim is a collection of plugins that replaces many basic plugins with
-- a coherent set of that work well together. It's from echasnovski, and together
-- with snacks is a good base without using a distro.

-- See the nomini category in flake.nix and in configs for everything mini replaces in my config.

local keymap = require("myLuaConf.keymap")

return {
  {
    "mini.nvim",
    for_cat = "mini",
    event = "DeferredUIEnter",
    after = function()
      require("mini.surround").setup()
      require("mini.pairs").setup()
      require("mini.move").setup({
        mappings = keymap.get_mini_move_mappings(),
      })
    end
  },
}

