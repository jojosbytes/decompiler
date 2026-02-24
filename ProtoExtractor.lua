-- ProtoExtractor.lua
local PotassiumDisassembler = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/jojosbytes/decompiler/refs/heads/main/dissasembler.luau"
))()

local ProtoExtractor = {}

local function normalizeProto(rawProto)
    if not rawProto then return nil end

    local norm = {
        source       = rawProto.Source,
        numParams    = rawProto.NumParams,
        maxStackSize = rawProto.MaxStackSize,
        isVarArg     = rawProto.IsVarArg,

        code     = rawProto.Instructions or rawProto.Code or {},
        k        = rawProto.Constants    or rawProto.KTable or {},
        upvalues = rawProto.Upvalues     or {},
        protos   = {},
    }

    if rawProto.Protos then
        for i, child in ipairs(rawProto.Protos) do
            norm.protos[i] = normalizeProto(child)
        end
    end

    return norm
end

function ProtoExtractor.FromScript(scr)
    local ok, bc = pcall(getscriptbytecode, scr)
    if not ok or typeof(bc) ~= "string" then
        return nil, "getscriptbytecode failed"
    end

    local ok2, result = pcall(PotassiumDisassembler.Disassemble, bc, false)
    if not ok2 or not result or not result.MainProto then
        return nil, "Disassemble failed"
    end

    local main = normalizeProto(result.MainProto)

    return {
        main    = main,
        strings = result.StringTable or {},
        version = {
            luau  = result.LuauVersion,
            types = result.TypesVersion,
        },
    }
end

return ProtoExtractor
