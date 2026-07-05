local utils = require("neoranger.utils")

local M = {}

-- Running session state. The terminal buffer outlives the floating window so
-- that toggling the window hides ranger instead of killing it.
local state = {
	win = nil, -- floating window id
	buf = nil, -- terminal buffer id
	job = nil, -- ranger job id
	cwd = nil, -- directory the running session was started in
}

---@class neoranger.Config
---@field width number Floating window width as a fraction of the screen (0.0-1.0)
---@field height number Floating window height as a fraction of the screen (0.0-1.0)
---@field border string Border style: "rounded", "single", "double", "solid", "shadow"
---@field ranger_cmd string|string[] Command used to launch ranger
---@field close_key string|false Terminal-mode key that hides the window (false to disable)
---@field choosefile_path? string Fixed path for ranger's selection file (default: a unique temp file per session)
---@field servername_path string Where the nvim servername is written for external scripts
M.defaults = {
	width = 0.8,
	height = 0.8,
	border = "rounded",
	ranger_cmd = "ranger",
	close_key = "<Esc>",
	choosefile_path = nil,
	servername_path = "/tmp/nvim_servername",
}

---@type neoranger.Config
M.config = vim.deepcopy(M.defaults)

--- Change Neovim's working directory to the current file's directory.
function M.cdw()
	local dirpath = vim.fn.expand("%:p:h")

	vim.cmd("cd " .. vim.fn.fnameescape(dirpath))

	vim.notify("Changed working directory to: " .. dirpath)
end

--- Write `v:servername` to `config.servername_path` so external scripts can
--- talk to this instance. Note that processes started from `:terminal`
--- already get the servername in the `$NVIM` environment variable.
function M.save_servername()
	vim.fn.writefile({ vim.v.servername }, M.config.servername_path)
	vim.notify("Servername saved: " .. vim.v.servername)
end

---@param cmd string|string[]
---@return string executable
local function ranger_executable(cmd)
	if type(cmd) == "table" then
		return cmd[1]
	end
	return cmd
end

--- Open a centered floating window showing `buf`.
---@param buf integer
---@param opts neoranger.Config
---@return integer win
local function open_float(buf, opts)
	local ui_h = vim.o.lines - vim.o.cmdheight
	local ui_w = vim.o.columns

	-- Aim for the configured fraction of the screen, at least 80x20, but
	-- never larger than the screen itself (minus the border).
	local height = math.min(ui_h - 2, math.max(20, math.floor(ui_h * opts.height)))
	local width = math.min(ui_w - 2, math.max(80, math.floor(ui_w * opts.width)))

	local row = math.max(0, math.floor((ui_h - height) / 2 - 1))
	local col = math.max(0, math.floor((ui_w - width) / 2))

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = opts.border,
		style = "minimal",
	})

	vim.wo[win].winhl = "NormalFloat:Normal,FloatBorder:FloatBorder"

	return win
end

--- Clean up after the ranger process ends and open whatever was selected.
---@param buf integer terminal buffer of the finished session
---@param choosefile string path ranger writes selected files to
local function on_ranger_exit(buf, choosefile)
	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		pcall(vim.api.nvim_win_close, win, true)
	end
	if vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
	end
	-- Only reset state if it still refers to this session (a new session may
	-- already have replaced it, e.g. after a restart in a different cwd).
	if state.buf == buf then
		state.win, state.buf, state.job, state.cwd = nil, nil, nil, nil
	end

	local files = utils.read_selected_files(choosefile)
	vim.fn.delete(choosefile)
	if not files then
		return
	end

	for i, file in ipairs(files) do
		if i == 1 and utils.is_buffer_empty() then
			vim.cmd("edit " .. vim.fn.fnameescape(file))
		else
			vim.cmd("tabedit " .. vim.fn.fnameescape(file))
		end
	end
end

--- Start ranger inside `state.buf`.
---@param opts neoranger.Config|{ cwd?: string }
---@param selectfile string file ranger should start with highlighted ("" for none)
local function open_ranger(opts, selectfile)
	local choosefile = opts.choosefile_path or vim.fn.tempname()
	vim.fn.delete(choosefile)
	vim.fn.writefile({ vim.v.servername }, opts.servername_path)

	local cmd = type(opts.ranger_cmd) == "table" and vim.deepcopy(opts.ranger_cmd) or { opts.ranger_cmd }
	table.insert(cmd, "--choosefiles=" .. choosefile)
	if selectfile ~= "" and vim.fn.filereadable(selectfile) == 1 then
		table.insert(cmd, "--selectfile=" .. selectfile)
	end

	local buf = state.buf
	state.cwd = opts.cwd or vim.fn.getcwd()
	state.job = vim.fn.jobstart(cmd, {
		term = true,
		cwd = state.cwd,
		on_exit = function()
			vim.schedule(function()
				on_ranger_exit(buf, choosefile)
			end)
		end,
	})

	if opts.close_key then
		vim.keymap.set("t", opts.close_key, function()
			M.toggle()
		end, { buffer = buf, desc = "Hide neoranger" })
	end

	vim.cmd.startinsert()
end

--- Toggle the floating ranger window. Closing the window keeps ranger
--- running; toggling again brings the same session back. Passing a `cwd`
--- different from the running session's restarts ranger there.
---@param opts? { cwd?: string }|neoranger.Config
function M.toggle(opts)
	opts = vim.tbl_deep_extend("force", M.config, opts or {})

	-- Window visible: hide it, keep ranger running.
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
		return
	end

	if opts.cwd then
		opts.cwd = vim.fn.fnamemodify(vim.fn.expand(opts.cwd), ":p")
		if vim.fn.isdirectory(opts.cwd) == 0 then
			vim.notify("neoranger: not a directory: " .. opts.cwd, vim.log.levels.ERROR)
			return
		end
	end

	-- A session is already running in the background.
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		if opts.cwd and opts.cwd ~= state.cwd then
			-- Different directory requested: discard the old session.
			if state.job then
				pcall(vim.fn.jobstop, state.job)
			end
			pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
			state.buf, state.job, state.cwd = nil, nil, nil
		else
			state.win = open_float(state.buf, opts)
			vim.cmd.startinsert()
			return
		end
	end

	local exe = ranger_executable(opts.ranger_cmd)
	if vim.fn.executable(exe) == 0 then
		vim.notify(
			("neoranger: '%s' is not executable. Is ranger installed? (see :checkhealth neoranger)"):format(exe),
			vim.log.levels.ERROR
		)
		return
	end

	local selectfile = vim.api.nvim_buf_get_name(0)

	state.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.buf].bufhidden = "hide"
	state.win = open_float(state.buf, opts)

	open_ranger(opts, selectfile)
end

-- Backwards-compatible alias for the old public name.
M.toggleFloat = M.toggle

--- Merge user options into the configuration. Calling this is optional; the
--- plugin works with defaults out of the box.
---@param opts? neoranger.Config
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
