local argparse = require('argparse')

local function setup_stats_cmd(parser)
    parser
        :command('stats')
        :summary('Display statistics about battery usage')
end

local function setup_daemon_cmd(parser)
    local daemon_cmd = parser
        :command('daemon')
        :summary('Start battery log daemon in foreground')

    daemon_cmd
        :option('-l --log-directory', 'Directory to save battery logs to')
        :args(1)
        :default('$XDG_DATA_HOME/batstat')

    daemon_cmd
        :option('-i --interval-in-seconds', 'Interval in seconds between log entries')
        :args(1)
        :default(60)
end

local parser = argparse()
    :name('batstat')
    :description('')
    :epilog('Found a bug? Report it at https://github.com/almgru/batstat/issues')

setup_stats_cmd(parser)
setup_daemon_cmd(parser)

return parser
