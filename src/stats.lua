local stats = {}

function stats.mean(data)
   local sum = 0

   for _, v in pairs(data) do
      sum = sum + v
   end

   return sum / #data
end

function stats.variance(data, mean)
   local deviations = {}

   for k, v in ipairs(data) do
      table.insert(deviations, k, math.pow(v - mean, 2))
   end

   return stats.mean(deviations)
end

function stats.standard_deviation(data)
   local mean = stats.mean(data)
   local variance = stats.variance(data, mean)

   return math.sqrt(variance)
end

return stats
