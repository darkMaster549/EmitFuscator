 
local aliases  = require("util.al")
 
local vmGen    = require("codegen.VH")
 
local encode   = require("util.en")
 
local deadcode = require("passes.de")
 
local cfg      = require("config")
 
 
return function(ast, transformed, layerNum)
 
    local emitted = transformed
 
    local layerOffset = cfg.offset + (layerNum * 111)
 
    local layerMarker = cfg.marker .. tostring(layerNum) .. "!"
 
 
    local encoded = encode.encode(emitted, layerOffset, layerMarker, cfg.sep)
 
 
    local chars  = #emitted
 
    local total  = math.max(cfg.noise.min, math.floor(chars * cfg.noise.multiplier))
 
    local before = math.floor(total * 0.6)
 
    local after  = total - before
 
 
    local decCode = ""
 
    decCode = decCode .. string.format("local _p=%q;", encoded)
 
    decCode = decCode .. string.format("local _p2=string.sub(_p,%d);", #layerMarker + 1)
 
    decCode = decCode .. string.format(
 
        "local _d=function()local o={};local i=1;while i<=#_p2 do local j=i;while j<=#_p2 and string.sub(_p2,j,j)~='%s' do j=j+1 end;local n=tonumber(string.sub(_p2,i,j-1));if n then o[#o+1]=string.char(n-%d)end;i=j+1;end;return table.concat(o)end;",
 
        cfg.sep, layerOffset
 
    )
 
 
    return aliases()
 
        .. vmGen()
 
        .. deadcode(before)
 
        .. decCode
 
        .. deadcode(after)
 
        .. "_x(_d())"
 
end
 
