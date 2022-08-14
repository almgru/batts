local glob = require('posix.glob').glob
local sleep = require('posix.unistd').sleep
local signal = require('posix.signal')
local basename = require('posix.libgen').basename

local daemon = {}

local function get_battery_directories()
   local bat_dirs = {}

   -- TODO: Fix so dependency on luaposix can be removed
   for _, file in pairs(glob('/sys/class/power_supply/BAT*', 0)) do
      table.insert(bat_dirs, file)
   end

   return bat_dirs
end

local battery_directories = get_battery_directories()

function daemon.start(sleep_interval_sec, battery_log_directory)
   local stop = false

   local function handler()
      stop = true
   end

   -- TODO: Find smaller library, that can be easily statically compiled, to handle signals
   signal.signal(signal.SIGINT, handler)
   signal.signal(signal.SIGTERM, handler)

   repeat
      for _, bat_dir in pairs(battery_directories) do
         local capacity_file, capacity_err = io.open(bat_dir .. '/capacity', 'r')
         local status_file, status_err = io.open(bat_dir .. '/status', 'r')
         local power_file, power_err = io.open(bat_dir .. '/power_now', 'r')

         if not capacity_file then
            error(capacity_err)
         elseif not status_file then
            error(status_err)
         elseif not power_file then
            error(power_err)
         end

         local capacity = capacity_file:read('*n')
         local status = status_file:read('*l')
         local power = power_file:read('*n')

         capacity_file:close()
         status_file:close()
         power_file:close()

         local battery = basename(bat_dir) -- TODO: Use string manipulation instead so dep on luaposix can be removed
         local battery_log_file, battery_log_err = io.open(battery_log_directory .. '/' .. battery .. '.log', 'a+')

         if not battery_log_file then
            error(battery_log_err)
         end

         local timestamp = os.date('%Y-%m-%d %H:%M:%S', os.time())
         local power_in_watts = power / 1000000
         local log_entry = string.format('%s: %s, %s, %d%%, %.2f W\n',
            timestamp, battery, status, capacity, power_in_watts)

         battery_log_file:write(log_entry)

         battery_log_file:close()
      end

      -- TODO: Find smaller library, that can be easily statically compiled, to handle sleep
      sleep(sleep_interval_sec)
   until stop
end

return daemon
