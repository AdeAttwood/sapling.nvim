require "sapling_scm_tests.setup"

local actions = require "sapling_scm.log_actions"
local editor_command = require "sapling_scm.editor_command"

local stub = require("busted").stub
local match = require("busted").match

describe("bookmark", function()
  vim.cmd "edit sl://show/."
  stub(editor_command, "run")

  teardown(function()
    editor_command.run:revert()
  end)

  describe("with no bookmark added in the input", function()
    stub(vim.ui, "input", function(_, callback)
      callback(nil)
    end)

    teardown(function()
      vim.ui.input:revert()
    end)

    actions.bookmark()

    it("calls vim.ui.input when the bookmark is called", function()
      assert.stub(vim.ui.input).was_called_with(match.is_table(), match.is_function())
    end)

    it("dose not call the editor_command.run", function()
      assert.stub(editor_command.run).was_not_called()
    end)
  end)

  describe("with a name in the callback for the input", function()
    stub(vim.ui, "input", function(_, callback)
      callback "MY_BOOKMARK"
    end)

    teardown(function()
      vim.ui.input:revert()
    end)

    actions.bookmark()

    it("calls vim.ui.input when the bookmark is called", function()
      assert.stub(vim.ui.input).was_called_with(match.is_table(), match.is_function())
    end)

    it("calls the editor command to create a bookmark", function()
      assert.stub(editor_command.run).was_called_with(match.has_match "sl bookmark")
    end)
  end)
end)

describe("goto", function()
  vim.cmd "edit sl://show/."
  stub(editor_command, "run")

  teardown(function()
    editor_command.run:revert()
  end)

  describe("with no bookmark added in the input", function()
    actions.go_to()

    it("calls the editor command with the correct command", function()
      assert.stub(editor_command.run).was_called_with(match.has_match "sl goto")
    end)

    it("calls the editor command passing in the ref flag with a ref", function()
      assert.stub(editor_command.run).was_called_with(match.has_match "-r '.*'")
    end)
  end)
end)
