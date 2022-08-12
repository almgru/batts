package = 'batstat'
version = 'dev-1'
source = {
   url = 'git+https://github.com/almgru/batstat'
}
description = {
   homepage = 'Track/show battery statistics',
   license = 'MIT'
}
supported_platforms = {
   'linux',
}
dependencies = {
   'lua ~> 5.1',
   'argparse >= 0.7.1-1',
   'luaposix >= 35.1-1',
}
build = {
   type = 'builtin',
   modules = {
      cli_parser = 'src/cli_parser.lua',
      daemon = 'src/daemon.lua',
   },
   install = {
      bin = {
         batstat = 'src/batstat.lua'
      },
   },
}
