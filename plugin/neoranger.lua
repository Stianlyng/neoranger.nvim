if vim.fn.has("nvim-0.11.0") == 0 then
	vim.notify("neoranger requires Neovim >= 0.11.0", vim.log.levels.ERROR)
	return
end

local function toggle(args)
	-- args.args is the optional directory argument, e.g. `:Neoranger ~/code`.
	require("neoranger").toggle({ cwd = args.args ~= "" and args.args or nil })
end

local command_opts = {
	nargs = "?",
	complete = "dir",
	desc = "Toggle floating ranger",
}

vim.api.nvim_create_user_command("Neoranger", toggle, command_opts)

-- Backwards-compatible alias.
vim.api.nvim_create_user_command("NeorangerFloat", toggle, command_opts)
