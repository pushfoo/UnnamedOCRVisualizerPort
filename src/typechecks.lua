typechecks = {
    is = {
        Integer = function(number)
            if type(number) ~= "number" then return false end
            return math.modf(number) == 0.0
        end,
        Array = function(t)
            return type(t) == "table" and #t ~= nil
        end,
        NonEmptyArray = function(t)
            return type(t) == "table" and #t > 0
        end
    }
}