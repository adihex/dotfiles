-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- ──── General ────

-- Clear search highlight on Escape (double-tap if in insert mode)
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Stay centered after navigation jumps
map("n", "n", "nzzzv", { desc = "Next search (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- ──── Visual Mode ────

-- Stay in visual mode when indenting
map("v", "<", "<gv", { desc = "Indent left (stay visual)" })
map("v", ">", ">gv", { desc = "Indent right (stay visual)" })

-- Move selected lines up/down with Alt-j/k
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ──── Terminal Mode ────

-- Escape from terminal mode (you'll use <C-/> to toggle terminal)
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ──── Window Navigation ────

-- Resize windows with Ctrl+Arrow
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- ──── Quickfix ────

-- Toggle quickfix list
map("n", "<leader>xq", function()
  vim.cmd.copen()
end, { desc = "Open Quickfix" })

-- ──── Disable Arrow Keys (training wheels off) ────
-- Uncomment these once you're comfortable with hjkl
-- map("n", "<Up>", "<Nop>", { desc = "No arrow keys!" })
-- map("n", "<Down>", "<Nop>", { desc = "No arrow keys!" })
-- map("n", "<Left>", "<Nop>", { desc = "No arrow keys!" })
-- map("n", "<Right>", "<Nop>", { desc = "No arrow keys!" })
-- map("i", "<Up>", "<Nop>", { desc = "No arrow keys!" })
-- map("i", "<Down>", "<Nop>", { desc = "No arrow keys!" })
-- map("i", "<Left>", "<Nop>", { desc = "No arrow keys!" })
-- map("i", "<Right>", "<Nop>", { desc = "No arrow keys!" })
