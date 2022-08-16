local cli_parser = require('cli_parser')
local daemon = require('daemon')
local stats = require('stats')
local battery_log_parser = require('battery_log_parser')
local date_utils = require('date_utils')
local func = require('func')

local args, err = cli_parser:parse()

if not args and err then
    error(err)
elseif args.stats then
    if args.log_directory == '$XDG_DATA_HOME/batstat' then
        local home = os.getenv('HOME') or error('HOME is not set.')
        local xdg_data_home = os.getenv('XDG_DATA_HOME') or home .. '/.local/share'
        args.log_directory = xdg_data_home .. '/batstat'
    end

    local find, find_err = io.popen('/usr/bin/find ' .. args.log_directory .. ' -maxdepth 1 -name "BAT*"')
    if not find then error(find_err) end

    local bat_log_files = {}
    for file in find:lines() do
        table.insert(bat_log_files, file)
    end

    find:close()

    if #bat_log_files == 0 then
        print('No battery log files found. Please start the batstat daemon.')
        os.exit(0)
    end

    for _, file in ipairs(bat_log_files) do
        local battery = file:match('.*/(BAT%d)')
        local log_file, log_file_err = io.open(file, 'r')

        if not log_file then
            error(log_file_err)
        end

        local battery_usage_summaries = battery_log_parser.parse(log_file)
        log_file:close()

        local durations = func.map(battery_usage_summaries, function(el) return el.duration end)
        local mean_duration = stats.mean(durations)
        local stddev_durations = stats.standard_deviation(durations)

        if #durations > stats.min_filter_population then
            local z_scores = stats.z_scores(durations, mean_duration, stddev_durations)
            durations = stats.filter_out_outliers(durations, z_scores)

            -- trim mean and stddev to exclude outliers
            mean_duration = stats.mean(durations)
            stddev_durations = stats.standard_deviation(durations)
        end

        local capacity_drain_per_minute = func.map(battery_usage_summaries, function(summary)
            return (summary.capacity_when_charging_started - summary.capacity_when_charging_stopped) / summary.duration
        end)

        local mean_drain_per_minute = stats.mean(capacity_drain_per_minute)
        local stddev_drain_per_minute = stats.standard_deviation(capacity_drain_per_minute)

        if #capacity_drain_per_minute > stats.min_filter_population then
            local z_scores = stats.z_scores(capacity_drain_per_minute, mean_drain_per_minute, stddev_drain_per_minute)
            capacity_drain_per_minute = stats.filter_out_outliers(capacity_drain_per_minute, z_scores)

            -- trim mean and stddev to exclude outliers
            mean_drain_per_minute = stats.mean(capacity_drain_per_minute)
            stddev_drain_per_minute = stats.standard_deviation(capacity_drain_per_minute)
        end

        local capacity_range_lower = func.map(battery_usage_summaries, function(summary)
            return summary.capacity_when_charging_started
        end)

        local capacity_range_upper = func.map(battery_usage_summaries, function(summary)
            return summary.capacity_when_charging_stopped
        end)

        local mean_capacity_range_lower = stats.mean(capacity_range_lower)
        local mean_capacity_range_upper = stats.mean(capacity_range_upper)
        local mean_capacity_range = string.format('%.0f%% - %.0f%%', mean_capacity_range_upper, mean_capacity_range_lower)

        local power_draw = func.reduce(battery_usage_summaries, {}, function(acc, el)
            for _, v in ipairs(el.power) do table.insert(acc, v) end

            return acc
        end)
        local mean_power_draw = stats.mean(power_draw)

        local mean_duration_hours, mean_duration_minutes = date_utils.get_hours_and_minutes(mean_duration)
        local stddev_duration_hours, stddev_duration_minutes = date_utils.get_hours_and_minutes(stddev_durations)
        local mean_discharge_rate = mean_drain_per_minute * 60
        local stddev_discharge_rate = stddev_drain_per_minute * 60
        local extrapolated_full_discharge_time = 100 / math.abs(mean_drain_per_minute)
        local extrapolated_hours, extrapolated_minutes = date_utils.get_hours_and_minutes(extrapolated_full_discharge_time)

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
        local battery_capacity_health = battery_full_file:read('*n') / battery_full_design_file:read('*n')

        battery_cycle_count_file:close()
        battery_full_file:close()
        battery_full_design_file:close()

        local any_nan = tostring(mean_duration) == "nan"
            or tostring(mean_drain_per_minute) == "nan"
            or tostring(mean_capacity_range_lower) == "nan" or tostring(mean_capacity_range_upper) == "nan"
            or tostring(mean_power_draw) == "nan"

        print(battery)
        print('====')

        print('cycle count: ' .. battery_cycle_count)
        print(string.format('capacity health: %.0f%%', battery_capacity_health * 100))

        if tostring(mean_duration) ~= "nan" then
            print('mean discharge time: ' .. mean_duration_hours .. 'h ' .. mean_duration_minutes .. 'm (σ ' ..
                stddev_duration_hours .. 'h ' .. stddev_duration_minutes .. 'm)')
        end

        if tostring(mean_drain_per_minute) ~= "nan" then
            print('mean discharge rate per hour: ' .. string.format('%.2f', mean_discharge_rate) .. '% (σ ' ..
                string.format('%.2f', stddev_discharge_rate) .. '%)')

            print('extrapolated full charge discharge time: ' ..
                extrapolated_hours .. ' hours, ' .. extrapolated_minutes .. ' minutes')
        end

        if tostring(mean_capacity_range_lower) ~= "nan" and tostring(mean_capacity_range_upper) ~= "nan" then
            print('mean off-line capacity range: ' .. mean_capacity_range)
        end

        if tostring(mean_power_draw) ~= "nan" then
            print('mean off-line power draw: ' .. string.format('%.2f W', mean_power_draw))
        end

        if any_nan then
            print('Some statistics are not ready yet. Check back later.')
        end
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
