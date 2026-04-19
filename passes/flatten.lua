local walker = require("ast.walker")

-- Wraps top-level do...end blocks with an extra control flow layer --
-- making it harder to follow execution order --
return function(ast)
    local tokens = ast.tokens
    local result = {}
    local i = 1

    while i <= #tokens do
        local tok = tokens[i]
        -- This will wrap standalone do blocks with repeat...until true --
        if tok.type == "keyword" and tok.value == "do" then
            table.insert(result, {type="keyword", value="repeat"})
            table.insert(result, {type="ws", value=" "})
            table.insert(result, tok)
            i = i + 1
            -- And This will find Matching end --
            local depth = 1
            while i <= #tokens and depth > 0 do
                local t = tokens[i]
                if t.type == "keyword" and (t.value == "do" or t.value == "then" or t.value == "function") then
                    depth = depth + 1
                elseif t.type == "keyword" and t.value == "end" then
                    depth = depth - 1
                    if depth == 0 then
                        table.insert(result, t)
                        table.insert(result, {type="ws", value=" "})
                        table.insert(result, {type="keyword", value="until"})
                        table.insert(result, {type="ws", value=" "})
                        table.insert(result, {type="raw", value="true"})
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
