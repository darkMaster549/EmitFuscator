math.randomseed(os.time())

local pipeline = require("pipeline")

local R   = "\27[31m"
local G   = "\27[32m"
local Y   = "\27[33m"
local C   = "\27[36m"
local W   = "\27[97m"
local DIM = "\27[2m"
local RST = "\27[0m"

local banner_plain = "-- This File Was Generated Using The EmitFuscator | 1.0.1\n\n" -- change this to your own Obfuscator freaking name :)
local banner_color = C.."-- This File Was Generated Using The EmitFuscator | 1.0.1"..RST.."\n\n"

local f = arg[1]
if not f then
    print(banner_color)
    print(Y.."Usage:"..RST.."  lua main.lua input.lua")
    print(DIM.."Example: lua main.lua myscript.lua"..RST)
    os.exit(1)
end

local file = io.open(f, "r")
if not file then
    print(R.."[ERROR]"..RST.." Cannot open: "..W..f..RST)
    os.exit(1)
end

local source = file:read("*a")
file:close()

print(banner_color)
print(G.."["..RST..W.."EmitFuscator"..RST..G.."]"..RST.." Starting obfuscation on "..Y..f..RST.."...")
print("")

local result = pipeline(source)
local final  = banner_plain .. result

local out = io.open("output.lua", "w")
out:write(final)
out:close()

print("")
print(G.."[DONE]"..RST.." Saved to "..Y.."output.lua"..RST)
