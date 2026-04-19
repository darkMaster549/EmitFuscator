local walker = require("ast.walker")

local function oNum(n)
    n = math.max(1, math.floor(tonumber(n) or 1))
    local t = math.random(1, 3)
    if t == 1 then
        local a = math.random(1, n)
        return string.format("(%d+%d)", a, n - a)
    elseif t == 2 then
        local b = math.random(1, 50)
        return string.format("(%d-%d)", n + b, b)
    else
        local c = math.random(1, 10)
        local b = math.random(c+1, c+20)
        return string.format("(%d-(%d-%d))", n + (b - c), b, c)
    end
end

return function(ast)
    walker.walk(ast, {
        number = function(tok)
            local n = tonumber(tok.value)
            -- This will Obfuscate only Integers --
            if n and math.floor(n) == n and n >= 1 and n <= 99999 and not tok.value:find("[xX%.]") then
                return {type="raw", value=oNum(n)}
            end
        end
    })
    return ast
end
