local inspect = require('inspect')

local func = {}

function func.map(t, selector)
   local result = {}

   for k, v in pairs(t) do
      table.insert(result, k, selector(v, k))
   end

   return result
end

function func.reduce(t, initial, reducer)
   local result = initial

   for k, v in ipairs(t) do
      result = reducer(result, v, k)
   end

   return result
end

return func
