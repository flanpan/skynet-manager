local skynet = require "skynet"
local sn_define = require "sn_define"
local st = require "skynet.sharetable"

local sn_sname = sn_define.sname
local METHOD = sn_define.METHOD
local ST_CONF_KEY = sn_define.ST_CONF_KEY

local service_obj = {}
local service_conf
local snd

local function get_snd()
    if not snd then
        snd = skynet.uniqueservice("snd")
    end
    return snd
end

local function get_service(service_name, id)
    local sname = sn_sname(service_name, id)
    local addr =  skynet.localname(sname)

    if addr then
        return addr, sname
    end

    addr = skynet.call(get_snd(), "lua", "get", service_name, id)
    return addr, sname
end

local function cmd_mt(service_name, id, method)
    return setmetatable({}, {__index = function(self, cmd)
        return function(...)
            local addr = get_service(service_name, id)

            if method == METHOD.REQ then
                skynet.call(addr, "lua", method, cmd, ...)
            else
                skynet.send(addr, "lua", method, cmd, ...)
            end
        end
    end})
end

local function get_service_obj(service_name, id)
    -- notice: addr may change
    local addr, sname = get_service(service_name, id)
    local s = service_obj[sname]
    if s then
        return s
    end

    s = {
        req = cmd_mt(service_name, id, METHOD.REQ),
        post = cmd_mt(service_name, id, METHOD.POST),
        sname = sname,
    }
    service_obj[sname] = s
    return s
end

local M = {}

function M.start(CMD)
    skynet.start(function()
        sn_define.dispatch(CMD)
    end)
end

return setmetatable(M, {__index = function(self, service_name)
    if not service_conf then
        service_conf = st.query(ST_CONF_KEY)
    end
    
    local conf = service_conf[service_name]
    if not conf then
        assert(false, ("[%s] no config"):format(service_name))
    end

    local obj
    if conf.unique then
        obj = get_service_obj(service_name)
    else
        obj = setmetatable({}, {__index = function(_, id)
            local balance_num = conf.balance_num
            if balance_num then
                assert(type(id) == "number", "balance service id must be number")
                id = id % balance_num
                if id == 0 then id = balance_num end
            end
            return get_service_obj(service_name, id)
        end})
    end
    self[service_name] = obj
    return obj
end})