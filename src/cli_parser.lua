local argparse = require('argparse')

local function setup_stats_cmd(parser)
   parser
       :command('stats')
       :summary('Display statistics about battery usage')
end

local function setup_daemon_cmd(parser)
   parser
       :command('daemon')
       :summary('Start battery log daemon in foreground')
end

local parser = argparse()
    :name('batstat')
    :description('')
    :epilog('Found a bug? Report it at https://github.com/almgru/batstat/issues')

setup_stats_cmd(parser)
setup_daemon_cmd(parser)

return parser
