
-- General settings
require("myLuaConf.opts")

-- Remaps
require("myLuaConf.remap")
Global_remaps()

-- Extra lze handlers
-- makes enabling an lze spec for a category slightly nicer
require("lze").register_handlers(require("nixCatsUtils.lzUtils").for_cat)
-- setup lsps within lze specs, and trigger only on correct filetypes
require("lze").register_handlers(require("lzextras").lsp)

-- Theming
require("myLuaConf.theme")

-- Plugins
require("myLuaConf.plugins")
require("myLuaConf.LSPs")

-- Debugging, linting, formatting
if nixCats("debug") then
  require("myLuaConf.debug")
end
if nixCats("lint") then
  require("myLuaConf.lint")
end
if nixCats("format") then
  require("myLuaConf.format")
end

