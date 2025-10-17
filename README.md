
# neoranger.nvim (WIP)

Ranger file manager in a floating window for Neovim.

## Features

- Opens ranger in a centered floating window
- Smart file opening: opens in current buffer if empty, otherwise in a new tab
- Change working directory to current file location
- No external dependencies (besides ranger itself)
- Customizable window size and border style
- Tab completion for directory paths

## Requirements

- Neovim >= 0.11.0
- Ranger file manager installed (`sudo apt install ranger` or `brew install ranger`)

## Install

**lazy.nvim:**
```lua
{
  "stianlyng/neoranger.nvim",
  config = function()
    require("neoranger").setup()
  end,
}
```

**nvim package manager:**
```lua
vim.pack.add({
  { src = "https://github.com/Stianlyng/neoranger.nvim.git" },
})

require('neoranger').setup()
```

**Manual:**

Auto-load:
```bash
git clone https://github.com/Stianlyng/neoranger.nvim.git ~/.config/nvim/pack/plugins/opt/neoranger.nvim
```

Optional-load:
```bash
git clone https://github.com/Stianlyng/neoranger.nvim.git ~/.config/nvim/pack/plugins/opt/neoranger.nvim
```

Then add this in your `init.lua`:
```lua
vim.cmd.packadd('neoranger.nvim')
require('neoranger').setup()
```

## Usage

### Commands

`:NeorangerFloat` - Opens ranger in a floating window

```vim
:NeorangerFloat          " Opens in current working directory
:NeorangerFloat ~/path   " Opens in specified directory
```

### API Functions

After setup, you can use these functions:

```lua
local neoranger = require("neoranger")

-- Toggle floating ranger window
neoranger.toggleFloat()                           -- Opens in current working directory
neoranger.toggleFloat({ cwd = "/some/path" })     -- Opens in specific directory
neoranger.toggleFloat({ cwd = vim.fn.expand("%:p:h") })  -- Opens in current file's directory

-- Change Neovim's working directory to current file's directory
neoranger.cdw()

-- Save Neovim servername to /tmp for external scripts
neoranger.save_servername()
```

### Keybind Examples

**Basic usage:**
```lua
-- Toggle ranger in current working directory
vim.keymap.set("n", "<leader>rc", function()
  require("neoranger").toggleFloat()
end, { desc = "Open ranger" })

-- Toggle ranger in current file's directory
vim.keymap.set("n", "<leader>rr", function()
  require("neoranger").toggleFloat({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Ranger in file dir" })
```

**Additional utilities:**
```lua
-- Save servername for external scripts
vim.keymap.set("n", "-", function()
  require("neoranger").save_servername()
end, { desc = "Save nvim servername" })

-- Change working directory to current file
vim.keymap.set("n", "<leader>cd", function()
  require("neoranger").cdw()
end, { desc = "CD to current file" })
```

### Inside Ranger

- **`q` or `<Esc>`**: Close the floating window
- **`l` or `<Enter>` on a file**: Open the selected file
  - If current buffer is empty → Opens in current buffer
  - If current buffer has content → Opens in a new tab
- All other ranger keybinds work as normal

## Configuration

Customize the plugin by passing options to `setup()`:

```lua
require("neoranger").setup({
  width = 0.8,          -- Percentage of screen width (0.8 = 80%)
  height = 0.8,         -- Percentage of screen height (0.8 = 80%)
  border = "rounded",   -- Border style: "rounded", "single", "double", "solid", "shadow"
  ranger_cmd = "ranger", -- Command to launch ranger (can use custom builds)
  choosefile_path = "/tmp/ranger_file_path",  -- Temp file for selected file path
  servername_path = "/tmp/nvim_servername",   -- Temp file for nvim servername
})
```

### Default Configuration

```lua
{
  width = 0.8,
  height = 0.8,
  border = "rounded",
  ranger_cmd = "ranger",
  choosefile_path = "/tmp/ranger_file_path",
  servername_path = "/tmp/nvim_servername",
}
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `width` | `float` | `0.8` | Floating window width as percentage of screen (0.0-1.0) |
| `height` | `float` | `0.8` | Floating window height as percentage of screen (0.0-1.0) |
| `border` | `string` | `"rounded"` | Border style: `"rounded"`, `"single"`, `"double"`, `"solid"`, `"shadow"` |
| `ranger_cmd` | `string` | `"ranger"` | Command to launch ranger (useful for custom ranger builds) |
| `choosefile_path` | `string` | `"/tmp/ranger_file_path"` | Temporary file path where ranger writes the selected file |
| `servername_path` | `string` | `"/tmp/nvim_servername"` | Temporary file path for storing nvim servername (for external scripts) |
