-- mini.nvim is a collection of plugins that replaces many basic plugins with
-- a coherent set of that work well together. It's from echasnovski, and together
-- with snacks is a good base without using a distro.

-- See the nomini category in flake.nvim for everything mini replaces in my config.

return {
  {
    "mini.nvim",
    for_cat = "mini",
    event = "DeferredUIEnter",
    after = function()
      require("mini.surround").setup()
      require("mini.pairs").setup()
      require("mini.move").setup(
        {
          mappings = {
            left = "H",
            right = "L",
            down = "J",
            up = "K",

            line_left = "<M-h>",
            line_right = "<M-l>",
            line_up = "<M-j>",
            line_down = "<M-k>",
          }
        }
      )
    end
  },
}

