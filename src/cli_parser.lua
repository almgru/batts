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
       :option('-i --interval-in-seconds', 'Interval in seconds between log entries')
       :args(1)
       :default(60)
end

local parser = argparse()
    :name('batts')
    :description('')
    :epilog('Found a bug? Report it at https://github.com/almgru/batts/issues')

parser:option('-l --log-directory', 'Directory to store/read battery logs from/to')
    :args(1)
    :default('$XDG_DATA_HOME/batts')

setup_stats_cmd(parser)
setup_daemon_cmd(parser)

return parser
