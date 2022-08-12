local cli_parser = require('cli_parser')
local daemon = require('daemon')

local args, err = cli_parser:parse()

if not args and err then
   return print(err)
elseif args.stats then
   local function date_string_to_timestamp(date_string)
      local pattern = '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'
      local y, mo, d, h, mi, s = date_string:match(pattern)
      return os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = s })
   end

   local function parse_log_entry(log_line)
      local pattern = '(%d+-%d+-%d+ %d+:%d+:%d+): (BAT%d), (%a+), (%d+)%%'
      local date_string, name, status, capacity = log_line:match(pattern)

      return {
         timestamp = date_string_to_timestamp(date_string),
         name = name,
         status = status,
         capacity = capacity,
      }
   end

   local function get_hours_and_minutes(minutes)
      return math.floor(minutes / 60), math.floor((minutes % 60) + 0.5)
   end

   local log_file, log_file_err = io.open('/home/almgru/.local/share/batstat/BAT1.log', 'r')

   if not log_file then
      error(log_file_err)
   end

   local prev_line
   local charge_cycle = 0
   local discharge_durations = {}
   local sessions_duration = 0
   local session_start = {}
   local charge_cycle_start

   for line in log_file:lines() do
      local curr = parse_log_entry(line)

      if prev_line ~= nil then
         local prev = parse_log_entry(prev_line)

         if prev.status ~= 'Discharging' and curr.status == 'Discharging' then
            charge_cycle = charge_cycle + 1
            charge_cycle_start = curr
            sessions_duration = 0
            session_start = curr
         elseif prev.status == 'Discharging' and curr.status ~= prev.status then
            if sessions_duration > 0 then
               sessions_duration = sessions_duration +
                   math.floor(((prev.timestamp - session_start.timestamp) / 60) + 0.5)
               table.insert(discharge_durations, {
                  duration = sessions_duration,
                  capacity_delta = charge_cycle_start.capacity - prev.capacity
               })
            else
               table.insert(discharge_durations, {
                  duration = math.floor(((prev.timestamp - charge_cycle_start.timestamp) / 60) + 0.5),
                  capacity_delta = charge_cycle_start.capacity - prev.capacity,
               })
            end

            sessions_duration = 0
            session_start = curr
         elseif curr.timestamp - prev.timestamp > 180 then
            sessions_duration = sessions_duration + math.floor(((prev.timestamp - session_start.timestamp) / 60) + 0.5)
            session_start = curr
         end
      elseif curr.status == 'Discharging' then
         charge_cycle = 1
         charge_cycle_start = curr
         session_start = curr
      end

      prev_line = line
   end

   local discharge_per_minute = {}

   local duration_sum = 0
   for _, item in ipairs(discharge_durations) do
      table.insert(discharge_per_minute, item.capacity_delta / item.duration)
      duration_sum = duration_sum + item.duration
   end

   local discharge_per_minute_sum = 0
   for _, value in ipairs(discharge_per_minute) do
      discharge_per_minute_sum = discharge_per_minute_sum + value
   end

   local mean_duration = duration_sum / #discharge_durations
   local mean_duration_hours, mean_duration_minutes = get_hours_and_minutes(mean_duration)
   local mean_discharge_per_minute = discharge_per_minute_sum / #discharge_per_minute
   local extrapolated_hours, extrapolated_minutes = get_hours_and_minutes(100 / mean_discharge_per_minute)

   print('TODO: filter out outliers')
   print('TODO: stdev for "mean discharge time" and "mean discharge rate per hour"')
   print('mean discharge time: ' .. mean_duration_hours .. ' hours, ' .. mean_duration_minutes .. ' minutes')
   print('mean discharge rate per hour: ' .. string.format('%.2f', mean_discharge_per_minute * 60) .. '%')
   print('extrapolated mean full charge discharge time: ' ..
      extrapolated_hours .. ' hours, ' .. extrapolated_minutes .. ' minutes')

elseif args.daemon then
   if args.log_directory == '$XDG_DATA_HOME/batstat' then
      local home = os.getenv('HOME') or error('HOME is not set.')
      local xdg_data_home = os.getenv('XDG_DATA_HOME') or home .. '/.local/share'
      args.log_directory = xdg_data_home .. '/batstat'
   end

   os.execute('mkdir -p ' .. args.log_directory)

   daemon.start(args.interval_in_seconds, args.log_directory)
end
