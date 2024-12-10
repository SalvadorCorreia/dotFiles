local plugins = {
  {
    'neovim/nvim-lspconfig',
    'numToStr/Comment.nvim',
    'github/copilot.vim',
  },
  {
    'williamboman/mason.nvim',
    opts = {
      ensure_installed = {
        'clangd',
      },
    },
  },
}
return plugins

