package.path = "src/?.lua;" .. package.path
local scheduler = require "scheduler"
local log = require "log"


-- 工会数据结构
local UnionModels = {}

local function getUnion( uid )
	if UnionModels[uid] == nil then
		UnionModels[uid] = {
			players = {},
		}
	end
	return UnionModels[uid]
end

-- 工会接口
local UnionSystem = {}

function UnionSystem.joinUnion(oActor, pid)
	local uid = oActor:GetID():gsub("(%a+)(%d+)", "%2")
	local model = getUnion(uid)
	if model.players[pid] ~= nil then
		return false
	end
	model.players[pid] = true
	oActor:echo("deductPlayerItem", pid, 20001, 10)
	return true
end

function UnionSystem.deductPlayerItem(oActor, pid, itemID, count)
	local uid = oActor:GetID():gsub("(%a+)(%d+)", "%2")
	log.Infof("union %s start deduct player %s item %s count %s", uid, pid, itemID, count)
	local err, suc = oActor:call("player" .. pid, "deductItem", itemID, count)
	assert(err == nil)
	log.Infof("union %s deduct player %s item %s count %s %s", uid, pid, itemID, count, suc and "succeed" or "failed")
	local err, leftCount = oActor:call("player" .. pid, "getItemCount", itemID)
	assert(err == nil)
	log.Infof("union %s query player %s item %s left count %s", uid, pid, itemID, leftCount)
end

-- 玩家数据结构
local PlayerModels = {}

local function getPlayer( pid )
	if PlayerModels[pid] == nil then
		PlayerModels[pid] = {
			item = {},
		}
	end
	return PlayerModels[pid]
end

-- 玩家接口
local PlayerSystem = {}

function PlayerSystem.addItem(oActor, itemID, count)
	local pid = oActor:GetID():gsub("(%a+)(%d+)", "%2")
	local model = getPlayer(pid)
	if model.item[itemID] == nil then
		model.item[itemID] = 0
	end
	model.item[itemID] = model.item[itemID] + count
	log.Infof("player %s add item %d count %d to %d.", pid, itemID, count, model.item[itemID])
end

function PlayerSystem.getItemCount(oActor, itemID)
	local pid = oActor:GetID():gsub("(%a+)(%d+)", "%2")
	local model = getPlayer(pid)
	if model.item[itemID] == nil then
		model.item[itemID] = 0
	end
	return model.item[itemID]
end

function PlayerSystem.deductItem(oActor, itemID, count)
	local pid = oActor:GetID():gsub("(%a+)(%d+)", "%2")
	local model = getPlayer(pid)
	if model.item[itemID] == nil then
		model.item[itemID] = 0
	end
	if model.item[itemID] < count then
		return false
	end
	model.item[itemID] = model.item[itemID] - count
	log.Infof("player %s deduct item %d count %d to %d.", pid, itemID, count, model.item[itemID])
	return true
end

function PlayerSystem.joinUnion(oActor, unionActID)
	local pid = oActor:GetID():gsub("(%a+)(%d+)", "%2")
	log.Infof("player %s apply join union %s", pid, unionActID)
	local err, suc = oActor:call(unionActID, "joinUnion", pid)
	assert(err == nil)
	log.Infof("player %s join union %s %s", pid, unionActID, suc and "succeed" or "failed")
end

function PlayerSystem.sendItem(oActor, receiver, itemID, count)
	local pid = oActor:GetID():gsub("(%a+)(%d+)", "%2")
	local model = getPlayer(pid)
	if model.item[itemID] == nil then
		model.item[itemID] = 0
	end
	if model.item[itemID] < count then
		log.Infof("player %s shortage item %s(%s < %s) send to %s.", pid, itemID, model.item[itemID], count, receiver)
		return
	end
	model.item[itemID] = model.item[itemID] - count
	local err = oActor:send(receiver, "addItem", itemID, count)
	assert(err == nil)
	log.Infof("player %s send item %s %s to %s", pid, itemID, count, receiver)
end

-- 测试入口函数
function Test()
	local sched = scheduler:new()
	-- 创建玩家101 Actor实例
	local player101, err = sched:newActor("player101")
	assert(err == nil)
	player101:registerHandlers( PlayerSystem )
	-- 创建玩家102 Actor实例
	local player102, err = sched:newActor("player102")
	assert(err == nil)
	player102:registerHandlers( PlayerSystem )
	-- 创建工会1001 Actor实例
	local union1001, err = sched:newActor("union1001")
	assert(err == nil)
	union1001:registerHandlers( UnionSystem )
	-- 玩家101, 先加道具, 再申请加入工会
	player101:echo("addItem", 20001, 15)
	player101:echo("joinUnion", union1001:GetID())
	-- 赠送玩家102道具
	player101:echo("sendItem", player102:GetID(), 20001, 3)
	-- 玩家102, 先加道具, 再申请加入工会
	player102:echo("addItem", 20001, 5)
	player102:echo("joinUnion", union1001:GetID())

	sched:run()
end

Test()