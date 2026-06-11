require "sapling_scm_tests.setup"

local diff_jump = require "sapling_scm.diff_jump"

local find_line_number = function(lines, needle)
  for line_number, line in ipairs(lines) do
    if line == needle then
      return line_number
    end
  end

  return nil
end

local create_buffer = function(name, lines, vars)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for key, value in pairs(vars or {}) do
    vim.api.nvim_buf_set_var(buf, key, value)
  end

  return buf
end

describe("diff_jump.location_from_lines", function()
  local lines = {
    "diff --git a/lua/test.lua b/lua/test.lua",
    "--- a/lua/test.lua",
    "+++ b/lua/test.lua",
    "@@ -10,3 +10,4 @@",
    " local one = 1",
    "-local two = 2",
    "+local two = 3",
    " local three = 3",
  }

  it("jumps to the hunk start from the file header", function()
    local location = assert(diff_jump.location_from_lines(lines, 1))
    assert.are.same({ file = "lua/test.lua", line = 10 }, location)
  end)

  it("maps removed lines to the new-side insertion point", function()
    local location = assert(diff_jump.location_from_lines(lines, 6))
    assert.are.same({ file = "lua/test.lua", line = 11 }, location)
  end)

  it("maps added lines to the new-side line", function()
    local location = assert(diff_jump.location_from_lines(lines, 7))
    assert.are.same({ file = "lua/test.lua", line = 11 }, location)
  end)

  it("maps later context lines after additions", function()
    local location = assert(diff_jump.location_from_lines(lines, 8))
    assert.are.same({ file = "lua/test.lua", line = 12 }, location)
  end)

  it("refuses to jump to deleted files", function()
    local _, err = diff_jump.location_from_lines({
      "diff --git a/lua/test.lua b/lua/test.lua",
      "deleted file mode 100644",
      "--- a/lua/test.lua",
      "+++ /dev/null",
      "@@ -1 +0,0 @@",
      "-local deleted = true",
    }, 6)

    assert.is_equal("no new-side target for this file", err)
  end)
end)

describe("diff_jump.target_from_buffer", function()
  it("builds a working tree target for Sdiff buffers", function()
    local buf = create_buffer("sl://diff/-r a -r b", {
      "diff --git a/lua/test.lua b/lua/test.lua",
      "--- a/lua/test.lua",
      "+++ b/lua/test.lua",
      "@@ -1 +1 @@",
      "+local test = true",
    })

    local target = assert(diff_jump.target_from_buffer(buf, 5))

    assert.are.same({
      action = "diff",
      file = "lua/test.lua",
      line = 1,
      path = "lua/test.lua",
      url = nil,
    }, target)
  end)

  it("builds a cat target for Sshow buffers", function()
    local buf = create_buffer("sl://show/.", {
      "# Node: abcdef",
      "diff --git a/lua/test.lua b/lua/test.lua",
      "--- a/lua/test.lua",
      "+++ b/lua/test.lua",
      "@@ -1 +1 @@",
      "+local test = true",
    }, {
      sapling_diff_action = "show",
      sapling_show_commit = "abcdef123456",
    })

    local target = assert(diff_jump.target_from_buffer(buf, 6))

    assert.are.same({
      action = "show",
      file = "lua/test.lua",
      line = 1,
      path = nil,
      url = "sl://cat/abcdef123456/lua/test.lua",
    }, target)
  end)
end)

describe("diff_jump.jump", function()
  describe("from Sdiff", function()
    vim.fn.system "echo 'This is a line added' >> README.md"
    vim.cmd "Sdiff"

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local line_number = assert(find_line_number(lines, "+This is a line added"))
    vim.api.nvim_win_set_cursor(0, { line_number, 0 })

    diff_jump.jump()

    teardown(function()
      vim.fn.system "sl revert README.md"
    end)

    it("opens the working tree file", function()
      assert.is_equal("README.md", vim.fn.expand "%:t")
    end)

    it("jumps to the matching line", function()
      assert.is_equal("This is a line added", vim.api.nvim_get_current_line())
    end)
  end)

  describe("from Sshow", function()
    vim.cmd "Sshow f5bdd00322fe"

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local line_number = assert(find_line_number(lines, "+local client = {}"))
    vim.api.nvim_win_set_cursor(0, { line_number, 0 })

    diff_jump.jump()

    it("opens the file at the shown revision", function()
      assert.matches("^sl://cat/.*/lua/sapling_scm/client.lua$", vim.fn.expand "%")
    end)

    it("jumps to the matching line", function()
      assert.is_equal("local client = {}", vim.api.nvim_get_current_line())
    end)
  end)
end)
