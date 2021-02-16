local queue = require "queue"
local actor = require "actor"

local scheduler = {}
scheduler.__index = scheduler

function scheduler:init()
	self.Actors = {}
	self.GlobalQueue = queue:new()
end

function scheduler:newActor( id )
	if self.Actors[id] ~= nil then
		return nil, ERR_ACTOR_CONFLICT
	end
	local oActor = actor:new(id, self)
	self.Actors[id] = oActor
	return oActor, nil
end

function scheduler:delActor( id )
	local obj = self.Actors[id]
	if obj == nil then
		return ERR_ACTOR_NOEXIST
	end
	self.Actors[id] = nil
	obj:exit()
end

function scheduler:getActor( id )
	return self.Actors[id]
end

function scheduler:pushGQ( oActor )
	self.GlobalQueue:push( oActor )
end

function scheduler:run()
	while true do
		local oActor = self.GlobalQueue:pop()
		if oActor == nil then
			return
		end
		oActor:dispatch()
	end
end

function scheduler:new()
	local o = {}
	setmetatable(o, self)
	o:init()
	return o
end

return scheduler