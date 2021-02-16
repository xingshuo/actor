local str_format = string.format
local os_date = os.date

LOG_LEVEL_DEBUG = 1
LOG_LEVEL_INFO  = 2
LOG_LEVEL_ERROR = 3
LOG_LEVEL_NULL  = 4 -- 不输出日志

local log = {
	level = LOG_LEVEL_INFO,
	print = print -- 默认标准输出
}

function log.Debugf( ... )
	if log.level > LOG_LEVEL_DEBUG then
		return
	end
	log.print(str_format("%s [DEBUG] %s", os_date("%Y-%m-%d %H:%M:%S"), str_format(...)))
end

function log.Debug( ... )
	if log.level > LOG_LEVEL_DEBUG then
		return
	end
	log.print(str_format("%s [DEBUG] ", os_date("%Y-%m-%d %H:%M:%S")), ...)
end

function log.Infof( ... )
	if log.level > LOG_LEVEL_INFO then
		return
	end
	log.print(str_format("%s [INFO] %s", os_date("%Y-%m-%d %H:%M:%S"), str_format(...)))
end

function log.Info( ... )
	if log.level > LOG_LEVEL_INFO then
		return
	end
	log.print(str_format("%s [INFO] ", os_date("%Y-%m-%d %H:%M:%S")), ...)
end

function log.Errorf( ... )
	if log.level > LOG_LEVEL_ERROR then
		return
	end
	log.print(str_format("%s [ERROR] %s", os_date("%Y-%m-%d %H:%M:%S"), str_format(...)))
end

function log.Error( ... )
	if log.level > LOG_LEVEL_ERROR then
		return
	end
	log.print(str_format("%s [ERROR] ", os_date("%Y-%m-%d %H:%M:%S")), ...)
end

function log.Fatalf( ... )
	log.print(str_format("%s [FATAL] %s", os_date("%Y-%m-%d %H:%M:%S"), str_format(...)))
	os.exit(-1)
end

function log.Fatal( ... )
	log.print(str_format("%s [FATAL] ", os_date("%Y-%m-%d %H:%M:%S")), ...)
	os.exit(-1)
end

return log