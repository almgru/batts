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

   local log_file, log_file_err = io.open('/home/almgru/.local/share/batstat/BAT1.log', 'r')

   if not log_file then
      error(log_file_err)
   end

   local prev_line

   for line in log_file:lines() do
      local charge_cycle = 1

      if prev_line ~= nil then
         local prev = parse_log_entry(prev_line)
         local curr = parse_log_entry(line)

         if curr.timestamp - prev.timestamp > 60 then
            print('new session in charge cycle ' .. charge_cycle)
         end

         if prev.status ~= 'Discharging' and curr.status == 'Discharging' then
            charge_cycle = charge_cycle + 1
            print('start of charge cycle ' .. charge_cycle)
         elseif prev.status == 'Discharging' and curr.status ~= prev.status then
            print('end of charge cycle ' .. charge_cycle)
         end
      else
         print('start of charge cycle ' .. charge_cycle)
      end

      prev_line = line
   end

elseif args.daemon then
   if args.log_directory == '$XDG_DATA_HOME/batstat' then
      local home = os.getenv('HOME') or error('HOME is not set.')
      local xdg_data_home = os.getenv('XDG_DATA_HOME') or home .. '/.local/share'
      args.log_directory = xdg_data_home .. '/batstat'
   end

   os.execute('mkdir -p ' .. args.log_directory)

   daemon.start(args.interval_in_seconds, args.log_directory)
end
