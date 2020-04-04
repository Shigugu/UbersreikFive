--[[
	Because we use more profile_index's the FindProfileIndex function will corrupt this process we removed it and walla :D
]]--
local mod = get_mod("MorePlayers")

mod:hook(MatchmakingStateJoinGame, "rpc_matchmaking_request_profile_reply", function(func, self, sender, client_cookie, host_cookie, profile_index, reply)
	if not self._handshaker_client:validate_cookies(client_cookie, host_cookie) then
		return
	end

	local selected_hero_name = self._selected_hero_name
	local reason = nil
	
	if reply == true then
		self._matchmaking_manager.debug.text = "profile_accepted"
		reason = "profile_accepted"
		
		if self._selected_career_name then
			local hero_attributes = Managers.backend:get_interface("hero_attributes")
			
			local career_index = career_index_from_name(profile_index, self._selected_career_name)

			hero_attributes:set(selected_hero_name, "career", career_index)
		end

		self:_set_state_to_start_lobby()
	else
		reason = "profile_declined"
		self._matchmaking_manager.debug.text = "profile_declined"
		self._show_popup = true
	end

	local player = Managers.player:local_player(1)
	local time_taken = (self._selected_hero_at_t and self._selected_hero_at_t - self._hero_popup_at_t) or 0

	Managers.telemetry.events:ui_matchmaking_select_player(player, selected_hero_name, reason, time_taken)
end)