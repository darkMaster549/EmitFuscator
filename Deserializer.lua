--==This file Reads a Lua 5.1 luac binary and returns a proto table==--

local Deserializer = {}

local function newReader(data)
    local r = { data = data, pos = 1 }

    function r:byte()
        local b = data:byte(self.pos)
        self.pos = self.pos + 1
        return b
    end

    function r:bytes(n)
        local s = data:sub(self.pos, self.pos + n - 1)
        self.pos = self.pos + n
        return s
    end

    function r:int32()
        local a, b, c, d = data:byte(self.pos, self.pos + 3)
        self.pos = self.pos + 4
        return a + b * 256 + c * 65536 + d * 16777216
    end

    function r:uint32()
        local v = self:int32()
        if v < 0 then v = v + 4294967296 end
        return v
    end

    function r:double()
        local bytes = { data:byte(self.pos, self.pos + 7) }
        self.pos = self.pos + 8

        local sign = (bytes[8] >= 128) and -1 or 1
        local exp  = (bytes[8] % 128) * 16 + math.floor(bytes[7] / 16)
        local frac = (bytes[7] % 16) * 2^48

        local pos2 = 2^40
        for i = 6, 1, -1 do
            frac = frac + bytes[i] * pos2
            pos2 = pos2 / 256
        end

        if exp == 0 and frac == 0 then return 0.0 end
        if exp == 2047 then
            return (frac == 0) and (sign * math.huge) or (0/0)
        end

        return sign * math.ldexp(1 + frac / 2^52, exp - 1023)
    end

    function r:string()
        local len = self:uint32()
        if len == 0 then return nil end
        local s = self:bytes(len)
        return s:sub(1, -2) -- strip null terminator
    end

    return r
end

local function readProto(r)
    local proto = {}

    proto.source     = r:string()
    proto.lineDefined    = r:int32()
    proto.lastLineDefined = r:int32()
    proto.numUpvalues    = r:byte()
    proto.numParams      = r:byte()
    proto.isVararg       = r:byte()
    proto.maxStack       = r:byte()

    -- Instructions
    local numInstructions = r:int32()
    proto.instructions = {}
    for i = 1, numInstructions do
        proto.instructions[i] = r:uint32()
    end

    -- Constants
    local numConstants = r:int32()
    proto.constants = {}
    for i = 1, numConstants do
        local t = r:byte()
        if t == 0 then
            proto.constants[i] = { type = "nil", value = nil }
        elseif t == 1 then
            proto.constants[i] = { type = "boolean", value = r:byte() ~= 0 }
        elseif t == 3 then
            proto.constants[i] = { type = "number", value = r:double() }
        elseif t == 4 then
            proto.constants[i] = { type = "string", value = r:string() }
        else
            error("Unknown constant type: " .. t)
        end
    end

    -- Sub-protos (nested functions)
    local numProtos = r:int32()
    proto.protos = {}
    for i = 1, numProtos do
        proto.protos[i] = readProto(r)
    end

    -- Source line positions
    local numLines = r:int32()
    proto.lineInfo = {}
    for i = 1, numLines do
        proto.lineInfo[i] = r:int32()
    end

    -- Locals
    local numLocals = r:int32()
    proto.locals = {}
    for i = 1, numLocals do
        proto.locals[i] = {
            name     = r:string(),
            startPC  = r:int32(),
            endPC    = r:int32(),
        }
    end

    -- Upvalue names
    local numUpvalNames = r:int32()
    proto.upvalueNames = {}
    for i = 1, numUpvalNames do
        proto.upvalueNames[i] = r:string()
    end

    return proto
end

function Deserializer.decode(bytecode)
    local r = newReader(bytecode)

    -- Validate Lua 5.1 header
    local sig = r:bytes(4)
    assert(sig == "\27Lua", "Not a Lua bytecode file")
    local ver = r:byte()
    assert(ver == 0x51, "Only Lua 5.1 bytecode supported (got " .. string.format("0x%X", ver) .. ")")

    r:byte() -- format (0 = official)
    r:byte() -- endianness (1 = little)
    r:byte() -- int size
    r:byte() -- size_t size
    r:byte() -- instruction size
    r:byte() -- number size
    r:byte() -- integral flag

    return readProto(r)
end

return Deserializer
