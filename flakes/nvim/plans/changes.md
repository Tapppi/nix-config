# changes to keybindings refactoring plan

Overall changes:

- Remove the LSP on_attach file and use the remap function created directly. Move myLuaconf/LSPs/init.lua to simply
myLuaConf/lsp.lua and delete the unneeded LSPs dir
- Remove section numbering in remaps.lua after making all changes
- Keep the notify dimissal and nohlsearch remap within plugins/init.lua, but document it in the global which key setup
- Load global remaps still in init.lua, don't move it
- Don't setup oil keymaps in which-key, it's a file explorer with its own help. Simply return the keymap for use in the
  oil config.
- Add a group for `<leader>f` that stands for "[F]ile" in the which key mappings
  - Add `<leader>fw` that writes the file with ":w"
  - Add `<leader>fW` that force-writes the file
- Instead of telescope_helpers file, let's create a myLuaConf/helpers.lua file where helpers are placed
  - move the telescope helpers into this new helpers file
  - rename live_grep_git_root to telescope_live_grep_git_root
- make sure the keybinding test list is coherent after all that has changed in the plan

Changes to how individual plugins keymaps are loaded:

- Create plugin-specific setup functions that are called when the plugin is loaded, instead of trying to duplicate
  plugin filtering inside the remap.lua which-key setup.
- Rename the plugin-specific functions to set_pluginname_remaps and set any relevant plugin keymaps with which-key in
  there as well as returning the plugin configuration keymap hash instead of having two functions per plugin
- Make sure that the "keys" configuration for lze plugin loading specs is kept after changes. Co-locate the lze keys
  and plugin-specific setup functions where applicable instead of a single lze keys table

