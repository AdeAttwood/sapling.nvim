require "sapling_scm_tests.setup"

local remote_url = require "sapling_scm.remote_url"
local client = require "sapling_scm.client"

local stub = require("busted").stub

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

describe("sapling_scm.remote_url.get_url_for_file", function()
  stub(client, "config", function(_, _)
    return "https://github.com/facebook/sapling.git"
  end)

  stub(client, "commit_info", function(_)
    return {
      node = "9092404705c3763084aa1f18966b1e9e1d1c92b8",
      remotenames = {},
    }
  end)

  describe("with a regular file passed in", function()
    local url = remote_url.get_url_for_file("README.md", 10, 10)

    it("has the correct url for a blob", function()
      assert.equal(
        "https://github.com/facebook/sapling/blob/9092404705c3763084aa1f18966b1e9e1d1c92b8/README.md/\\#L10-L10",
        url
      )
    end)
  end)

  describe("with a sapling show url passed in", function()
    local url = remote_url.get_url_for_file("sl://show/my-revset", 10, 10)

    it("the commit url is returned", function()
      assert.equal("https://github.com/facebook/sapling/commit/9092404705c3763084aa1f18966b1e9e1d1c92b8", url)
    end)

    it("resolves the correct revset from the show url", function()
      assert.stub(client.commit_info).was_called_with "my-revset"
    end)
  end)

  describe("with a dot as the sapling revset", function()
    local url = remote_url.get_url_for_file("sl://show/.", 10, 10)

    it("the commit url is returned", function()
      assert.equal("https://github.com/facebook/sapling/commit/9092404705c3763084aa1f18966b1e9e1d1c92b8", url)
    end)

    it("resolves the correct revset from the show url", function()
      assert.stub(client.commit_info).was_called_with "."
    end)
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

describe("sapling_scm.remote_url.commit", function()
  it("returns the correct blob URL for github.com", function()
    assert.equal(
      "https://github.com/facebook/sapling/commit/some-commit-id",
      remote_url.commit("https://github.com/facebook/sapling.git", "some-commit-id")
    )
  end)
end)
