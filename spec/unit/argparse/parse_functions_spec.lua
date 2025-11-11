require 'busted.runner'()

local startsWith = require('util').startsWith
local argparse = require('argparse')
local parseNumber = argparse.parseNumber
local parseSize = argparse.parseSize

local function packOneOffGeneratorFunction(raw)
    local toReturn = --[[@as string?]] raw
    local toIndex = 1
    local function it()
        local gotten = toReturn
        local gottendIndex = toIndex
        if gotten then
            toReturn = nil
            toIndex = nil
        end
        return gotten,gottendIndex
    end
    return it
end

local function emptyIt()
    return nil,nil
end

describe('argparse.parseNumber', function()
    describe('returns nil and error for non-number strings', function()
        local notNumberStrings = {
            '',
            'aardvark',
            '-f',
            '--long-flag'
        }
        for i, v in ipairs(notNumberStrings) do
            it("returns nil,errorString for str='" .. v .. "'", function()
                local iter = packOneOffGeneratorFunction(v)
                local num, err = parseNumber(iter, 'e')
                assert.Equals(num, nil)
                assert.True(type(err) == 'string')
                assert.True(startsWith(err, 'ParseError:'))
            end)
        end
    end)
    it('returns nil and error for emp[ty generator', function()
        local num, err = parseNumber(emptyIt, 'number')
        assert.Equals(num, nil)
        assert.True(type(err) == 'string')
        assert.True(startsWith(err, 'ParseError'))
    end)
    describe('returns number and nil for error string on valid values', function()
        local values = {
            {'1', 1},
            {'0x2', 2},
            {'-1', -1}
        }

        for i, v in ipairs(values) do
            local raw = v[1]
            local expected = v[2]
            it(string.format('reads %s as %i', raw, expected), function()
                local iter = packOneOffGeneratorFunction(raw)
                local num, err = parseNumber(iter)
                assert.Equals(type(num), 'number')
                assert.Equals(err, nil)
                assert.Equals(num, expected)
            end)
        end
    end)
end)

local function packIteratorOf2(a, b)
    local i = 0
    local src = {a,b}
    local function inner()
        if i <= 2 then
            i = i + 1
            return src[i],i
        end
        return nil,nil
    end
    return inner
end

describe('argparse.parseSize', function()
    for _, pair in ipairs({
        {},
        {'a','2'},
        {'2', 'b'},
    }) do
        local it = packIteratorOf2(pair[1], pair[2])
        local s,err = parseSize(it)
        assert.Equals(s,nil)
        assert.Equals(type(err), 'string')
        assert.True(startsWith(err, "ParseError:"))
    end

    for _, pair in ipairs({
        {{'0', '0'}, {0,0}},
        {{'1', '1'}, {1,1}},
        {{'200', '200'}, {200,200}},
        {{'-1', '-1'}, {-1,-1}}
    }) do
        if #pair ~= 2 then error("Bad pair length? " .. tostring(#pair)) end
        local raw = pair[1]
        local wRaw = raw[1]
        local hRaw = raw[2]
        local expected = pair[2]
        local wExpected = expected[1]
        local hExpected = expected[2]
        it(string.format('parses %s, %s, as %i, %i + name=nil', wRaw, hRaw, wExpected, hExpected), function()
            local iter = packIteratorOf2(wRaw, hRaw)
            local first, err = parseSize(iter)
            assert.Equals(err, nil)
            assert.Equals(first[1], wExpected)
            assert.Equals(first[2], hExpected)
        end)
        it(string.format('parses %s, %s, as %i, %i + name="customSizeName"', wRaw, hRaw, wExpected, hExpected), function()
            local iter = packIteratorOf2(wRaw, hRaw)
            local second, err = parseSize(iter, 'customSizeName')
            assert.Equals(err, nil)
            assert.Equals(second[1], wExpected)
            assert.Equals(second[2], hExpected)
        end)
    end
end)