local walker = require("ast.walker")

return function(ast)
    local tokens = ast.tokens
    local result = {}
    local i = 1

    while i <= #tokens do
        local tok = tokens[i]
        if tok.type == "keyword" and tok.value == "do" then
            local dvar = "_d" .. tostring(math.random(1000, 9999))
            local state = math.random(10, 99)
            local next  = math.random(100, 999)

            table.insert(result, {type="raw", value=
                "local "..dvar.."="..tostring(state)..
                ";while "..dvar.."~=0 do if "..dvar.."=="..tostring(state).." then "..dvar.."="..tostring(next)..";"
            })
            i = i + 1

            local depth = 1
            while i <= #tokens and depth > 0 do
                local t = tokens[i]
                if t.type == "keyword" and (t.value == "do" or t.value == "then" or t.value == "function") then
                    depth = depth + 1
                elseif t.type == "keyword" and t.value == "end" then
                    depth = depth - 1
                    if depth == 0 then
                        table.insert(result, {type="raw", value=
                            ";"..dvar.."=0;elseif "..dvar.."=="..tostring(next).." then "..dvar.."=0;end end"
                        })
                        i = i + 1
                        break
                    end
                end
                table.insert(result, t)
                i = i + 1
            end
        else
            table.insert(result, tok)
            i = i + 1
        end
    end

    ast.tokens = result
    return ast
end
