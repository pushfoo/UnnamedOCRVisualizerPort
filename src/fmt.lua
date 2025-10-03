--[[ Shared formatting helpers.

- quote
- flag helpers (short and long)
- table printing
- error formatting
- storage for error format prefabs

]]

fmt = {
    --[[ Quote-wrap any item (naively passes to tostring() first).

    @param anything: a value to quotewrap
    @param quote: optional quote character (defaults to `"`)
    ]]
    quote = function(anything, quote)
        quote = quote or "\""
        if type(anything) ~= "string" then
            anything = tostring(anything)
        end
        return string.format("%s%s%s", quote, anything, quote)
    end,
    -- [[ Format CLI flags. ]]
    flags = {
        --[[ Format a name to a short flag by taking the first character.

        IMPORTANT: Assumes the following:
        - We don't need to case-shift values.
        - The first char will be valid.
        ]]
        short = function(name)
            return "-" .. string.sub(name, 1, 1)
        end,
        --[[ Format a name to a long flag.

        1. Replace all spaces and underscores with "-"
        2. Lowercase it
        3. Prefix "--"
        ]]
        long = function(name)
            return "--" .. string.gsub(name, "[_%w]+", "-").lower()
        end
    },
    --[[ Format a table as a string. ]]
    table = function(t, indent)
        if t == nil then return "nil" end
        if indent == nil then indent = "" end
        local parts = {}
        for k, v in ipairs(t) do
            local kString = tostring(k)
            local vString = nil
            if type(v) == "table" then
                vString = fmt.table(v, indent .. "    ")
            else
                vString = tostring(v)
            end
            local formatted = string.format("    %s=%s", kString, vString)
            table.insert(parts, formatted)
        end
        local joined = "{\n" .. table.concat(parts, ",\n") .. "\n}"
        return joined
    end,
    --[[ Mnemonic sugar around Lua's weirdly-named string.sub function.

    @param s: The string to get the first char of.
    ]]
    firstChar = function(s)
       return string.sub(s, 1, 1)
    end,
    --[[ Format an error message

    @param errorName: IndexError, etc.
    @param template: A string.format template.
    @param args: A table of args to unpack.
    ]]
    error = function (errorName, template, args)
        return errorName .. ": " .. string.format(template, args)
    end,
    -- Return a wrapped fmt.error wrapper which takes a table.
    getErrorTemplater = function(errorName, template)
        local templater = function(args)
            return fmt.error(errorName, template, args)
        end
        return templater
    end,
    --[[ Static table to hold shared error formatters (see below)]]
    errors = {},
}
fmt.errors.required_value = fmt.getErrorTemplater("RequiredValue", "missing required %s= value")
fmt.errors.index_error = fmt.getErrorTemplater("IndexError", "expected %i with current=%i: only have %i args")
fmt.errors.wrong_size = fmt.getErrorTemplater("WrongSizeError", "expected %s, but got %i")
