local client = {}

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

return client
