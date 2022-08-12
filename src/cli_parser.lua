local argparse = require('argparse')

local function setup_stats_cmd(parser)
   parser
       :command('stats')
       :summary('Display statistics about battery usage')
end

local parser = argparse()
    :name('batstat')
    :description('')
    :epilog('Found a bug? Report it at https://github.com/almgru/batstat/issues')

setup_stats_cmd(parser)

return parser
