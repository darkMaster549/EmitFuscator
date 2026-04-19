local aliases  = require("util.aliases")
local vmGen    = require("codegen.vm")
local encode   = require("util.encode")
local deadcode = require("passes.deadcode")
local cfg      = require("config")

return function(ast, transformed, layerNum)
    local emitted = transformed
    local layerOffset = cfg.offset + (layerNum * 111)
    local bytes = encode.encode(emitted, layerOffset)

    local piece = {}
    for j = 1, #bytes do
        piece[j] = tostring(bytes[j])
    end
    local payload = "{" .. table.concat(piece, ",") .. "}"

    local chars  = #emitted
    local total  = math.max(cfg.noise.min, math.floor(chars * cfg.noise.multiplier))
    local before = math.floor(total * 0.6)
    local after  = total - before

    local decCode = ""
    decCode = decCode .. "local _p=" .. payload .. ";"
    decCode = decCode .. string.format(
        "local _d=function()local o={};for i=1,#_p do o[i]=string.char(_p[i]-%d)end;return table.concat(o)end;",
        layerOffset
    )

    return aliases()
        .. vmGen()
        .. deadcode(before)
        .. decCode
        .. deadcode(after)
        .. "_x(_d())"
end
