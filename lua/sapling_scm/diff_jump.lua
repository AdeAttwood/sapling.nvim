local client = require "sapling_scm.client"

local diff_jump = {}

local normalize_diff_path = function(path)
  if path == "/dev/null" then
    return nil
  end

  if path:sub(1, 1) == '"' and path:sub(-1) == '"' then
    path = path:sub(2, -2):gsub('\\"', '"')
  end

  if path:sub(1, 2) == "a/" or path:sub(1, 2) == "b/" then
    return path:sub(3)
  end

  return path
end

---@param line string
---@return table | nil
local parse_hunk_header = function(line)
  local old_start, old_count, new_start, new_count = line:match "^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@"
  if not old_start then
    return nil
  end

  local normalize_count = function(count)
    if count == "" then
      return 1
    end

    return tonumber(count)
  end

  return {
    old_start = tonumber(old_start),
    old_count = normalize_count(old_count),
    new_start = tonumber(new_start),
    new_count = normalize_count(new_count),
  }
end

---@param line string
---@return string
local classify_diff_line = function(line)
  if line:match [[^\\ No newline at end of file$]] then
    return "meta"
  end

  local prefix = line:sub(1, 1)
  if prefix == "+" then
    return "add"
  end

  if prefix == "-" then
    return "remove"
  end

  if prefix == " " then
    return "context"
  end

  return "other"
end

---@param lines string[]
---@param cursor_line number
---@return number | nil, number | nil
local find_file_bounds = function(lines, cursor_line)
  local start_line
  for line_number = cursor_line, 1, -1 do
    if lines[line_number]:match "^diff %-%-git " then
      start_line = line_number
      break
    end
  end

  if not start_line then
    return nil, nil
  end

  local end_line = #lines
  for line_number = start_line + 1, #lines do
    if lines[line_number]:match "^diff %-%-git " then
      end_line = line_number - 1
      break
    end
  end

  return start_line, end_line
end

---@param lines string[]
---@param start_line number
---@param end_line number
---@return string | nil
local find_new_path = function(lines, start_line, end_line)
  for line_number = start_line, end_line do
    local path = lines[line_number]:match "^%+%+%+ (.*)$"
    if path then
      return normalize_diff_path(path)
    end
  end

  return nil
end

---@param lines string[]
---@param start_line number
---@param end_line number
---@param cursor_line number
---@return number | nil, table | nil
local find_hunk = function(lines, start_line, end_line, cursor_line)
  for line_number = cursor_line, start_line, -1 do
    local hunk = parse_hunk_header(lines[line_number])
    if hunk then
      return line_number, hunk
    end
  end

  for line_number = start_line, end_line do
    local hunk = parse_hunk_header(lines[line_number])
    if hunk then
      return line_number, hunk
    end
  end

  return nil, nil
end

---@param lines string[]
---@param cursor_line number
---@return { file: string, line: number } | nil, string | nil
function diff_jump.location_from_lines(lines, cursor_line)
  local start_line, end_line = find_file_bounds(lines, cursor_line)
  if not start_line or not end_line then
    return nil, "no diff target found on this line"
  end

  local file = find_new_path(lines, start_line, end_line)
  if not file then
    return nil, "no new-side target for this file"
  end

  local hunk_line, hunk = find_hunk(lines, start_line, end_line, cursor_line)
  if not hunk_line or not hunk then
    return nil, "no hunk target found for this file"
  end

  local target_line = hunk.new_start
  for line_number = hunk_line + 1, cursor_line - 1 do
    local kind = classify_diff_line(lines[line_number])
    if kind == "add" or kind == "context" then
      target_line = target_line + 1
    end
  end

  return { file = file, line = target_line }, nil
end

---@param buf integer
---@return { action: string, commit: string | nil, file: string | nil } | nil
local get_buffer_source = function(buf)
  local ok_action, action = pcall(vim.api.nvim_buf_get_var, buf, "sapling_diff_action")
  if ok_action and action then
    local ok_commit, commit = pcall(vim.api.nvim_buf_get_var, buf, "sapling_show_commit")
    return { action = action, commit = ok_commit and commit or nil, file = nil }
  end

  local name = vim.api.nvim_buf_get_name(buf)
  local show_commit = name:match "^sl://show/(.*)$"
  if show_commit then
    return { action = "show", commit = show_commit, file = nil }
  end

  if name:match "^sl://diff/" then
    return { action = "diff", commit = nil, file = nil }
  end

  local _, cat_file = name:match "^sl://cat/([^/]+)/(.*)$"
  if cat_file then
    return { action = "cat", commit = nil, file = cat_file }
  end

  return nil
end

---@param buf integer
---@param cursor_line number
---@return { action: string, file: string, line: number, path: string | nil, url: string | nil } | nil, string | nil
function diff_jump.target_from_buffer(buf, cursor_line)
  local source = get_buffer_source(buf)
  if not source or source.action == "cat" then
    return nil, "not a sapling diff buffer"
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local location, err = diff_jump.location_from_lines(lines, cursor_line)
  if not location then
    return nil, err
  end

  if source.action == "show" then
    if not source.commit then
      return nil, "no shown revision found for this buffer"
    end

    return {
      action = "show",
      file = location.file,
      line = location.line,
      path = nil,
      url = string.format("sl://cat/%s/%s", source.commit, location.file),
    },
      nil
  end

  return {
    action = "diff",
    file = location.file,
    line = location.line,
    path = location.file,
    url = nil,
  },
    nil
end

---@param buf integer
---@param cursor_line number
---@return { file: string, line: number } | nil, string | nil
function diff_jump.working_copy_target_from_buffer(buf, cursor_line)
  local source = get_buffer_source(buf)
  if not source then
    return nil, "not a sapling buffer"
  end

  if source.action == "cat" then
    if not source.file then
      return nil, "no file found for this buffer"
    end

    return {
      file = source.file,
      line = cursor_line,
    }, nil
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return diff_jump.location_from_lines(lines, cursor_line)
end

---@param current_win integer
---@return integer
local find_destination_window = function(current_win)
  local previous_window_number = vim.fn.winnr "#"
  if previous_window_number > 0 then
    local previous_window = vim.fn.win_getid(previous_window_number)
    if previous_window ~= current_win and vim.api.nvim_win_is_valid(previous_window) then
      local previous_buffer = vim.api.nvim_win_get_buf(previous_window)
      local previous_name = vim.api.nvim_buf_get_name(previous_buffer)
      if not previous_name:match "^sl://" then
        return previous_window
      end
    end
  end

  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if window ~= current_win then
      local buffer = vim.api.nvim_win_get_buf(window)
      local name = vim.api.nvim_buf_get_name(buffer)
      if not name:match "^sl://" then
        return window
      end
    end
  end

  return current_win
end

---@param line_number number
local set_cursor = function(line_number)
  local line_count = vim.api.nvim_buf_line_count(0)
  local clamped = math.max(1, math.min(line_number, line_count))
  vim.api.nvim_win_set_cursor(0, { clamped, 0 })
end

---@param file string
---@return string | nil, string | nil
local resolve_working_copy_path = function(file)
  local root = client.root()
  if not root or root == "" then
    return nil, "could not determine repository root"
  end

  local path = vim.fn.simplify(root .. "/" .. file)
  if vim.fn.filereadable(path) ~= 1 then
    return nil, "working copy file not found: " .. file
  end

  return path, nil
end

---@param destination_window integer
---@param target { file: string, line: number }
---@return boolean, string | nil
local open_working_copy_target = function(destination_window, target)
  local path, err = resolve_working_copy_path(target.file)
  if not path then
    return false, err
  end

  vim.api.nvim_set_current_win(destination_window)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  set_cursor(target.line)

  return true, nil
end

function diff_jump.jump()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local target, err = diff_jump.target_from_buffer(vim.api.nvim_get_current_buf(), cursor[1])
  if not target then
    vim.notify("Sapling: " .. err, vim.log.levels.INFO)
    return false
  end

  local destination_window = find_destination_window(vim.api.nvim_get_current_win())

  if target.action == "show" and target.url then
    vim.api.nvim_set_current_win(destination_window)
    vim.cmd("edit " .. vim.fn.fnameescape(target.url))
    set_cursor(target.line)
    return true
  end

  if target.file then
    local ok, open_err = open_working_copy_target(destination_window, {
      file = target.file,
      line = target.line,
    })
    if ok then
      return true
    end

    vim.notify("Sapling: " .. open_err, vim.log.levels.INFO)
    return false
  end

  vim.notify("Sapling: no jump target found", vim.log.levels.INFO)
  return false
end

function diff_jump.edit_working_copy()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local target, err = diff_jump.working_copy_target_from_buffer(vim.api.nvim_get_current_buf(), cursor[1])
  if not target then
    vim.notify("Sapling: " .. err, vim.log.levels.INFO)
    return false
  end

  local ok, open_err = open_working_copy_target(find_destination_window(vim.api.nvim_get_current_win()), target)
  if ok then
    return true
  end

  vim.notify("Sapling: " .. open_err, vim.log.levels.INFO)
  return false
end

return diff_jump
