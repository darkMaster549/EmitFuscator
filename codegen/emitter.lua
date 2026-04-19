local aliases  = require("util.aliases")
local vmGen    = require("codegen.vm")
local encode   = require("util.encode")
local deadcode = require("passes.deadcode")
local cfg      = require("config")

local function randSep()
    local pool = "ABCDEFGHJKLMNPRSTUVWXYZ"
    local s = ""
    for i = 1, 2 do
        local idx = math.random(1, #pool)
        s = s .. pool:sub(idx, idx)
    end
    return s
end

return function(ast, transformed, layerNum)
    local emitted = transformed
    local layerOffset = cfg.offset + (layerNum * math.random(50, 200))
    local layerMarker = cfg.marker .. tostring(layerNum) .. "!"
    local sep = randSep()

    local encoded = encode.encode(emitted, layerOffset, layerMarker, sep)

    local markerLen = #layerMarker
    local chars  = #emitted
    local total  = math.max(cfg.noise.min, math.floor(chars * cfg.noise.multiplier))
    local before = math.floor(total * 0.6)
    local after  = total - before

    local sepEncoded = ""
    for i = 1, #sep do
        sepEncoded = sepEncoded .. (i > 1 and ".." or "") ..
            string.format("string.char(%d)", sep:byte(i))
    end

    local decCode = ""
    decCode = decCode .. string.format("local _p=%q;", encoded)
    decCode = decCode .. string.format("local _p2=string.sub(_p,%d);", markerLen + 1)
    decCode = decCode .. string.format("local _sk=(%s);", sepEncoded)
    decCode = decCode .. string.format("local _loff=%d;", layerOffset)
    decCode = decCode .. "local _bx=function(a,b)local r,m=0,1;for i=1,32 do local ra=a%2;local rb=b%2;r=r+(ra~=rb and m or 0);a=math.floor(a/2);b=math.floor(b/2);m=m*2;end;return r;end;"
    decCode = decCode .. "local _d=function()local o={};local i=1;local fi=i;while fi<=#_p2 and string.sub(_p2,fi,fi+#_sk-1)~=_sk do fi=fi+1;end;local _key=tonumber(string.sub(_p2,1,fi-1));i=fi+#_sk;while i<=#_p2 do local j=i;while j<=#_p2 and string.sub(_p2,j,j+#_sk-1)~=_sk do j=j+1;end;local n=tonumber(string.sub(_p2,i,j-1));if n then o[#o+1]=string.char(_bx(n-_loff,_key))end;i=j+#_sk;end;return table.concat(o);end;"

    local vmCode, xn = vmGen()

    return aliases()
        .. vmCode
        .. deadcode(before)
        .. decCode
        .. deadcode(after)
        .. xn .. "(_d())"
end
