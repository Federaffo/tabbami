local M = {}

-- OpenAI provider
M.openai = {
  create_request = function(prompt, config)
    return {
      model = config.model,
      messages = {
        {
          role = "user",
          content = prompt
        }
      },
      max_tokens = config.max_tokens,
      temperature = config.temperature,
      stream = false,
    }
  end,
  
  create_headers = function(config)
    return {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. config.api_key,
    }
  end,
  
  parse_response = function(response_text)
    local ok, response = pcall(vim.json.decode, response_text)
    if not ok then
      return nil, "Failed to parse JSON response"
    end
    
    if response.error then
      return nil, response.error.message or "Unknown API error"
    end
    
    if response.choices and response.choices[1] and response.choices[1].message then
      local content = response.choices[1].message.content
      return content:gsub("^%s*", ""):gsub("%s*$", ""), nil
    end
    
    return nil, "No completion found in response"
  end
}

-- Anthropic provider
M.anthropic = {
  create_request = function(prompt, config)
    return {
      model = config.model,
      max_tokens = config.max_tokens,
      messages = {
        {
          role = "user",
          content = prompt
        }
      }
    }
  end,
  
  create_headers = function(config)
    return {
      ["Content-Type"] = "application/json",
      ["x-api-key"] = config.api_key,
      ["anthropic-version"] = "2023-06-01",
    }
  end,
  
  parse_response = function(response_text)
    local ok, response = pcall(vim.json.decode, response_text)
    if not ok then
      return nil, "Failed to parse JSON response"
    end
    
    if response.error then
      return nil, response.error.message or "Unknown API error"
    end
    
    if response.content and response.content[1] and response.content[1].text then
      local content = response.content[1].text
      return content:gsub("^%s*", ""):gsub("%s*$", ""), nil
    end
    
    return nil, "No completion found in response"
  end
}

-- Ollama provider
M.ollama = {
  create_request = function(prompt, config)
    return {
      model = config.model,
      prompt = prompt,
      stream = config.stream or false,
      options = {
        temperature = 0.3,
        top_p = 0.9,
      }
    }
  end,
  
  create_headers = function(config)
    return {
      ["Content-Type"] = "application/json",
    }
  end,
  
  parse_response = function(response_text)
    local ok, response = pcall(vim.json.decode, response_text)
    if not ok then
      return nil, "Failed to parse JSON response"
    end
    
    if response.error then
      return nil, response.error
    end
    
    if response.response then
      local content = response.response
      return content:gsub("^%s*", ""):gsub("%s*$", ""), nil
    end
    
    return nil, "No completion found in response"
  end
}

-- Make HTTP request
function M.make_request(url, headers, data, callback)
  local json_data = vim.json.encode(data)
  
  -- Build curl command
  local cmd = { "curl", "-s", "-X", "POST", url }
  
  -- Add headers
  for key, value in pairs(headers) do
    table.insert(cmd, "-H")
    table.insert(cmd, key .. ": " .. value)
  end
  
  -- Add data
  table.insert(cmd, "-d")
  table.insert(cmd, json_data)
  
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local response_text = table.concat(data, "\n")
        if response_text and response_text ~= "" then
          callback(response_text, nil)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_text = table.concat(data, "\n")
        callback(nil, error_text)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        callback(nil, "Request failed with exit code: " .. exit_code)
      end
    end,
  })
end

-- Main function to get completion from provider
function M.get_completion(prompt, config, callback)
  local provider_name = config.provider or "openai"
  local provider_config = require('tabbami.config').get_provider_config(config)
  local provider = M[provider_name]
  
  if not provider then
    callback(nil, "Unsupported provider: " .. provider_name)
    return
  end
  
  -- Handle custom provider
  if provider_name == "custom" then
    if provider_config.request_formatter and provider_config.response_parser then
      local request_data = provider_config.request_formatter(prompt)
      local headers = provider_config.headers or {}
      
      if provider_config.api_key then
        headers["Authorization"] = "Bearer " .. provider_config.api_key
      end
      
      M.make_request(provider_config.api_url, headers, request_data, function(response, error)
        if error then
          callback(nil, error)
          return
        end
        
        local suggestion, parse_error = provider_config.response_parser(response)
        callback(suggestion, parse_error)
      end)
    else
      callback(nil, "Custom provider not properly configured")
    end
    return
  end
  
  -- Handle built-in providers
  local request_data = provider.create_request(prompt, provider_config)
  local headers = provider.create_headers(provider_config)
  
  M.make_request(provider_config.api_url, headers, request_data, function(response, error)
    if error then
      callback(nil, error)
      return
    end
    
    local suggestion, parse_error = provider.parse_response(response)
    callback(suggestion, parse_error)
  end)
end

return M 