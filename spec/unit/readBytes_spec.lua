require 'busted.runner'()
if love == nil then
    _G.love = {
        data = {},
        graphics = {}
    }
    _G.ISTUBBED = true
end
local env = require('env')

describe("env", function()
    assert(env ~= nil)
    describe("env.run.readyBytes", function()
        it("reads bytes", function()
            local _passedData = nil
            local DUMMY_DATA = {}
            love = {
                data = {
                }
            }
            if _G.ISTUBBED then
                function _G.love.data.decode(returnType, format, data)
                    _passedData = data
                    return DUMMY_DATA
                end
            end
            -- Simple and reliable compared to string handling
            local _bytes = env.run.readBytes("cat spec/unit/env_example_byte.raw")
            assert.True(_bytes == DUMMY_DATA)
            assert.True(_passedData == 'AQID', string.format("Expected 'AQID' but got '%s'",  _passedData))
        end)
    end)
end)
  -- tests to here