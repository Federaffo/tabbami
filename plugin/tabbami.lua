-- Prevent loading twice
if vim.g.loaded_tabbami then
  return
end
vim.g.loaded_tabbami = true

-- Create user commands
vim.api.nvim_create_user_command('TabbamiaComplete', function()
  require('tabbami').complete()
end, {
  desc = 'Manually trigger Tabbami completion'
})

vim.api.nvim_create_user_command('TabbamiaSetup', function(opts)
  local config = {}
  if opts.args and opts.args ~= "" then
    config = vim.json.decode(opts.args)
  end
  require('tabbami').setup(config)
end, {
  desc = 'Setup Tabbami plugin with configuration',
  nargs = '?'
})

-- Auto-setup with default configuration if not already set up
local tabbami = require('tabbami')
if not tabbami.config.setup_done then
  tabbami.setup()
  tabbami.config.setup_done = true
end 