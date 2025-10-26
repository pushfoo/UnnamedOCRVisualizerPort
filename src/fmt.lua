--[[ Shared formatting helpers.

- quote
- flag helpers (short and long)
- table printing
- error formatting
- storage for error format prefabs

]]

local fmt = {}

--- Quote-wrap any item (naively passes to tostring() first).
---@param anything any a value to quotewrap
---@param quote string? optional quote character (defaults to `"`)
---@return string
function fmt.quote(anything, quote)
    quote = quote or "\""
    if type(anything) ~= "string" then
        anything = tostring(anything)
    end
    return string.format("%s%s%s", quote, anything, quote)
end

    -- [[ Format CLI flags. ]]
fmt.flags = {}


--- Format a name to a short flag by taking the first character.
--- IMPORTANT: Assumes the following:
--- - We don't need to case-shift values.
--- - The first char will be valid.
---@param name string The name of the variable.
---@return string - The `-n` for `name_width_underscores`.
function fmt.flags.short(name)
    return "-" .. string.sub(name, 1, 1)
end

--- Format a name to a long flag.
---@param name string A value name for the flag.
---@param autoLower? boolean Whether to autolowercase.
---@return string? - A string of the form `--name-with-dashes`.
function fmt.flags.long(name, autoLower)
    local substituted = name:gsub("[_%w]+", "-")
    if substituted then
        if autoLower or false then
             substituted = substituted:lower()
        end
        return "--" .. substituted
    end
    return nil
end

--- Format a table as a string.
---@param t table<any, any>
---@param indent? string
---@return string
function fmt.table(t, indent)
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
end

--- Format an error message
---@param errorName string IndexError, etc.
---@param template string A string.format template.
---@param args table<string, any> A table of args to unpack.
---@return string
function fmt.error(errorName, template, args)
    return errorName .. ": " .. string.format(template, unpack(args))
end

--- Return a wrapped fmt.error wrapper which takes a table.
---@param errorName string
---@param template string
---@return function
function fmt.getErrorTemplater(errorName, template)
    local templater = function(args)
        return fmt.error(errorName, template, args)
    end
    return templater
end

--[[ Static table to hold shared error formatters (see below)]]
fmt.errors = {
    required_value = fmt.getErrorTemplater("RequiredValue", "missing required %s= value"),
    index_error = fmt.getErrorTemplater("IndexError", "expected %i with current=%i: only have %i args"),
    wrong_size = fmt.getErrorTemplater("WrongSizeError", "expected %s, but got %i")
}

return fmt