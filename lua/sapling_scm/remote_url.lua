local remote_url = {}

---@param commit_info CommitInfo
---@return string
remote_url.get_object_ref = function(commit_info)
  if #commit_info.remotenames > 0 then
    local remote_name, _ = commit_info.remotenames[1]:gsub("remote/", "")
    return remote_name
  end

  return commit_info.node
end

---@param path string
---@param ref string
---@param file string
---@param start_line number
---@param end_line number
---@return string
remote_url.blob = function(path, ref, file, start_line, end_line)
  local host = path:gsub(".git$", "")
  return string.format("%s/blob/%s/%s/\\#L%s-L%s", host, ref, file, start_line, end_line)
end

return remote_url
