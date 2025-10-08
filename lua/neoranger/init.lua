local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Create a user command
  vim.api.nvim_create_user_command('Neoranger', function()
    print('Hello from neoranger!')
  end, {})
end

return M
