local date_utils = require('date_utils')
local math_utils = require('math_utils')

local battery_log_parser = {}

local function parse_log_entry(log_line)
   local pattern = '(%d+-%d+-%d+ %d+:%d+:%d+): (BAT%d), (%a+), (%d+)%%(.*)$'
   local date_string, name, status, capacity, trailing = log_line:match(pattern)
   local power

   if trailing ~= '' then
      local optional_pattern = ', (%d+%p%d+) W'
      power = tonumber(trailing:match(optional_pattern))
   end

   return {
      timestamp = date_utils.date_string_to_timestamp(date_string),
      name = name,
      status = status,
      capacity = capacity,
      power = power,
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

function battery_log_parser.parse(log_file)
   local prev_line
   local battery_usage_summaries = {}
   local sessions_duration = 0
   local session_start = {}
   local charge_cycle_start
   local power = {}

   for line in log_file:lines() do
      local curr = parse_log_entry(line)

      if curr.status == 'Discharging' then
         table.insert(power, curr.power)
      end

      if prev_line ~= nil then
         local prev = parse_log_entry(prev_line)

         if started_discharge(curr.status, prev.status) then
            charge_cycle_start = curr
            sessions_duration = 0
            session_start = curr
            power = {}
         elseif started_charge(curr.status, prev.status) then
            if sessions_duration > 0 then
               sessions_duration = sessions_duration +
                   math_utils.integer_round((prev.timestamp - session_start.timestamp) / 60)
               table.insert(battery_usage_summaries, {
                  duration = sessions_duration,
                  capacity_when_charging_started = prev.capacity,
                  capacity_when_charging_stopped = charge_cycle_start.capacity,
                  power = power,
               })
            else
               table.insert(battery_usage_summaries, {
                  duration = math_utils.integer_round((prev.timestamp - charge_cycle_start.timestamp) / 60),
                  capacity_when_charging_started = prev.capacity,
                  capacity_when_charging_stopped = charge_cycle_start.capacity,
                  power = power,
               })
            end

            sessions_duration = 0
            session_start = curr
         elseif curr.timestamp - prev.timestamp > 180 then
            sessions_duration = sessions_duration +
                math_utils.integer_round((prev.timestamp - session_start.timestamp) / 60)
            session_start = curr
         end
      elseif curr.status == 'Discharging' then
         charge_cycle_start = curr
         session_start = curr
      end

      prev_line = line
   end

   return battery_usage_summaries
end

return battery_log_parser
