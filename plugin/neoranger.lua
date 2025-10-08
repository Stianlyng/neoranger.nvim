-- Auto-load the plugin
if vim.fn.has('nvim-0.7.0') == 0 then
  vim.api.nvim_err_writeln('hello-plugin requires Neovim >= 0.7.0')
  return
end

-- Auto-setup with default options
require('neoranger').setup()
