local client = require "sapling_scm.client"
local remote_url = require "sapling_scm.remote_url"

vim.api.nvim_create_user_command("Sbrowse", function(props)
  local file = vim.fn.expand "%"
  local start_line = props.line1
  local end_line = props.line2

  local host = remote_url.blob(client.head_info())
  local url = string.format("%s/%s\\#L%s-L%s", host, file, start_line, end_line)
  vim.cmd(string.format("silent !xdg-open %s", url))
end, { range = true, desc = "Browse the current object on the remote url" })
