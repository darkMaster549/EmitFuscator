local cfg     = require("config")
local parser  = require("ast.parser")
local emitter = require("codegen.emitter")

-- load enabled passes --
local passes = {}
if cfg.passes.rename   then passes[#passes+1] = require("passes.rename")   end
if cfg.passes.numbers  then passes[#passes+1] = require("passes.numbers")  end
if cfg.passes.strings  then passes[#passes+1] = require("passes.strings")  end
if cfg.passes.flatten  then passes[#passes+1] = require("passes.flatten")  end
-- deadcode is handled inside emitter, not as an AST pass --

return function(source)
    local passes_count = math.min(cfg.max_passes, 2)
    local current = source

    for i = 1, passes_count do
        io.write("Pass " .. i .. "/" .. passes_count .. "... ")
        io.flush()

        -- parse to AST --
        local ast = parser.parse(current)

        -- run each AST pass --
        for _, pass in ipairs(passes) do
            ast = pass(ast)
        end

        -- emit obfuscated output
        current = emitter(ast, current, i)
        print("done")
    end

    return current
end
