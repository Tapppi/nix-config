# changes to keybindings refactoring plan

- Remove the LSP on_attach file and use the remap function created directly
- Remove section numbering in remaps.lua after making all changes
- Create plugin-specific which-key setup functions below the global which-key setup function
  that are called when the plugin is loaded, instead of trying to duplicate plugin filtering inside
  the remap.lua which-key setup
- Move the remap of Esc for nohlsearch and notify into setup_global_remap with the same check for
  whether notify exists, but keep the notify setup within plugins/init.lua
- Make sure that the "keys" configuration for lze plugin loading specs is kept after changes
- Load global remaps still in init.lua, don't move it
- Rename the get_** functions to set_** and set any relevant plugin keymaps in there as well as
  returning the plugin configuration keymap hash instead of having two functions per plugin
- Add a group for `<leader>f` that stands for "[F]ile" in the which key mappings in a separate step
  - Add `<leader>fw` that writes the file with ":w"
  - Add `<leader>fW` that force-writes the file
- Instead of telescope_helpers file, let's create a helpers.lua file in the myLuaConf dir where all
  simple helper functions should be placed
  - move the telescope helpers into this new helpers file
  - rename live_grep_git_root to telescope_live_grep_git_root
- make sure the keybinding test list is coherent after all that has changed in the plan

