local func = {}

function func.map(t, selector)
   local result = {}

   for k, v in pairs(t) do
      table.insert(result, k, selector(v, k))
   end

   return result
end

return func
