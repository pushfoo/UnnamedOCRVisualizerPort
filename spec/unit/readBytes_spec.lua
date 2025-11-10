require 'busted.runner'()

local env = require('env')
if love == nil then
    _G.love = {
        data = {},
        graphics = {}
    }
    _G.ISTUBBED = true
end

---@diagnostic disable
if describe == nil then describe = _G.describe end
if it == nil then it = _G.it end
if assert == nil then
    assert = _G.assert
    if assert.True == nil then assert.True = _G.assert.True end
    if assert.has_error == nil then assert.has_error = _G.assert.has_error end
end
---@diagnostic enable

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
                ---@diagnostic disable-next-line
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