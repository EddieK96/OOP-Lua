class.MultiKeyMap({metaList = {}, multiKeys = {}, multiKeyIndex})

function MultiKeyMap:new(mkMap)
   self.metaList = (mkMap and cloneTable(mkMap.metaList)) or {}
   self.multiKeys = (mkMap and cloneTable(mkMap.multiKeys)) or {}
   self.multiKeyIndex = (mkMap and cloneTable(mkMap.multiKeyIndex)) or 0
end

function MultiKeyMap:getFreeMultiKeyIndex()
	while self.multiKeys[self.multiKeyIndex] or self.metaList[self.multiKeyIndex] do
		self.multiKeyIndex = self.multiKeyIndex + 1
	end
	return self.multiKeyIndex
end

function MultiKeyMap:searchMultiKey (id)
	local found
	if isTable(id) then
		-- Iterate through list  of multi-keys...
		for k,mk in pairs(self.multiKeys) do
			--Iterate through multi-key...
			for __,sk in pairs(mk) do
				found = nil
				-- Iterate through parameter...
				for ___,idk in pairs(id) do
					if (idk == sk) then
						found = k
						break
					end
				end
				if not found then
					break -- Skip to next multi-key since key element was not found in id...
				end
			end
			if found then
				return found -- Iteration through multi-key yielded a result.
			end
		end
	else
		for k,mk in pairs(self.multiKeys) do
			if mk == id then
				found = k
				break
			end 
		end
	end
	return found
end

function MultiKeyMap:insertMultiKey (id)
	local __id = self:searchMultiKey(id)

	if isNil(__id) then -- not found
		__id = self:getFreeMultiKeyIndex ()
		self.multiKeys[__id] = clone(id)
		self.multiKeyIndex = __id
		return __id
	else -- found
		return __id
	end
end
								
function MultiKeyMap:insert (id, item)
	local i = 0
	local __id
	__id = self:searchMultiKey(id)


	if isNil(__id) then -- If not found...
		__id =  self:insertMultiKey(id)
		self.metaList[__id] = {[i] = item} -- create list
		self.multiKeyIndex = __id
	else -- If exists, then add in sublist.
		if isTable(self.metaList[__id]) then
			while self.metaList[__id][i] do	
				i = i + 1
			end
			self.metaList[__id][i] = item
		else
			self.metaList[__id] = {[0] = self.metaList[__id], [1] = item}
		end
	end
	return __id,i
end

function MultiKeyMap:remove (id, subIndex)
	local __id
	__id = self:searchMultiKey(id)

	if not isNil(__id) then -- found element...
		if (not isNil(subIndex)) then -- subindex passed...
			self.metaList[__id][subIndex] = nil
			if self.metaList[__id] == {} then
				self.metaList[__id] = nil
				self.multiKeys[__id] = nil
			end
		else
			self.metaList[__id] = nil
			self.multiKeys[__id] = nil
		end	
	end
	return __id
end

function MultiKeyMap:setEntry (id, subIndex, item)
	local _id = self.searchMultiKey()
	if isNil(_id) then
		self.insertMultiKey(id)
	end
	self.metaList[_id][subIndex] = item
end

function MultiKeyMap:getEntry (id, subIndex)
	local _id = self.searchMultiKey()
	if not isNil(_id) then
		return self.metaList[_id][subIndex]
	end
end

function MultiKeyMap:setEntries (id, item)
	local _id = self.searchMultiKey()
	if isNil(_id) then
		self.insertMultiKey(id)
	end
	self.metaList[_id] = item
end

function MultiKeyMap:getEntries (id, item)
	local _id = self.searchMultiKey()
	if not isNil(_id) then
		return self.metaList[_id]
	end
end