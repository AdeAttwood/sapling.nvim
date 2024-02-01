require "sapling_scm_tests.setup"

local remote_url = require "sapling_scm.remote_url"

describe("sapling_scm.remote_url.blob", function()
  it("returns the node when there is no refs provided", function()
    local head_info = {
      node = "9092404705c3763084aa1f18966b1e9e1d1c92b8",
      peerurls = { default = "https://github.com/facebook/sapling.git" },
      remotenames = {},
    }

    assert.is_equal(
      "https://github.com/facebook/sapling/blob/9092404705c3763084aa1f18966b1e9e1d1c92b8",
      remote_url.blob(head_info)
    )
  end)

  it("returns the branch when there is one provided", function()
    local head_info = {
      node = "9092404705c3763084aa1f18966b1e9e1d1c92b8",
      peerurls = { default = "https://github.com/facebook/sapling.git" },
      remotenames = { "remote/development" },
    }

    assert.is_equal("https://github.com/facebook/sapling/blob/development", remote_url.blob(head_info))
  end)
end)
