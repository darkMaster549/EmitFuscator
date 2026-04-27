local M = {}

local function bxor(a, b)
    local r, m = 0, 1
    for i = 1, 32 do
        local ra = a % 2
        local rb = b % 2
        r = r + (ra ~= rb and m or 0)
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        m = m * 2
    end
    return r
end

function M.encode(source, layerOffset, marker, sep)
    local key = math.random(1, 255)
    local o = {}
    for i = 1, #source do
        local b = source:byte(i)
        o[i] = tostring(bxor(b, key) + layerOffset)
    end
    return marker .. tostring(key) .. sep .. table.concat(o, sep)
end

return M
