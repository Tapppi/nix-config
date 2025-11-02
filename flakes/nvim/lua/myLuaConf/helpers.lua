-- lua/myLuaConf/helpers.lua
-- Helper functions for various plugins

local M = {}

-- ============================================================================
-- Git Helpers
-- ============================================================================

function M.find_git_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()

  if current_file == "" then
    current_dir = cwd
  else
    current_dir = vim.fn.fnamemodify(current_file, ":h")
  end

  local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("Not a git repository. Searching on current working directory")
    return cwd
  end
  return git_root
end

-- ============================================================================
-- Telescope Helpers
-- ============================================================================

function M.telescope_live_grep_git_root()
  local git_root = M.find_git_root()
  if git_root then
    require("telescope.builtin").live_grep({
      search_dirs = { git_root },
    })
  end
end

-- ============================================================================
-- Conform Helpers
-- ============================================================================

function M.conform_status()
  local formatters, use_lsp = require("conform").list_formatters_to_run()
  local names = vim.tbl_map(function(formatter)
    return formatter.name
  end, formatters)
  if use_lsp then
    table.insert(names, "LSP")
  end
  return "[" .. table.concat(names, ", ") .. "]"
end

return M
