local editor_command = {}

local edit_script = [[
#!/bin/sh

TMP_SCRIPT="%s"
printf "sapling_edit:$1" >&2
while [ ! -f "$TMP_SCRIPT.exit" ]; do sleep 0.05 2>/dev/null || sleep 1; done
exit 0
]]

-- Write content to a file and return true if successful
--
---@return boolean
local write_file = function(name, content)
  local f = io.open(name, "w")
  if not f then
    return false
  end

  f:write(content)
  f:close()

  return true
end

-- Edits a file in the current nvim process and calls on_close when the buffer
-- is closed.
local edit_in_vim = function(file, on_close)
  vim.cmd("tabnew | edit " .. file)

  vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete", "TabClosed" }, {
    buffer = 0,
    callback = on_close,
  })
end

-- Run a command that will require you to edit a file. For commands like
-- metaedit and commit, this will open an editor. Because we are already in an
-- editor, we will open the file in the current editor and do some tricks to
-- pause the command until the file is closed.
--
---@param command string The command to run i.e. `sl commit`
editor_command.run = function(command)
  local tmp_file = os.tmpname() .. ".sapling-nvim"

  write_file(tmp_file, string.format(edit_script, tmp_file))

  vim.fn.jobstart(command, {
    env = { EDITOR = "sh " .. tmp_file },
    on_exit = function()
      vim.cmd "edit %"
    end,
    on_stderr = function(_, data)
      for _, v in ipairs(data) do
        local file = string.match(v, "sapling_edit:(.*)")
        if file then
          edit_in_vim(file, function()
            write_file(tmp_file .. ".exit", "")
          end)
        end
      end
    end,
  })
end

editor_command.terminal = function(command)
  -- If we are on a sapling buffer when we run the terminal command, then we
  -- want to reload it when we are done running the command. The view may have
  -- changed like the log buffer.
  local buffer_name = vim.api.nvim_buf_get_name(0)
  if string.match(buffer_name, "^sl://") then
    local cmd_id = nil
    cmd_id = vim.api.nvim_create_autocmd({ "BufEnter" }, {
      buffer = 0,
      callback = function()
        vim.schedule(function()
          vim.cmd("edit " .. buffer_name)
        end)

        vim.api.nvim_del_autocmd(cmd_id)
      end,
    })
  end

  local tmp_file = os.tmpname() .. ".sapling-nvim"

  write_file(tmp_file, string.format(edit_script, tmp_file))

  vim.cmd "tabnew"

  vim.fn.termopen(command, {
    env = { EDITOR = "sh " .. tmp_file },
    on_stdout = function(_, data)
      for _, v in ipairs(data) do
        local file = string.match(v, "sapling_edit:(.*)")
        if file then
          edit_in_vim(file, function()
            write_file(tmp_file .. ".exit", "")
          end)
        end
      end
    end,
  })

  vim.cmd "file term://sapling"
  vim.cmd "startinsert"
end

return editor_command
