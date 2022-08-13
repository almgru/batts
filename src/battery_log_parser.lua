local battery_log_parser = {}

-- TODO: Move to module (maybe date-utils?)
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

local function in_potential_charging_state(state)
   return state == 'Charging' or state == 'Full' or state == 'Unknown'
end

local function started_charge(current_battery_state, previous_battery_state)
   return in_potential_charging_state(current_battery_state) and previous_battery_state == 'Discharging'
end

local function started_discharge(current_battery_state, previous_battery_state)
   return current_battery_state == 'Discharging' and in_potential_charging_state(previous_battery_state)
end

--
-- TODO: Move to module (maybe math-util?)
local function integer_round(number) return math.floor(number + 0.5) end

function battery_log_parser.parse(log_file)
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

   return discharge_durations
end

return battery_log_parser
