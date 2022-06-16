class.IntervalTask({status = nil, routine = nil, interval = nil, callback = nil, deleteAfterUse = nil})
function IntervalTask:new(interval, run, delay, deleteAfterUse, routine, finished, callback)
   local status = (run and (not delay) and "running") or "stopped" 
   self.status = status or (intervalTask and intervalTask.status)
   self.routine = routine or (intervalTask and intervalTask.routine)
   self.interval = interval or (intervalTask and intervalTask.interval)
   self.deleteAfterUse = deleteAfterUse or (intervalTask and intervalTask.deleteAfterUse)
   self.callback = finished or (intervalTask and intervalTask.callback)
   if self.status == "running" or (run and not isNil(delay)) then
   	self.status = "stopped"
   	self:run(delay, callback)
   end
end

function IntervalTask:run(delay, callback)
	if not (self.status == "running") then
		self.status = "running"
		local thread = function(pr)
			Citizen.CreateThread(function()
				local condition = true
				while condition and (self.status == "running") do
					if delay then
						if not isNil(callback) then
							callback()
						end
						if not isNil(pr) then
							pr:resolve()
						end
						Citizen.Wait(self.interval)
						if condition and (self.status == "running") then
							condition = self.routine()
						end
					else
						condition = self.routine()
						if not isNil(callback) then
							callback()
						end
						if not isNil(pr) then
							pr:resolve()
						end
						Citizen.Wait(self.interval)
					end
				end

				if (not condition) then
					self.status = "finished"
				end

				if (self.status == "finished") then
					self:finish()
				end
			end)
		end
		
		if isNil(callback) then -- try executing synchronously...
			try(function()
				Citizen.Await(promise.new(thread))
			end,
			function(err) -- except: No callback defined outside coroutine...
				print("")
				print("^3WARNING", "Caught Error: " .. err .. "^0")
				print("^7" .. debug.traceback(nil) .. "^0")
				print("^2Task executes asynchronously. ^0Consider passing a callback or use inside a coroutine.")
				print("")
			end) 
		else
			thread()
		end
	end
end

function IntervalTask:stop()
	self.status = "stopped"
end

function IntervalTask:finish()
	if (self.status == "running") then -- This makes the coroutine wait to finish the current interval.
		self.status = "finished"
	else
		if not isNil(self.callback) then
			self.callback()
		end
		if self.deleteAfterUse then
			self = nil
		end
	end
end

function IntervalTask:refresh()
	switch(self.status, {
		["running"] = function ()
			self.status = stopped
			self:run()
		end,
		["finished"] = function ()
			self:finish()
		end
	})
end

function IntervalTask:setInterval(ms)
	self.interval = ms
end

function IntervalTask:getInterval()
	return clone(self.interval)
end

function IntervalTask:getStatus()
	return clone(self.status)
end

function IntervalTask:setRoutine(routine)
	if isType(routine, "function") then
		self.routine = routine
	end
end

function IntervalTask:getRoutine()
	return clone(self.routine)
end

function IntervalTask:setCallback(callback)
	self.callback = callback
end

function IntervalTask:getCallback()
	return clone(self.callback)
end

-- testing
--[[
class.SomeClass(extends(IntervalTask),{})

function SomeClass:new(...)
	self.override = IntervalTask:new(...)
	self.test = 42
end

function SomeClass:get()
	return self.test
end

Citizen.CreateThread(function()
	local obj = {} 
	obj = SomeClass:new(5000, true, true, false, function()
		print(obj:get())
	end)
end)
]]
-- example
--[[
Citizen.CreateThread(function()
	handler = IntervalTaskHandler:new(false)

	handler:createTask(10000, "1", true, false, true, true, function() 
		print("doSomething1") 
		return true 
	end)
	handler:createTask(10000, "1", true, false, true, true, function() 
		print("doSomething2") 
		return true 
	end)
	handler:createTask(10000, "1", true, false, true, true, function() 
		print("doSomething3") 
		return true 
	end)
	handler:createTask(10000, "1", true, false, true, true, function() 
		print("doSomething4") 
		return true 
	end)
	-- Do something once...
	for i = 0, 10, 1 do
		handler:createTask(10000, "doOnce", true, false, false, false, function() 
			print("Do something once...") 
			return false -- returns break condition. 
		end)
	end
	print("This is all.")
	--> Do something once...
	--> This is all.
end)
]]

class.IntervalTaskHandler({taskMultiKeyMap = {}})
function IntervalTaskHandler:new(runAll)
   self.taskMultiKeyMap = (intervalTaskHandler and cloneTable(intervalTaskHandler.taskMultiKeyMap)) or MultiKeyMap:new()
   if runAll then
   	self:runAll()
   else
   	self:refresh()
   end
end

function IntervalTaskHandler:createTask(interval, id, run, delay, allowMultiValue, deleteAfterUse, routine)
	local _id = self.taskMultiKeyMap:searchMultiKey(id)

	if isNil(_id) or allowMultiValue then
		return self.taskMultiKeyMap:insert(id, IntervalTask:new(interval, run, delay, deleteAfterUse, routine))
	end 
end

function IntervalTaskHandler:refresh()
	for k,v in pairs(self.taskMultiKeyMap.metaList) do
		if isTable(v) then
			for _k,_v in pairs(self.taskMultiKeyMap.metaList[k]) do
				self.taskMultiKeyMap.metaList[k][_k]:refresh()
			end
		elseif not isNil(v) then
			self.taskMultiKeyMap.metaList[k]:refresh()
		end
	end
end

function IntervalTaskHandler:setAllTasks(metaList, keyList)
	self:setStatusForAll("stopped", function()
		self.taskMultiKeyMap.metaList = cloneTable(metaList)
		if not isNil(keyList) then
			taskMultiKeyMap.multiKeys = cloneTable(keyList)
		end
		self:refresh()
	end)
end

function IntervalTaskHandler:getAllTasks()
	return cloneTable(self.taskMultiKeyMap.metaList), cloneTable(self.taskMultiKeyMap.multiKeys)
end

function IntervalTaskHandler:setTask(key, subIndex, task)
	self.dropTask(key, subIndex, function()
		local _id
		self.taskMultiKeyMap:setEntryByValue(key, subIndex, task)
		_id = taskMultiKeyMap:searchMultiKey(key)
		taskMultiKeyMap.metaList[_id][subIndex]:refresh()
	end)
end

function IntervalTaskHandler:getTask(key, subIndex)
	return self.taskMultiKeyMap:getEntry(key, subIndex)
end

function IntervalTaskHandler:run(key, subIndex, callback, finished)
	local _id = self.taskMultiKeyMap:searchMultiKey(key)
	if not isNil(_id) then
		if not isNil(callback) then
			self.taskMultiKeyMap.metaList[_id][subIndex]:setCallback(finished)
		end
		self.taskMultiKeyMap.metaList[_id][subIndex]:run(false, callback)
	end
end

function IntervalTaskHandler:stop(key, subIndex, callback)
	local _id = self.taskMultiKeyMap:searchMultiKey(key)
	if not isNil(_id) then
		if not isNil(callback) then
			self.taskMultiKeyMap.metaList[_id][subIndex]:setCallback(callback)
		end
		self.taskMultiKeyMap.metaList[_id][subIndex]:stop()
	end
end

function IntervalTaskHandler:runKeyGroup(key, callback, finished)
	local _id = self.taskMultiKeyMap:searchMultiKey(key)
	local i = 0
	local length 
	if not isNil(_id) then
		length = tableLength(self.taskMultiKeyMap.metaList[_id])
		for k,v in pairs(self.taskMultiKeyMap.metaList[_id]) do
			self:run(key, k, function()
				i = i + 1
				if i >= length then
					callback()
				end
			end, finished)
		end
	end
end

function IntervalTaskHandler:stopKeyGroup(key, callback)
	local _id = self.taskMultiKeyMap:searchMultiKey(key)
	local i = 0
	local length 
	if not isNil(_id) then
		length = tableLength(self.taskMultiKeyMap.metaList[_id])
		for k,v in pairs(self.taskMultiKeyMap.metaList[_id]) do
			self:stop(key, k, function()
				i = i + 1
				if i >= length then
					callback()
				end
			end)
		end
	end
end

function IntervalTaskHandler:dropTask(key, subIndex, callback)
	self:stop(key, subIndex, function()
		self.taskMultiKeyMap:remove(key, subIndex)
		if not isNil(callback) then
			callback()
		end
	end)
end

function IntervalTaskHandler:dropTasks(key, callback)
	local _id = self.taskMultiKeyMap:searchMultiKey(key)
	local i = 0
	local size
	
	if not isNil(_id) then
		size = tableLength(self.taskMultiKeyMap.metaList[_id])
		for subIndex,value in pairs(self.taskMultiKeyMap.metaList[_id]) do
			self:dropTask(key, subIndex, function()
				i = i + 1
				if i == (size) then
					callback()
				end
			end)
		end
	end
end

function IntervalTaskHandler:setTasks(key, tasks)
	local _id
	self:dropTasks(key, function()

	end)
	self.taskMultiKeyMap:setEntriesByValue(key, tasks)
	_id = taskMultiKeyMap:searchMultiKey(key)
	
	if isTable(taskMultiKeyMap.metaList[_id]) then
		for subIndex,v in pairs(taskMultiKeyMap.metaList[_id]) do
			taskMultiKeyMap.metaList[_id][subIndex]:refresh()
		end
	elseif taskMultiKeyMap.metaList[_id].refresh then
		taskMultiKeyMap.metaList[_id]:refresh()
	end
end

function IntervalTaskHandler:getTasks(key)
	return self.taskMultiKeyMap:getEntries(key)
end

function IntervalTaskHandler:setRoutines(key, routines)
	local _id = self.taskMultiKeyMap:searchMultiKey(key)
	if not isNil(_ik) then
		for k,v in pairs(routines) do
			self.taskMultiKeyMap.metaList[_id][k]:setRoutine(v)
		end
	end 
end

function IntervalTaskHandler:getRoutines(key)
	local _id =  self.taskMultiKeyMap:searchMultiKey(key)
	local routines = {}
	if not isNil(_id) then
		for k,v in pairs(self.taskMultiKeyMap.metaList[_id]) do
			routines[k] = self.taskMultiKeyMap.metaList[_id][k]:getRoutine()
		end
		return routines
	end
end

function IntervalTaskHandler:stopAll(callback)
	local i = 0
	local length = tableLength(self.taskMultiKeyMap.multiKeys)
	for k,v in pairs(self.taskMultiKeyMap.multiKeys) do
		self:stopKeyGroup(v, function() 
			i = i + 1
			if i >= length then
				callback()
			end
		end)
	end
end

function IntervalTaskHandler:runAll(callback, finished)
	local i = 0
	local length = tableLength(self.taskMultiKeyMap.multiKeys)
	for k,v in pairs(self.taskMultiKeyMap.multiKeys) do
		self:runKeyGroup(v, function() 
			i = i + 1
			if i >= length then
				callback()
			end
		end, finished)
	end
end

function IntervalTaskHandler:getStatus(key, subIndex)
	local _id =  self.taskMultiKeyMap:searchMultiKey(key)
	if not isNil(_id) then
		return self.taskMultiKeyMap.metaList[_id][subIndex]:getStatus()
	end
end