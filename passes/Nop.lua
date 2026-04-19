local cfg = require("config")

local function trueCmp()
    local a = math.random(100, 500)
    local b = math.random(a+1, a+500)
    local t = math.random(1, 3)
    if t == 1 then return string.format("(%d<=%d)", a, b)
    elseif t == 2 then return string.format("(%d>=%d)", b, a)
    else return string.format("(%d==%d)", a, a) end
end

local function deadCmp()
    local a = math.random(100, 500)
    local b = math.random(a+1, a+500)
    local t = math.random(1, 3)
    if t == 1 then return string.format("(%d>=%d)", a, b)
    elseif t == 2 then return string.format("(%d<=%d)", b, a)
    else return string.format("(%d==%d)", a, b) end
end

local function oNum(n)
    n = math.max(1, math.floor(n))
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
        return string.format("(%d-(%d-%d))", n + (b-c), b, c)
    end
end

local function realStmt(v)
    local t = math.random(1, 6)
    if t == 1 then
        
        local s = math.random(3, 9)
        local str = ""
        for i = 1, s do str = str .. string.char(math.random(65, 90)) end
        return string.format("local %s=#%q;", v, str)
    elseif t == 2 then
        
        local a = math.random(2, 20)
        local b = math.random(2, 20)
        return string.format("local %s=math.floor(%d*%d/%d);", v, a*b, math.random(1,4), math.random(1,4))
    elseif t == 3 then
        
        local sz = math.random(2, 4)
        local entries = {}
        for i = 1, sz do entries[i] = tostring(math.random(1, 100)) end
        return string.format("local %s={%s};%s=%s[%d];", v, table.concat(entries,","), v, v, math.random(1, sz))
    elseif t == 4 then
        
        local str = string.char(math.random(65,90)) .. string.char(math.random(65,90))
        return string.format("local %s=string.byte(%q,%d);", v, str, math.random(1,2))
    elseif t == 5 then
        -- modulo --
        local a = math.random(10, 999)
        local b = math.random(2, 9)
        return string.format("local %s=%d%%%d;", v, a, b)
    else
        
        local a = math.random(1, 50)
        local b = math.random(51, 100)
        return string.format("local %s;if %s then %s=%d else %s=%d end;", v, trueCmp(), v, a, v, b)
    end
end

local function shiftedConst(v, val)
    local shift = math.random(1, 50)
    local t = math.random(1, 3)
    if t == 1 then
        return string.format("local %s=(%d+%d);", v, val - shift, shift)
    elseif t == 2 then
        return string.format("local %s=(%d-%d);", v, val + shift, shift)
    else
        local mul = math.random(2, 5)
        if val % mul == 0 then
            return string.format("local %s=(%d*%d);", v, val // mul, mul)
        else
            return string.format("local %s=(%d+%d);", v, val - shift, shift)
        end
    end
end

local function genNoiseBlock(count, blockNum)
    local blockSize = math.min(count, cfg.noise.block_size)
    local stmts = {}
    local blockLocals = 0
    local blockNums = {}
    local localVIdx = 200 + (blockNum * 500)

    local function bNextV()
        local name = "v" .. tostring(localVIdx)
        localVIdx = localVIdx + 1
        return name
    end

    local function bGetNum()
        if #blockNums == 0 then return nil end
        return blockNums[math.random(1, #blockNums)]
    end

    local function bStmt()
        local v = bNextV()
        local t = math.random(1, 10)

        if t <= 3 then
            
            local s = realStmt(v)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return "do " .. s .. " end "

        elseif t <= 5 then
            
            local val = math.random(1, 999)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return "do " .. shiftedConst(v, val) .. " end "

        elseif t == 6 then
            
            local iters = math.random(2, 5)
            local acc = math.random(1, 10)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s=%d;for _i=1,%d do %s=%s+_i;end end ", v, acc, iters, v, v)

        elseif t == 7 then
            
            local a = string.char(math.random(65,90))
            local b = string.char(math.random(65,90))
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s=%q..%q;%s=#%s; end ", v, a, b, v, v)

        elseif t == 8 then
            
            local val = math.random(1, 99)
            local prev = bGetNum()
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            local sc = shiftedConst(v, val)
            if prev then
                return string.format("do %s if %s>0 then %s=%s+0;end end ", sc, v, v, v)
            else
                return "do " .. sc .. " end "
            end

        elseif t == 9 then
            
            local a = math.random(10, 500)
            local b = math.random(2, 9)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s=math.floor(%d/%d); end ", v, a, b)

        else
            -- real table length
            local sz = math.random(2, 5)
            local entries = {}
            for i = 1, sz do entries[i] = tostring(math.random(1,99)) end
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s={%s};%s=#%s; end ", v, table.concat(entries,","), v, v)
        end
    end

    for i = 1, blockSize do
        local ok, result = pcall(bStmt)
        if ok and result and result ~= "" then
            stmts[#stmts+1] = result
        end
    end

    return table.concat(stmts, "")
end

return function(count)
    local blocks = {}
    local remaining = count
    local blockNum = 0
    while remaining > 0 do
        local blockSize = math.min(remaining, cfg.noise.block_size)
        blockNum = blockNum + 1
        blocks[#blocks+1] = genNoiseBlock(blockSize, blockNum)
        remaining = remaining - blockSize
    end
    return table.concat(blocks, "")
end
