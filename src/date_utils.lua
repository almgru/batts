local date_utils = {}

function date_utils.get_hours_and_minutes(minutes)
   local hours = math.floor(minutes / 60)
   local mins = math.floor((minutes % 60) + 0.5)

   if mins == 60 then
      hours = hours + 1
      mins = 0
   end

   return hours, mins
end

return date_utils
