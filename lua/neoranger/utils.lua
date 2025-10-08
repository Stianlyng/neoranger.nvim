local M = {}

--- Check if the current buffer is empty
---@return boolean
function M.is_buffer_empty()
  if vim.fn.empty(vim.fn.expand('%')) == 1
    and vim.api.nvim_buf_line_count(0) == 1
    and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == '' then
    return true
  else
    return false
  end
end

--- Read the first line from a ranger choosefile
---@param path string Path to the choosefile
---@return string|nil First line of the file or nil if failed
function M.read_ranger_file(path)
  if not path or path == "" then
    return nil
  end

  local stat = vim.loop.fs_stat(path)
  if not stat or stat.size == 0 then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    vim.notify("Failed to read file: " .. path, vim.log.levels.ERROR)
    return nil
  end

  return lines[1]
end

--- Debug logging function
---@param msg any Message to log (can be string or table)
function M.log(msg)
  local log_file = vim.fn.stdpath("cache") .. "/neoranger-debug.log"
  local f = io.open(log_file, "a")
  if not f then return end

  if type(msg) == "table" then
    msg = vim.inspect(msg)
  end

  f:write(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. msg .. "\n")
  f:close()
end

return M
