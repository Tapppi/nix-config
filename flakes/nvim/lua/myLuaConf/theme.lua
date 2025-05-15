local colorschemeName = nixCats("colorscheme")

if not require("nixCatsUtils").isNixCats then
  colorschemeName = "catppuccin-mocha"
end

if string.find(colorschemeName, "^catppuccin") then
  require("catppuccin").setup({
    -- transparent_background = true,
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
      ---@diagnostic disable-next-line: assign-type-mismatch
      gitsigns = {
        enabled = true,
        -- transparent = true,
      },
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
      -- TODO: harpoon = true,
      -- TODO: mini = true,
      -- TODO: snacks = true,
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

vim.cmd.colorscheme(colorschemeName)

require("lze").load {
--  {
--    "rainbow-delimiters.nvim",
--    for_cat = "general.extra",
--    event = "DeferredUIEnter",
--    dep_of = "indent-blankline.nvim",
--  },
  {
    "indent-blankline.nvim",
    for_cat = "general.extra",
    event = "DeferredUIEnter",
    after = function(_)
      -- TODO: use RainbowDelimiter* hl groups and set them to alt theme of catppuccin for better separation
      local highlight = {
        "RainbowRed",
        "RainbowYellow",
        "RainbowBlue",
        "RainbowOrange",
        "RainbowGreen",
        "RainbowViolet",
        "RainbowCyan",
      }
      require("ibl").setup({
        scope = {
          highlight = highlight
        },
      })

      vim.g.rainbow_delimiters = { highlight = highlight }
      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
    end,
  },
}
