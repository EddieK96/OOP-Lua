-- Wide range of possible notations:
-- Call method:
-- 1: class([name:string], [table])
-- 2: class([name:string], extends([parent]), [table])
-- 3: class.[name]([table])
-- 4: class.[name](extends([parent]), [table])

-- Indexing method:
-- 5: function class:[name]([params]) [constructor block] end
-- 6: class.[name] = {extends([parent]), function[optional name to "highlight"](self, [params]) [constructor block] end}

local classes = {}
local meta = {}
local _type = type

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

function isMetaTable(o, m)
	return (getmetatable(o) == m)
end

function extends (o)
	if type(o) == "class" then
		return o
	elseif (type(o) == "table") or (type(o) == "instance") then
		return o
	elseif (type(o) == "string") and not (classes[o] == nil) then
		return classes[o]
	else
		error("^1Cannot inherit from type \"" .. type(o) .. "\".^0", 2)
	end
end

-- NO TOUCH/USE ZONE...

local cmeta = {}
class = {}

local function newDynamicClass (name, parent_, _const)
	local parent
	local const
	if isNil(_const) then
		const = parent_
	else
		const = _const
		parent = parent_
	end
	local metaTable
	o = {}
	if not isReference(o) then
		error("^1Attempt to register a value as a class.^0" ,2)
	end
	_G[name] = o
	classes[name] = o
	local modifyConstructor = function(table, constructor)
		rawset(table, "new", function(self, ...) -- Actual constructor ...
			-- Set meta-table upon defining the constructor on the frontend.
			local o = {}
			local retval
		   setmetatable(o, self)
		   self.__index = self
		   -- constructor = function(self, ...) as per colon notation.
			retval =  constructor(o, ...) -- Using "self" in the constructor now refers to the object beeing created.
			if not isNil(o.override) then
				o = deepMerge (clone(o), clone(o.override), {__keyMatch = function(ov, oov)
					return ov
				end})
				setmetatable(o, self)
			end
			if isNil(retval) then
				return o  -- returns "self" as specified inside the constructor.
			else
				return retval
			end
		end)
	end
	local modifyNewConstructor = function(m)
		m = m or {}
		setmetatable(_G[name], m)
		function m.__newindex (table, key, value)
			if key == "new" then
				print("NEW", name)
				modifyConstructor(table, value)
				m.__call = table.new
			else
				rawset(table, key, value)
			end
		end
	end

	if isNil(parent) then -- create base-class.
		if isNil(meta[name]) then
			meta[name] = {}
		end
		metaTable = meta[name]
	else -- inherit from specified parent.
		metaTable = parent
	end

	modifyNewConstructor(metaTable)
	if isType(const, "function") then
		modifyConstructor(o, o.new)
		metaTable.__call = o.new
	end
	return metaTable
end

local function newClass (name, parent_, o)
	local parent
	local metaTable
	if isNil(o) then
		o = parent_
	else
		parent = parent_
	end
	o = o or {}
	if not isReference(o) then
		error("^1Attempt to register a value as a class.^0" ,2)
	end
	_G[name] = o
	classes[name] = o
	local modifyConstructor = function(table, constructor)
		rawset(table, "new", function(self, ...) -- Actual constructor ...
			-- Set meta-table upon defining the constructor on the frontend.
			local o = {}
			local retval
		   setmetatable(o, self)
		   self.__index = self
		   -- constructor = function(self, ...) as per colon notation.
			retval =  constructor(o, ...) -- Using "self" in the constructor now refers to the object beeing created.
			if not isNil(o.override) then
				o = deepMerge (clone(o), clone(o.override), {__keyMatch = function(ov, oov)
					return ov
				end})
				setmetatable(o, self)
			end
			if isNil(retval) then
				return o  -- returns "self" as specified inside the constructor.
			else
				return retval
			end
		end)
	end
	local modifyNewConstructor = function(m)
		m = m or {}
		setmetatable(_G[name], m)
		function m.__newindex (table, key, value)
			if key == "new" then
				modifyConstructor(table, value)
				m.__call = table.new
			else
				rawset(table, key, value)
			end
		end
	end

	if isNil(parent) then -- create base-class.
		if isNil(meta[name]) then
			meta[name] = {}
		end
		metaTable = meta[name]
	else -- inherit from specified parent.
		metaTable = parent
	end

	modifyNewConstructor(metaTable)
	if isType(rawget(o, new), "function") then
		print("^5Modify constructor for " .. name .. "^0")
		modifyConstructor(o, o.new)
		metaTable.__call = o.new
	end
	return metaTable
end
setmetatable(class, cmeta)

function cmeta.__index (table, key)
	return function(parent_, o)
		local retval = newClass(key, parent_, o)
		return retval
	end
end

function cmeta.__call (self, ...)
	return newClass(...)
end

function cmeta.__newindex (table, key, value)
	local extendable
	local constructor
	for k,v in pairs(value) do
		if isType(v, "class") or isType(v, "table") or isType(v, "instance") then
			extendable = v
		elseif isType(v, "function") then
			constructor = v
		end
	end
	newDynamicClass(key, extendable, constructor)
end