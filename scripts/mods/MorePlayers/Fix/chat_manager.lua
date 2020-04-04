--[[
	
]]--
local mod = get_mod("MorePlayers")

mod:hook(ChatManager, "send_chat_message", function (func, self, channel_id, local_player_id, ...)
	if local_player_id >= 8 then
		local_player_id = 1
	end
	
	return func(self, channel_id, local_player_id, ...)
end)