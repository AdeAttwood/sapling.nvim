local remote_url = {}

---@param head_info HeadInfo
---@return string
local function get_object_ref(head_info)
  if #head_info.remotenames > 0 then
    local remote_name, _ = head_info.remotenames[1]:gsub("remote/", "")
    return remote_name
  end

  return head_info.node
end

---@param head_info HeadInfo
---@return string
remote_url.blob = function(head_info)
  local url = head_info.peerurls["default"]:gsub(".git$", "")
  local object_ref = get_object_ref(head_info)

  return string.format("%s/blob/%s", url, object_ref)
end

return remote_url
