local editor_command = require "sapling_scm.editor_command"
local actions = {}

---@return string
local get_hash_from_line = function()
  return vim.api.nvim_get_current_line():match "[0-9a-f]+"
end

actions.show_current_hash = function()
  local hash = get_hash_from_line()
  vim.cmd("edit sl://show/" .. hash)
end

actions.metaedit = function()
  local hash = get_hash_from_line()
  editor_command.run(string.format("sl metaedit -r '%s'", hash))
end

actions.commit = function()
  editor_command.run "sl commit -v"
end

return actions
