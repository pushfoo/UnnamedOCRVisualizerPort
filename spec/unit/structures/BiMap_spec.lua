require 'busted.runner'()
local structures = require('structures')


local BiMap = require("structures").BiMap

local _newBlankBiMap = function() return BiMap:new() end

local _types = {
    ['number'] = 1,
    ['bool'] = true,
    ['string'] = 'allowed',
    ['table'] = {1, 2}
}

describe("BiMap", function()
    describe("Creation", function()
        describe('with zero arguments', function()
            it('has length zero', function()
                assert.True(_newBlankBiMap():getn() == 0)
            end)
            it('isEmpty() returns true', function()
                assert.True(_newBlankBiMap():isEmpty())
            end)
        end)
    end)
    describe(':insert()', function()

        it('rejects empty args', function()
            local badV = {[1]=nil}
            local expectedError = string.format(structures.ERR_TEMPLATES.BIMAP_ARG_FORMAT, "TypeError")
            local function _doerr()
                _newBlankBiMap():insert()
            end
            assert.has_error(_doerr, expectedError)
        end)

        describe('accepts non-nil keys and values', function()
            for typename, value in pairs(_types) do
                it(string.format(
                    'accepts type %s keys (value = %s)',
                    typename, tostring(value)
                ),
                function()
                    local b = BiMap:new()
                    b:insert({value, typename})
                end)
            end
        end)
    end)
end)
