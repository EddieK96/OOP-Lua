local classes = {}
local meta = {}
local _type = type

local oop = {
	classes = classes,
	meta = meta,
	_type = _type
}

function getOopBase ()
	return oop
end

function isInstance(o, class)
  while o do
    o = getmetatable(o)
    if class == o then return true end
  end
  return false
end

function type (o)
	if _type(o) == "table" then
		for className,class in pairs(classes) do
			if isInstance(o, class) then
				return "instance"
			end
			if class == o then
				return "class"
			end
		end
	end
	return _type(o)
end

function isMetaTable(o, m)
	return (getmetatable(o) == m)
end

function try (func, except, finally)
	local _error = nil
	if (func) and (except == nil) and (finally == nil) then
		if not xpcall(func, function(err) 
			_error = err
		end) then
			error("UNCAUGHT ERROR: " .. _error .. "", 2)
		end
	end
	
	if (func) and (except) and (finally == nil) then
		xpcall(func, function(err) 
			_error = err
			except(err)
		end)
	end
	
	if (func) and (except == nil) and (finally) then
		if xpcall(func, function(err) 
			_error = err
			finally(err)
		end) then
			finally()
		else
			error("^1UNCAUGHT ERROR: " .. _error .. "^0", 2)
		end
	end
	
	if (func) and (except) and (finally) then
		if xpcall(func, function(err) 
			_error = err
			except(err)
			finally(err)
		end) then
			finally()
		end
	end
end

function switch(v, cases)
	local f
	if not (v == nil) then
		f = cases[v] -- get case function by key
	end
	if(f) then -- if function exists for case...
		f() -- execute function
	elseif cases.isNil and (v == nil) then
		cases.isNil()
	elseif cases.default then -- for case default
		cases.default()
	end
end

--[[ Usage/Example:
switch(9, {
	[1] = function ()
		--print "Case 1."
	end,
	[2] = function ()
		--print "Case 2."
	end,
	[3] = function ()
		--print "Case 3."
	end,
	isNil = function ()
		--print "Default."
	end,
	default = function ()
		--print "Default."
	end,
})
--]]
--[[
function awaitInit (l, cb)
	if cb == nil then
		while (l == nil) or (l.initialized == nil) or (l.initialized == false) do
			Citizen.Wait(0)
		end
	else
		Citizen.CreateThread(function ()
			while (l == nil) or (l.initialized == nil) or (l.initialized == false) do
				Citizen.Wait(0)
			end
			cb()
		end)
	end
end
]]

function isNil(input)
	return input == nil
end

function ifNil(input, when, elseBlock)
	if isNil(input) then
		return when()
	elseif not isNil(elseBlock) then
		return elseBlock()
	end
end

function ifNotNil(input, when, elseBlock)
	if not isNil(input) then
		return when()
	elseif not isNil(elseBlock) then
		return elseBlock()
	end
end

function awaitInit (ln, cb)
	local thread = function (pr)
		Citizen.CreateThread(function ()
			while isNil(_G[ln]) or isNil(_G[ln].initialized) or (_G[ln].initialized == false) do
				Citizen.Wait(0)
			end
			if isType(_G[ln], "function") then
				_G[ln]()
			end
			if not isNil(cb) then
				cb()
			end
			if not isNil(pr) then
				pr:resolve()
			end
		end)
	end
	if isNil(cb) then -- try executing synchronously...
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

function isType(input, t)
	return(type(input) == t)
end

function isEmptyTable(input)
	return(input == {})
end

function any (conditions)
	if isEmptyTable(conditions) then
		return false
	end
	for k,v in pairs(conditions) do
		if v then
			return true
		end
	end
	return false
end

function isReference (l)
	return isType(l, "table") or isType(l, "userdata") or isType(l, "thread")
end

function await(ln, cb)
	local thread = function (pr)
		Citizen.CreateThread(function ()
			while (isNil(_G[ln])) do
				Citizen.Wait(0)
			end
			if isType(_G[ln], "function") then
				_G[ln]()
			end
			if not isNil(cb) then
				cb()
			end
			if not isNil(pr) then
				pr:resolve()
			end
		end)
	end
	if isNil(cb) then -- try executing synchronously...
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

-- example
--[[
await("deutscheBahn", function()
	print("yes.")
end)


Citizen.CreateThread(function()
	Citizen.Wait(4000)
	deutscheBahn = {}
end)
]]
function cout (text)
	if Config and Config.debugMode then
		Citizen.Trace(text .. "\n")
	end
end

function cloneTable(t) --from ESX/common/tables
	local meta = getmetatable(t)
	local target = {}

	for k,v in pairs(t) do
		if type(v) == 'table' then
			target[k] = cloneTable(v)
		else
			target[k] = v
		end
	end

	setmetatable(target, meta)

	return target
end

function clone(t)
	if type(t) ~= "table" then
		return t 
	end

	local meta = getmetatable(t)
	local target = {}

	for k,v in pairs(t) do
		if type(v) == "table" then
			target[k] = cloneTable(v)
		else
			target[k] = v
		end
	end

	setmetatable(target, meta)

	return target
end

function tableLength (t)
	local count = 0
	for k,v in pairs(t) do count = count + 1 end
	return count
end

function getPedPool() 
	return GetGamePool("CPed")
end
	
function boolToInt (b)
	if b then
		return 1
	else
		return 0
	end
end

function boolToStr (b)
	if b then
		return "true"
	else
		return "false"
	end
end

function all (conditions)
	if isEmptyTable(conditions) then
		return false
	end
	for k,v in pairs(conditions) do
		if not v then
			return false
		end
	end
	if conditions then
		return false
	end
	return true
end

function isTable(input)
	return(type(input) == "table")
end

function verify(variables, callback, elseBlock)
	local valid = true
	if isTable(variables) then
		for k,v in pairs(variables) do
			if isNil(v) then
				valid = false
				break
			end
		end
	else
		if isNil(variables) then
			valid = false
		end
	end
	if valid then
		if isNil(callback) then
			return true	
		else
			return callback()
		end
	else 
		if isNil(elseBlock) then
			return false
		else
			return callback()
		end
	end
end

function xand (conditions)
	local lastState
	local fi = true
	for k,v in pairs(conditions) do
		if (not(v == lastState)) and not fi then
			return false
		end
		lastState = v
		fi = false
	end
	return true
end

function xor (conditions, limit)
	local count = 0
	if limit == nil then
		_limit = 1
	elseif limit >= 0 then
		_limit = limit
	elseif limit < 0 then
		_limit = tableLength(conditions) + limit
	end

	-- Count true statements...
	for k,v in pairs(conditions) do
		if v then
			count = count + 1
		end
	end
	-- at least one input is set to true && count is not over limit...
	if (count > 0) and not(count > _limit) then
		return true
	-- No input is set to true...
	else
		return false
	end
end

--https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3
--[[
Copyright (c) 2022 web.archive.org

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Except as contained in this notice, the name(s) of the above copyright holders shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization.
]]
function deepCompare(t1,t2,ignore_mt)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
	local v2 = t2[k1]
	if v2 == nil or not deepCompare(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
	local v1 = t1[k2]
	if v1 == nil or not deepCompare(v1,v2) then return false end
	end
	return true
end
-- END OF REFERENCE

function isElementInTable(t, e)
	for k,v in pairs(t) do
		if isTable(v) and isTable(e) then
			if (v == e) or deepCompare(v, e) then
				return k
			end
		elseif v == e then
			return k
		end
	end
end

function isSubset(subset, of)
	for k,v in pairs(subset) do
		if not isElementInTable(of, v) then
			return false
		end
	end
	return true
end


function setMerge (table1, table2, target)
	local result = {}
	for k,v in pairs(table1) do
		if not (isElementInTable(result, v)) then
			table.insert(result, v)
		end
	end
	for k,v in pairs(table2) do
		if not (isElementInTable(result, v)) then
			table.insert(result, v)
		end
	end
	if target or isTable(target) then
		target = cloneTable(result)
	else
		return cloneTable(result)
	end
end

function toSet(table)
	return setMerge(table, {})
end

-- Similar to deepCompare but it compares types of values instead of values.
-- "behaviour" is a kind of metatable defining that functions behaviour:
-- behaviour.__ordered (boolean): Weither or not to consider table indexes when comparing both table structures.
-- behaviour.__orderDepth (integer): The depth to where index order is considered.
function typeCompare(table1, table2, behaviour, depth, currentDepth)
	local types = {}
	local types2 = {}
	local _currentDepth
	local orderDefined
	if currentDepth then
		_currentDepth = currentDepth
	else
		_currentDepth = 0
	end
	-- Saves subtypes into types table.
	local getTypes = function(table, compareTo, typeTable)
		if isTable(table) then
			for k,v in pairs(table) do
				orderDefined = behaviour and behaviour.__ordered and all({
					behaviour.__orderCurrentDepth,
					behaviour.__orderDepth,
					verify({behaviour.__orderCurrentDepth, behaviour.__orderDepth}, 
						function() -- if valid...
							return behaviour.__orderCurrentDepth < behaviour.__orderDepth
						end,		
						function() -- else...
							return true
						end
					)})
				local recursion = function()
					typeTable[k] = typeCompare(v, compareTo[k], behaviour, depth, _currentDepth + 1)
				end
				local recursionNoOrder = function()
					typeTable[k] = typeCompare(v, {}, behaviour, depth, _currentDepth + 1)
				end
				
				if isTable(v) and (isNil(depth) or (_currentDepth < depth)) then	-- If requirement (&&: v is table) for recursion...
					if behaviour and any({ -- If behaviour is defined... 
						not isNil(behaviour.__ordered),
						not isNil(behaviour.__orderDepth),
						not isNil(behaviour.__orderCurrentDepth),
					}) then	
						if orderDefined then -- If order is defined...
							if isNil(behaviour.__orderCurrentDepth) then
								behaviour.__orderCurrentDepth = 0
							else
								behaviour.__orderCurrentDepth = behaviour.__orderCurrentDepth + 1
							end
							recursion()		
						else -- No order is defined...
							recursionNoOrder()
						end
					else -- Default depth iteration...
						recursionNoOrder()
					end
				else -- No recursion (&&: v is not a table)...
					typeTable[k] = type(v)
				end
			end
		else
			typeTable = type(table)
		end
	end

	getTypes(table1, table2, types)
	getTypes(table2, table1, types2)

	--print("types: " .. json.encode(types), "types2: " .. json.encode(types2))
	if currentDepth then
		return(cloneTable(types))
	elseif orderDefined then
		return deepCompare(types, types2)
	else
		return deepCompare(toSet(types), toSet(types2))
	end
end

--[[ TEST
a = {
	[0] = 1,
	[1] = 3,
	[2] = 4,
	[3] = {1,2}
}

b = {
	[0] = 2,
	[1] = 5,
	[3] = 1,
	[2] = {1,2}
}
]]
--print("Result: " .. boolToStr(typeCompare(a, b)))

function toTarget (result, target, callback)
	--print(json.encode(result))
	if target or isTable(target) then
		if isTable(result) then
			--print("Value changes...")
			target = cloneTable(result)
			--print("toTarget Result: " .. json.encode(cloneTable(result)), "toTarget Target: " .. json.encode(target))
		else
			target = result
		end
		if callback then
			--print("Run callback with target = " .. json.encode(target))
			callback(cloneTable(result))
		end
	else
		if isTable(result) then
			return cloneTable(result)
		else
			return result
		end
	end
end

-- This function represents a base for custom list-merging behaviour defined via a meta-table. 
-- Default behaviour (without overriding meta-functions) 
-- Merges lists or inserts element into other element (table). 
-- mergeBehaviour.__leftIsTable (function): What to do in case of index match if the left element (table/element1) is a table.
-- mergeBehaviour.__rightIsTable (function): What to do in case of index match if the right element (table/element2) is a table.
-- mergeBehaviour.__bothAreTables (function): What to do in case of index match if both elements are tables.
-- mergeBehaviour.__noneIsTable (function): What to do in case of index match if none of both elements are tables.
function merge(element1, element2, mergeBehaviour, _target, callback)
	local passed = false
	local result
	local target = _target
	if xor({
		isNil(element1),
		isNil(element2)
	}) then
		if isNil(element1) then
			return element2
		else
			return element1
		end
	end
	if isTable(element1) and isTable(element2) then
		if mergeBehaviour and mergeBehaviour.__bothAreTables then
			result = mergeBehaviour.__bothAreTables()
		elseif (not (mergeBehaviour and any({
			mergeBehaviour.__leftIsTable,
			mergeBehaviour.__rightIsTable,
			mergeBehaviour.__bothAreTables,
			mergeBehaviour.__noneIsTable
		}))) then
			passed = true
			Citizen.CreateThread(function() 
				while not deepMerge do
					Citizen.Wait(0)
					--print("waiting...")
				end
				--result = cloneTable(deepMerge(element1, element2))
				target[42]()
				toTarget(cloneTable(deepMerge(element1, element2)), target, callback)
				--print("set:", json.encode(cloneTable(deepMerge(element1, element2))))
			end)
		end
	elseif (not isTable(element1)) and isTable(element2) then
		if mergeBehaviour and mergeBehaviour.__rightIsTable then
			result = mergeBehaviour.__rightIsTable()
		elseif not (mergeBehaviour and any({
			mergeBehaviour.__leftIsTable,
			mergeBehaviour.__rightIsTable,
			mergeBehaviour.__bothAreTables,
			mergeBehaviour.__noneIsTable
		})) then
			result = cloneTable(element2)
			table.insert(result, element1)
		end
	elseif isTable(element1) and not isTable(element2) then
		if mergeBehaviour and mergeBehaviour.__leftIsTable then
			result = mergeBehaviour.__leftIsTable()
		elseif not (mergeBehaviour and any({
			mergeBehaviour.__leftIsTable,
			mergeBehaviour.__rightIsTable,
			mergeBehaviour.__bothAreTables,
			mergeBehaviour.__noneIsTable
		})) then
			result = cloneTable(element1)
			table.insert(result, element2)
		end
	-- If both aren't tables...
	else
		if mergeBehaviour and mergeBehaviour.__noneIsTable then
			result = mergeBehaviour.__noneIsTable()
		elseif not (mergeBehaviour and any({
			mergeBehaviour.__leftIsTable,
			mergeBehaviour.__rightIsTable,
			mergeBehaviour.__bothAreTables,
			mergeBehaviour.__noneIsTable
		})) then
			result = {element1, element2}
		end
	end
	-- Note: Result can be nil.
	if not passed then
		print(json.encode(target))
		return toTarget(result, target, callback)
	end
end

-- resultValue = mergeBehaviour.__keyMatch(t1v, t2v), 
-- resultValue = mergeBehaviour.__keyValueMatch(t1v, t2v), 
-- resultKey, resultValue = mergeBehaviour.__valueMatch(t1k, t1v, t2k, t2v)
function deepMerge (table1, table2, mergeBehaviour, _target)
	local result = {}
	local _table1
	local _table2
	local switched = false
	local target = _target

	if #table1 > #table2 then
		_table1 = table1
		_table2 = table2
	else
		switched = true
		_table1 = table2
		_table2 = table1
	end
	for i=0,2,1 do
		if i == 1 then
			local temp = clone(_table1)
			_table1 = clone(_table2)
			_table2 = clone(temp)
		end
		for k,v in pairs(_table1) do
			local default = true
			local t2key = isElementInTable(_table2, v)
			if mergeBehaviour and mergeBehaviour.__valueMatch then
				if t2key then
					default = false
					if switched then
						--return result_k,result_v pair...
						local rk,vk = mergeBehaviour.__valueMatch(t2key, _table2[t2key], k, _table1[k])
						result[rk] = vk
					else
						local rk,vk = mergeBehaviour.__valueMatch(k, _table1[k], t2key, _table2[t2key])
						result[rk] = vk
					end
				end
				--default -> nothing
			end

			-- if same key exists in other table...
			if _table2[k] then
				-- Check behaviour match...
				if mergeBehaviour and mergeBehaviour.__keyValueMatch and (v == _table2[k] or deepCompare(v, _table2[k])) and not result[k] then
					if isTable(mergeBehaviour.__keyValueMatch) then
						if mergeBehaviour.__keyValueMatch[k] then
							default = false
							if switched then
								result[k] = mergeBehaviour.__keyValueMatch[k](_table2[k], _table1[k])
							else
								result[k] = mergeBehaviour.__keyValueMatch[k](_table2[k], _table2[k])
							end
						end
					else
						default = false
						if switched then
							result[k] = mergeBehaviour.__keyValueMatch(_table2[k], _table1[k])
						else
							result[k] = mergeBehaviour.__keyValueMatch(_table1[k], _table2[k])
						end
					end
				end
				-- Check behaviour match...
				if mergeBehaviour and mergeBehaviour.__keyMatch and not result[k] then
					if isTable(mergeBehaviour.__keyMatch) then
						if mergeBehaviour.__keyMatch[k] then
							default = false
							if switched then
								result[k] = mergeBehaviour.__keyMatch[k](_table2[k], _table1[k])
							else
								result[k] = mergeBehaviour.__keyMatch[k](_table2[k], _table2[k])
							end
						end
					else
						default = false
						if switched then
							result[k] = mergeBehaviour.__keyMatch(_table2[k], _table1[k])
						else
							result[k] = mergeBehaviour.__keyMatch(_table1[k], _table2[k])
						end
					end

				-- If behaviour not defined...
				elseif not any({
					v == _table2[k],
					deepCompare(v, _table2[k]),
					mergeBehaviour and any({
						mergeBehaviour.__keyMatch,
						mergeBehaviour.__keyValueMatch,
						mergeBehaviour.__valueMatch
					})
				}) then
					default = false
					result[k] = merge(v, _table2[k])
				elseif (v == _table2[k]) or deepCompare(v, _table2[k]) then
					result[k] = v
				end
			-- No match...
			else
				if isTable(v) then
					----print("Sc. 2.isTable")
					result[k] = cloneTable(v)
				else
					result[k] = v
				end
			end
			-- Default case...
			if default and mergeBehaviour and mergeBehaviour.__default then
				if switched then
					--return result_k,result_v pair...
					local rk,vk = mergeBehaviour.__default(t2key, _table2[t2key], k, _table1[k])
					if isNil(rk) then
						table.insert(result, vk)
					else
						result[rk] = vk
					end
				else
					local rk,vk = mergeBehaviour.__default(k, _table1[k], t2key, _table2[t2key])
					if isNil(rk) then
						table.insert(result, vk)
					else
						result[rk] = vk
					end
				end
			end
		end
	end
	return toTarget(result, target)
end

function loadFile(path, resource)
	if not resource then
		return LoadResourceFile(GetCurrentResourceName(), path)
	else
		return LoadResourceFile(resource, path)
	end
end

function saveFile(path, text, resource, length)
	if not resource then
		if not length then
			return SaveResourceFile(GetCurrentResourceName(), path, text, -1)
		else
			return SaveResourceFile(GetCurrentResourceName(), path, text, length)
		end
	-- if resource...
	else
		if not length then
			return SaveResourceFile(resource, path, text, -1)
		else
			return SaveResourceFile(resource, path, text, length)
		end
	end
end

--[[
local idCounter = 0
function cache(list, id, callback, timeInterval, memoryInterval)
-- Creating or altering a table:
	local insertAfter = "identifier"
	local idc = idCounter
	EasySQL.ready (function()
		local sqlTypeTable = {	
			["identifier"] = {dataType = "varchar", length = 255, defaultValue = "NOT NULL", isPrimaryKey = true}, 
			["data"] = {dataType = "longtext", length = nil, defaultValue = nil, isPrimaryKey = false}
		}
		createTableIfNotExists (id, sqlTypeTable, function(result)
			print(json.encode(result))
			doAtInterval(0, {"cache", id}, function()
				if timeInterval then
					doAtInterval(timeInterval, {"cacheTimeIntervalCheck", id}, function()
						clearCache(id)
						return true
					end)
				end
				if memoryInterval and isCacheFull(id) then
					clearCache(id)
				end
				doOnce({"cacheCallback", id, idc}, function()
					idCounter = idCounter + 1
					callback()
				end)
				--if caches
				--return true
			end)
		end)
	end)
end


function processAnimList(str)
	local currentWord = {value = "", _type = "", group = ""}
	local currentCharacter = 1
	local currentGroup = ""
	local words = {}
	local wordIndex = 0
	----print(string.sub(strn, 1, 1))
	for var=1,#str do
	   currentCharacter = string.sub(str, var, var)
	   switch(currentCharacter, {
			[" "] = function ()
				if not(currentWord.value == "") then
					if currentWord._type == "group" then
						currentGroup = currentWord.value
						currentWord.group = ""
					elseif currentWord._type == "anim" then
						currentWord.group = currentGroup
					end
					words[wordIndex] = cloneTable(currentWord)
					wordIndex = wordIndex + 1
				end
				currentWord = {value = "", _type = "", group = ""}
			end,
			["\n"] = function ()
				if not(currentWord.value == "") then
					if currentWord._type == "group" then
						currentGroup = currentWord.value
						currentWord.group = ""
					elseif currentWord._type == "anim" then
						currentWord.group = currentGroup
					end
					words[wordIndex] = cloneTable(currentWord)
					wordIndex = wordIndex + 1
				end
				currentWord = {value = "", _type = "", group = ""}
			end,
			["@"] = function ()
				currentWord._type = "group"
				currentWord.value = currentWord.value .. currentCharacter
			end,
			default = function ()
				if not (currentWord._type == "group") then 
					currentWord._type = "anim"
				end
				currentWord.value = currentWord.value .. currentCharacter
			end,
		})
	end
	local list = {}
	for k,v in pairs(words) do
		if (v.group == "") then
			list[v.value] = {}
			----print("list[" .. v.value .. "]")
		else
			if list[v.group] then
				table.insert(list[v.group], v.value)
			else
				list[v.group] = {}
			end
		end
	end
	loadFile("animations.json")
	saveFile("animations.json", json.encode(list))	
end

function getAnimations()
	local loadFile = LoadResourceFile(GetCurrentResourceName(), "animations.json")
	return json.decode(loadFile)
end
animations = getAnimations()

local flags = {} 
for var=0,511 do
	table.insert(flags, var)
end
function getAnimationStream(entity)
	local stream = {}
	--local flags = {0, 1, 2, 16, 32, 120}

	for group,animList in pairs(animations) do
		Citizen.Wait(0)
		for k,anim in pairs(animList) do
			for _,flag in pairs(flags) do
				if IsEntityPlayingAnim(
					entity, 
					group , 
					anim , 
					flag
				) then
					if not stream[group] then
						stream[group] = {}
					end
					table.insert(stream[group], anim)
				end
			end
		end
	end
	return stream
end
]]