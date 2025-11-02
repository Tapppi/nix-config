local catUtils = require("nixCatsUtils")
local remap = require("myLuaConf.keymap")

if catUtils.enableForCategory("lspDebugMode", false) then
  vim.lsp.set_log_level("debug")
end

-- NOTE: This file uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- This is a slightly more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- nixCats gives us the paths, which is faster than searching the rtp!
local old_ft_fallback = require("lze").h.lsp.get_ft_fallback()
require("lze").h.lsp.set_ft_fallback(function(name)
  local lspcfg = nixCats.pawsible({ "allPlugins", "opt", "nvim-lspconfig" }) or
      nixCats.pawsible({ "allPlugins", "start", "nvim-lspconfig" })
  if lspcfg then
    local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
    if not ok then
      ok, cfg = pcall(dofile, lspcfg .. "/lua/lspconfig/configs/" .. name .. ".lua")
    end
    return (ok and cfg or {}).filetypes or {}
  else
    return old_ft_fallback(name)
  end
end)

require("lze").load {
  {
    "nvim-lspconfig",
    for_cat = "general.always",
    on_require = { "lspconfig" },
    -- NOTE: define a function for lsp,
    -- and it will run for all specs with type(plugin.lsp) == table
    -- when their filetype trigger loads them
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    before = function(_)
      vim.lsp.config("*", {
        on_attach = remap.setup_lsp_keymaps,
      })
    end,
  },
  {
    "mason.nvim",
    -- only run it when not on nix
    enabled = not catUtils.isNixCats,
    on_plugin = { "nvim-lspconfig" },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd("mason-lspconfig.nvim")
      require("mason").setup()
      -- auto install will make it install servers when lspconfig is called on them.
      require("mason-lspconfig").setup { automatic_installation = true, }
    end,
  },
  {
    -- lazydev makes your neovim config lsp better without extra lsp configuration.
    "lazydev.nvim",
    for_cat = "neonixdev",
    cmd = { "LazyDev" },
    ft = "lua",
    after = function(_)
      require("lazydev").setup({
        library = {
          { words = { "nixCats" }, path = (nixCats.nixCatsPath or "") .. "/lua" },
          -- Load the wezterm types when the `wezterm` module is required
          -- Needs `justinsgithub/wezterm-types` to be installed
          {
            -- words = { "wezterm" },
            path = "wezterm-types",
            mods = { "wezterm" },
          },
        },
      })
    end,
  },
  {
    -- name of the lsp
    "lua_ls",
    enabled = nixCats("lua") or nixCats("neonixdev") or false,
    -- provide a table containing filetypes,
    -- and then whatever your functions defined in the function type specs expect.
    -- in our case, it just expects the normal lspconfig setup options,
    -- but with a default on_attach and capabilities
    lsp = {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          formatters = {
            ignoreComments = true,
          },
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { "nixCats", "vim", },
            disable = { "missing-fields" },
          },
          telemetry = { enabled = false },
        },
      },
    },
    -- also these are regular specs and you can use before and after and all the other normal fields
  },
  {
    "bash-language-server",
    enabled = catUtils.enableForCategory("bash", false),
    lsp = {
      -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
      filetypes = { "bash", "sh", "zsh" },
    },
  },
  {
    "gopls",
    for_cat = "go",
    -- if you don't provide the filetypes it asks lspconfig for them
    lsp = {},
  },
  -- NOTE: handled by rustaceanvim
  -- {
  --   "rust-analyzer",
  --   for_cat = "rust",
  --   lsp = {},
  -- },
  {
    "zls",
    for_cat = "zig",
    lsp = {},
  },
  {
    "typescript-tools.nvim",
    for_cat = "typescript",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    ft = { "javascriptreact", "typescriptreact", "javascript", "typescript" },
    after = function (_)
      require("typescript-tools").setup {
        expose_as_code_action = "all",
        jsx_close_tag = {
          enable = true
        },
      }
    end,
  },
  {
    "rnix",
    -- mason doesn't have nixd
    enabled = not catUtils.isNixCats,
    lsp = {},
  },
  {
    "nil_ls",
    -- mason doesn't have nixd
    enabled = not catUtils.isNixCats,
    lsp = {},
  },
  {
    "nixd",
    enabled = catUtils.enableForCategory("neonixdev", false),
    lsp = {
      settings = {
        nixd = {
          -- nixd requires some configuration, we pass it through the 'extra' field in our packageDefinitions
          -- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
          nixpkgs = {
            expr = nixCats.extra("nixdExtras.nixpkgs") or 'import <nixpkgs> {}',
          },
          options = {
            -- If you integrated with your system flake, you should use inputs.self as the path to your system flake
            -- that way it will ALWAYS work, regardless of where your config actually was.
            nixos = {
              -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options''
              expr = nixCats.extra("nixdExtras.nixos_options")
            },
            -- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
            -- You can override the correct one into your package definition on import in your main configuration,
            -- or just put an absolute path to where it usually is and accept the impurity.
            ["home-manager"] = {
              -- nixdExtras.home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options''
              expr = nixCats.extra("nixdExtras.home_manager_options")
            }
          },
          formatting = {
            command = { "nixfmt" }
          },
          diagnostic = {
            suppress = {
              "sema-escaping-with"
            }
          }
        }
      },
    },
  },
}
