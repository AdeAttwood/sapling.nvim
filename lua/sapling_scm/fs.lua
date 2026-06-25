local client = require "sapling_scm.client"

-- Test to see if we have baleia installed. If we do we can use it to highlight
-- ansi colors from command output.
local has_baleia, baleia = pcall(function()
  return require("baleia").setup { name = "SaplingColors" }
end)

-- Highlight the buffer using baleia if it is installed.
local highlight_buffer = function(buf)
  if has_baleia then
    baleia.once(buf)
  end
end

---@param buf integer
---@param action string
---@param commit string | nil
local configure_diff_buffer = function(buf, action, commit)
  vim.api.nvim_buf_set_var(buf, "sapling_diff_action", action)

  if commit then
    vim.api.nvim_buf_set_var(buf, "sapling_show_commit", commit)
  else
    pcall(vim.api.nvim_buf_del_var, buf, "sapling_show_commit")
  end

  vim.keymap.set("n", "gd", function()
    require("sapling_scm.diff_jump").jump()
  end, {
    noremap = true,
    silent = true,
    nowait = true,
    buffer = buf,
    desc = "Jump to the new-side location from the current sapling diff",
  })
end

---@alias action "show" | "log"

---@class ShowAction
---@field action "show"
---@field commit string
--
---@class LogAction
---@field action "log"
---@field pattern string

---@param url string
---@return ShowAction | LogAction | nil
local parse_url = function(url)
  if url == "sl://smartlog" then
    return { action = "smartlog" }
  end

  local show_matches = url:match "sl://show/(.*)"
  if show_matches then
    return { action = "show", commit = show_matches }
  end

  local log_matches = url:match "sl://log/(.*)"
  if log_matches then
    return { action = "log", pattern = log_matches }
  end

  local diff_matches = url:match "sl://diff/(.*)"
  if diff_matches then
    return { action = "diff", pattern = diff_matches }
  end

  local cat_ref, cat_file = url:match "sl://cat/([^/]+)/(.*)"
  if cat_ref and cat_file then
    return { action = "cat", commit = cat_ref, file = cat_file }
  end

  if url == "sl://status" then
    return { action = "status" }
  end

  -- No handler for this url is found
  return nil
end

---@param url string
---@param buf integer
local handle = function(url, buf)
  local action = parse_url(url)

  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

  if not action then
    -- TODO(AdeAttwood): Handle this case with an error buffer
    return
  end

  if action.action == "cat" then
    local content = client.cat(action.commit, action.file)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    -- This will make sure all of the default autocmds are run on the buffer.
    -- For example setting the filetype for syntax highlighting.
    vim.api.nvim_exec_autocmds("BufRead", {})
  end

  if action.action == "show" then
    local commit = client.show(action.commit)

    vim.api.nvim_buf_set_option(buf, "filetype", "diff")
    configure_diff_buffer(buf, "show", commit.node)

    local header = {
      "# Node: " .. commit.node,
      "# Author: " .. commit.user,
      "# Date: " .. os.date("%c", commit.date[1]),
      "#",
    }

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)

    local index = #header + 1

    local desc = vim.split(commit.desc, "\n")
    for _, line in ipairs(desc) do
      if #line == 0 then
        vim.api.nvim_buf_set_lines(buf, index, -1, false, { "#" })
      else
        vim.api.nvim_buf_set_lines(buf, index, -1, false, { "# " .. line })
      end

      index = index + 1
    end

    vim.api.nvim_buf_set_lines(buf, index, -1, false, vim.split(commit.diff, "\n"))
  end

  if action.action == "log" then
    local log = client.log_text(action.pattern)

    vim.api.nvim_buf_set_option(buf, "filetype", "saplinglog")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, log)
    highlight_buffer(buf)
  end

  if action.action == "smartlog" then
    local log = client.smartlog_text()

    vim.api.nvim_buf_set_option(buf, "filetype", "saplingsmartlog")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, log)
    highlight_buffer(buf)
  end

  if action.action == "diff" then
    local diff = client.diff(action.pattern)
    vim.api.nvim_buf_set_option(buf, "filetype", "diff")
    configure_diff_buffer(buf, "diff", nil)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, diff)
  end

  if action.action == "status" then
    local status = client.status()
    vim.api.nvim_buf_set_option(buf, "filetype", "saplingstatus")

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# Sapling status" })
    for i, item in ipairs(status) do
      vim.api.nvim_buf_set_lines(buf, i, -1, false, { item.status .. " " .. item.path })
    end
  end
end

return { handle = handle, parse_url = parse_url }
