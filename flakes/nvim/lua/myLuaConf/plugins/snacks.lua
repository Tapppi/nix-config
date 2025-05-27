-- Snacks.nvim is a collection of plugins that replaces many basic plugins with
-- a coherent set of that work well together. It's from folke, and is a good
-- base without using a distro.

-- See the nosnacks category in flake.nvim for everything snacks replaces in
-- my config.

return {
  {
    "snacks.nvim",
    for_cat = "snacks",
    lazy = false,
    after = function()
      require("snacks").setup({
        indent = {
          enabled = true,
          animate = {
            enabled = false,
            easing = "easeOutQuant",
            duration = {
              step = 10,
              total = 300,
            }
          },
          chunk = {
            enabled = true,
            hl = vim.g.rainbow_delimiters.highlight,
            only_current = false,
            char = {
              corner_top = "┌",
              corner_bottom = "└",
              -- Doesn't look smooth in iterm2
              -- corner_top = "╭",
              -- corner_bottom = "╰",
              horizontal = "─",
              vertical = "│",
              arrow = ">",
            },
          },
          scope = {
            enabled = true,
            hl = vim.g.rainbow_delimiters.highlight,
            -- Set to true when not using chunks
            underline = false,
            only_current = false,
            char = "│",
          },
        },
        -- picker = {
        --   enabled = true,
        --   theme = "catppuccin",
        -- },
      })
    end,
  }
}
