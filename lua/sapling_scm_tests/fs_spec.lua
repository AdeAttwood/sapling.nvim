require "sapling_scm_tests.setup"

-- Run a vim command and get the output of the current buffer
--
---@param command string
---@return string, string[]
local run_command = function(command)
  vim.cmd(command)

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if not lines then
    return "", {}
  end

  return vim.fn.join(lines, "\n"), lines
end

describe("Slog", function()
  describe("with a single commit hash", function()
    local content, lines = run_command "Slog f5bdd00322fe"

    it("has only one line in the output", function()
      assert.is_equal(1, #lines)
    end)

    it("has the commit sha in the output", function()
      assert.matches("f5bdd00322fe", content)
    end)

    it("has the commit message in the buffer", function()
      assert.matches("chore: initial commit", content)
    end)

    it("has the buffer file type set to saplinglog", function()
      assert.is_equal("saplinglog", vim.bo.filetype)
    end)
  end)

  describe("with a range of commits", function()
    local content, lines = run_command "Slog f5bdd00322fe::73a8acee4819"

    it("has multiple lines in the output", function()
      assert.is_equal(3, #lines)
    end)

    it("has the first commit sha in the output", function()
      assert.matches("f5bdd00322fe", content)
    end)

    it("has the first commit message in the output", function()
      assert.matches("chore: initial commit", content)
    end)

    it("has the last commit sha in the output", function()
      assert.matches("73a8acee4819", content)
    end)

    it("has the last commit message in the output", function()
      assert.matches("feat: support showing commits and logging", content)
    end)
  end)
end)

describe("Sshow", function()
  describe("with the first commit", function()
    local content, _ = run_command "Sshow f5bdd00322fe"

    it("has the full node in the output", function()
      assert.matches("Node: f5bdd00322fea627d5dfa5de9180a37d22a51ce5", content)
    end)

    it("has the author in the output", function()
      assert.matches("Author: Ade Attwood", content)
    end)

    it("has the diff printed in the buffer", function()
      assert.matches("--git a/plugin/sapling_scm.lua", content)
    end)

    it("has the buffer file type set to diff", function()
      assert.is_equal("diff", vim.bo.filetype)
    end)
  end)
end)
