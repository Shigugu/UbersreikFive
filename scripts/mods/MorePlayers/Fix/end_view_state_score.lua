--[[
	If you have more then 4 players and you reach the score board it crash.
	
	Fix:
		Limit the total widget by 4. This way the scoreboard wont crash
		
	Future:
		It would be nice the scores would be placed on different possitions and placed based on NUM_PLAYERS
]]--
local mod = get_mod("MorePlayers")

mod:hook(EndViewStateScore, "_setup_player_scores", function(func, self, players_session_scores)
	local score_panel_scores = {}
	local player_names = {}
	local widget_index = 1
	local score_index = 1
	self._players_by_widget_index = {}
	local players_by_widget_index = self._players_by_widget_index
	local hero_widgets = self._hero_widgets

	for stats_id, player_data in pairs(players_session_scores) do
		if widget_index <= 4 then
			self:_set_topic_data(player_data, widget_index)
			self:_group_scores_by_player_and_topic(score_panel_scores, player_data, widget_index)

			player_names[widget_index] = player_data.name
			players_by_widget_index[widget_index] = player_data
			local peer_id = player_data.peer_id
			local profile_index = player_data.profile_index
			local career_index = player_data.career_index
			local profile_data = SPProfiles[profile_index]
			local careers = profile_data.careers
			local career_settings = careers[career_index]
			local portrait_image = career_settings.portrait_image
			local portrait_frame = player_data.portrait_frame or "default"
			local player_level = player_data.player_level
			local is_player_controlled = player_data.is_player_controlled
			local level_text = (is_player_controlled and ((player_level and tostring(player_level)) or "-")) or "BOT"
			local widget_definition = UIWidgets.create_portrait_frame("player_frame_" .. widget_index, portrait_frame, level_text, 1, nil, portrait_image)
			hero_widgets[widget_index] = UIWidget.init(widget_definition)
			widget_index = widget_index + 1
		end
	end

	self:_setup_score_panel(score_panel_scores, player_names)
end)
