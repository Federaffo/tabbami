local M = {}

-- Default configuration
M.defaults = {
  -- LLM Provider settings
  provider = "openai", -- "openai", "anthropic", "ollama", "custom"
  
  -- OpenAI settings
  openai = {
    api_key = os.getenv("OPENAI_API_KEY") or "",
    api_url = "https://api.openai.com/v1/chat/completions",
    model = "gpt-3.5-turbo",
    max_tokens = 150,
    temperature = 0.3,
  },
  
  -- Anthropic settings
  anthropic = {
    api_key = os.getenv("ANTHROPIC_API_KEY") or "",
    api_url = "https://api.anthropic.com/v1/messages",
    model = "claude-3-haiku-20240307",
    max_tokens = 150,
  },
  
  -- Ollama settings (local)
  ollama = {
    api_url = "http://localhost:11434/api/generate",
    model = "codellama:7b",
    stream = false,
  },
  
  -- Custom provider settings
  custom = {
    api_url = "",
    api_key = "",
    model = "",
    headers = {},
    request_formatter = nil, -- function(prompt) -> request_body
    response_parser = nil,   -- function(response) -> suggestion
  },
  
  -- Plugin behavior
  trigger_length = 3,
  max_suggestions = 1,
  timeout = 5000,
  debounce_ms = 500,
  
  -- Context settings
  context_lines_before = 10,
  context_lines_after = 5,
  
  -- UI configuration
  highlight_group = "Comment",
  accept_key = "<Tab>",
  cancel_key = "<Esc>",
  
  -- Keymaps
  keymaps = {
    accept = "<Tab>",
    cancel = "<Esc>",
    manual_trigger = "<C-Space>",
  },
  
  -- Filetypes to enable/disable
  enabled_filetypes = {}, -- empty means all filetypes
  disabled_filetypes = { "TelescopePrompt", "help", "alpha" },
  
  -- Logging
  log_level = "warn", -- "trace", "debug", "info", "warn", "error"
}

-- Get provider configuration
function M.get_provider_config(config)
  local provider = config.provider or "openai"
  return config[provider] or config.openai
end

-- Validate configuration
function M.validate(config)
  local provider = config.provider or "openai"
  local provider_config = config[provider]
  
  if not provider_config then
    return false, "Provider '" .. provider .. "' not configured"
  end
  
  if provider == "openai" and (not provider_config.api_key or provider_config.api_key == "") then
    return false, "OpenAI API key not configured. Set OPENAI_API_KEY environment variable or pass it in config."
  end
  
  if provider == "anthropic" and (not provider_config.api_key or provider_config.api_key == "") then
    return false, "Anthropic API key not configured. Set ANTHROPIC_API_KEY environment variable or pass it in config."
  end
  
  if provider == "custom" then
    if not provider_config.api_url or provider_config.api_url == "" then
      return false, "Custom provider requires api_url"
    end
    if not provider_config.request_formatter then
      return false, "Custom provider requires request_formatter function"
    end
    if not provider_config.response_parser then
      return false, "Custom provider requires response_parser function"
    end
  end
  
  return true, nil
end

-- Check if plugin should be enabled for current filetype
function M.is_enabled_for_filetype(config, filetype)
  -- Check disabled filetypes
  for _, ft in ipairs(config.disabled_filetypes or {}) do
    if ft == filetype then
      return false
    end
  end
  
  -- Check enabled filetypes (if specified)
  if config.enabled_filetypes and #config.enabled_filetypes > 0 then
    for _, ft in ipairs(config.enabled_filetypes) do
      if ft == filetype then
        return true
      end
    end
    return false
  end
  
  return true
end

return M 