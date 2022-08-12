local glob = require('posix.glob').glob
local sleep = require('posix.unistd').sleep
local signal = require('posix.signal')
local basename = require('posix.libgen').basename

local daemon = {}

local function get_battery_directories()
   local bat_dirs = {}

   for _, file in pairs(glob('/sys/class/power_supply/BAT*', 0)) do
      table.insert(bat_dirs, file)
   end

   return bat_dirs
end

local battery_directories = get_battery_directories()

function daemon.start(sleep_interval_sec, battery_log_path)
   local stop = false

   local function handler()
      stop = true
   end

   signal.signal(signal.SIGINT, handler)
   signal.signal(signal.SIGTERM, handler)

   repeat
      for _, bat_dir in pairs(battery_directories) do
         local capacity_file, capacity_err = io.open(bat_dir .. '/capacity', 'r')
         local status_file, status_err = io.open(bat_dir .. '/status', 'r')

         if not capacity_file then
            error(capacity_err)
         elseif not status_file then
            error(status_err)
         end

         local capacity = capacity_file:read('*n')
         local status = status_file:read('*l')

         capacity_file:close()
         status_file:close()

         local battery_log_file, battery_log_err = io.open(battery_log_path, 'a+')

         if not battery_log_file then
            error(battery_log_err)
         end

         local timestamp = os.date('%Y-%m-%d %H:%M:%S', os.time())
         local battery = basename(bat_dir)
         battery_log_file:write(timestamp .. ': ' .. battery .. ', ' .. status .. ', ' .. capacity .. '%' .. '\n')

         battery_log_file:close()
      end

      sleep(sleep_interval_sec)
   until stop
end

return daemon
