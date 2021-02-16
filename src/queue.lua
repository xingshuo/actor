local queue = {}
queue.__index = queue

function queue:push( v )
	local item = {
		value = v,
	}
	if self.tail == nil then
		self.head = item
		self.tail = item
	else
		self.tail.next = item
		self.tail = item
	end
end

function queue:top()
	local item = self.head
	if item == nil then
		return nil
	end
	return item.value
end

function queue:pop()
	local item = self.head
	if item == nil then
		return nil
	end

	if item.next == nil then
		self.head = nil
		self.tail = nil
	else
		self.head = item.next
	end
	return item.value
end

function queue:size()
	if self.head == nil then
		return 0
	end

	local sz = 1
	local head, tail = self.head, self.tail
	while head ~= tail do
		sz = sz + 1
		head = head.next
	end
	return sz
end

function queue:new()
	local q = {
		head = nil,
		tail = nil,
	}
	setmetatable(q, self)
	return q
end

return queue