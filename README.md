# nvim-bardic

Neovim support for [Bardic](https://github.com/katelouie/bardic), the Python-first interactive fiction engine and authoring system.

> Status: early implementation scaffold. The plugin is being built toward feature parity with the Bardic VSCode extension.

## Planned features

- `.bard` file detection using the `bardic` filetype.
- Syntax highlighting for Bardic passages, choices, directives, control flow, inline expressions, and Python blocks.
- Passage folding and snippets for common Bardic constructs.
- Bardic CLI integration for compile and lint workflows.
- Story graph view with image display, companion passage index, missing/orphan passage indicators, refresh, export, and jump-to-source navigation.
- Live passage preview with optional state injection.

## Installation

### Neovim built-in package manager: `vim.pack.add()`

```lua
vim.pack.add({
  { src = "https://github.com/feoh/nvim-bardic" },
})

require("bardic").setup()
```

### lazy.nvim

```lua
{
  "feoh/nvim-bardic",
  ft = "bardic",
  config = function()
    require("bardic").setup()
  end,
}
```

### packer.nvim

```lua
use({
  "feoh/nvim-bardic",
  config = function()
    require("bardic").setup()
  end,
})
```

### vim-plug

```vim
Plug 'feoh/nvim-bardic'
```

Then in Lua config:

```lua
require("bardic").setup()
```

### Manual package install

```bash
git clone https://github.com/feoh/nvim-bardic \
  ~/.local/share/nvim/site/pack/plugins/start/nvim-bardic
```

## Requirements

- Neovim 0.10+ is the target baseline.
- Bardic CLI/runtime for compile, lint, graph, and preview features:

  ```bash
  pip install bardic
  ```

- Optional graph image rendering support, likely via [image.nvim](https://github.com/3rd/image.nvim) or terminal graphics support.

## Configuration

```lua
require("bardic").setup({
  bardic_cmd = "bardic",
  python_cmd = nil,
  timeout_ms = 10000,
  prefer_cli = true,
  auto_refresh_graph = true,
  graph = {
    image_backend = "auto",
    open_command = nil,
  },
})
```

## Commands

The command surface is scaffolded and will be implemented incrementally:

- `:BardicCompile`
- `:BardicLint`
- `:BardicGraph`
- `:BardicGraphRefresh`
- `:BardicGraphExport`
- `:BardicPreview`

## License

MIT
