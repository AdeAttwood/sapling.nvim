require "sapling_scm_tests.setup"

local coalesce = require "sapling_scm.coalesce"

describe("coalesce", function()
  it("returns nil when only nil values as passed in", function()
    assert.is_equal(coalesce(nil, nil, nil), nil)
  end)

  it("returns the first value if its not nill", function()
    assert.is_equal(coalesce("Test", nil), "Test")
  end)

  it("dose not return a empty string as value", function()
    assert.is_equal(coalesce("", "Test"), "Test")
  end)
end)
