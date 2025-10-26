require("lze").load({
  {
    "conform.nvim",
    -- cmd = { "" },
    -- event = "",
    -- ft = "",
    keys = {
      { "<leader>ff", desc = "[F]ormat [F]ile" },
    },
    after = function(plugin)
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          -- NOTE: download some formatters in lspsAndRuntimeDeps
          -- and configure them here
          lua = { "stylua" },
          -- go = { "gofmt", "golint" },
          -- templ = { "templ" },
          -- Conform will run multiple formatters sequentially
          -- python = { "isort", "black" },
          -- Use a sub-list to run only the first available formatter
          -- javascript = { { "prettierd", "prettier" } },
        },
      })

      -- Create a command `:Format` local to the LSP buffer
      vim.api.nvim_create_user_command("Format", function(_)
        conform.format({
          async = false,
          timeout_ms = 3000,
        })
      end, { desc = "Format current buffer with Conform" })
      vim.keymap.set({ "n", "v" }, "<leader>ff", function()
        conform.format({
          async = false,
          timeout_ms = 3000,
        })
      end, { desc = "[F]ormat [F]ile with Conform" })
    end,
  },
})
