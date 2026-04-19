local M = {}

-- Walk tokens and call visitor for each token type
function M.walk(ast, visitors)
    for i, tok in ipairs(ast.tokens) do
        local fn = visitors[tok.type]
        if fn then
            local result = fn(tok, i, ast.tokens)
            if result ~= nil then
                ast.tokens[i] = result
            end
        end
    end
end

-- Emit tokens back to source string
function M.emit(ast)
    local parts = {}
    for _, tok in ipairs(ast.tokens) do
        if tok.type == "string" and not tok.raw then
            parts[#parts+1] = tok.quote .. tok.value .. tok.quote
        elseif tok.type == "string" and tok.raw then
            parts[#parts+1] = tok.value
        else
            parts[#parts+1] = tok.value
        end
    end
    return table.concat(parts)
end

return M
