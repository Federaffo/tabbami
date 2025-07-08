# Tabbami

A Neovim plugin that provides AI-powered code completion using Large Language Models (LLMs). Get intelligent code suggestions as you type and accept them with Tab.

## Features

- 🤖 **Multiple LLM Providers**: Support for OpenAI, Anthropic, Ollama, and custom providers
- ⚡ **Real-time Suggestions**: Get code predictions as you type
- 🔧 **Configurable**: Extensive configuration options for behavior and appearance
- 🎯 **Context Aware**: Uses surrounding code context for better predictions
- 🚀 **Lightweight**: Minimal impact on editor performance
- 📝 **Filetype Support**: Works with all programming languages

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/tabbami",
  config = function()
    require("tabbami").setup({
      provider = "openai",
      openai = {
        api_key = os.getenv("OPENAI_API_KEY"),
        model = "gpt-3.5-turbo",
      }
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/tabbami",
  config = function()
    require("tabbami").setup({
      provider = "openai",
      openai = {
        api_key = os.getenv("OPENAI_API_KEY"),
        model = "gpt-3.5-turbo",
      }
    })
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'your-username/tabbami'
```

Then add to your `init.lua`:

```lua
require("tabbami").setup({
  provider = "openai",
  openai = {
    api_key = os.getenv("OPENAI_API_KEY"),
    model = "gpt-3.5-turbo",
  }
})
```

## Configuration

### Default Configuration

```lua
require("tabbami").setup({
  -- LLM Provider
  provider = "openai", -- "openai", "anthropic", "ollama", "custom"
  
  -- OpenAI Configuration
  openai = {
    api_key = os.getenv("OPENAI_API_KEY"),
    api_url = "https://api.openai.com/v1/chat/completions",
    model = "gpt-3.5-turbo",
    max_tokens = 150,
    temperature = 0.3,
  },
  
  -- Plugin Behavior
  trigger_length = 3,      -- Minimum characters to trigger completion
  debounce_ms = 500,       -- Debounce delay in milliseconds
  context_lines_before = 10, -- Lines of context before cursor
  context_lines_after = 5,   -- Lines of context after cursor
  
  -- UI Configuration
  highlight_group = "Comment", -- Highlight group for suggestions
  
  -- Key Mappings
  keymaps = {
    accept = "<Tab>",           -- Accept suggestion
    cancel = "<Esc>",           -- Cancel suggestion
    manual_trigger = "<C-Space>", -- Manual trigger
  },
  
  -- Filetype Configuration
  enabled_filetypes = {},  -- Empty means all filetypes
  disabled_filetypes = { "TelescopePrompt", "help", "alpha" },
})
```

### Provider Configurations

#### OpenAI

```lua
require("tabbami").setup({
  provider = "openai",
  openai = {
    api_key = os.getenv("OPENAI_API_KEY"),
    model = "gpt-4", -- or "gpt-3.5-turbo"
    temperature = 0.2,
    max_tokens = 200,
  }
})
```

#### Anthropic (Claude)

```lua
require("tabbami").setup({
  provider = "anthropic",
  anthropic = {
    api_key = os.getenv("ANTHROPIC_API_KEY"),
    model = "claude-3-haiku-20240307",
    max_tokens = 150,
  }
})
```

#### Ollama (Local)

```lua
require("tabbami").setup({
  provider = "ollama",
  ollama = {
    api_url = "http://localhost:11434/api/generate",
    model = "codellama:7b",
    stream = false,
  }
})
```

#### Custom Provider

```lua
require("tabbami").setup({
  provider = "custom",
  custom = {
    api_url = "https://your-api.com/completions",
    api_key = "your-api-key",
    headers = {
      ["Custom-Header"] = "value",
    },
    request_formatter = function(prompt)
      return {
        prompt = prompt,
        max_tokens = 150,
        temperature = 0.3,
      }
    end,
    response_parser = function(response)
      local data = vim.json.decode(response)
      return data.completion, nil
    end,
  }
})
```

## Usage

### Basic Usage

1. Start typing in insert mode
2. After typing a few characters, Tabbami will show suggestions as virtual text
3. Press `<Tab>` to accept the suggestion
4. Press `<Esc>` to cancel the suggestion

### Manual Trigger

You can manually trigger completion by pressing `<C-Space>` (or your configured key) in insert mode.

### Commands

- `:TabbamiaComplete` - Manually trigger completion
- `:TabbamiaSetup` - Reconfigure the plugin

## Environment Variables

Set up your API keys as environment variables:

```bash
# For OpenAI
export OPENAI_API_KEY="your-openai-api-key"

# For Anthropic
export ANTHROPIC_API_KEY="your-anthropic-api-key"
```

## Customization

### Custom Highlight Groups

You can customize the appearance of suggestions by setting a custom highlight group:

```lua
-- Set custom highlight
vim.cmd[[highlight TabbamaiSuggestion guifg=#808080 gui=italic]]

require("tabbami").setup({
  highlight_group = "TabbamaiSuggestion",
})
```

### Filetype-Specific Configuration

Enable only for specific filetypes:

```lua
require("tabbami").setup({
  enabled_filetypes = { "python", "javascript", "lua" },
})
```

Or disable for specific filetypes:

```lua
require("tabbami").setup({
  disabled_filetypes = { "markdown", "text", "help" },
})
```

### Custom Key Mappings

```lua
require("tabbami").setup({
  keymaps = {
    accept = "<C-y>",        -- Accept with Ctrl+y
    cancel = "<C-e>",        -- Cancel with Ctrl+e
    manual_trigger = "<C-j>", -- Manual trigger with Ctrl+j
  },
})
```

## Troubleshooting

### Common Issues

1. **No suggestions appearing**
   - Check that your API key is properly set
   - Verify the provider is correctly configured
   - Ensure the filetype is not disabled

2. **Slow performance**
   - Increase `debounce_ms` value
   - Reduce `context_lines_before` and `context_lines_after`

3. **API errors**
   - Check your API key and quota
   - Verify the API URL is correct
   - Check network connectivity

### Debug Mode

Enable debug logging to troubleshoot issues:

```lua
require("tabbami").setup({
  log_level = "debug",
})
```

## Requirements

- Neovim 0.8+
- `curl` command available in PATH
- Internet connection (for cloud providers)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details. 