local M = {}

--- Whether the current buffer is an empty, unnamed, unmodified scratch —
--- i.e. safe to replace with `:edit` instead of opening a new tab.
---@return boolean
function M.is_buffer_empty()
	return vim.api.nvim_buf_get_name(0) == ""
		and not vim.bo.modified
		and vim.api.nvim_buf_line_count(0) == 1
		and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
end

--- Read the file ranger's `--choosefiles` writes selected paths to.
---@param path? string
---@return string[]|nil files One path per entry, or nil if nothing was selected
function M.read_selected_files(path)
	if not path or path == "" then
		return nil
	end

	local stat = vim.uv.fs_stat(path)
	if not stat or stat.size == 0 then
		return nil
	end

	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		vim.notify("neoranger: failed to read file: " .. path, vim.log.levels.ERROR)
		return nil
	end

	return #lines > 0 and lines or nil
end

--- Append a message to the debug log at stdpath("cache")/neoranger-debug.log.
---@param msg string|table
function M.log(msg)
	local log_file = vim.fn.stdpath("cache") .. "/neoranger-debug.log"

	local f = io.open(log_file, "a")
	if not f then
		return
	end

	if type(msg) == "table" then
		msg = vim.inspect(msg)
	end

	f:write(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. msg .. "\n")
	f:close()
end

return M
