-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- ──── Auto-Save ────
-- Save on leaving insert mode or when text changes (with debounce via updatetime)
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  pattern = "*",
  callback = function()
    -- Don't auto-save in special buffers
    if vim.bo.buftype ~= "" then
      return
    end
    -- Don't auto-save if the buffer isn't modified
    if not vim.bo.modified then
      return
    end
    vim.cmd("silent! wall")
  end,
  desc = "Auto-save on InsertLeave and TextChanged",
})
