return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Python environments and tools are managed by uv/Astral.
        -- ty provides type checking/import analysis; ruff provides lint/format.
        ty = {
          mason = false,
          cmd = { "ty", "server" },
        },
        pyright = { enabled = false },
        basedpyright = { enabled = false },
        ruff = {
          mason = false,
          cmd = { "ruff", "server" },
        },
      },
    },
  },
}
