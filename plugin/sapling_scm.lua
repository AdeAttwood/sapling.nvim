local client = require "sapling_scm.client"
local remote_url = require "sapling_scm.remote_url"
local fs = require "sapling_scm.fs"

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "sl://*" },
  callback = function(event)
    fs.handle(event.file, event.buf)
  end,
  desc = "Sapling SCM URL handler",
})

vim.api.nvim_create_user_command("Sshow", function(props)
  vim.cmd("edit sl://show/" .. props.args)
end, { nargs = "+", desc = "Browse the current object on the remote url" })

vim.api.nvim_create_user_command("Slog", function(props)
  vim.cmd("edit sl://log/" .. props.args)
end, { nargs = "+", desc = "Browse the current object on the remote url" })

vim.api.nvim_create_user_command("Sbrowse", function(props)
  local file = vim.fn.expand "%"
  local start_line = props.line1
  local end_line = props.line2

  local host = remote_url.blob(client.head_info())
  local url = string.format("%s/%s\\#L%s-L%s", host, file, start_line, end_line)
  vim.cmd(string.format("silent !xdg-open %s", url))
end, { range = true, desc = "Browse the current object on the remote url" })
