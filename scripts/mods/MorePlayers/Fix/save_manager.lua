--[[
	Because the MorePlayers mod had a different ProfilePriority with more elements.
	The bot_spawn_priority is in a rare case influenced by the ProfilePriority and adds more elements to this
	data. The official game cant handle with these extra elements and crashes at start.
	
	Fix:
		- Before PlayerData is been saved check if the bot_spawn_priority has not to much elements
]]--
local mod = get_mod("MorePlayers")

mod:hook(SaveManager, "auto_save", function(func, self, file_name, data, ...)
	mod:debug("SaveManager.auto_save()")
	
	local all_players_data = data.player_data
	if all_players_data then
		for key, value in pairs(all_players_data) do
			local player_data = all_players_data[key]
			
			if player_data.bot_spawn_priority and #player_data.bot_spawn_priority > 5 then
				player_data.bot_spawn_priority = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5}
			end
		end
	end
	
	return func(self, file_name, data, ...)
end)
