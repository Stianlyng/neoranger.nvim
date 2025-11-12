if vim.fn.has('nvim-0.11.0') == 0 then
	vim.api.nvim_err_writeln('neoranger requires Neovim >= 0.11.0')
	return
end

require('neoranger').setup()
