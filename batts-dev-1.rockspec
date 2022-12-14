rockspec_format = '3.0'
package = 'batts'
version = 'dev-1'
source = {
   url = 'git+https://github.com/almgru/batts'
}
description = {
   homepage = 'https://github.com/almgru/batts',
   license = 'MIT'
}
supported_platforms = {
   'linux',
}
dependencies = {
   'lua ~> 5.1',
   'argparse >= 0.7.1-1',
   'sleep >= 1.0.0-4',
   'lua_signal >= 1.2.0-1',
   'luastatic >= 0.0.12-1',
   'ansicolors >= 1.0.2-3',
   'ftcsv >= 1.2.1-1',
}
test_dependencies = {
   'busted >= 2.1.1-1',
   'luaposix >= 35.1-1',
}
test = {
   type = 'busted'
}
build = {
   type = 'builtin',
   modules = {
      cli_parser = 'src/cli_parser.lua',
      daemon = 'src/daemon.lua',
      stats = 'src/stats.lua',
      battery_log_parser = 'src/battery_log_parser.lua',
      func = 'src/func.lua',
      date_utils = 'src/date_utils.lua',
      math_utils = 'src/math_utils.lua',
   },
   install = {
      bin = {
         batts = 'src/batts.lua'
      },
   },
}
