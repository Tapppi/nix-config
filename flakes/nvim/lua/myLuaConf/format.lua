---@param bufnr integer
---@param ... string
---@return string
local function first(bufnr, ...)
  local conform = require("conform")
  for i = 1, select("#", ...) do
    local formatter = select(i, ...)
    if conform.get_formatter_info(formatter, bufnr).available then
      return formatter
    end
  end
  return select(1, ...)
end

require("lze").load({
  {
    "conform.nvim",
    cmd = { "Format" },
    keys = {
      { "<leader>ff", "<cmd>Format<cr>", desc = "[F]ormat [F]ile", mode = "n" },
      { "<leader>f", "<cmd>Format<cr>", desc = "[F]ormat selection", mode = "v" },
    },
    after = function(_)
      local conform = require("conform")

      conform.setup({
        default_format_opts = {
          lsp_format = "fallback",
          timeout_ms = 2000,
          async = false,
        },
        formatters_by_ft = {
          -- NOTE: download some formatters in lspsAndRuntimeDeps
          -- and configure them here
          lua = { "stylua" },
          gleam = { "gleam" },
          markdown = function(bufnr)
            return { first(bufnr, "prettierd", "prettier"), "injected" }
          end,
          -- go = { "gofmt", "golint" },
          -- templ = { "templ" },
          -- Conform will run multiple formatters sequentially
          -- python = { "isort", "black" },
          -- Use a sub-list to run only the first available formatter
          -- javascript = { { "prettierd", "prettier" } },
        },
      })

      -- Create a command `:Format` local to the LSP buffer
      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        conform.format({ range = range }, function(err)
          if not err then
            local mode = vim.api.nvim_get_mode().mode
            if vim.startswith(string.lower(mode), "v") then
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
            end
          end
        end)
      end, { desc = "Format selection or current buffer with Conform", range = true })
    end,
  },
})
