require 'busted.runner'()

local splitFlagsInToken = require("argparse").splitFlagInToken
describe('argparse.splitFlags', function()
    it('handles a --long-flag=1 (has an = value ffmpeg-style)', function()
        local result = splitFlagsInToken('--long-flag=1')
        local first = result[1]
        assert.Equals(#result, 1)
        assert.Equals(type(first), 'table')
        assert.Equals(first.expanded,'--long-flag=1')
    end)
    it("handles a block of joint short-flags ('-fs' => {'-f', '-s'} equivalent", function()
        local values = {'f', 's'}
        local result = splitFlagsInToken('-fs')
        assert.Equals(#result, 2)
        for i, v in ipairs(result) do
            assert.Equals(v.value, values[i])
            assert.Equals(v.flag, 'short')
            assert.Equals(v.expanded, '-' .. values[i])
        end
    end)
end)