local client = require "sapling_scm.client"
local remote_url = require "sapling_scm.remote_url"
local fs = require "sapling_scm.fs"
local log_actions = require "sapling_scm.log_actions"

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "sl://*" },
  callback = function(event)
    fs.handle(event.file, event.buf)
  end,
  desc = "Sapling SCM URL handler",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "saplinglog",
  callback = function(args)
    local ops = { noremap = true, silent = true, nowait = true, buffer = args.buf }
    vim.keymap.set("n", "<CR>", log_actions.show_current_hash, ops)
    vim.keymap.set("n", "<C-e>", log_actions.metaedit, ops)
    vim.keymap.set("n", "<C-c>", log_actions.commit, ops)
    vim.keymap.set("n", "<C-b>", log_actions.bookmark, ops)
    vim.keymap.set("n", "<C-g>", log_actions.go_to, ops)
  end,
})

vim.api.nvim_create_user_command("Sshow", function(props)
  vim.cmd("edit sl://show/" .. props.args)
end, { nargs = "+", desc = "Browse the current object on the remote url" })

vim.api.nvim_create_user_command("Slog", function(props)
  vim.cmd("edit sl://log/" .. props.args)
end, { nargs = "+", desc = "Browse the current object on the remote url" })

vim.api.nvim_create_user_command("Sdiff", function(props)
  vim.cmd("edit sl://diff/" .. props.args)
end, { nargs = "?", desc = "Browse the current object on the remote url" })

vim.api.nvim_create_user_command("Sstatus", function()
  vim.cmd "edit sl://status"
end, { desc = "Browse the current object on the remote url" })

vim.api.nvim_create_user_command("Sannotate", function()
  local width, annotations = client.annotate(".", vim.api.nvim_buf_get_name(0))

  vim.cmd "set cursorbind"

  vim.cmd(string.format("vert topleft split | vertical resize %d | e /tmp/annotations", width))
  vim.api.nvim_buf_set_option(0, "buftype", "nofile")
  vim.api.nvim_win_set_option(0, "number", false)
  vim.api.nvim_win_set_option(0, "relativenumber", false)
  vim.api.nvim_win_set_option(0, "signcolumn", "no")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, annotations)
  vim.cmd "set cursorbind"
end, { desc = "Browse the current object on the remote url" })

vim.api.nvim_create_user_command("Scommit", log_actions.commit, { desc = "Commit all your current changes" })

vim.api.nvim_create_user_command("Sbrowse", function(props)
  local file = vim.fn.expand "%"
  local start_line = props.line1
  local end_line = props.line2

  local defualt_path = client.config('paths.default')
  local ref = remote_url.get_object_ref(client.commit_info())
  local url = remote_url.blob(defualt_path, ref, file, start_line, end_line)

  vim.cmd(string.format("silent !xdg-open %s", url))
end, { range = true, desc = "Browse the current object on the remote url" })
