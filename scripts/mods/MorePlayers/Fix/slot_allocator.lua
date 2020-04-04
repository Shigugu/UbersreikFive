--[[
	Slot allocator had max 6 number of profiles
	
	Fix:
		use the NUM_PROFILES
]]--
local mod = get_mod("MorePlayers")

mod:hook(SlotAllocator, "init", function(func, self, is_server, lobby, num_profiles)
	return func(self, is_server, lobby, mod.NUM_PROFILES)
end)