local VMTemplate = {}
-- allais --
VMTemplate.source = [==[
local b=string.byte;local sb=string.sub;local cc=string.char;local tc=table.concat;local ti=table.insert;local mld=math.ldexp;local mfl=math.floor;local sel=select;local unp=unpack or table.unpack;local genv=getfenv or function() return _ENV end;

local function decode(data)
    local pos=1
    local function rByte()
        local v=b(data,pos);pos=pos+1;return v
    end
    local function rInt32()
        local a,b2,c,d=b(data,pos,pos+3);pos=pos+4
        local v=a+b2*256+c*65536+d*16777216
        if v>=2147483648 then v=v-4294967296 end
        return v
    end
    local function rUint32()
        local v=rInt32()
        if v<0 then v=v+4294967296 end
        return v
    end
    local function rDouble()
        local bytes={b(data,pos,pos+7)};pos=pos+8
        local sign=(bytes[8]>=128) and -1 or 1
        local exp=(bytes[8]%128)*16+mfl(bytes[7]/16)
        local frac=(bytes[7]%16)*2^48
        local pw=2^40
        for i=6,1,-1 do frac=frac+bytes[i]*pw;pw=pw/256 end
        if exp==0 and frac==0 then return 0.0 end
        if exp==2047 then return frac==0 and sign*math.huge or 0/0 end
        return sign*mld(1+frac/2^52,exp-1023)
    end
    local function rString()
        local len=rUint32()
        if len==0 then return nil end
        local s=sb(data,pos,pos+len-2);pos=pos+len
        return s
    end

    local function readProto()
        local proto={}
        proto.source=rString()
        proto.lineDefined=rInt32()
        proto.lastLineDefined=rInt32()
        proto.numUpvalues=rByte()
        proto.numParams=rByte()
        proto.isVararg=rByte()
        proto.maxStack=rByte()

        local ni=rInt32()
        proto.instructions={}
        for i=1,ni do proto.instructions[i]=rUint32() end

        local nc=rInt32()
        proto.constants={}
        for i=1,nc do
            local t=rByte()
            if t==0 then
                proto.constants[i]=nil
            elseif t==1 then
                proto.constants[i]=(rByte()~=0)
            elseif t==3 then
                proto.constants[i]=rDouble()
            elseif t==4 then
                proto.constants[i]=rString()
            end
        end

        local np=rInt32()
        proto.protos={}
        for i=1,np do proto.protos[i]=readProto() end

        rInt32() rInt32() rInt32() -- skip stripped debug sections
        return proto
    end

    return readProto()
end

local function luaVM(proto, upvals, env)
    local function execProto(proto, upvals, ...)
        local regs   = {}
        local pc     = 1
        local insts  = proto.instructions
        local consts = proto.constants
        local protos = proto.protos
        local top    = -1
        local vararg = {...}

        -- Load params
        for i=1,proto.numParams do
            regs[i-1]=vararg[i]
        end

        -- Upvalue cell system
        local openUpvals = {}
        local function getUpval(uv)
            return uv[1][uv[2]]
        end
        local function setUpval(uv, v)
            uv[1][uv[2]] = v
        end
        local function closeUpvals(from)
            for k,uv in pairs(openUpvals) do
                if k >= from then
                    local v = uv[1][uv[2]]
                    uv[1] = {v}
                    uv[2] = 1
                    openUpvals[k] = nil
                end
            end
        end
        local function openUpval(reg)
            if not openUpvals[reg] then
                openUpvals[reg] = {regs, reg}
            end
            return openUpvals[reg]
        end

        local function RK(x)
            if x >= 256 then return consts[x-256+1]
            else return regs[x] end
        end

        -- decode instruction fields
        local function getABC(i)
            local op = i % 64
            local a  = mfl(i/64)   % 256
            local c  = mfl(i/16384) % 512
            local b2 = mfl(i/8388608) % 512
            return op, a, b2, c
        end
        local function getABx(i)
            local op = i % 64
            local a  = mfl(i/64) % 256
            local bx = mfl(i/16384) % 262144
            return op, a, bx
        end
        local function getAsBx(i)
            local op, a, bx = getABx(i)
            return op, a, bx - 131071
        end

        local function callProto(f, args)
            if type(f) == "function" then
                return {f(unp(args))}
            elseif type(f) == "table" then
                local mt = getmetatable(f)
                if mt and mt.__call then
                    return {mt.__call(f, unp(args))}
                end
            end
            error("attempt to call a " .. type(f) .. " value")
        end

        while true do
            local inst = insts[pc]
            local op, a, b2, c = getABC(inst)
            pc = pc + 1

            if op == 0 then -- MOVE
                regs[a] = regs[b2]

            elseif op == 1 then -- LOADK
                local _, _, bx = getABx(inst)
                regs[a] = consts[bx+1]

            elseif op == 2 then -- LOADBOOL
                regs[a] = (b2 ~= 0)
                if c ~= 0 then pc = pc + 1 end

            elseif op == 3 then -- LOADNIL
                for i = a, b2 do regs[i] = nil end

            elseif op == 4 then -- GETUPVAL
                regs[a] = getUpval(upvals[b2+1])

            elseif op == 5 then -- GETGLOBAL
                local _, _, bx = getABx(inst)
                regs[a] = env[consts[bx+1]]

            elseif op == 6 then -- GETTABLE
                regs[a] = regs[b2][RK(c)]

            elseif op == 7 then -- SETGLOBAL
                local _, _, bx = getABx(inst)
                env[consts[bx+1]] = regs[a]

            elseif op == 8 then -- SETUPVAL
                setUpval(upvals[b2+1], regs[a])

            elseif op == 9 then -- SETTABLE
                regs[a][RK(b2)] = RK(c)

            elseif op == 10 then -- NEWTABLE
                regs[a] = {}

            elseif op == 11 then -- SELF
                local obj = regs[b2]
                regs[a+1] = obj
                regs[a]   = obj[RK(c)]

            elseif op == 12 then -- ADD
                regs[a] = RK(b2) + RK(c)

            elseif op == 13 then -- SUB
                regs[a] = RK(b2) - RK(c)

            elseif op == 14 then -- MUL
                regs[a] = RK(b2) * RK(c)

            elseif op == 15 then -- DIV
                regs[a] = RK(b2) / RK(c)

            elseif op == 16 then -- MOD
                regs[a] = RK(b2) % RK(c)

            elseif op == 17 then -- POW
                regs[a] = RK(b2) ^ RK(c)

            elseif op == 18 then -- UNM
                regs[a] = -regs[b2]

            elseif op == 19 then -- NOT
                regs[a] = not regs[b2]

            elseif op == 20 then -- LEN
                regs[a] = #regs[b2]

            elseif op == 21 then -- CONCAT
                local parts = {}
                for i = b2, c do parts[#parts+1] = tostring(regs[i]) end
                regs[a] = tc(parts)

            elseif op == 22 then -- JMP
                local _, _, sbx = getAsBx(inst)
                pc = pc + sbx

            elseif op == 23 then -- EQ
                local res = (RK(b2) == RK(c))
                if (a ~= 0) == res then pc = pc + 1 end

            elseif op == 24 then -- LT
                local res = (RK(b2) < RK(c))
                if (a ~= 0) == res then pc = pc + 1 end

            elseif op == 25 then -- LE
                local res = (RK(b2) <= RK(c))
                if (a ~= 0) == res then pc = pc + 1 end

            elseif op == 26 then -- TEST
                if (regs[a] and true or false) ~= (c ~= 0) then pc = pc + 1 end

            elseif op == 27 then -- TESTSET
                if (regs[b2] and true or false) == (c ~= 0) then
                    regs[a] = regs[b2]
                else
                    pc = pc + 1
                end

            elseif op == 28 then -- CALL
                local func = regs[a]
                local args = {}
                local argEnd = b2 == 0 and top or (a + b2 - 1)
                for i = a+1, argEnd do args[#args+1] = regs[i] end
                local results = callProto(func, args)
                if c == 0 then
                    top = a + #results - 1
                    for i = 0, #results - 1 do regs[a+i] = results[i+1] end
                else
                    for i = 0, c-2 do regs[a+i] = results[i+1] end
                end

            elseif op == 29 then -- TAILCALL
                local func = regs[a]
                local args = {}
                local argEnd = b2 == 0 and top or (a + b2 - 1)
                for i = a+1, argEnd do args[#args+1] = regs[i] end
                return unp(callProto(func, args))

            elseif op == 30 then -- RETURN
                local results = {}
                local retEnd = b2 == 0 and top or (a + b2 - 2)
                for i = a, retEnd do results[#results+1] = regs[i] end
                closeUpvals(0)
                return unp(results)

            elseif op == 31 then -- FORLOOP
                local _, _, sbx = getAsBx(inst)
                local idx   = regs[a] + regs[a+2]
                local limit = regs[a+1]
                local step  = regs[a+2]
                if (step > 0 and idx <= limit) or (step <= 0 and idx >= limit) then
                    regs[a]   = idx
                    regs[a+3] = idx
                    pc = pc + sbx
                end

            elseif op == 32 then -- FORPREP
                local _, _, sbx = getAsBx(inst)
                regs[a] = regs[a] - regs[a+2]
                pc = pc + sbx

            elseif op == 33 then -- TFORLOOP
                local func = regs[a]
                local results = callProto(func, {regs[a+1], regs[a+2]})
                for i = 1, c do regs[a+2+i] = results[i] end
                if regs[a+3] ~= nil then
                    regs[a+2] = regs[a+3]
                else
                    pc = pc + 1
                end

            elseif op == 34 then -- SETLIST
                local n = b2 == 0 and (top - a) or b2
                local base = (c == 0 and (insts[pc]) or c) * 50
                if c == 0 then pc = pc + 1 end
                for i = 1, n do regs[a][base + i] = regs[a + i] end

            elseif op == 35 then -- CLOSE
                closeUpvals(a)

            elseif op == 36 then -- CLOSURE
                local _, _, bx = getABx(inst)
                local subProto = protos[bx+1]
                local newUpvals = {}
                for i = 1, subProto.numUpvalues do
                    local pseudo = insts[pc]; pc = pc + 1
                    local pseudoOp = pseudo % 64
                    local pA = mfl(pseudo/64) % 256
                    local pB = mfl(pseudo/8388608) % 512
                    if pseudoOp == 0 then -- MOVE -> share register
                        newUpvals[i] = openUpval(pB)
                    else -- GETUPVAL -> share upvalue
                        newUpvals[i] = upvals[pB+1]
                    end
                end
                regs[a] = function(...)
                    return execProto(subProto, newUpvals, ...)
                end

            elseif op == 37 then -- VARARG
                local n = b2 - 1
                if n == -1 then
                    n = #vararg
                    top = a + n - 1
                end
                for i = 0, n-1 do regs[a+i] = vararg[i+1] end
            end
        end
    end

    -- This Build root upvalue pointing to env
    local rootUpvals = { {{env}, 1} }
    return function(...)
        return execProto(proto, rootUpvals, ...)
    end
end

local function hexDecode(hex)
    return (hex:gsub("..", function(h)
        return string.char(tonumber(h, 16))
    end))
end

local function run(payload, env, ...)
    local raw  = hexDecode(payload)
    local proto = decode(raw)
    local vm   = luaVM(proto, {}, env or genv())
    return vm(...)
end

]==]

return VMTemplate
