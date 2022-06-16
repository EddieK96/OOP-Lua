class.Cache({
	entries = {}, 
	endpoint = {}, 
	intervalTask = {},
	entryIterval = 100, 
	timeInterval = 60000,
	publicEnums = {
		["NEVER"] = ifNil(_G["NEVER"], function() --> if not set...
			return -1
		end, function() --> else...
			return _G["NEVER"] -- ...let variable be.
		end)
	}
})

function Cache:new(endpoint, timeInterval, entryIterval, callback)
	self.entryIterval = entryIterval or self.entryIterval
	self.endpoint = endpoint or self.endpoint
	self.intervalTask = IntervalTask:new(timeInterval, false, false, false, function()
		self:clear("timeout")
		return true
	end, nil, callback)
	self:clearAtInterval(timeInterval, callback)
end

function Cache:store(item)
	table.insert(self.entries, item)
end

function Cache:clear(how)
	local rtval
	switch(type(self.endpoint), {
		["function"] = function ()
			rtval = self.endpoint(self.entries, how)
		end,
		["table"] = function ()
			local time = {GetUtcTime()}
			local strTime = json.encode(time)
			if isNil(self.endpoint[strTime]) then
				self.endpoint[strTime] = {clone(self.entries)}
			else
				table.insert(self.endpoint[strTime], clone(self.entries))
			end
		end,
		["class"] = function ()
			self.endpoint:new(table.unpack(self.entries))
		end,
		["instance"] = function ()
			self.endpoint = clone(self.entries)
		end,
		default = function ()
			self.endpoint = clone(self.entries)
		end
	})
	self.entries = {}
	rtval = clone(self.endpoint)
	return rtval,how
end

function Cache:clearAtInterval(timeInterval, callback)
	self.intervalTask:setInterval(timeInterval or 60000)
	if not (self.intervalTask:getInterval() < 0) then
		self.intervalTask:run(true, callback)
	else
		self:stopInterval()
		if not isNil(callback) then
			callback()
		end
	end
end

function Cache:stopInterval()
	self.intervalTask:stop()
end

-- example
--[[
Citizen.CreateThread(function()
	local events = Cache:new(function(data, how)
		for k,e in pairs(data) do
			print(e)
		end
	end, 10000)
	events:store("foo")
	events:store("bar")
	Citizen.Wait(11000)
	--events:stopInterval()
	events:store("yes")
	events:store("no")
end)
]]