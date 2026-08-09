-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- ──── Keyboard Discipline ────
-- Disable mouse — forces you to learn keyboard navigation
-- Re-enable by setting to "a" (all) if you need it temporarily
vim.opt.mouse = ""

-- ──── Line Numbers ────
-- Relative + absolute: shows distance for jumps (5j, 12k)
-- Current line shows absolute number in the gutter
vim.opt.relativenumber = true
vim.opt.number = true

-- ──── Scrolling Comfort ────
-- Keep 8 lines of context above/below cursor
vim.opt.scrolloff = 8
-- Keep 8 columns of context left/right of cursor
vim.opt.sidescrolloff = 8

-- ──── Whitespace Visibility ────
-- Show tabs, trailing spaces, and nbsp (helps with text objects)
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- ──── Responsiveness ────
-- Faster update time for CursorHold events (git blame, diagnostics)
vim.opt.updatetime = 200
-- Quicker which-key popup (default 1000ms is sluggish)
vim.opt.timeoutlen = 300

-- ──── Search ────
-- Search as you type
vim.opt.incsearch = true
-- Ignore case unless uppercase is typed
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ──── Misc ────
-- Spell check only enabled manually (use <leader>us to toggle)
vim.opt.spelllang = "en_us"
-- More undo history
vim.opt.undolevels = 10000
-- Always show tabline (buffers) for buffer awareness
vim.opt.showtabline = 2
-- Minimum window width to prevent windows from collapsing
vim.opt.winminwidth = 5
-- Split windows open below and to the right (natural reading flow)
vim.opt.splitbelow = true
vim.opt.splitright = true
