class.Queue()
function Queue:new(o)
	self = (o and o._get()) or {data = {}, size = 0, last = -1, first = 0}
	local oQueue = {}
	function oQueue.insert (_o, val)
		return Queue:insert(self, val)
	end
 
  	function oQueue.pop (_o)
  		return Queue:pop(self)
	end

	function oQueue.popAll (_o, loop)
		return Queue:popAll(self, loop)
	end

	function oQueue.getFirst (_o)
		return Queue:getFirst(self)
	end

	function oQueue.getLast (_o)
		return Queue:getLast(self)
	end

	function oQueue.getSize (_o)
		return Queue:getSize(self)
	end

	function oQueue.getData (_o)
		return Queue:getData(self)
	end

	function oQueue._get (_o)
		return clone(self)
	end

   return oQueue
end

function Queue:insert(q, val)
   q.last = q.last + 1
   q.data[q.last] = val
   q.size = q.size + 1
end

function Queue:pop(q)
	if q.size > 0 then
		local rval
	  	rval = q.data[q.first]
	  	q.data[q.first] = nil
	  	q.first = q.first + 1
	   q.size = q.size - 1
	   return rval
	end
end

function Queue:popAll(q, loop)
	local rval
	while self:getSize(q) > 0 do
		rval = self:pop(q)
		if not isNil(loop) then
			loop(rval)
		end
	end
end

function Queue:getFirst(q)
  	return q.data[q.first]
end

function Queue:getLast(q)
	return q.data[q.last]
end

function Queue:getSize(q)
	return q.size
end

function Queue:getData(q)
	return q.data
end

-- testing
--[[
q = Queue:new()
q:insert("42")
q:insert("69")
q:insert("420")
q:insert("yes")

q:popAll(function(v)
	print(v)
end)
]]