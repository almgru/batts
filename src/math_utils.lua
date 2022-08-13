local math_utils = {}

function math_utils.integer_round(number)
   return number > 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
end

return math_utils
