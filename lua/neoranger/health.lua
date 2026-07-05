local M = {}

--- Runs on `:checkhealth neoranger`.
function M.check()
	local health = vim.health

	health.start("neoranger")

	if vim.fn.has("nvim-0.11.0") == 1 then
		health.ok("Neovim >= 0.11.0")
	else
		health.error("Neovim >= 0.11.0 is required")
	end

	local cmd = require("neoranger").config.ranger_cmd
	local exe = type(cmd) == "table" and cmd[1] or cmd
	if vim.fn.executable(exe) == 1 then
		health.ok(("'%s' found at %s"):format(exe, vim.fn.exepath(exe)))
	else
		health.error(("'%s' is not executable"):format(exe), {
			"Install ranger (https://github.com/ranger/ranger), e.g. `sudo apt install ranger` or `brew install ranger`",
			"Or point `ranger_cmd` in setup() at your ranger binary",
		})
	end
end

return M
