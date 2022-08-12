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

   local function subrange(t, first, last)
      local sub = {}

      for i = first, last do
         sub[#sub + 1] = t[i]
      end

      return sub
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

   for index, item in ipairs(discharge_durations) do
      print('discharge_durations[' .. index .. '] = {')
      print('  capacity_delta = ' .. item.capacity_delta)
      print('  duration = ' .. item.duration)
      print('}')

      table.insert(discharge_per_minute, item.capacity_delta / item.duration)
   end

   local sum = 0
   for index, value in ipairs(discharge_per_minute) do
      print('discharge_per_minute[' .. index .. '] = ' .. value)
      sum = sum + value
   end

   local mean_discharge_per_minute = sum / #discharge_per_minute

   print('mean discharge time: TODO')
   print('mean discharge rate per hour: ' .. mean_discharge_per_minute * 60 .. '%')
   print('extrapolated mean full charge discharge time: ' .. 100 / mean_discharge_per_minute)

   --table.sort(discharge_durations, function(a, b) return a.duration < b.duration end)
   --local lower_half = #discharge_durations % 2 == 1
   --    and subrange(discharge_durations, 1, math.floor(#discharge_durations / 2))
   --    or subrange(discharge_durations, 1, #discharge_durations / 2)
   --local upper_half = #discharge_durations % 2 == 1
   --    and subrange(discharge_durations, math.ceil(#discharge_durations / 2) + 1, #discharge_durations)
   --    or subrange(discharge_durations, #discharge_durations / 2, #discharge_durations)
   --local lqr = #lower_half % 2 == 1
   --    and lower_half[math.ceil(#lower_half / 2)].duration
   --    or (lower_half[#lower_half / 2].duration + lower_half[#lower_half / 2 + 1].duration) / 2
   --local uqr = #upper_half % 2 == 1
   --    and upper_half[math.ceil(#upper_half / 2)].duration
   --    or (upper_half[#upper_half].duration / 2 + upper_half[#upper_half / 2 + 1].duration) / 2

   --local discharge_durations_without_outliers = {}

   --print('lqr = ' .. lqr .. ', uqr = ' .. uqr)

   --for _, v in ipairs(discharge_durations) do
   --   if v.sessions_duration >= lqr and v.sessions_duration <= uqr then
   --      table.insert(discharge_durations_without_outliers, #discharge_durations_without_outliers + 1, v)
   --   end
   --end

   --local sum = 0
   --for _, v in ipairs(discharge_durations_without_outliers) do
   --   sum = sum + v.sessions_duration
   --end

   --local mean_discharge_time_in_min = sum / #discharge_durations_without_outliers
   --local mean_discharge_time_h = math.floor((sum / #discharge_durations_without_outliers) / 60)
   --local mean_discharge_time_min = math.floor(((sum / #discharge_durations_without_outliers) % 60) + 0.5)
   --local extrapolated_h = math.floor((mean_discharge_time_in_min / 0.2) / 60)
   --local extrapolated_min = math.floor(((mean_discharge_time_in_min / 0.2) % 60) + 0.5)

   --print('mean discharge time: ' .. mean_discharge_time_h .. ' hours, ' .. mean_discharge_time_min .. ' minutes')
   --print('extrapolated mean full charge discharge time ' ..
   --   extrapolated_h .. ' hours, ' .. extrapolated_min .. ' minutes')

elseif args.daemon then
   if args.log_directory == '$XDG_DATA_HOME/batstat' then
      local home = os.getenv('HOME') or error('HOME is not set.')
      local xdg_data_home = os.getenv('XDG_DATA_HOME') or home .. '/.local/share'
      args.log_directory = xdg_data_home .. '/batstat'
   end

   os.execute('mkdir -p ' .. args.log_directory)

   daemon.start(args.interval_in_seconds, args.log_directory)
end
