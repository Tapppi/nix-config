-- Functions that define all my keymaps, so they are centralised and easy to grok

local catUtils = require('nixCatUtils')

-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
function Global_remaps()
  vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Scroll Down' })
  vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Scroll Up' })
  vim.keymap.set("n", "n", "nzzzv", { desc = 'Next Search Result' })
  vim.keymap.set("n", "N", "Nzzzv", { desc = 'Previous Search Result' })

  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = 'Previous buffer' })
  vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = 'Next buffer' })
  vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = 'Last buffer' })
  vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = 'delete buffer' })

  -- This is replaced by mini.move
  if not catUtils.enableForCategory("mini", false)
    and catUtils.enableForCategory("nomini", true) then
    vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Moves Line Down' })
    vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Moves Line Up' })
  end
end
