local utils = require('neoranger.utils')

local M = {}
local state = { win = nil, buf = nil }

--- Default configuration
M.defaults = {
	width = 0.8,
	height = 0.8,
	border = "rounded",
	ranger_cmd = "ranger",
	choosefile_path = "/tmp/ranger_file_path",
	servername_path = "/tmp/nvim_servername",
}

M.config = {}

function M.save_servername()
	vim.fn.writefile({ vim.v.servername }, '/tmp/nvim_servername')
	print("Servername saved: " .. vim.v.servername)
end

--- Toggle the floating ranger window
---@param opts? table Optional configuration overrides
function M.toggle(opts)
	opts = vim.tbl_deep_extend("force", M.config, opts or {})

	-- If it's open, close it
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
		state.buf = nil
		return
	end

	-- Dimensions
	local ui_h = vim.o.lines - vim.o.cmdheight
	local ui_w = vim.o.columns
	local height = math.max(20, math.floor(ui_h * opts.height))
	local width = math.max(80, math.floor(ui_w * opts.width))
	local row = math.floor((ui_h - height) / 2 - 1)
	local col = math.floor((ui_w - width) / 2)

	-- Create scratch buffer
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")

	-- Floating window
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = opts.border,
		style = "minimal",
	})

	-- Style
	vim.api.nvim_win_set_option(state.win, "winhl", "NormalFloat:Normal,FloatBorder:FloatBorder")

	-- Delete old choosefile to prevent opening stale files
	vim.fn.delete(opts.choosefile_path)

	-- Save Neovim server name for potential external communications
	vim.fn.writefile({ vim.v.servername }, opts.servername_path)

	-- Launch ranger
	local cmd = opts.ranger_cmd .. " --choosefile=" .. opts.choosefile_path
	vim.fn.termopen(cmd, {
		cwd = opts.cwd or vim.fn.getcwd(),
		on_exit = function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				pcall(vim.api.nvim_win_close, state.win, true)
			end
			state.win = nil
			state.buf = nil

			-- Check if a file was selected
			local file_selected = vim.fn.filereadable(opts.choosefile_path)

			if file_selected == 1 then
				local selected_file = utils.read_ranger_file(opts.choosefile_path)
				if selected_file then
					if utils.is_buffer_empty() then
						vim.cmd('edit ' .. vim.fn.fnameescape(selected_file))
					else
						vim.cmd('tabedit ' .. vim.fn.fnameescape(selected_file))
					end
				end
			end
		end,
	})

	vim.cmd.startinsert()

	-- Keymaps for convenience
	vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = state.buf, noremap = true, silent = true })
	vim.keymap.set({ "n", "t" }, "q", function()
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_close(state.win, true)
		end
	end, { buffer = state.buf, noremap = true, silent = true })
end

--- Setup the plugin with user configuration
---@param opts? table User configuration options
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

	-- Create a user command
	vim.api.nvim_create_user_command('Neoranger', function(args)
		M.toggle({ cwd = args.args ~= "" and args.args or nil })
	end, { nargs = "?", complete = "dir", desc = "Toggle floating ranger" })
end

return M
