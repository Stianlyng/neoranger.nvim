local utils = require('neoranger.utils')

local M = {}

local state = {
	win = nil,
	buf = nil,
}

M.defaults = {
	width = 0.8,                        -- Float: 0.8 = 80% of screen width
	height = 0.8,                       -- Float: 0.8 = 80% of screen height
	border = "rounded",                 -- Options: "rounded", "single", "double", "solid", "shadow"
	ranger_cmd = "ranger",              -- Command to launch ranger (could be custom build)
	choosefile_path = "/tmp/ranger_file_path", -- Where ranger writes selected file
	servername_path = "/tmp/nvim_servername", -- For external scripts to talk to nvim
}

-- This will hold the merged configuration (defaults + user options)
M.config = {}

function M.cdw()
	-- vim.fn.expand() expands special characters:
	--   % = current filename
	--   :p = expand to full path
	--   :h = remove filename, keep directory (head)
	local dirpath = vim.fn.expand('%:p:h')

	vim.cmd('cd ' .. vim.fn.fnameescape(dirpath))

	print('Changed working directory to: ' .. dirpath)
end

function M.save_servername()
	vim.fn.writefile({ vim.v.servername }, '/tmp/nvim_servername')
	print("Servername saved: " .. vim.v.servername)
end

local function open_ranger(opts)
	vim.fn.delete(opts.choosefile_path)
	vim.fn.writefile({ vim.v.servername }, opts.servername_path)

	local cmd = opts.ranger_cmd .. " --choosefile=" .. opts.choosefile_path

	vim.fn.termopen(cmd, {
		cwd = opts.cwd or vim.fn.getcwd(),

		on_exit = function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				pcall(vim.api.nvim_win_close, state.win, true)
			end

			state.win = nil
			state.buf = nil

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
end
function M.toggleFloat(opts)
	opts = vim.tbl_deep_extend("force", M.config, opts or {})

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
		state.buf = nil
		return
	end

	local ui_h = vim.o.lines - vim.o.cmdheight
	local ui_w = vim.o.columns

	local height = math.max(20, math.floor(ui_h * opts.height))
	local width = math.max(80, math.floor(ui_w * opts.width))

	local row = math.floor((ui_h - height) / 2 - 1)
	local col = math.floor((ui_w - width) / 2)

	state.buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")

	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor", -- Position relative to entire editor (not a specific window)
		width = width, -- Window width in columns
		height = height, -- Window height in rows
		row = row, -- Starting row position
		col = col, -- Starting column position
		border = opts.border, -- Border style (rounded, single, double, etc.)
		style = "minimal", -- Minimal UI (no line numbers, statusline, etc.)
	})

	vim.api.nvim_win_set_option(state.win, "winhl", "NormalFloat:Normal,FloatBorder:FloatBorder")

	-- open ranger inside the floating buffer
	open_ranger(opts)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

	vim.api.nvim_create_user_command('NeorangerFloat', function(args)
		-- args.args = command-line arguments provided by user
		-- Examples:
		--   :Neoranger           -> args.args = ""
		--   :Neoranger ~/code    -> args.args = "~/code"

		M.toggleFloat({ cwd = args.args ~= "" and args.args or nil })
	end, {
		nargs = "?",       -- "?" means 0 or 1 arguments (optional)
		complete = "dir",  -- Tab completion for directory paths
		desc = "Toggle floating ranger", -- Description for :help
	})
end

return M
