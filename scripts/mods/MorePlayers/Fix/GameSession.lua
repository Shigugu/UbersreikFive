--[[
	Because the GameSession has a limit on the local_player_id we need to patch the value
]]--
local mod = get_mod("MorePlayers")

mod:hook(GameSession, "game_object_field", function(func, self, go_id, key, ...)
	local value = func(self, go_id, key, ...)
	
	if key == "local_player_id" then
		--[[
		mod:debug(string.format("GameSession.game_object_field('local_player_id') = %s", value))
		
		if value == 8 then
			mod:debug("local_player_id = 8, WWWOOOT!!! :D It works mothafucka! :D")
		end
	
		if value == 0 then
			mod:debug("local_player_id = 0, FUUUU!!!!! xD")
		end
		]]--
		
		if value == 0 then
			value = 8
		end
	end
	
	return value
end)