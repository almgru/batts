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
    -- TODO: Read from option
    local log_file, log_file_err = io.open('/home/almgru/.local/share/batstat/BAT1.log', 'r')

    if not log_file then
        error(log_file_err)
    end

    local battery_usage_summaries = battery_log_parser.parse(log_file)
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

    print('mean discharge time: ' .. mean_duration_hours .. 'h ' .. mean_duration_minutes .. 'm (σ ' ..
        stddev_duration_hours .. 'h ' .. stddev_duration_minutes .. 'm)')
    print('mean discharge rate per hour: ' .. string.format('%.2f', mean_discharge_rate) .. '% (σ ' ..
        string.format('%.2f', stddev_discharge_rate) .. '%)')
    print('extrapolated full charge discharge time: ' ..
        extrapolated_hours .. ' hours, ' .. extrapolated_minutes .. ' minutes')
    print('mean off-line capacity range: ' .. mean_capacity_range)
    print('mean off-line power draw: ' .. string.format('%.2f W', mean_power_draw))

elseif args.daemon then
    if args.log_directory == '$XDG_DATA_HOME/batstat' then
        local home = os.getenv('HOME') or error('HOME is not set.')
        local xdg_data_home = os.getenv('XDG_DATA_HOME') or home .. '/.local/share'
        args.log_directory = xdg_data_home .. '/batstat'
    end

    os.execute('mkdir -p ' .. args.log_directory)

    daemon.start(args.interval_in_seconds, args.log_directory)
end
