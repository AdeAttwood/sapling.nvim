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
  local show_matches = url:match "sl://show/(.*)"
  if show_matches then
    return { action = "show", commit = show_matches }
  end

  local log_matches = url:match "sl://log/(.*)"
  if log_matches then
    return { action = "log", pattern = log_matches }
  end

  local diff_matcehs = url:match "sl://diff/(.*)"
  if diff_matcehs then
    return { action = "diff", pattern = diff_matcehs }
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

  if action.action == "show" then
    local commit = client.show(action.commit)

    vim.api.nvim_buf_set_option(buf, "filetype", "diff")

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
      vim.api.nvim_buf_set_lines(buf, index, -1, false, { "# " .. line })
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

  if action.action == "diff" then
    local diff = client.diff(action.pattern)
    vim.api.nvim_buf_set_option(buf, "filetype", "diff")
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

return { handle = handle }
