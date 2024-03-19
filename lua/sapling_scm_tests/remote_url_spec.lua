require "sapling_scm_tests.setup"

local remote_url = require "sapling_scm.remote_url"

describe("sapling_scm.remote_url.get_object_ref", function()
  it("returns the node when there is no refs provided", function()
    local commit_info = {
      node = "9092404705c3763084aa1f18966b1e9e1d1c92b8",
      peerurls = { default = "https://github.com/facebook/sapling.git" },
      remotenames = {},
    }

    assert.is_equal("9092404705c3763084aa1f18966b1e9e1d1c92b8", remote_url.get_object_ref(commit_info))
  end)

  it("returns the branch when there is one provided", function()
    local commit_info = {
      node = "9092404705c3763084aa1f18966b1e9e1d1c92b8",
      peerurls = { default = "https://github.com/facebook/sapling.git" },
      remotenames = { "remote/development" },
    }

    assert.is_equal("development", remote_url.get_object_ref(commit_info))
  end)
end)

describe("sapling_scm.remote_url.blob", function()
  it("returns the correct blob URL for github.com", function()
    assert.equal(
      "https://github.com/facebook/sapling/blob/development/README.md/\\#L10-L10",
      remote_url.blob("https://github.com/facebook/sapling.git", "development", "README.md", 10, 10)
    )
  end)
end)
