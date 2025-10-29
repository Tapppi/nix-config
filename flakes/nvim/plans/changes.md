# new keybindings refactoring plan

Use the change requests to create a new simpler plan. Don't include validation in the steps, just create an overall
keybinding list to test at the end of the document

- Validate and update as needed the inventory of current keymaps in the old plan
- Create the structure of the final document and steps for filling out the sections:
  - first global keymap func
  - global which key setup func for groups
  - LSP keymap
  - then plugin specific lze keys and config functions, GROUPED BY PLUGIN, e.g. gitsigns buffer-local,
    telescope lze & telescope keymap func
- Analyse the keybindings of each plugin INDIVIDUALLY and needed changes based on the "Changes to
  individual plugins keymaps" section of this document and incorporate findings to the new plan
- MOVE KEYBINDINGS AS IS, DO NOT CHANGE ANY OF THE vim.keymap.set FUNCTIONS OR THE Which-key GROUPS
- Add a group for `<leader>f` that stands for "[F]ile" in the which key mappings
  - Add `<leader>fw` that writes the file with ":w"
  - Add `<leader>fW` that force-writes the file

Overall notes and changes from the old plan:

- No numbered sections in the final document, just normal comments above each section
- Do NOT add keymaps through which key. Only use it to document "abnormal" keymaps that are not setup normally through
  vim.keymap.set. Which key will read normal keymaps as well!
- Remove the LSP on_attach file and use the remap function created directly. Move myLuaconf/LSPs/init.lua to simply
myLuaConf/lsp.lua and delete the unneeded LSPs dir
- Create a new function for setting up the notify dismissal / nohlsearch keybinding for `<Esc>` that takes as argument
  the notify.dismiss function to call. If the argument is not present, then just include nohlsearch. Use that function
  from plugins/init.lua when setting up notify
- Load global remaps still in init.lua, don't move it
- Don't setup oil keymaps in which-key, it's a file explorer with its own help. Simply return the keymap for use in the
  oil config.
- Instead of telescope_helpers file, let's create a myLuaConf/helpers.lua file where helpers are placed
  - move the telescope helpers into this new helpers file
  - rename live_grep_git_root to telescope_live_grep_git_root
- make sure the keybinding test list is coherent after all that has changed in the plan

### Changes to individual plugins keymaps:

- Create plugin-specific setup functions in remap.lua that are called when the plugin is loaded
- At maximum, create an lze keymap and a setup function per plugin. The setup function sets needed keymaps and returns
  any needed plugin configuration keymap table that is then used in the plugins config
- Make sure that the "keys" configuration for lze plugin loading specs is kept after changes if it exists before changes.
  Co-locate the lze keys and plugin-specific functions where applicable instead of a monolith lze keys table

