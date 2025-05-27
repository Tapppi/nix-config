_G.colorschemeName = nixCats("colorscheme")

if not _G.colorschemeName then
  _G.colorschemeName = "catppuccin-mocha"
end

vim.cmd.colorscheme(colorschemeName)

if string.find(colorschemeName, "^catppuccin") then
  require("catppuccin").setup({
    transparent_background = true,
    dim_inactive = {
      enabled = true,
      shade = "dark",
      percentage = 0.15,
    },
    integrations = {
      blink_cmp = true,
      -- TODO: colorful_winsep = {
      --  enabled = true,
      --  color = "teal",
      --},
      gitsigns = true,
      indent_blankline = {
        enabled = true,
        scope_color = 'sapphire',
        colored_indent_levels = true,
      },
      -- TODO: illuminate = {
      --  enabled = true,
      --  lsp = true,
      --}
      rainbow_delimiters = true,
      -- TODO: trouble = true,
      -- TODO: harpoon = true,
      mini = true,
      snacks = true,
      notifier = true,
      notify = true,
      markdown = true,
      -- TODO: noice = true,
      dap = true,
      dap_ui = true,
      -- TODO: ufo = true,
      which_key = true,


      mason = true,
    }
  })
end

-- Define rainbow delimiters highlight groups, also used for IBL/Snacks.scope
-- The hl groups come from catppuccin rainbow_delimiters integration
vim.g.rainbow_delimiters = {
  highlight = {
    "RainbowDelimiterRed",
    "RainbowDelimiterYellow",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
  },
}

if not nixCats("snacks") and nixCats("nosnacks") then
  -- snacks indent is configured in plugins/snacks.lua
  require("lze").load {
    {
      "indent-blankline.nvim",
      for_cat = "nosnacks",
      event = "DeferredUIEnter",
      after = function(_)
        require("ibl").setup({
          scope = {
            highlight = vim.g.rainbow_delimiters.highlight,
          },
        })

        local hooks = require "ibl.hooks"
        hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
      end,
    },
  }
end
