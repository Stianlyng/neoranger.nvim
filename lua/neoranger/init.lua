local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Create a user command
  vim.api.nvim_create_user_command('HelloPlugin', function()
    print('Hello from my plugin!')
  end, {})
end

return M
