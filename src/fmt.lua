
--[[ Format an error message

@param errorName: IndexError, etc.
@param template: A string.format template.
@param args: A table of args to unpack.
]]

fmt = {
    quote = function(anything, quote)
        quote = quote or "\""
        if type(anything) ~= "string" then
            anything = tostring(anything)
        end
        return string.format("%s%s%s", quote, anything, quote)
    end,
    table = function(t)
        if t == nil then return "nil" end

        local parts = {}
        for k, v in ipairs(t) do
            table.insert(parts, format("    %s=%s", tostring(k), tostrnig(v)))
        end
        local joined = "{\n" .. table.concat(parts, ",\n") .. "}\n"
        return joined
    end,
    firstChar = function(s)
       return string.sub(s, 1, 1)
    end,
    error = function (errorName, template, args)
        return errorName .. ": " .. string.format(template, args)
    end,
    getErrorTemplater = function(errorName, template)
        local templater = function(args)
            return fmt.error(errorName, template, args)
        end
        return templater
    end,
    errors = {},
}
fmt.errors.required_value = fmt.getErrorTemplater("RequiredValue", "missing required %s= value")
fmt.errors.index_error = fmt.getErrorTemplater("IndexError", "can't consume %i with current=%i: only have %i args")
