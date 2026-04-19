local walker = require("ast.walker")

local reserved = {
    pairs=1,ipairs=1,print=1,tostring=1,tonumber=1,type=1,
    math=1,string=1,table=1,unpack=1,select=1,error=1,
    pcall=1,xpcall=1,next=1,rawget=1,rawset=1,rawequal=1,
    setmetatable=1,getmetatable=1,require=1,load=1,loadstring=1,
    game=1,workspace=1,script=1,_ENV=1,_G=1,
    ["and"]=1,["or"]=1,["not"]=1,["true"]=1,["false"]=1,["nil"]=1,
}

local function genName(n)
    local pool = "lIiIlliIlI"
    local name = ""
    local idx = n
    repeat
        local r = (idx % #pool) + 1
        name = pool:sub(r,r) .. name
        idx = math.floor(idx / #pool)
    until idx == 0
    return "_" .. name
end

return function(ast)
    local map = {}
    local counter = math.random(0, 999)
    local tokens = ast.tokens

    for i, tok in ipairs(tokens) do
        if tok.type == "keyword" and (tok.value == "local" or tok.value == "function") then
            for j = i+1, math.min(i+5, #tokens) do
                local t = tokens[j]
                if t.type == "ident" and not reserved[t.value] then
                    if not map[t.value] then
                        map[t.value] = genName(counter)
                        counter = counter + 1
                    end
                    break
                end
            end
        end
        if tok.type == "keyword" and tok.value == "function" then
            local depth = 0
            for j = i+1, math.min(i+30, #tokens) do
                local t = tokens[j]
                if t.type == "punct" and t.value == "(" then depth = depth + 1
                elseif t.type == "punct" and t.value == ")" then
                    depth = depth - 1
                    if depth == 0 then break end
                elseif depth > 0 and t.type == "ident" and not reserved[t.value] then
                    if not map[t.value] then
                        map[t.value] = genName(counter)
                        counter = counter + 1
                    end
                end
            end
        end
    end

    walker.walk(ast, {
        ident = function(tok)
            if map[tok.value] then
                return {type="ident", value=map[tok.value]}
            end
        end
    })

    return ast
end
