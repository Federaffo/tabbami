-- Example Tabbami configuration
-- Copy this to your Neovim config and modify as needed

-- Basic OpenAI setup
require("tabbami").setup({
  provider = "openai",
  openai = {
    api_key = os.getenv("OPENAI_API_KEY"),
    model = "gpt-3.5-turbo",
  }
})

--[[
-- Advanced configuration example
require("tabbami").setup({
  -- Provider selection
  provider = "openai", -- "openai", "anthropic", "ollama", "custom"
  
  -- OpenAI configuration
  openai = {
    api_key = os.getenv("OPENAI_API_KEY"),
    model = "gpt-4", -- or "gpt-3.5-turbo"
    temperature = 0.2,
    max_tokens = 200,
  },
  
  -- Behavior settings
  trigger_length = 4,        -- Trigger after 4 characters
  debounce_ms = 300,         -- Faster response
  context_lines_before = 15, -- More context
  context_lines_after = 8,
  
  -- UI customization
  highlight_group = "Comment",
  
  -- Custom key mappings
  keymaps = {
    accept = "<C-y>",          -- Accept with Ctrl+y instead of Tab
    cancel = "<C-e>",          -- Cancel with Ctrl+e
    manual_trigger = "<C-j>",  -- Manual trigger with Ctrl+j
  },
  
  -- Filetype configuration
  enabled_filetypes = { "python", "javascript", "typescript", "lua", "go", "rust" },
  disabled_filetypes = { "markdown", "text", "help", "alpha" },
})
--]]

--[[
-- Ollama (local) setup example
require("tabbami").setup({
  provider = "ollama",
  ollama = {
    api_url = "http://localhost:11434/api/generate",
    model = "codellama:7b", -- or "codellama:13b", "codellama:34b"
    stream = false,
  }
})
--]]

--[[
-- Anthropic (Claude) setup example
require("tabbami").setup({
  provider = "anthropic",
  anthropic = {
    api_key = os.getenv("ANTHROPIC_API_KEY"),
    model = "claude-3-haiku-20240307",
    max_tokens = 150,
  }
})
--]]

--[[
-- Multiple providers with fallback example
local tabbami = require("tabbami")

-- Try OpenAI first
if os.getenv("OPENAI_API_KEY") then
  tabbami.setup({
    provider = "openai",
    openai = {
      api_key = os.getenv("OPENAI_API_KEY"),
      model = "gpt-3.5-turbo",
    }
  })
-- Fall back to Ollama if available
elseif vim.fn.executable("curl") == 1 then
  tabbami.setup({
    provider = "ollama",
    ollama = {
      api_url = "http://localhost:11434/api/generate",
      model = "codellama:7b",
    }
  })
end
--]] 