-- Functions that define all my keymaps, so they are centralised and easy to grok

-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
function global_remaps()
  if not nixCats("mini") and nixCats("nomini") then
    vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Moves Line Down' })
    vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Moves Line Up' })
  end
end
