local date_utils = {}

function date_utils.get_hours_and_minutes(minutes)
   local hours = math.floor(minutes / 60)
   local mins = math.floor((minutes % 60) + 0.5)

   if minutes == 60 then
      hours = hours + 1
      mins = 0
   end

   return hours, mins
end

function date_utils.date_string_to_timestamp(date_string)
   local pattern = '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'
   local y, mo, d, h, mi, s = date_string:match(pattern)
   return os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = s })
end

return date_utils
