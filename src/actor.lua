require "defines"
local queue = require "queue"
local log = require "log"

local str_format = string.format
local t_remove = table.remove
local t_unpack = table.unpack
local t_pack = table.pack

local co_resume = coroutine.resume
local co_yield = coroutine.yield
local co_create = coroutine.create
local traceback = debug.traceback

local function try_coresume(message, co, ...)
	local ok, status, ret = co_resume(co, ...)
	if not ok then
		local tb = traceback(co, message)
		-- 直接抛出异常, 期望scheduler.run xpcall调用oActor:dispatch
		error(tb)
	end
	return status, ret
end

local actor = {}
actor.__index = actor

function actor:init(id, scheduler)
	self.ID = id
	self.Scheduler = scheduler
	self.MsgQueue = queue:new()
	self.WaitSession = nil
	self.Response = nil
	self.ReqSession = 1
	self.Handlers = {}
	self.Co = co_create(function ()
		local f, ret
		while true do
			f = co_yield("return", ret)
			ret = t_pack(f(co_yield()))
		end
	end)
	-- run until wait f
	try_coresume("actor.init", self.Co)
end

function actor:exit()
	-- lua 5.4 may use api: coroutine.close (self.Co)
end

function actor:GetID()
	return self.ID
end

-- 一类actor实例(比如玩家,工会等)引用同一份handlers table
function actor:registerHandlers( handlers )
	self.Handlers = handlers
end

function actor:pushMsg(source, msgType, session, tArgs)
	if msgType == MSG_REQ then
		if self.WaitSession ~= nil then -- rpc blocked
			self.MsgQueue:push({source,msgType,session,tArgs})
			return
		end
		self.MsgQueue:push({source,msgType,session,tArgs})
		if self.MsgQueue:size() == 1 then
			self.Scheduler:pushGQ(self)
		end
	elseif msgType == MSG_RSP then
		if self.WaitSession == nil then
			log.Errorf("unknow rsp session %s", session)
			return
		end
		if self.WaitSession ~= session then
			log.Errorf("wakeup session error %s!=%s", session, self.WaitSession)
			return
		end
		if self.Response ~= nil then
			log.Errorf("repeat response session %s", session)
			return
		end
		self.Response = {source,msgType,session,tArgs}
		self.Scheduler:pushGQ(self)
	end
end

function actor:dispatch()
	if self.Response ~= nil then
		local rsp = self.Response
		self.WaitSession, self.Response = nil, nil
		local tbmsg = str_format("%s on response %s from %s", self.ID, rsp[3], rsp[1])
		status, ret = try_coresume(tbmsg, self.Co, rsp[4])
		if status == "suspend" then -- on rpc call
			return
		end
	elseif self.WaitSession ~= nil then -- rpc blocked
		return
	end
	
	-- handle requests
	local msg, tbmsg
	while true do
		::continue::
		msg = self.MsgQueue:pop()
		if msg == nil then
			return
		end
		local source, _, session, tArgs = t_unpack(msg)
		local method = tArgs[1]
		local handler = self.Handlers[method]
		if handler == nil then
			log.Errorf("handler %s no exist [%s -> %s]", method, source, self.ID)
			goto continue
		end
		tArgs[1] = self
		
		tbmsg = str_format("%s on pass handler %s session %s from %s", self.ID, method, session, source)
		try_coresume(tbmsg, self.Co, handler)

		tbmsg = str_format("%s on request %s session %s from %s", self.ID, method, session, source)
		local status, ret = try_coresume(tbmsg, self.Co, t_unpack(tArgs))
		if status == "suspend" then -- on rpc call
			return
		end
		if session ~= NO_RSP_SESSION then
			local srcActor = self.Scheduler:getActor(source)
			if srcActor ~= nil then
				srcActor:pushMsg(self.ID, MSG_RSP, session, ret)
			else
				log.Errorf("source actor %s no exist to %s", source, self.ID)
			end
		end
	end
end

-- 回射调用自身method方法, actor初始化或避免actor之间双向call导致死锁时调用
-- 返回值: err
function actor:echo(method, ... )
	return self:send(self.ID, method, ...)
end

-- 返回值: err, values...
function actor:call(dst, method, ...)
	local dstActor = self.Scheduler:getActor(dst)
	if dstActor == nil then
		return ERR_ACTOR_NOEXIST
	end
	if self.ReqSession == NO_RSP_SESSION then
		self.ReqSession = NO_RSP_SESSION + 1
	end
	local session = self.ReqSession
	self.ReqSession = self.ReqSession + 1
	self.WaitSession = session
	dstActor:pushMsg(self.ID, MSG_REQ, session, t_pack(method, ...))
	local rsp = co_yield("suspend")
	return nil, t_unpack(rsp)
end

-- 返回值: err
function actor:send(dst, method, ...)
	local dstActor = self.Scheduler:getActor(dst)
	if dstActor == nil then
		return ERR_ACTOR_NOEXIST
	end
	dstActor:pushMsg(self.ID, MSG_REQ, NO_RSP_SESSION, t_pack(method, ...))
end

function actor:new(id, scheduler)
	local o = {}
	setmetatable(o, self)
	o:init(id, scheduler)
	return o
end

return actor