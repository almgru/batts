local stats = {}

local z_score_filter_threshold = 2.5

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

function stats.z_scores(data, mean, stddev)
   local z_scores = {}

   for k, v in ipairs(data) do
      table.insert(z_scores, k, (v - mean) / stddev)
   end

   return z_scores
end

function stats.filter_out_outliers(data, z_scores)
   local filtered = {}

   for k, v in ipairs(data) do
      if math.abs(z_scores[k]) < z_score_filter_threshold then table.insert(filtered, #filtered + 1, v) end
   end

   return filtered
end

stats.min_filter_population = 20

return stats
