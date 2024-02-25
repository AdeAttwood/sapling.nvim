local client = {}

local SHOW_COMMAND = [[sl show -Tjson '%s']]
local LOG_COMMAND = [[sl log -r '%s']]

---@class HeadInfo
---@field node string
---@field remotenames string[]
---@field peerurls { [string]: string }

-- Get the head info from the current repo, this is only the minimal info
-- needed to create URLs.
--
---@return HeadInfo
client.head_info = function()
  local head_info = vim.fn.system [[sl log -r '.' -T"{dict(remotenames,node,peerurls)|json}"]]
  return vim.json.decode(head_info)
end

---@class ShowResult
---@field node string
---@field date table<number, number>
---@field user string
---@field phase string
---@field desc string
---@field diff string

--- Gets info about a single commit
--
---@param commit string The commit like to show
---@return ShowResult
client.show = function(commit)
  local result = vim.fn.system(SHOW_COMMAND:format(commit))
  local decoded = vim.json.decode(result)

  return decoded[1]
end

--- Runs the sapling log command and returns the output as a list of strings.
--
---@return string[]
client.log_text = function(pattern)
  return vim.fn.systemlist(LOG_COMMAND:format(pattern))
end

-- Runs `sl annotate` and returns the contents without the line contents. It
-- will also return the length of the longest item so you can create a window
-- the same length of its contents. You will also need to specify the ref of
-- the file so it annotates the correct version.
--
---@return number, string[]
client.annotate = function(ref, file)
  local annotate_command = vim.fn.systemlist(string.format("sl annotate -r '%s' '%s'", ref, file))
  local width = 0
  local result = {}

  for _, line in ipairs(annotate_command) do
    local parts = vim.split(line, ":")
    local ref_date_and_user = parts[1]
    local part_size = #ref_date_and_user

    if part_size > width then
      width = part_size
    end

    table.insert(result, ref_date_and_user)
  end

  return width, result
end

-- Run the diff command and return the output as a list of strings. If no param
-- is passed then it will return the diff of your current changes.
--
---@param ref string | nil
---@return string[]
client.diff = function(ref)
  if not ref or ref == "" then
    return vim.fn.systemlist("sl diff --git")
  end

  return vim.fn.systemlist(string.format("sl diff %s", ref))
end

client.STATUS_MODIFIED = "M"
client.STATUS_ADDED = "A"
client.STATUS_UNTRACKED = "?"
client.STATUS_REMOVED = "R"

---@alias Status "M" | "A" | "?" | "R"

---@class StatusItem
---@field status Status
---@field path string

-- Returns output of `sl status` as an array..
---@return StatusItem[]
client.status = function()
  return vim.json.decode(vim.fn.system("sl status -Tjson"))
end

return client
