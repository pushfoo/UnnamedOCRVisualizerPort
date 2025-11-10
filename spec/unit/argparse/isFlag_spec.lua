require 'busted.runner'()

local isFlag = require('argparse').isFlag

describe('argparse.isFlag', function()
    describe('non-flag input', function ()
       it('returns false for empty strings', function()
            assert.False(isFlag(''))
       end)
       local notAString = {
        1,
        true,
        {"e"}
       }
       for _, item in ipairs(notAString) do
        local T_notaString = type(item)
        it(
            string.format('raises an exception for non-string %s (%s)',
            T_notaString, tostring(item)),
            function()
                assert.has_error(function()
                    isFlag(item)
                end)
            end)
       end
       local notFlagsButStrings = {"Yes", "No", "C:\\users\\Username\\Documents\\file.png"}
       describe('returns false for non-flag values', function()
         for _, item in ipairs(notFlagsButStrings) do
            it('returns false for ' .. item, function()
                assert.False(isFlag(item))
            end)
         end
       end)
    end)
end)