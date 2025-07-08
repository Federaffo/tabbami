-- Basic test script for Tabbami plugin
local tabbami = require('tabbami')
local config = require('tabbami.config')
local providers = require('tabbami.providers')

-- Test configuration validation
print("Testing configuration validation...")

-- Test valid OpenAI config
local valid_config = {
  provider = "openai",
  openai = {
    api_key = "test_key",
    model = "gpt-3.5-turbo",
  }
}

local is_valid, error_msg = config.validate(valid_config)
assert(is_valid, "Valid config should pass validation")
print("✓ Valid OpenAI config passed validation")

-- Test invalid config (missing API key)
local invalid_config = {
  provider = "openai",
  openai = {
    api_key = "",
    model = "gpt-3.5-turbo",
  }
}

local is_valid, error_msg = config.validate(invalid_config)
assert(not is_valid, "Invalid config should fail validation")
print("✓ Invalid config correctly failed validation: " .. error_msg)

-- Test filetype checking
print("\nTesting filetype filtering...")

local test_config = {
  enabled_filetypes = { "lua", "python" },
  disabled_filetypes = { "help", "alpha" }
}

assert(config.is_enabled_for_filetype(test_config, "lua"), "Lua should be enabled")
assert(config.is_enabled_for_filetype(test_config, "python"), "Python should be enabled")
assert(not config.is_enabled_for_filetype(test_config, "javascript"), "JavaScript should be disabled (not in enabled list)")
assert(not config.is_enabled_for_filetype(test_config, "help"), "Help should be disabled")
print("✓ Filetype filtering works correctly")

-- Test provider configuration
print("\nTesting provider configuration...")

local provider_config = config.get_provider_config(valid_config)
assert(provider_config.api_key == "test_key", "Should get correct provider config")
assert(provider_config.model == "gpt-3.5-turbo", "Should get correct model")
print("✓ Provider configuration retrieval works")

-- Test OpenAI request creation
print("\nTesting OpenAI request creation...")

local openai_provider = providers.openai
local test_prompt = "Complete this function"
local openai_config = {
  model = "gpt-3.5-turbo",
  max_tokens = 150,
  temperature = 0.3,
  api_key = "test_key"
}

local request = openai_provider.create_request(test_prompt, openai_config)
assert(request.model == "gpt-3.5-turbo", "Request should have correct model")
assert(request.messages[1].content == test_prompt, "Request should have correct prompt")
print("✓ OpenAI request creation works")

local headers = openai_provider.create_headers(openai_config)
assert(headers["Authorization"] == "Bearer test_key", "Headers should have correct auth")
print("✓ OpenAI headers creation works")

-- Test response parsing
print("\nTesting response parsing...")

local test_response = '{"choices":[{"message":{"content":"  console.log(\\"Hello\\");  "}}]}'
local suggestion, error = openai_provider.parse_response(test_response)
assert(suggestion == 'console.log("Hello");', "Should parse and trim response correctly")
assert(error == nil, "Should not have error for valid response")
print("✓ Response parsing works correctly")

-- Test error response
local error_response = '{"error":{"message":"Invalid API key"}}'
local suggestion, error = openai_provider.parse_response(error_response)
assert(suggestion == nil, "Should not have suggestion for error response")
assert(error == "Invalid API key", "Should return correct error message")
print("✓ Error response handling works")

-- Test plugin setup
print("\nTesting plugin setup...")

local test_setup_config = {
  provider = "openai",
  openai = {
    api_key = "test_key",
    model = "gpt-3.5-turbo",
  },
  trigger_length = 5,
  debounce_ms = 1000,
}

-- Mock vim functions for testing
_G.vim = _G.vim or {}
_G.vim.tbl_deep_extend = function(behavior, ...)
  local result = {}
  for _, tbl in ipairs({...}) do
    for k, v in pairs(tbl) do
      result[k] = v
    end
  end
  return result
end

_G.vim.notify = function(msg, level)
  if level == vim.log.levels.ERROR then
    error(msg)
  end
  print("NOTIFY: " .. msg)
end

_G.vim.log = { levels = { ERROR = 1, WARN = 2, INFO = 3 } }

-- Test setup without errors
local success = pcall(function()
  -- Mock vim API functions
  _G.vim.api = {
    nvim_create_augroup = function() return 1 end,
    nvim_create_autocmd = function() end,
    nvim_create_namespace = function() return 1 end,
  }
  _G.vim.keymap = {
    set = function() end,
  }
  _G.vim.defer_fn = function(fn, ms) return { stop = function() end } end
  
  tabbami.setup(test_setup_config)
end)

assert(success, "Plugin setup should succeed with valid config")
print("✓ Plugin setup works correctly")

print("\nAll tests passed! ✓") 