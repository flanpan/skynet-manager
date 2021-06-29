local skynet = require "skynet"

local M = {}

M.METHOD = {
    REQ = "req",
    POST = "post"
}

M.ST_CONF_KEY = "snconf"

function M.sname(service_name, id)
    local sname = ".sn." .. service_name
    if id then
        sname = sname .. "." .. tostring(id)
    end
    return sname
end

function M.dispatch(CMD)
    skynet.dispatch("lua", function(_1,_2, method, cmd, ...)
        local ret
        local f = CMD[cmd]
        if not f then
            error("invalid command: " .. cmd)
        else
            ret = skynet.pack(f(...))
        end

        if method == M.METHOD.REQ then
            return skynet.retpack(ret)
        end
    end)
end

return M