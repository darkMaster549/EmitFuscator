 
local M = {}
 
 
function M.encode(source, layerOffset, marker, sep)
 
    local o = {}
 
    for i = 1, #source do
 
        o[i] = tostring(source:byte(i) + layerOffset)
 
    end
 
    return marker .. table.concat(o, sep)
 
end
 
 
return M
 
