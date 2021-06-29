local skynet = require "skynet"
local queue = require "skynet.queue"
local sn_define = require "sn_define"
require "skynet.manager"

local sn_sname = sn_define.sname
local lock = queue()
local service_conf

local CMD = {}

function CMD.get(service_name, id)
    assert(type(service_conf) == "table", "init balance service first.")
    
    local conf = service_conf[service_name]
    assert(conf, service_name)

    if conf.unique and id then
        assert(false, ("[%s] is not multi service, id=[%s]"):format(service_name, id))
    end

    local addr
    lock(function()
        local sname = sn_sname(service_name, id)
        addr = skynet.localname(sname)
        if not addr then
            if id then
                addr = skynet.newservice(service_name, id)
            else
                addr = skynet.newservice(service_name)
            end
            skynet.name(sname, addr)
        end
    end)

    return addr
end

skynet.init(function()
    local st = require "skynet.sharetable"
    service_conf = st.query(sn_define.ST_CONF_KEY)
end)

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = CMD[cmd]
        assert(f, cmd)
        return skynet.retpack(f(...))
    end)
end)
