local MyDisassembler = {}

local function getProto(fn)
    local ok, proto = pcall(debug.getproto, fn, 1)
    if ok and typeof(proto) == "table" and typeof(proto.instructions) == "table" then
        return proto
    end
    return nil
end

local function toIR(proto)
    local IR = {}
    for i, ins in ipairs(proto.instructions) do
        IR[i] = {
            op  = ins.OP or ins.op or ins[1],
            a   = ins.A  or ins.a  or ins[2],
            b   = ins.B  or ins.b  or ins[3],
            c   = ins.C  or ins.c  or ins[4],
            bx  = ins.Bx or ins.bx,
            sbx = ins.SBx or ins.sbx,
            raw = ins,
        }
    end
    return IR
end

local function reg(r)
    return "r" .. tostring(r)
end

local function decompileIR(IR, constants)
    local out = {}

    for pc, ins in ipairs(IR) do
        local op = ins.op

        if op == "MOVE" then
            table.insert(out, ("local %s = %s"):format(reg(ins.a), reg(ins.b)))

        elseif op == "LOADK" then
            local k = constants and constants[(ins.bx or 0) + 1]
            table.insert(out, ("local %s = %q"):format(reg(ins.a), tostring(k)))

        elseif op == "LOADN" then
            table.insert(out, ("local %s = %d"):format(reg(ins.a), ins.bx))

        elseif op == "GETGLOBAL" then
            table.insert(out, ("local %s = GLOBAL[%d]"):format(reg(ins.a), ins.raw.Aux or 0))

        elseif op == "GETTABLE" then
            table.insert(out, ("local %s = %s[%s]"):format(reg(ins.a), reg(ins.b), reg(ins.c)))

        elseif op == "SETTABLE" then
            table.insert(out, ("%s[%s] = %s"):format(reg(ins.b), reg(ins.c), reg(ins.a)))

        elseif op == "CALL" then
            table.insert(out, ("-- CALL %s"):format(reg(ins.a)))

        elseif op == "RETURN" then
            table.insert(out, "-- RETURN")

        else
            table.insert(out, ("-- %s (unhandled)"):format(tostring(op)))
        end
    end

    return table.concat(out, "\n")
end

function MyDisassembler.DecompileFunction(fn)
    local proto = getProto(fn)
    if not proto then
        return "-- no proto"
    end

    local IR = toIR(proto)
    local constants = proto.constants or proto.k or {}

    return decompileIR(IR, constants)
end

return MyDisassembler
