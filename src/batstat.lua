local cli_parser = require('cli_parser')
local daemon = require('daemon')
local stats = require('stats')

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

   local function map(t, selector)
      local result = {}

      for k, v in pairs(t) do
         table.insert(result, k, selector(v, k))
      end

      return result
   end

   local function in_potential_charging_state(state)
      return state == 'Charging' or state == 'Full' or state == 'Unknown'
   end

   local function started_charge(current_battery_state, previous_battery_state)
      return in_potential_charging_state(current_battery_state) and previous_battery_state == 'Discharging'
   end

   local function started_discharge(current_battery_state, previous_battery_state)
      return current_battery_state == 'Discharging' and in_potential_charging_state(previous_battery_state)
   end

   local function integer_round(number) return math.floor(number + 0.5) end

   local log_file, log_file_err = io.open('/home/almgru/.local/share/batstat/BAT1.log', 'r')

   if not log_file then
      error(log_file_err)
   end

   local prev_line
   local discharge_durations = {}
   local sessions_duration = 0
   local session_start = {}
   local charge_cycle_start

   for line in log_file:lines() do
      local curr = parse_log_entry(line)

      if prev_line ~= nil then
         local prev = parse_log_entry(prev_line)

         if started_discharge(curr.status, prev.status) then
            charge_cycle_start = curr
            sessions_duration = 0
            session_start = curr
         elseif started_charge(curr.status, prev.status) then
            if sessions_duration > 0 then
               sessions_duration = sessions_duration + integer_round((prev.timestamp - session_start.timestamp) / 60)
               table.insert(discharge_durations, {
                  duration = sessions_duration,
                  capacity_delta = charge_cycle_start.capacity - prev.capacity
               })
            else
               table.insert(discharge_durations, {
                  duration = integer_round((prev.timestamp - charge_cycle_start.timestamp) / 60),
                  capacity_delta = charge_cycle_start.capacity - prev.capacity,
               })
            end

            sessions_duration = 0
            session_start = curr
         elseif curr.timestamp - prev.timestamp > 180 then
            sessions_duration = sessions_duration + integer_round((prev.timestamp - session_start.timestamp) / 60)
            session_start = curr
         end
      elseif curr.status == 'Discharging' then
         charge_cycle_start = curr
         session_start = curr
      end

      prev_line = line
   end

   local durations = map(discharge_durations, function(el) return el.duration end)
   local mean_duration = stats.mean(durations)
   local stddev_durations = stats.standard_deviation(durations)

   -- Filter out outliers
   if #durations > 20 then
      local z_scores = stats.z_scores(durations, mean_duration, stddev_durations)

      local filtered_durations = {}
      for k, v in ipairs(durations) do
         if math.abs(z_scores[k]) < 10 then table.insert(filtered_durations, k, v) end
      end

      durations = filtered_durations

      -- trim mean and stddev to exclude outliers
      mean_duration = stats.mean(filtered_durations)
      stddev_durations = stats.standard_deviation(filtered_durations)
   end

   local discharge_per_minute = map(discharge_durations, function(duration)
      return duration.capacity_delta / duration.duration
   end)

   local mean_discharge_per_minute = stats.mean(discharge_per_minute)
   local stddev_discharge_per_minute = stats.standard_deviation(discharge_per_minute)

   if #discharge_per_minute > 20 then
      local z_scores = stats.z_scores(discharge_per_minute, mean_discharge_per_minute, stddev_discharge_per_minute)

      local filtered_discharges = {}
      for k, v in ipairs(discharge_per_minute) do
         if math.abs(z_scores[k]) < 10 then table.insert(filtered_discharges, k, v) end
      end

      discharge_per_minute = filtered_discharges

      -- trim mean and stddev to exclude outliers
      mean_discharge_per_minute = stats.mean(discharge_per_minute)
      stddev_discharge_per_minute = stats.standard_deviation(discharge_per_minute)
   end

   local mean_duration_hours, mean_duration_minutes = get_hours_and_minutes(mean_duration)
   local stddev_duration_hours, stddev_duration_minutes = get_hours_and_minutes(stddev_durations)
   local mean_discharge_rate = mean_discharge_per_minute * 60
   local stddev_discharge_rate = stddev_discharge_per_minute * 60
   local extrapolated_hours, extrapolated_minutes = get_hours_and_minutes(100 / mean_discharge_per_minute)

   print('mean discharge time: ' .. mean_duration_hours .. 'h ' .. mean_duration_minutes .. 'm (σ ' ..
      stddev_duration_hours .. 'h ' .. stddev_duration_minutes .. 'm)')
   print('mean discharge rate per hour: ' .. string.format('%.2f', mean_discharge_rate) .. '% (σ ' ..
      string.format('%.2f', stddev_discharge_rate) .. '%)')
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
