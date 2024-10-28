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

actions.bookmark = function()
  local hash = get_hash_from_line()
  vim.ui.input({ prompt = "Bookmark name for " .. hash .. ": " }, function(name)
    if name then
      editor_command.run(string.format("sl bookmark -f -r '%s' '%s'", hash, name))
      vim.cmd "edit %"
    end
  end)
end

actions.go_to = function()
  local hash = get_hash_from_line()
  editor_command.run(string.format("sl goto -r '%s'", hash))
end

actions.commit = function()
  editor_command.run "sl commit -v"
end

actions.undo = function()
  editor_command.run "sl undo"
end

local rebase = function(action)
  return function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local tmp_file = os.tmpname() .. ".sapling-rebase"
    local f = io.open(tmp_file, "w")
    if not f then
      return false
    end

    for _, line in ipairs(lines) do
      if line == vim.api.nvim_get_current_line() then
        f:write(action)
      else
        f:write "pick"
      end

      f:write(line:sub(3, -1) .. "\n")
    end

    f:close()

    editor_command.run(string.format("sl histedit --commands '%s'", tmp_file))
  end
end

actions.rebase_reorder = rebase "pick"
actions.rebase_roll = rebase "roll"

return actions
