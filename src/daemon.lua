local sleep = require('sleep')
local signal = require('signal').signal

local daemon = {}

local function get_battery_directories()
    local bat_dirs = {}

    local find, err = io.popen('/usr/bin/find /sys/class/power_supply -maxdepth 1 -name "BAT*"')
    if not find then error(err) end

    for file in find:lines() do
        table.insert(bat_dirs, file)
    end

    find:close()

    return bat_dirs
end

local battery_directories = get_battery_directories()

function daemon.start(sleep_interval_sec, battery_log_directory)
    local stop = false
    local sleeping = false

    local function handler()
        if sleeping then os.exit(0) else stop = true end
    end

    signal('SIGINT', handler)
    signal('SIGTERM', handler)

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

            local battery = bat_dir:match('/sys/class/power_supply/(BAT%d)')
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

        sleeping = true
        sleep(sleep_interval_sec * 1000)
        sleeping = false
    until stop
end

return daemon
