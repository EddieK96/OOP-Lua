class.Ref() -- is used to create references for primitive types that cannot be passed to functions by reference (int, string, etc.).
function Ref:new (ref)
	function Ref.__call (self, set)
		if not set then
			return self.value
		else
			self.value = set
		end
	end
	self.value = (isTable(ref) and ref.value) or (isTable(ref) and ref) or ref 
end

function Ref:set(value)
	self.value = value
end

function Ref:get()
	return self.value
end
--example...
--[[
local ref = Ref(42)
print(ref()) --42)
ref(32)
print(ref()) --32
ref:set(9)
print(ref()) --9

print("ref2:")
local ref2 = Ref:new(53)
print(ref2()) --53
ref2(43)
print(ref2()) --43
ref2:set(19)
print(ref2()) --19
ref2:set(nil)
print(ref2.value) --nil
ref2(43)
print(ref2()) --43
print("ref: " .. ref()) --9
]]