local actions = {}

---@return string
local get_hash_from_line = function()
  return vim.api.nvim_get_current_line():match "[0-9a-f]+"
end

actions.show_current_hash = function()
  local hash = get_hash_from_line()
  vim.cmd("edit sl://show/" .. hash)
end

return actions
