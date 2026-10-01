# tuios-nvim-navigator

Seamless navigation between Neovim splits and TUIOS panes.

The plugin first moves between Neovim splits. When the current split is at an edge, it emits a
private terminal sequence that TUIOS can use to focus the adjacent TUIOS pane.

Requires TUIOS with Neovim pane navigation support.

[![Démo](assets/demo.gif)](assets/demo-sdr.mp4)

## Installation

With lazy.nvim:

```lua
{
  "Tim4c/tuios-nvim-navigator",
  config = function()
    require("tuios-nvim-navigator").setup()
  end,
}
```

## Configuration

The default mappings are `Ctrl+h/j/k/l` in normal mode:

```lua
require("tuios-nvim-navigator").setup({
  keymaps = {
    left = "<C-h>",
    down = "<C-j>",
    up = "<C-k>",
    right = "<C-l>",
  },
})
```
