--[[
	When Conflict director spawns enemies it expect a player position is found.
	
	Console Log:
		ConflictDirector_spawn_one.log
]]--
local mod = get_mod("MorePlayers")

mod:hook(ConflictDirector, "spawn_one", function(func, ...)
	if PLAYER_POSITIONS[1] then
		func(...)
	end
end)