require 'busted.runner'()

local structures = require('structures')
local ERR_TEMPLATES = structures.ERR_TEMPLATES
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
        local BIMAP_ARG_FORMAT = ERR_TEMPLATES.BIMAP_ARG_FORMAT
        it('rejects empty args', function()
            local expectedError = string.format(BIMAP_ARG_FORMAT, "TypeError")
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
                BIMAP_ARG_FORMAT,
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
        describe('It rejects keys with names identical to BiMaps member names', function()
            local BIMAP_MEMBER_CONFLICT = ERR_TEMPLATES.BIMAP_MEMBER_CONFLICT
            for k, v in pairs(BiMap) do
                local expectedError = string.format(BIMAP_MEMBER_CONFLICT, tostring(k))
                it('rejects name ' .. tostring(k), function()
                    local b = BiMap:new()
                    assert.has_error(function()
                        b:insert({k, 'should reject this'})
                    end, expectedError)
                end)
            end
        end)

        describe('__index()', function()
            it('bimap[nameString]', function()
                local b = BiMap:new()
                b:insert({'a', 1})
                local indexedValue = b['a']

                assert.True(indexedValue == 1)
            end)
            it('bimap.NAME_HERE', function()
                local b = BiMap:new()
                b:insert({'NAME_HERE', 'value'})
                local indexedValue = b.NAME_HERE

                assert.True(indexedValue == 'value')
            end)
        end)
    end)
end)
