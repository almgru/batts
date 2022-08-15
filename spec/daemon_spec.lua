local daemon = require('daemon')
local posix = require('posix')
local glob = require('posix.glob').glob
local sleep = require('posix.unistd').sleep
local signal = require('posix.signal')

describe('daemon', function()
    describe('start', function()
        it('starts logging battery capacity level', function()
            local pid = posix.fork()

            if pid == 0 then
                daemon.start(1, '.')
                os.exit(0)
            else
                sleep(1)
                signal.kill(pid)
                posix.wait(pid)
            end

            for _, file in pairs(glob('./BAT*.log', 0)) do
                os.remove(file)
            end
        end)
    end)
end)
