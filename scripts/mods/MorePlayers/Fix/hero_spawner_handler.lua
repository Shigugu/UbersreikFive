--[[
	Prevent the game to save the profile index, this prevent crashes in official game
]]--
local mod = get_mod("MorePlayers")

mod:hook(HeroSpawnerHandler, "save_selected_profile", mod.func_fix_profile_index)