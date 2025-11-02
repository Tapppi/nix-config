# Neovim Configuration (flakes/nvim/)

This is a standalone flake for Neovim configuration using [nixCats](https://nixcats.org/).

## Config Project Architecture

### Overview

The Neovim configuration is built with:

- **nixCats**: Nix-based package management for Neovim
- **lze**: Lazy loading plugin manager
- **lzextras**: Additional lze utilities
- **No lazy.nvim**: Uses native Neovim loading via lze
- **No mason.nvim when using Nix**: All LSPs/tools via Nix packages. Mason is ONLY used when running outside Nix.

### Directory Structure

```txt
# git repo root
.editorconfig           # EditorConfig for formatting
stylua.toml             # Lua formatting config
AGENTS.md
flakes/nvim/
├── flake.nix           # nixCats configuration
├── init.lua            # Entry point
├── lua/
│   ├── myLuaConf/      # Main configuration
│   │   ├── init.lua    # Config loader
│   │   ├── opts.lua    # Neovim options
│   │   ├── keymap.lua  # Key mappings
│   │   ├── theme.lua   # Color scheme
│   │   ├── format.lua  # Formatting (conform.nvim)
│   │   ├── lint.lua    # Linting (nvim-lint)
│   │   ├── debug.lua   # DAP configuration
│   │   ├── lsp.lua     # LSP setup (lsp lze specs, lspconfig, fallback util)
│   │   └── plugins/    # Plugin configurations
│   │       ├── init.lua        # Plugin loader
│   │       ├── completion.lua  # Example: Blink.cmp config
│   │       ├── telescope.lua   # Example: Telescope config
│   │       └── ...
│   └── nixCatsUtils/   # nixCats utilities
├── plans/              # AI agent workspace for planning
└── README.md
```

### AI Agent Planning Workspace

The `plans/` directory is a workspace for AI agents to save plans, notes, and decisions about upcoming changes.
Use this directory to document complex multi-step changes before implementation, track ongoing work, or note
architectural decisions. Files in this directory are not part of the runtime configuration.

## Lua Code Style

### Lua Formatting with StyLua

All Lua code is formatted with StyLua, see `stylua.toml` in repo root (not in `flakes/nvim`).
StyLua is configured to match the root `.editorconfig` rules except for the final newline insertion, which it
doesn't support.

### Lua Conventions

- **Indentation**: 2 spaces (no tabs)
- **Line length**: 120 characters maximum
- **Quotes**: Prefer double quotes (AutoPreferDouble)
- **Function calls**: Always use parentheses
- **Module pattern**: Use local requires at top of file
- **Comments**: Use `--` for inline, `-- NOTE:`, `-- TODO:` for annotations

### Example Lua Style (with excessive comments not to be replicated)

```lua
local M = {}

-- Module imports
local catUtils = require("nixCatsUtils")
local lzUtils = require("nixCatsUtils.lzUtils")

-- Configuration function
function M.setup()
  local opts = {
    setting = "value",
    nested = {
      key = "value",
    },
  }

  require("plugin").setup(opts)
end

return M
```

## nixCats Package System

### Category System

nixCats uses a category-based system to conditionally include plugins and tools. See `flakes/nvim/flake.nix` in
the `packageDefinitions` section. The `defaultCategories` attribute defines which categories are enabled by default,
and individual packages (like `nvim`) can override these with their own `categories` attribute.

Example from flake.nix:
```nix
packageDefinitions = {
  nvim = { pkgs, ... }: {
    settings = { /* ... */ };
    categories = defaultCategories // {
      general = true;
      lua = true;
      neonixdev = true;
      # ... more categories
    };
  };
};
```

Common category types:
- **Language support**: Categories like `lua`, `go`, `rust`, `typescript`, etc.
- **Feature categories**: `lint`, `format`, `debug`
- **Core categories**: `general` (always enabled), `neonixdev` (Nix development), `mini` (improved editor functionality)

To check available categories in your build, use `:lua print(vim.inspect(nixCats.cats))` in Neovim.

### Category Definitions

See `flake.nix` for the full `categoryDefinitions`. The configurations within control what a category enables, example:

- **lspsAndRuntimeDeps**: LSP servers, linters, formatters (available in PATH)
- **startupPlugins**: Loaded at startup
- **optionalPlugins**: Loaded lazily via lze
- **environmentVariables**: Runtime environment vars
- **python3.libraries**: Python packages for Neovim
- **extraLuaPackages**: Lua packages for Neovim

### Package Definitions

Packages, i.e. nvim executables with separate configs are configured in `flake.nix`. The main ones:

1. **nvim**: Main package (wrapped config from nix)
   - Aliases: `vim`, `vi`
2. **testNvim**: Testing package (unwrapped, impure)
   - Loads config from default project path for the config `~/project/github/tapppi/nix-config/flakes/nvim`
   - Good for testing changes without bothering with nix rebuilds

## Plugin Management

### Startup vs Optional Plugins

In `flake.nix` in the `categoryDefinitions` there are two configurations for plugins per category:

**startupPlugins** load immediately via Neovim's packpath:
- Core dependencies required by multiple plugins (e.g. plenary, lze, notify)
- Essential utilities (vim-repeat, vim-sleuth)
- Theme plugins
- File explorer, i.e. Oil.nvim (loaded through lze, but non-lazily)

**optionalPlugins** are loaded lazily via lze specs, includes everything else including:
- LSP and completion configurations (e.g. nvim-lspconfig)
- Language-specific tooling
- Feature plugins with clear trigger points (commands, keys, events)

### Plugin downloads outside Nix

When running outside Nix, required plugins are installed with `lua/myLuaConf/non_nix_download.lua` which uses the
`lua/nixCatsUtils/catPacker.lua` to install `paq` and use it to insatall the plugins. Mason is used for installing
LSPs outside Nix.

### Adding New Plugins

1. Add plugin source to `flake.nix` `categoryDefinitions`:

From nixpkgs, PREFERRED when available:

```nix
optionalPlugins = {
  general = with pkgs.vimPlugins; [
    # Add plugin here
    new-plugin-name
  ];
};
```

From GitHub, when plugin not available in nixpkgs:

```nix
# flake.nix
# Add to overlay with name format "plugins-<pluginName>" to automatically include in pkgs.neovimPlugins
inputs = {
  "plugins-newplugin" = {
    url = "github:author/newplugin";
    flake = false;
  };
};
# In categoryDefinitions:
optionalPlugins = {
  general = with pkgs.vimPlugins; [
    # ...
    pkgs.neovimPlugins.newplugin  # Note: neovimPlugins, not vimPlugins
  ];
};
```

2. Create Lua configuration in `lua/myLuaConf/plugins/`, either new file or add to existing general file.

```lua
-- lua/myLuaConf/plugins/newplugin.lua
require("lze").load {
  {
    "new-plugin",
    for_cat = "general", -- Enable for category or use `enabled = <any lua>` for more complex configurations
    -- See available triggers in lze section
    cmd = { "PluginCommand" },
    keys = { { "<leader>np", "<cmd>PluginCommand<cr>", desc = "Plugin command" } },
    after = function(_)
      -- If the plugin needs a setup function call
      require("new-plugin").setup({
        -- configuration
      })
    end,
  },
}
```

3. Load in `lua/myLuaConf/plugins/init.lua` if config was added to a new file

4. Add plugin to `lua/myLuaConf/non_nix_download.lua` if it should be usable outside Nix (yes by default)

### Lazy Loading with lze

lze supports multiple loading triggers, use triggers applicable to the typical
way the plugin is used:

```lua
require("lze").load {
  {
    "plugin-name",
    -- Options to enable plugin:
    for_cat = "category",                                  -- If category enabled, shortcut
    enabled = catUtils.enableForCategory("category", true) -- Allows more complex logic for enabling

    -- Trigger options:
    cmd = { "CommandName" },              -- On command
    event = "BufReadPre",                 -- On event
    ft = "lua",                           -- On filetype
    keys = { "<leader>x" },               -- On keymap

    -- Setup options:
    before = function(plugin) end,        -- Before loading
    after = function(plugin) end,         -- After loading
    load = function(name) end,            -- Custom load function
  },
}
```

## LSP Configuration

### LSP Setup Pattern

LSPs are configured in `lua/myLuaConf/LSPs/init.lua` using lzextras.lsp handler:

```lua
require("lze").load {
  {
    "nvim-lspconfig",
    for_cat = "general.always",
    on_require = { "lspconfig" },
    -- Runs for all plugins with spec.lsp defined
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    -- Other irrelevant config for lspconfig...
  },
  {
    "lua_ls",
    enabled = nixCats("lua") or nixCats("neonixdev") or false,
    lsp = {
      settings = { /* ... */ },
    },
  },
  -- More LSP configs...
}
```

### Available LSPs

LSPs are configured in `lua/myLuaConf/LSPs/init.lua`. Check the file for current LSP support. Common patterns:

- Language-specific LSPs are gated by their category (typically with e.g. `for_cat = "go"` in lze spec)
- To see which LSPs are available in your build, use `:LspInfo` in Neovim

### Adding New LSP

1. Add LSP package to `flake.nix` categoryDefinitions:

```nix
lspsAndRuntimeDeps = {
  mylang = with pkgs; [
    mylang-language-server
  ];
};
```

2. Add category in packageDefinitions if needed:

```nix
categories = defaultCategories // {
  mylang = true;
};
```

3. Add LSP spec to `lua/myLuaConf/LSPs/init.lua`:

```lua
{
  "mylang-language-server",
  for_cat = "mylang",
  lsp = {
    -- optional: override filetypes
    -- filetypes = { "mylang" },
    settings = {
      -- LSP-specific settings
    },
  },
},
```

## Completion System

Uses **blink.cmp** and **luasnip**, configured in `lua/myLuaConf/plugins/completion.lua`

## Linting (nvim-lint)

Configured in `lua/myLuaConf/lint.lua` when `lint` category is enabled. Dependencies added in `lspsAndRuntimeDeps`.

## Formatting (conform.nvim)

Configured in `lua/myLuaConf/format.lua` when `format` category is enabled. Dependencies added in `lspsAndRuntimeDeps`.

## Debugging (DAP, nvim-dap)

Configured in `lua/myLuaConf/debug.lua` when `debug` category is enabled. Dependencies added in `lspsAndRuntimeDeps`.

## Theme System

Configured in `lua/myLuaConf/theme.lua`, controlled by the value of the `colorscheme` category in `flake.nix`
`packageDefinitions`.

To check the current theme: `:lua print(nixCats("colorscheme"))`

## Testing Neovim

If you are configured with access to a full interactive terminal, troubleshoot within Neovim.
If not, ask the user to collaborate on troubleshooting with you.

### Using testNvim

The `testNvim` package allows testing lua configuration changes without rebuilding, just restarting is enough.

```bash
# Build testNvim once, or after adding new plugins/dependencies
nix build .#testNvim

# Run testNvim after configuration changes
./result/bin/testNvim
```

### Checking plugins and categories

Within Neovim:

```vim
" Print individual plugin's path
:lua print(nixCats.pawsible.allPlugins.opt.luasnip)
" List available plugins and paths
:NixCats pawsible
" Check if category is enabled
:lua print(nixCats("lua"))
" Inspect plugins health information
:checkhealth telescope
```

### Checking current LSPs

Use `:LspInfo` to check which LSPs are configured, and whether there are any errors.

## Guidelines for AI Agents: Neovim-Specific

### When Modifying Lua Configuration

1. **Format with StyLua**: Ensure all Lua follows stylua.toml settings
2. **Use nixCats helpers**: See [Understanding nixCats Utilities](#understanding-nixcats-utilities)
3. **Prefer lze loading**: Don't use lazy.nvim patterns, we do NOT use lazy.nvim
4. **Test incrementally**: See [the Testing Neovim section](#testing-neovim)
5. **Follow module structure**: Keep plugins organized in separate files

### When Adding Plugins

1. **Check nixpkgs**: Search for plugin in vimPlugins, only use GitHub with overlay if not available in nixpkgs
2. **Add to category**: Place in appropriate category in flake.nix
3. **Create spec**: Write lze spec with appropriate triggers and options
4. **Load in plugins/init.lua**: Import the new plugin file if one was created
5. **Document keybindings**: All keybindings must be set in `lua/myLuaConf/keymap.lua`

See the [Plugin Management section](#plugin-management) for details.

### When Configuring LSPs

1. **Add LSP package**: Include in lspsAndRuntimeDeps in `flake.nix`
2. **Create spec**: Add to `lua/myLuaConf/LSPs/init.lua` with proper category
3. **Test filetypes**: Verify LSP loads on correct filetypes
4. **Use on_attach**: Leverage common on_attach for consistency
5. **Enable category**: Update defaultCategories if needed

See the [LSP Configuration section](#lsp-configuration) for details.

### Common Neovim Pitfalls

- Don't use `lazy.nvim` patterns (no `lazy = true`)
- Don't use `mason.nvim` when using Nix (isNixCats check)
- Remember lze uses `after` not `config` for setup functions
- LSP specs use `lsp` table, not direct `config` function
- Category subcategories use dot notation: `general.always`

### Recommended Workflow for Neovim Changes

1. **Plan**: Review existing patterns in lua/myLuaConf/
2. **Edit**: Make changes to Lua files
3. **Format**: Run StyLua if not in auto-format setup
4. **Test**: Use testNvim to verify changes, see [the Testing Neovim section](#testing-neovim)
5. **Build**: `nix build .#nvim` when ready
6. **Deploy**: Update system or use `./result/bin/nvim`

### Understanding nixCats Utilities

nixCats has utilities under `lua/nixCatsUtils/init.lua`. This is an overview of those utilities:

```lua
local catUtils = require("nixCatsUtils")
-- Check if using nixCats (vs mason & paq fallback)
if catUtils.isNixCats then
  -- Using Nix packages
end

-- Check category enabled
-- Returns a boolean value and accepts a fallback value to return if not in nixCats
if catUtils.enableForCategory("lua", true) then
  -- Lua category enabled or running outside of nixCats
end

-- Get category value or default
local colorscheme = catUtils.getCatOrDefault("colorscheme", "catppuccin-mocha")
```

The `nixCats` global also has a few basic utilities that are useful:

```lua
-- Get nested category value from the package's 'extra' field in packageDefinitions using the nixCats global
local nixpkgs = nixCats.extra("nixdExtras.nixpkgs") -- Returns value of field with better handling of nesting

-- Get category value (or the default if not in nixCats, so true for our config)
if nixCats("lua") then
  -- Lua category enabled
end

-- Get plugin path
local lspconfig_path = nixCats.pawsible({
  "allPlugins", "opt", "nvim-lspconfig"
})
```

`nixCatsUtils/lzUtils.lua` defines the `for_cat` handler for lze and `nixCatsUtils/catPacker.lua` defines the fallback
plugin installation with `paq`. You SHOULD never need to touch these.

## Updating Dependencies

Plugins can be updated by updating the Flake Inputs:

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
nix flake lock --update-input nixCats
```

## Additional Resources

- [nixCats Documentation](https://nixcats.org/)
- [nixCats example template this config is based on](https://github.com/BirdeeHub/nixCats-nvim/tree/main/templates/example)
- [lze Plugin Manager](https://github.com/BirdeeHub/lze)
- [lzextras Utilities](https://github.com/BirdeeHub/lzextras)
- [Neovim LSP Configuration](https://neovim.io/doc/user/lsp.html)

