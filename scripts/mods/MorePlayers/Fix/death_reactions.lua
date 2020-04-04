--[[
	When you kill a lord boss it crashed the game
]]--
local mod = get_mod("MorePlayers")

mod:hook(_G, "ferror", function(func, message, ...)
	if message == "Sanity check, how did we get above 4 here?" then
		-- Because IamLupo fuck things up xD
		return
	end
	
	return func(message, ...)
end)