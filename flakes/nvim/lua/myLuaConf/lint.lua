require('lze').load {
  {
    "nvim-lint",
    for_cat = 'lint',
    event = "FileType",
    after = function()
      require('lint').linters_by_ft = {
        gitcommit = { 'gitlint' },
        bash = { 'shellcheck' },
        zsh = { 'zsh', 'shellcheck' },
        markdown = { 'markdownlint-cli2' },
        go = { 'golangci-lint' },
        -- javascript = { 'eslint' },
        -- typescript = { 'eslint' },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
