--[[
	When you finished a map and everyone returns to the inn this process crashes all clients
	
	Console log:
		matchmaking_ui_vote.log
]]--
local mod = get_mod("MorePlayers")

mod:hook(MatchmakingUI, "large_window_set_player_portrait", function(func, self, index, ...)
	local widget = self:_get_detail_widget("party_slot_" .. index)
	local status_widget = self:_get_widget("player_status_" .. index)
	
	if widget and status_widget then
		return func(self, index, ...)
	end
end)

mod:hook(MatchmakingUI, "large_window_set_player_connecting", function(func, self, index, ...)
	local widget = self:_get_detail_widget("party_slot_" .. index)
	local status_widget = self:_get_widget("player_status_" .. index)
	
	if widget and status_widget then
		return func(self, index, ...)
	end
end)

mod:hook(MatchmakingUI, "_set_player_ready_state", function(func, self, index, ...)
	local widget = self:_get_detail_widget("party_slot_" .. index)
	local status_widget = self:_get_widget("player_status_" .. index)
	
	if widget and status_widget then
		return func(self, index, ...)
	end
end)

mod:hook(MatchmakingUI, "_set_player_is_voting", function(func, self, index, ...)
	local widget = self:_get_detail_widget("party_slot_" .. index)
	
	if widget then
		return func(self, index, ...)
	end
end)

mod:hook(MatchmakingUI, "_set_player_voted_yes", function (func, self, index, ...)
	local widget = self:_get_detail_widget("party_slot_" .. index)
	
	if widget then
		return func(self, index, ...)
	end
end)