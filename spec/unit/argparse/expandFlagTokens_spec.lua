require 'busted.runner'()

local expandFlagTokens = require('argparse').expandFlagTokens
describe('argparse.expandFlagTokens', function()
    it('empty returns empty array', function()
        local result = expandFlagTokens({})
        assert.Equals(#result, 0)
    end)
    it('expands short tokens but leaves longs alone', function()
        local result = expandFlagTokens({'--long-flag=1', '-fs'})
        assert.Equals(#result,3)
        local first = result[1]
        assert.Equals(first.flag, 'long')
        assert.Equals(first.expanded, '--long-flag=1')

        local second = result[2]
        assert.Equals(second.flag, 'short')
        assert.Equals(second.expanded, '-f')

        local third = result[3]
        assert.Equals(third.flag, 'short')
        assert.Equals(third.expanded, '-s')

    end)
end)