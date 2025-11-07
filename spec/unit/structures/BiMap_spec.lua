require 'busted.runner'()
local structures = require('structures')


local BiMap = require("structures").BiMap

local _newBlankBiMap = function() return BiMap:new() end

local _types = {
    2,
    true,
    'allowed',
    {1, 2}
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
            local expectedError = string.format(structures.ERR_TEMPLATES.BIMAP_ARG_FORMAT, "TypeError")
            local function _doerr()
                _newBlankBiMap():insert()
            end
            assert.has_error(_doerr, expectedError)
        end)


        describe('accepts {k, v} array pairs', function()
            for _, value in ipairs(_types) do
                local typename = type(value)
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


        describe('rejects other pairs', function()
            local expectedErr = string.format(
                structures.ERR_TEMPLATES.BIMAP_ARG_FORMAT,
                "ValueError"
            )
            local function doBadWith(_bad)
                local function do_err()
                    local b = BiMap:new()
                    b:insert(_bad)
                end
                it(string.format('rejects tables with length %i', #_bad), function()
                    assert.has_error(do_err, expectedErr)
                end)
            end
            doBadWith({1,})
            doBadWith({1,2,3})
            doBadWith({1,2,3,4,5})
        end)
    end)
end)
