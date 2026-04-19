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

local function genNoiseBlock(count, blockNum)
    local blockSize = math.min(count, cfg.noise.block_size)
    local stmts = {}
    local blockLocals = 0
    local blockNums = {}
    local blockTbls = {}
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
        if blockLocals >= cfg.noise.block_size then
            local prev = bGetNum()
            if not prev then return "" end
            return string.format("%s=%s;", prev, oNum(math.random(1,9)))
        end
        local v = bNextV()
        local t = math.random(1, 12)
        if t <= 4 or #blockNums == 0 then
            local val = math.random(1, 99)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            local style = math.random(1, 5)
            if style == 1 then
                return string.format("do local %s=%s; end ", v, oNum(val))
            elseif style == 2 then
                return string.format("do local %s=(%s and %s) or %s; end ", v, trueCmp(), oNum(val), oNum(math.random(1,9)))
            elseif style == 3 then
                return string.format("do local %s=%s;while true do if %s then %s=%s+%s;break;end end end ", v, oNum(val), trueCmp(), v, v, oNum(0))
            elseif style == 4 then
                return string.format("do local %s=%s;if %s then %s=%s+%s;end end ", v, oNum(val), trueCmp(), v, v, oNum(0))
            else
                return string.format("do local %s=%s;local _=v11(%s,%d); end ", v, oNum(val), v, math.random(1,9))
            end
        elseif t == 5 then
            local sz = math.random(3, 5)
            local entries = {}
            for i = 1, sz do entries[i] = oNum(math.random(1,50)) end
            table.insert(blockTbls, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s={%s}; end ", v, table.concat(entries, ","))
        elseif t == 8 then
            local val = math.random(2, 9)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s=%s;if (%s<=%s) then %s=%s+%s;elseif (%s or %s<=%s) then %s=%s-%s;end end ", v, oNum(val), v, oNum(val+3), v, v, oNum(0), deadCmp(), v, oNum(1), v, v, oNum(0))
        elseif t == 9 then
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s=%s;while true do if (%s or %s) then break;end end end ", v, oNum(math.random(1,9)), trueCmp(), deadCmp())
        elseif t == 11 then
            local val = math.random(2, 9)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s=%s;repeat %s=%s+%s;until %s>=%s; end ", v, oNum(1), v, v, oNum(0), v, oNum(val))
        else
            local val = math.random(1, 9)
            table.insert(blockNums, v)
            blockLocals = blockLocals + 1
            return string.format("do local %s=%s;local _=v11(%s,%d); end ", v, oNum(val), v, math.random(1,9))
        end
    end

    for i = 1, blockSize do
        local ok, result = pcall(bStmt)
        if ok and result and result ~= "" then
            stmts[#stmts+1] = result
        end
    end

    return "do " .. table.concat(stmts, "") .. " end "
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
