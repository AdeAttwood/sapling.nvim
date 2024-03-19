local client = require "sapling_scm.client"
local fs = require "sapling_scm.fs"

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

---@param path string
---@param ref string
---@return string
remote_url.commit = function(path, ref)
  local host = path:gsub(".git$", "")
  return string.format("%s/commit/%s", host, ref)
end

---@param file_name string
---@param start_line number
---@param end_line number
---@return string
remote_url.get_url_for_file = function(file_name, start_line, end_line)
  local default_path = client.config "paths.default"
  local url

  local parsed = fs.parse_url(file_name)
  if parsed and parsed.action == "show" then
    -- The show command can take any revset to show. This will resolve the
    -- revset into a commit hash so we can send the user to teh correct
    -- permalink url. This will also prevent us from sending the user to a url
    -- with a sapling revset in that that hosts don't understand.
    local rev = client.commit_info(parsed.commit).node
    url = remote_url.commit(default_path, rev)
  else
    local ref = remote_url.get_object_ref(client.commit_info())
    url = remote_url.blob(default_path, ref, file_name, start_line, end_line)
  end

  return url
end

return remote_url
