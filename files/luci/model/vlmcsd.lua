local m, s

local running=(luci.sys.call("pidof vlmcsd > /dev/null") == 0)
if running then	
	m = Map("vlmcsd", translate("vlmcsd config"), translate("Vlmcsd is running."))
else
	m = Map("vlmcsd", translate("vlmcsd config"), translate("Vlmcsd is not running."))
end

s = m:section(TypedSection, "vlmcsd", "")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enabled", translate("Enable"))
enable.rmempty = false
function enable.cfgvalue(self, section)
	return luci.sys.init.enabled("vlmcsd") and self.enabled or self.disabled
end

local hostname = luci.model.uci.cursor():get_first("system", "system", "hostname")

autoactivate = s:option(Flag, "autoactivate", translate("Auto activate"))
autoactivate.rmempty = false

config = s:option(Value, "config", translate("configfile"), translate("This file is /etc/vlmcsd.ini."), "")
config.template = "cbi/tvalue"
config.size = 100
config.rows = 25
config.wrap = "off"

function config.cfgvalue(self, section)
	return nixio.fs.readfile("/etc/vlmcsd.ini")
end

function config.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("/etc/vlmcsd.ini", value)
end

function enable.write(self, section, value)
	if value == "1" then
		luci.sys.call("/etc/init.d/vlmcsd enable >/dev/null")
		luci.sys.call("/etc/init.d/vlmcsd start >/dev/null")
		luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null")
	else
		luci.sys.call("/etc/init.d/vlmcsd stop >/dev/null")
		luci.sys.call("/etc/init.d/vlmcsd disable >/dev/null")
		luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null")
	end
	Flag.write(self, section, value)
end

function autoactivate.write(self, section, value)
	if value == "1" then
		luci.sys.call("sed -i '/srv-host=_vlmcs._tcp.lan/d' /etc/dnsmasq.conf")
		luci.sys.call("echo srv-host=_vlmcs._tcp.lan,".. hostname ..".lan,1688,0,100 >> /etc/dnsmasq.conf")
	else
		luci.sys.call("sed -i '/srv-host=_vlmcs._tcp.lan/d' /etc/dnsmasq.conf")
	end
	Flag.write(self, section, value)
end

return m
