-- Functions that define my keymaps, so they are centralised and easy to grok

local catUtils = require("nixCatsUtils")

-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
function Global_remaps()
  vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })
  vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up" })
  vim.keymap.set("n", "n", "nzzzv", { desc = "Next Search Result" })
  vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous Search Result" })

  vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

  -- Create a command `:BufOnly` for deleting all but the current buffer
  vim.api.nvim_create_user_command(
    "BufOnly",
    '%bd|e#|bd#|norm `"',
    { desc = "Close all other buffers" }
  )

  vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = "Previous buffer" })
  vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = "Next buffer" })
  vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = "Last buffer" })
  vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = "delete buffer" })
  vim.keymap.set("n", "<leader><leader>o", "<cmd>BufOnly<CR>", { desc = "Close all other buffers" })

  -- Remap for dealing with word wrap
  vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
  vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

  -- Diagnostic keymaps
  vim.keymap.set(
    "n",
    "[d",
    vim.diagnostic.goto_prev,
    { desc = "Go to previous diagnostic message" }
  )
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
  vim.keymap.set(
    "n",
    "<leader>e",
    vim.diagnostic.open_float,
    { desc = "Open floating diagnostic message" }
  )
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

  -- Copy to/from clipboard
  -- In order to not clobber system-wide clipboard, easy-to-use keymaps instead of
  -- vim.o.clipboard = 'unnamedplus'
  vim.keymap.set(
    { "v", "x", "n" },
    "<leader>y",
    '"+y',
    { noremap = true, silent = true, desc = "Yank to clipboard" }
  )
  vim.keymap.set(
    { "n", "v", "x" },
    "<leader>Y",
    '"+yy',
    { noremap = true, silent = true, desc = "Yank line to clipboard" }
  )
  vim.keymap.set(
    { "n", "v", "x" },
    "<leader>p",
    '"+p',
    { noremap = true, silent = true, desc = "Paste from clipboard" }
  )
  vim.keymap.set(
    "i",
    "<C-p>",
    "<C-r><C-p>+",
    { noremap = true, silent = true, desc = "Paste from clipboard from within insert mode" }
  )

  -- Better "paste over selection" and "select all"
  vim.keymap.set("x", "<leader>P", '"_dP', {
    noremap = true,
    silent = true,
    desc = "Paste over selection without erasing unnamed register",
  })
  vim.keymap.set(
    { "n", "v", "x" },
    "<leader><C-a>",
    "gg0vG$",
    { noremap = true, silent = true, desc = "Select all" }
  )

  -- Move lines
  -- This is replaced by mini.move
  if
    not catUtils.enableForCategory("mini", false) and catUtils.enableForCategory("nomini", true)
  then
    vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
    vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })
  end
end
