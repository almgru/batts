local version = 'dev-1'

local colors = require('ansicolors')

local cli_parser = require('cli_parser')
local daemon = require('daemon')
local stats = require('stats')
local battery_log_parser = require('battery_log_parser')
local date_utils = require('date_utils')
local func = require('func')

local args, err = cli_parser:parse()

if args.log_directory == '$XDG_DATA_HOME/batts' then
   local home = os.getenv('HOME') or error('HOME is not set.')
   local xdg_data_home = os.getenv('XDG_DATA_HOME') or home .. '/.local/share'
   args.log_directory = xdg_data_home .. '/batts'
end

os.execute('mkdir -p ' .. args.log_directory)

local function get_battery_log_files(log_directory)
   local find, find_err = io.popen('/usr/bin/find ' .. log_directory .. ' -maxdepth 1 -name "BAT*"')
   if not find then error(find_err) end

   local bat_log_files = {}
   for file in find:lines() do
      table.insert(bat_log_files, file)
   end

   find:close()

   return bat_log_files
end

if not args and err then
   error(err)
elseif args.stats then
   local bat_log_files = get_battery_log_files(args.log_directory)

   if #bat_log_files == 0 then
      print(colors('%{red}No battery log files found. Please start the batts daemon.'))
      os.exit(0)
   end

   for _, file in ipairs(bat_log_files) do
      local battery = file:match('.*/(BAT%d)')
      local battery_usage_summaries = battery_log_parser.parse(file)

      local durations = func.map(battery_usage_summaries, function(el) return el.duration end)
      local mean_duration = stats.mean(durations)
      local stddev_durations = stats.standard_deviation(durations)

      local capacity_drain_per_minute = func.map(battery_usage_summaries, function(summary)
         return (summary.capacity_when_charging_started - summary.capacity_when_charging_stopped) / summary.duration
      end)

      local mean_drain_per_minute = stats.mean(capacity_drain_per_minute)
      local stddev_drain_per_minute = stats.standard_deviation(capacity_drain_per_minute)

      local capacity_range_lower = func.map(battery_usage_summaries, function(summary)
         return summary.capacity_when_charging_started
      end)

      local capacity_range_upper = func.map(battery_usage_summaries, function(summary)
         return summary.capacity_when_charging_stopped
      end)

      local mean_capacity_range_lower = stats.mean(capacity_range_lower)
      local mean_capacity_range_upper = stats.mean(capacity_range_upper)

      local power_draw = func.reduce(battery_usage_summaries, {}, function(acc, el)
         for _, v in ipairs(el.power) do table.insert(acc, v) end

         return acc
      end)
      local mean_power_draw = stats.mean(power_draw)
      local stddev_power_draw = stats.standard_deviation(power_draw)

      local mean_duration_hours, mean_duration_minutes = date_utils.get_hours_and_minutes(mean_duration)
      local stddev_duration_hours, stddev_duration_minutes = date_utils.get_hours_and_minutes(stddev_durations)
      local mean_discharge_rate = math.abs(mean_drain_per_minute * 60)
      local stddev_discharge_rate = stddev_drain_per_minute * 60
      local extrapolated_full_discharge_time = 100 / math.abs(mean_drain_per_minute)
      local extrapolated_hours, extrapolated_minutes = date_utils.get_hours_and_minutes(extrapolated_full_discharge_time)
      local extrapolated_range_lower = 100 / (math.abs(mean_drain_per_minute) + math.abs(stddev_drain_per_minute))
      local extrapolated_lower_h, extrapolated_lower_m = date_utils.get_hours_and_minutes(extrapolated_range_lower)
      local extrapolated_range_upper = 100 / (math.abs(mean_drain_per_minute) - math.abs(stddev_drain_per_minute))
      local extrapolated_upper_h, extrapolated_upper_m = date_utils.get_hours_and_minutes(extrapolated_range_upper)

      local battery_cycle_count_file, battery_cycle_count_err = io.open('/sys/class/power_supply/' ..
         battery .. '/cycle_count', 'r')
      local battery_full_file, battery_full_err = io.open('/sys/class/power_supply/' .. battery .. '/energy_full', 'r')
      local battery_full_design_file, battery_full_design_err = io.open('/sys/class/power_supply/' ..
         battery .. '/energy_full_design', 'r')

      if not battery_cycle_count_file then
         error(battery_cycle_count_err)
      end

      if not battery_full_file then
         error(battery_full_err)
      end

      if not battery_full_design_file then
         error(battery_full_design_err)
      end

      local battery_cycle_count = battery_cycle_count_file:read('*n')
      local battery_full = battery_full_file:read('*n')
      local battery_full_design = battery_full_design_file:read('*n')
      local battery_capacity_health = battery_full / battery_full_design

      battery_cycle_count_file:close()
      battery_full_file:close()
      battery_full_design_file:close()

      print(battery)

      local any_nan = tostring(mean_duration) == "nan"
          or tostring(mean_drain_per_minute) == "nan"
          or tostring(mean_capacity_range_lower) == "nan" or tostring(mean_capacity_range_upper) == "nan"
          or tostring(mean_power_draw) == "nan"

      if any_nan then
         print(colors('%{yellow}Some statistics are not ready yet. Check back later.'))
      else
         if tostring(mean_power_draw) ~= "nan" then
            print('mean off-line power draw:\t\t\t' ..
               string.format('%.2f W (± %.2f W)', mean_power_draw, stddev_power_draw))
         end

         if tostring(mean_drain_per_minute) ~= "nan" then
            print('mean discharge rate per hour:\t\t\t' .. string.format('%.2f', mean_discharge_rate) .. '% (± ' ..
               string.format('%.2f', stddev_discharge_rate) .. '%)')
         end

         if tostring(mean_capacity_range_lower) ~= "nan" and tostring(mean_capacity_range_upper) ~= "nan" then
            local color = (mean_capacity_range_upper <= 80 and mean_capacity_range_lower >= 20 and 'green')
                or (mean_capacity_range_upper >= 90 and mean_capacity_range_lower <= 10 and 'red')
                or 'reset'

            print(colors('mean off-line capacity range:\t\t\t' ..
               string.format('%%{%s}%.0f%% - %.0f%%%%{reset}', color, mean_capacity_range_upper,
                  mean_capacity_range_lower)))
         end

         if tostring(mean_duration) ~= "nan" then
            print('mean discharge time:\t\t\t\t' .. mean_duration_hours .. 'h ' .. mean_duration_minutes .. 'm (± ' ..
               stddev_duration_hours .. 'h ' .. stddev_duration_minutes .. 'm)')
         end

         if tostring(extrapolated_hours) ~= 'nan' then
            print('extrapolated full charge discharge time:\t' .. extrapolated_hours .. 'h ' .. extrapolated_minutes ..
               'm (' .. extrapolated_lower_h .. 'h ' .. extrapolated_lower_m .. 'm – ' .. extrapolated_upper_h ..
               'h ' .. extrapolated_upper_m .. 'm)')
         end
      end

      local health_color = (battery_capacity_health >= 0.95 and 'green')
          or (battery_capacity_health <= 0.75 and 'red')
          or 'reset'

      print(colors(string.format(
         'capacity health:\t\t\t\t%%{%s}%.0f%% (%.1f Wh / %.1f Wh)',
         health_color,
         battery_capacity_health * 100,
         battery_full / 1000000,
         battery_full_design / 1000000
      )))

      print('cycle count:\t\t\t\t\t' .. battery_cycle_count)
   end
elseif args.daemon then
   daemon.start(args.interval_in_seconds, args.log_directory)
elseif args.version then
   print('batts version ' .. version)
end
