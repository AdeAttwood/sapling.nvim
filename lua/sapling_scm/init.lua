local config = require "sapling_scm.config"

local sapling_scm = {}

-- Private variable to check if the plugin has been setup, this is to prevent
-- multiple setups. This is only exposed for testing purposes.
---@private
sapling_scm.has_setup = false

---@class SaplingScmSetupOptions
---@field log_action_mappings { [string]: string }

---@param user_config SaplingScmSetupOptions
function sapling_scm.setup(user_config)
  if sapling_scm.has_setup then
    return
  end

  config.user_config = user_config or {}
  sapling_scm.has_setup = true
end

return sapling_scm
