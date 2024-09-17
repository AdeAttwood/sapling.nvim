--- Finds the first non-nil value among the provided arguments.
---
---@param ... any The list of arguments to check.
---@return any The first non-nil value, or nil if all arguments are nil.
return function(...)
  for _, item in ipairs { ... } do
    if type(item) == "string" and #item > 0 then
      return item
    end

    if type(item) ~= "string" and item ~= nil then
      return item
    end
  end
end
