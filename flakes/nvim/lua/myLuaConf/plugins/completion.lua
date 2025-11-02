local keymap = require("myLuaConf.keymap")

local load_w_after = function(name)
  vim.cmd.packadd(name)
  vim.cmd.packadd(name .. '/after')
end

return {
  {
    "cmp-cmdline",
    for_cat = "general.blink",
    on_plugin = { "blink.cmp" },
    load = load_w_after,
  },
  {
    "blink.compat",
    for_cat = "general.blink",
    dep_of = { "cmp-cmdline" },
  },
  {
    "luasnip",
    for_cat = "general.blink",
    dep_of = { "blink.cmp" },
    after = function(_)
      local ls = require 'luasnip'
      require('luasnip.loaders.from_vscode').lazy_load()
      ls.config.setup {}

      keymap.setup_luasnip_keymaps(ls)
    end,
  },
  {
    "colorful-menu.nvim",
    for_cat = "general.blink",
    on_plugin = { "blink.cmp" },
  },
  {
    "blink.cmp",
    for_cat = "general.blink",
    event = "DeferredUIEnter",
    after = function(_)
      require("blink.cmp").setup({
        -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
        -- See :h blink-cmp-config-keymap for configuring keymaps
        keymap = {
          preset = 'default',
        },
        cmdline = {
          enabled = true,
          completion = {
            menu = {
              auto_show = true,
            },
          },
          ---@diagnostic disable-next-line: assign-type-mismatch
          sources = function()
            local type = vim.fn.getcmdtype()
            -- Search forward and backward
            if type == '/' or type == '?' then return { 'buffer' } end
            -- Commands
            if type == ':' or type == '@' then return { 'cmdline', 'cmp_cmdline' } end
            return {}
          end,
        },
        fuzzy = {
          -- See the docs for control of how prebuilt binaries are installed
          implementation = 'prefer_rust_with_warning',
          sorts = {
            'exact',
            -- defaults
            'score',
            'sort_text',
          },
        },
        signature = {
          enabled = true,
          window = {
            show_documentation = true,
          },
        },
        completion = {
          menu = {
            scrolloff = 2,
            min_width = 10,
            max_height = 10,
            winblend = 15,
            draw = {
              -- We don't need label_description now because label and label_description are already
              -- combined together in label by colorful-menu.nvim.
              -- TODO: fix { "kind_icon" }, test label_description with lang where it matters
              columns = { { "kind" }, { "label" , gap = 1 }, { "source_name" }, },
              components = {
                label = {
                  text = function(ctx)
                    return require("colorful-menu").blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end,
                },
              },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            window = {
              min_width = 15,
              max_height = 20,
              max_width = 65,
              winblend = 15,
            }
          },
        },
        snippets = {
          preset = 'luasnip',
        },
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer', 'omni' },
          per_filetype = {
            lua = { 'lsp', 'path', 'snippets', 'buffer', 'omni', 'lazydev' },
          },
          providers = {
            path = {
              score_offset = 50,
            },
            lsp = {
              score_offset = 40,
            },
            snippets = {
              score_offset = 40,
            },
            cmp_cmdline = {
              name = 'cmp_cmdline',
              module = 'blink.compat.source',
              score_offset = -100,
              opts = {
                cmp_name = 'cmdline',
              },
            },
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              score_offset = 100,
              enabled = nixCats('neonixdev'),
            },
          },
        },
      })
    end,
  },
}

