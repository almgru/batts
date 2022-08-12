local cli_parser = require('cli_parser')
local daemon = require('daemon')

local args, err = cli_parser:parse()

if not args and err then
   return print(err)
elseif args['stats'] then
   print('TODO')
elseif args['daemon'] then
   daemon.start(60, 'battery.log')
end
