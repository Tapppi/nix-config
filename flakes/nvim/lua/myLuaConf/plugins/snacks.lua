-- Snacks.nvim is a collection of plugins that replaces many basic plugins with
-- a coherent set of that work well together. It's from folke, and together
-- with mini is a good base without using a distro.

-- See the nosnacks category in flake.nvim for everything snacks replaces in
-- my config.

return {
  {
    "snacks.nvim",
    for_cat = "snacks",
    lazy = false,
    -- Picker hotkeys, todo replace telescope
    -- keys = {
    --   -- Do we want picker cache hotkeys?
    --   -- Do we want a md task picker? (Ref @linkarzu dotfiles and snacks picker video)
    --   { "<leader>sM", '<cmd>Telescope notify<CR>', mode = { "n" }, desc = '[S]earch [M]essage', },
    --   { "<leader>sp", live_grep_git_root,          mode = { "n" }, desc = '[S]earch git [P]roject root', },
    --   {
    --     "<leader>/",
    --     function()
    --       -- Slightly advanced example of overriding default behavior and theme
    --       -- You can pass additional configuration to telescope to change theme, layout, etc.
    --       require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    --         winblend = 10,
    --         previewer = false,
    --       })
    --     end,
    --     mode = { "n" },
    --     desc = '[/] Fuzzily search in current buffer',
    --   },
    --   {
    --     "<leader>s/",
    --     function()
    --       require('telescope.builtin').live_grep {
    --         grep_open_files = true,
    --         prompt_title = 'Live Grep in Open Files',
    --       }
    --     end,
    --     mode = { "n" },
    --     desc = '[S]earch [/] in Open Files'
    --   },
    --   { "<leader><leader>s", function() return require('telescope.builtin').buffers() end,     mode = { "n" }, desc = '[ ] Find existing buffers', },
    --   { "<leader>s.",        function() return require('telescope.builtin').oldfiles() end,    mode = { "n" }, desc = '[S]earch Recent Files ("." for repeat)', },
    --   { "<leader>sr",        function() return require('telescope.builtin').resume() end,      mode = { "n" }, desc = '[S]earch [R]esume', },
    --   { "<leader>sd",        function() return require('telescope.builtin').diagnostics() end, mode = { "n" }, desc = '[S]earch [D]iagnostics', },
    --   { "<leader>sg",        function() return require('telescope.builtin').live_grep() end,   mode = { "n" }, desc = '[S]earch by [G]rep', },
    --   { "<leader>sw",        function() return require('telescope.builtin').grep_string() end, mode = { "n" }, desc = '[S]earch current [W]ord', },
    --   { "<leader>ss",        function() return require('telescope.builtin').builtin() end,     mode = { "n" }, desc = '[S]earch [S]elect Telescope', },
    --   { "<leader>sf",        function() return require('telescope.builtin').find_files() end,  mode = { "n" }, desc = '[S]earch [F]iles', },
    --   { "<leader>sk",        function() return require('telescope.builtin').keymaps() end,     mode = { "n" }, desc = '[S]earch [K]eymaps', },
    --   { "<leader>sh",        function() return require('telescope.builtin').help_tags() end,   mode = { "n" }, desc = '[S]earch [H]elp', },
    -- },
    after = function()
      require("snacks").setup({
        indent = {
          enabled = true,
          animate = {
            enabled = false,
            easing = "easeOutQuant",
            duration = {
              step = 10,
              total = 300,
            }
          },
          chunk = {
            enabled = true,
            hl = vim.g.rainbow_delimiters.highlight,
            only_current = false,
            char = {
              corner_top = "┌",
              corner_bottom = "└",
              -- Doesn't look smooth in iterm2
              -- corner_top = "╭",
              -- corner_bottom = "╰",
              horizontal = "─",
              vertical = "│",
              arrow = ">",
            },
          },
          scope = {
            enabled = true,
            hl = vim.g.rainbow_delimiters.highlight,
            -- Set to true when not using chunks
            underline = false,
            only_current = false,
            char = "│",
          },
        },
        -- picker = {
        --   enabled = true,
        --   theme = "catppuccin",
        -- },
      })
    end,
  }
}
