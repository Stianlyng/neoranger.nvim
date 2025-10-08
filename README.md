# neoranger.nvim

A dependency-free integration of Ranger into Neovim. 

## Installation

Using nvim package manager:
```lua
vim.pack.add({
  { src = "https://github.com/Stianlyng/neovim-plugin-starter.git" },
})

require('neoranger').setup()

```

Using lazy.nvim:
```lua
{
  "Stianlyng/neoranger.nvim",
  config = function()
    require("neoranger").setup()
  end,
}
```

Native manual nvim approach:
- clone into `~/.config/nvim/pack/plugins/opt`

```lua
vim.cmd.packadd('neoranger.nvim')
require('neoranger').setup()
```

## Usage

Run the command:
```
:HelloPlugin
```

This will print "Hello from my plugin!" to the message area.
