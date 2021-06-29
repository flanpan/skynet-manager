local skynet = require "skynet"
local st = require "skynet.sharetable"
local sn_define = require "sn_define"
local KEY = sn_define.ST_CONF_KEY

return function(service_conf)
    assert(not st.query(KEY), "allow init only once")
    assert(service_conf)
    for service_name, conf in pairs(service_conf) do
        assert(type(conf.unique) == "boolean", service_name)

        local balance_num = conf.balance_num
        if balance_num then
            assert(not conf.unique, service_name)
            assert(type(balance_num) == "number", service_name)
            assert(balance_num > 0, service_name)
        end
    end
    st.loadtable(KEY, service_conf)
end