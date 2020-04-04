--[[
	When there are more then 4 players and a multi twitch vote accour then widget doesnt exist.
	
	Fix:
		Try to limit the total players to vote for, Will need later a better gui system
	
	Console log:
		twitch-vote.log
]]--
local mod = get_mod("MorePlayers")

mod:hook(TwitchVoteUI, "_sorted_player_list", function (func, self)
	local new_players = {}
	
	local players = func(self)
	
	for index, player in ipairs(players) do
		if index <= 4 then
			new_players[#new_players + 1]  = player
		end
	end
	
	return new_players
end)