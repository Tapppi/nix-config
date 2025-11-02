-- NOTE: These 2 need to be set up before any plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable if on an ancient typewriter, nvim should also auto-configure this if not set
vim.opt.termguicolors = true

-- [[ Setting options ]]
-- See `:help vim.o`

-- Save undo history
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search, ignores *,#,gd
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.tagcase = 'followscs'

-- Decrease update time
vim.opt.updatetime = 200
-- Wait for mappings for 300ms after last keypress
vim.opt.timeoutlen = 300

-- Show tabs and trailing spaces with glyphs, see `:help 'list'` `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Set window borders and transparency
vim.opt.winblend = 5
vim.opt.winborder = 'rounded'

-- Set highlight on search (see remap.lua for ESC to :nohlsearch bind)
vim.opt.hlsearch = true

-- Preview substitutions live, as you type!
vim.opt.incsearch = true
vim.opt.inccommand = 'split'

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Make line numbers default
vim.opt.nu = true
vim.opt.relativenumber = true
-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Enable mouse for all modes
vim.opt.mouse = 'a'

--{{{ Editorconfig related stuff
-- Indent, try smartindent on file if cindent is not satisfactory
vim.opt.cpoptions:append('I')
vim.opt.autoindent = true
-- vim.opt.smartindent = true
vim.opt.cindent = true
vim.opt.expandtab = true
vim.opt.smarttab = true
-- Tab sizes are set by vim-sleuth automatically and respect .editorconfig
-- Keep at default like :help suggests, and use sts and shiftwidth
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- stops line wrapping from being confusing
vim.opt.breakindent = true
-- vim.opt.linebreak = true
vim.opt.colorcolumn = '+2,+3'
vim.opt.textwidth = 100

-- End of line
vim.opt.fixendofline = true
vim.opt.endofline = true
--}}}

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menu,preview,noselect'

-- [[ Disable auto comment on enter ]]
-- See :help formatoptions
local filetype_fo_group = vim.api.nvim_create_augroup('FileTypeFormatOptions', { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  desc = "remove formatoptions",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
  group = filetype_fo_group,
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local yank_hl_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = yank_hl_group,
  pattern = '*',
})

vim.g.netrw_liststyle=0
vim.g.netrw_banner=0

-- see help sticky keys on windows
vim.cmd([[command! W w]])
vim.cmd([[command! Wq wq]])
vim.cmd([[command! WQ wq]])
vim.cmd([[command! Q q]])

