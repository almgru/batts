local lfs = require('lfs')

local cli_parser = require('cli_parser')

local args, err = cli_parser:parse()

if not args and err then
   return print(err)
elseif args['stats'] then
   local bat_dirs = {}

   for file in lfs.dir('/sys/class/power_supply') do
      if string.find(file, '^BAT') then
         table.insert(bat_dirs, file)
      end
   end

   for _, bat_dir in pairs(bat_dirs) do
      local capacity_file, capacity_err = io.open('/sys/class/power_supply/' .. bat_dir .. '/capacity', 'r')
      local status_file, status_err = io.open('/sys/class/power_supply/' .. bat_dir .. '/status', 'r')

      if not capacity_file then
         error(capacity_err)
      elseif not status_file then
         error(status_err)
      end

      local capacity = capacity_file:read('*n')
      local status = status_file:read('*l')

      io.close(capacity_file)
      io.close(status_file)

      local current_datetime = os.date('%Y-%m-%d %H:%M:%S', os.time())
      print(current_datetime .. ': ' .. bat_dir .. ', ' .. status .. ', ' .. capacity .. '%')
   end
end
