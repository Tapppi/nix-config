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
      local keymaps = keymap.get_mini_ai_keymaps()
      require("mini.ai").setup({
        custom_textobjects = keymaps.custom_textobjects,
        mappings = keymaps.mappings,
      })

      require("mini.pairs").setup()
      require("mini.surround").setup()
      require("mini.move").setup({
        mappings = keymap.get_mini_move_mappings(),
      })

      -- Markdown-specific mini.ai configuration
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          local keymaps = keymap.get_mini_ai_keymaps()
          vim.b.miniai_config = {
            custom_textobjects = vim.tbl_extend("force", keymaps.custom_textobjects, keymaps.markdown_textobjects),
          }
        end,
        desc = "Setup mini.ai markdown textobjects",
      })
    end,
  },
}
