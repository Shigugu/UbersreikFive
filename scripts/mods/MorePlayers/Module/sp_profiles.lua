--[[
	
]]--
local mod = get_mod("MorePlayers")

mod.func_original_profile = function(func, ...)
	SPProfiles = mod.SPProfiles.original
	ProfilePriority = mod.ProfilePriority.original
	
	func(...)
	
	SPProfiles = mod.SPProfiles.modified
	ProfilePriority = mod.ProfilePriority.modified
end

mod.SPProfiles = {
	-- Keep a copy of the original list to still let the gui draw the correct way
	original = {
		[1] = SPProfiles[1],
		[2] = SPProfiles[2],
		[3] = SPProfiles[3],
		[4] = SPProfiles[4],
		[5] = SPProfiles[5]
	},
	
	-- The list we can return to if we want a reset
	start = {
		[1] = SPProfiles[1],
		[2] = SPProfiles[2],
		[3] = SPProfiles[3],
		[4] = SPProfiles[4],
		[5] = SPProfiles[5],
		[6] = SPProfiles[1],
		[7] = SPProfiles[5],
		[8] = SPProfiles[3],
		[9] = SPProfiles[4],
		[10] = SPProfiles[2]
	},
	-- The list we want to have to modify the game state
	modified = {},
	
	set = function(self, profile_id, character_id)
		--self.start[profile_id] = self.original[character_id]
		self.modified[profile_id] = self.original[character_id]
	end,
	
	get_character_id = function(self, profile_id)
		local search_profile = self.modified[profile_id]
		
		for character_id, profile in pairs(self.original) do
			if search_profile == profile then
				return character_id
			end
		end
		
		return nil
	end,
	
	reset = function(self)
		for key, _ in pairs(self.start) do
			self.modified[key] = self.start[key]
		end
	end
}
mod.SPProfiles:reset()
SPProfiles = mod.SPProfiles.modified

mod.ProfilePriority = {
	-- Keep a copy of the original list to still let the gui draw the correct way
	original = {
		[1] = ProfilePriority[1],
		[2] = ProfilePriority[2],
		[3] = ProfilePriority[3],
		[4] = ProfilePriority[4],
		[5] = ProfilePriority[5]
	},
	
	-- The list we can return to if we want a reset
	start = {
		[1] = ProfilePriority[1],
		[2] = ProfilePriority[2],
		[3] = ProfilePriority[3],
		[4] = ProfilePriority[4],
		[5] = ProfilePriority[5],
		[6] = 6,
		[7] = 7,
		[8] = 8,
		[9] = 9,
		[10] = 10
	},
	-- The list we want to have to modify the game state
	modified = {},
	
	reset = function(self)
		for key, _ in pairs(self.start) do
			self.modified[key] = self.start[key]
		end
	end
}
mod.ProfilePriority:reset()
ProfilePriority = mod.ProfilePriority.modified
