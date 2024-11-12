local config_mt = {}
config_mt.__index = config_mt

function config_mt:get_in(config, key_table)
  local current_value = config
  for _, key in ipairs(key_table) do
    if current_value == nil then
      return nil
    end

    current_value = current_value[key]
  end

  return current_value
end

function config_mt:get(key_table)
  return self:get_in(self.user_config, key_table) or self:get_in(self.default_config, key_table)
end

local config = { user_config = {} }

config.default_config = {
  smartlog_log_action_mappings = {
    ["<CR>"] = "show_current_hash",
  },
  log_action_mappings = {
    ["<CR>"] = "show_current_hash",
    ["<C-r>"] = "rebase_reorder",
    ["<C-u>"] = "undo",
    ["<C-f>"] = "rebase_roll",
    ["<C-e>"] = "metaedit",
    ["<C-c>"] = "commit",
    ["<C-b>"] = "bookmark",
    ["<C-m>"] = "bookmark",
    ["<C-g>"] = "go_to",
  },
}

return setmetatable(config, config_mt)
