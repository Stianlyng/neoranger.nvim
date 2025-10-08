
# neoranger.nvim

Ranger in a floating window.

## What it does

- Opens files in new tabs
- todo; change working directory
- No dependencies

## Requirements

- Neovim 0.12 Nightly (only tested there, might work elsewhere idk)
- Ranger installed 

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

## How to use

### Command

`:Neoranger` opens it. That's the whole command.

```vim
:Neoranger          " current dir
:Neoranger ~/path   " some other dir
```

### Keybind examples:

```lua
-- basic toggle
vim.keymap.set("n", "<leader>fr", function()
  require("neoranger").toggle()
end, { desc = "Toggle Ranger" })

-- open where your current file lives
vim.keymap.set("n", "<leader>fc", function()
  require("neoranger").toggle({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Toggle Ranger (current file dir)" })
```

### Inside ranger

- `q` or `<Esc>`: close the window
- `l` or `<Enter>` on a file: opens it
  - If current buffer is empty → Opens in current buffer
  - If current buffer has content → Opens in new tab
- Regular `q` to quit ranger without picking anything

## Config

Tweak it by passing options to `setup()`:

```lua
require("neoranger").setup({
  width = 0.8,          -- percentage of screen
  height = 0.8,
  border = "rounded",   -- "rounded", "single", "double", "solid", "shadow"
  ranger_cmd = "ranger",
})
```

**Defaults:**
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
