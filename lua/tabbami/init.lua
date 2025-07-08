local M = {}
local config_module = require('tabbami.config')
local providers = require('tabbami.providers')

-- Plugin configuration
M.config = {}

-- Current suggestion state
local current_suggestion = nil
local suggestion_ns = vim.api.nvim_create_namespace("tabbami_suggestion")
local debounce_timer = nil

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", config_module.defaults, opts or {})
  
  -- Validate configuration
  local valid, error_msg = config_module.validate(M.config)
  if not valid then
    vim.notify("Tabbami configuration error: " .. error_msg, vim.log.levels.ERROR)
    return
  end
  
  -- Create autocommands
  local group = vim.api.nvim_create_augroup("Tabbami", { clear = true })
  
  -- Trigger completion on text change (with debouncing)
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
    group = group,
    callback = function()
      M.trigger_completion_debounced()
    end,
  })
  
  -- Clear suggestion when leaving insert mode
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      M.clear_suggestion()
      M.cancel_debounce()
    end,
  })
  
  -- Setup key mappings
  M.setup_keymaps()
end

-- Setup key mappings
function M.setup_keymaps()
  local keymaps = M.config.keymaps or {}
  
  -- Accept suggestion
  vim.keymap.set("i", keymaps.accept or "<Tab>", function()
    if not M.accept_suggestion() then
      -- If no suggestion to accept, perform default tab behavior
      local tab_key = keymaps.accept or "<Tab>"
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(tab_key, true, true, true), "n", true)
    end
  end, { noremap = true, silent = true })
  
  -- Cancel suggestion
  vim.keymap.set("i", keymaps.cancel or "<Esc>", function()
    M.clear_suggestion()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", true)
  end, { noremap = true, silent = true })
  
  -- Manual trigger
  vim.keymap.set("i", keymaps.manual_trigger or "<C-Space>", function()
    M.complete()
  end, { noremap = true, silent = true })
end

-- Debounced completion trigger
function M.trigger_completion_debounced()
  M.cancel_debounce()
  
  debounce_timer = vim.defer_fn(function()
    M.trigger_completion()
  end, M.config.debounce_ms or 500)
end

-- Cancel debounce timer
function M.cancel_debounce()
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer = nil
  end
end

-- Get context for LLM
function M.get_context()
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  
  -- Get context configuration
  local context_before = M.config.context_lines_before or 10
  local context_after = M.config.context_lines_after or 5
  
  -- Get lines before and after cursor
  local lines_before = vim.api.nvim_buf_get_lines(buf, math.max(0, current_line - context_before), current_line, false)
  local lines_after = vim.api.nvim_buf_get_lines(buf, current_line, math.min(vim.api.nvim_buf_line_count(buf), current_line + context_after), false)
  
  -- Get current line and cursor position
  local current_line_text = vim.api.nvim_get_current_line()
  local col = cursor[2]
  
  return {
    before = table.concat(lines_before, "\n"),
    current = current_line_text,
    after = table.concat(lines_after, "\n"),
    cursor_col = col,
    filetype = vim.bo.filetype,
  }
end

-- Create LLM prompt
function M.create_prompt(context)
  local prompt = string.format([[
You are a code completion assistant. Based on the context provided, predict the next line of code that the user wants to write.

File type: %s

Code before cursor:
%s

Current line: %s
Cursor position: %d

Code after cursor:
%s

Instructions:
- Provide only the next line of code that should be written
- Do not include any explanation or additional text
- The response should be a single line that naturally continues the code
- Consider the existing code style and patterns
- If the current line is incomplete, complete it instead of adding a new line

Response (single line only):]], context.filetype, context.before, context.current, context.cursor_col, context.after)
  
  return prompt
end

-- Show suggestion in buffer
function M.show_suggestion(suggestion)
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  
  -- Clear previous suggestion
  M.clear_suggestion()
  
  -- Store current suggestion
  current_suggestion = {
    text = suggestion,
    line = line,
    buf = buf,
  }
  
  -- Show as virtual text
  vim.api.nvim_buf_set_extmark(buf, suggestion_ns, line - 1, 0, {
    virt_text = {{ suggestion, M.config.highlight_group }},
    virt_text_pos = "eol",
  })
end

-- Clear current suggestion
function M.clear_suggestion()
  if current_suggestion then
    vim.api.nvim_buf_clear_namespace(current_suggestion.buf, suggestion_ns, 0, -1)
    current_suggestion = nil
  end
end

-- Accept current suggestion
function M.accept_suggestion()
  if current_suggestion then
    local suggestion_text = current_suggestion.text
    M.clear_suggestion()
    
    -- Insert the suggestion
    vim.api.nvim_put({suggestion_text}, "l", true, true)
    
    return true
  else
    return false
  end
end

-- Trigger completion
function M.trigger_completion()
  -- Don't trigger if we already have a suggestion
  if current_suggestion then
    return
  end
  
  local context = M.get_context()
  local current_line = context.current
  
  -- Check if filetype is enabled
  if not config_module.is_enabled_for_filetype(M.config, context.filetype) then
    return
  end
  
  -- Check if we should trigger completion
  if #current_line < (M.config.trigger_length or 3) then
    return
  end
  
  -- Don't trigger on empty lines or lines with only whitespace
  if current_line:match("^%s*$") then
    return
  end
  
  local prompt = M.create_prompt(context)
  
  providers.get_completion(prompt, M.config, function(suggestion, error)
    if error then
      vim.notify("Tabbami error: " .. error, vim.log.levels.ERROR)
      return
    end
    
    if suggestion and suggestion ~= "" then
      vim.schedule(function()
        M.show_suggestion(suggestion)
      end)
    end
  end)
end

-- Manual trigger function
function M.complete()
  M.clear_suggestion()
  M.trigger_completion()
end

return M 