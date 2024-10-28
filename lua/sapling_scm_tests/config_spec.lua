require "sapling_scm_tests.setup"

local config = require "sapling_scm.config"

describe("config", function()
  before_each(function()
    config.user_config = {}
  end)

  it("returns nil if we access a key that is not a valid config item", function()
    assert.is_nil(config:get { "not", "a", "thing" })
  end)

  it("returns when there is only a user config", function()
    config.user_config = { key = "value" }
    assert.is_equal("value", config:get { "key" })
  end)

  it("returns the overridden value", function()
    config.default_config.key = "default value"
    config.user_config = { key = "value one" }

    assert.is_equal("value one", config:get { "key" })
  end)

  it("returns the default value", function()
    config.default_config.key = "default value"

    assert.is_equal("default value", config:get { "key" })
  end)
end)
