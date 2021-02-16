local str_format = string.format

-- 错误定义
ERR_ACTOR_NOEXIST = 1
ERR_ACTOR_CONFLICT = 2
ERR_HANDLER_NOEXIST = 3
ERR_RPC_SESSION_NOEXIST = 4

function NewError(errCode, errMsg)
	return setmetatable(
		{
			errCode = errCode,
			errMsg = errMsg,
		}, 
		{
			__tostring = function ( t )
				return str_format("ErrCode:[%s] ErrMsg:[%s]", t.errCode, t.errMsg)
			end
		}
	)
end

-- 消息类型
MSG_REQ = 1
MSG_RSP = 2

-- RPC相关
NO_RSP_SESSION = 0