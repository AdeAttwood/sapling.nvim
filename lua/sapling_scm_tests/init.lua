require "busted.runner"()

local busted = require "busted"

local exit_code = 0

local test_dir = string.sub(debug.getinfo(1).source, 2, #"/init.lua" * -1)
local test_files = vim.split(vim.fn.glob(test_dir .. "**/*_spec.lua"), "\n")

busted.subscribe({ "error" }, function()
  exit_code = 1
  return nil, true
end)

busted.subscribe({ "failure" }, function()
  exit_code = 1
  return nil, true
end)

busted.subscribe({ "exit" }, function()
  os.exit(exit_code)

  return nil, true
end)

vim.opt.rtp:append(vim.fn.getcwd())

require "plugin.sapling_scm"

for _, file in ipairs(test_files) do
  require(file:gsub(".lua", ""))
end

print("Ran " .. #test_files .. " tests.")
