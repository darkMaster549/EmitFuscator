-- Tokenizer and AST builder for Lua 5.1
local M = {}

local keywords = {
    ["and"]=1,["break"]=1,["do"]=1,["else"]=1,["elseif"]=1,
    ["end"]=1,["false"]=1,["for"]=1,["function"]=1,["if"]=1,
    ["in"]=1,["local"]=1,["nil"]=1,["not"]=1,["or"]=1,
    ["repeat"]=1,["return"]=1,["then"]=1,["true"]=1,["until"]=1,["while"]=1,
}

function M.tokenize(src)
    local tokens = {}
    local i = 1
    local len = #src

    local function peek() return src:sub(i, i) end
    local function advance() i = i + 1 end
    local function cur() return src:sub(i, i) end

    while i <= len do
        -- skip whitespace
        if cur():match("%s") then
            local ws = ""
            while i <= len and cur():match("%s") do ws = ws .. cur(); advance() end
            table.insert(tokens, {type="ws", value=ws})

        -- line comment
        elseif src:sub(i, i+1) == "--" and src:sub(i+2, i+3) ~= "[[" then
            local cm = ""
            while i <= len and cur() ~= "\n" do cm = cm .. cur(); advance() end
            table.insert(tokens, {type="comment", value=cm})

        -- long comment
        elseif src:sub(i, i+3) == "--[[" then
            local cm = "--[["
            i = i + 4
            while i <= len and src:sub(i, i+1) ~= "]]" do cm = cm .. cur(); advance() end
            cm = cm .. "]]"; i = i + 2
            table.insert(tokens, {type="comment", value=cm})

        -- long string
        elseif src:sub(i, i+1) == "[[" then
            local s = "[["
            i = i + 2
            while i <= len and src:sub(i, i+1) ~= "]]" do s = s .. cur(); advance() end
            s = s .. "]]"; i = i + 2
            table.insert(tokens, {type="string", value=s, raw=true})

        -- string
        elseif cur() == '"' or cur() == "'" then
            local q = cur(); advance()
            local s = ""
            while i <= len and cur() ~= q do
                if cur() == "\\" then s = s .. cur(); advance() end
                s = s .. cur(); advance()
            end
            advance()
            table.insert(tokens, {type="string", value=s, quote=q})

        -- number
        elseif cur():match("%d") or (cur() == "." and src:sub(i+1,i+1):match("%d")) then
            local n = ""
            while i <= len and cur():match("[%d%.xXaAbBcCdDeEfF_]") do n = n .. cur(); advance() end
            table.insert(tokens, {type="number", value=n})

        -- identifier or keyword
        elseif cur():match("[%a_]") then
            local id = ""
            while i <= len and cur():match("[%w_]") do id = id .. cur(); advance() end
            if keywords[id] then
                table.insert(tokens, {type="keyword", value=id})
            else
                table.insert(tokens, {type="ident", value=id})
            end

        -- operators and symbols
        else
            local two = src:sub(i, i+1)
            local ops2 = {"==","~=","<=",">=","..","//","<<",">>"}
            local found = false
            for _, op in ipairs(ops2) do
                if two == op then
                    table.insert(tokens, {type="op", value=op})
                    i = i + 2; found = true; break
                end
            end
            if not found then
                table.insert(tokens, {type="sym", value=cur()})
                advance()
            end
        end
    end

    return tokens
end

function M.parse(src)
    local tokens = M.tokenize(src)
    -- Return token stream as flat AST for passes to walk
    return {tokens = tokens, source = src}
end

return M
