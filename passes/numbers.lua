local walker = require("ast.walker")

local function shiftNum(n)
    local t = math.random(1, 4)
    if t == 1 then
        local s = math.random(1, 50)
        return string.format("(%d+%d)", n - s, s)
    elseif t == 2 then
        local s = math.random(1, 50)
        return string.format("(%d-%d)", n + s, s)
    elseif t == 3 then
        local mul = math.random(2, 5)
        if n % mul == 0 and n > 0 then
            return string.format("(%d*%d)", n // mul, mul)
        else
            local s = math.random(1, 50)
            return string.format("(%d+%d)", n - s, s)
        end
    else
        -- shift using string.len of a known string
        local s = math.random(1, 20)
        local pad = n - s
        if pad >= 0 then
            local str = string.rep("x", s)
            return string.format("(#%q+%d)", str, pad)
        else
            local ss = math.random(1, 50)
            return string.format("(%d+%d)", n - ss, ss)
        end
    end
end

return function(ast)
    walker.walk(ast, {
        number = function(tok)
            local n = tonumber(tok.value)
            if n and math.floor(n) == n and n >= 1 and n <= 99999 and not tok.value:find("[xX%.]") then
                return {type="raw", value=shiftNum(n)}
            end
        end
    })
    return ast
end
