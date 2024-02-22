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

return client
