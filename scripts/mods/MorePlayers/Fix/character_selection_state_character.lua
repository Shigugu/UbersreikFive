--[[
	Character selection it draws to much characters
	
	Prevent the game to save the profile index, this prevent crashes in official game
]]--
local mod = get_mod("MorePlayers")

mod:hook(CharacterSelectionStateCharacter, "on_enter", function (func, self, ...)
	mod.hero_selection = true
	
	func(self, ...)
	
	-- Because the orginal system is selecting the hero by profile_index, we patch this with by feeding the character_id
	local current_profile_index = self.profile_synchronizer:profile_by_peer(self.peer_id, self.local_player_id)
	local character_id = mod.SPProfiles:get_character_id(current_profile_index)
	
	self:_select_hero(character_id, self._career_index, true)
end)

mod:hook(CharacterSelectionStateCharacter, "on_exit", function (func, ...)
	mod.hero_selection = false
	
	return func(...)
end)

mod:hook(CharacterSelectionStateCharacter, "_handle_input", function(func, self, dt, t)
	if mod.profile_id then
		self:_change_profile(mod.profile_id, 1)
		
		self.parent:set_input_blocked(true)
		
		mod.profile_id = nil
		
		return
	end
	
	local input_service = self:input_service()

	self:_handle_gamepad_selection(input_service)
	self:_handle_mouse_selection()

	local current_profile_index = self.profile_synchronizer:profile_by_peer(self.peer_id, self.local_player_id)
	local select_button = self._widgets_by_name.select_button

	UIWidgetUtils.animate_default_button(select_button, dt)

	if self:_is_button_hover_enter(select_button) then
		self:_play_sound("play_gui_start_menu_button_hover")
	end

	local gamepad_active = Managers.input:is_device_active("gamepad")
	local confirm_available = not select_button.content.button_hotspot.disable_button
	local confirm_pressed = gamepad_active and confirm_available and input_service:get("confirm_press", true)
	local back_pressed = gamepad_active and self.allow_back_button and input_service:get("back_menu", true)

	if self:_is_button_pressed(select_button) or confirm_pressed then
		self:_play_sound("play_gui_start_menu_button_click")
		
		local current_character_id = mod.SPProfiles:get_character_id(current_profile_index)
		
		--if self._selected_profile_index ~= current_character_id then
			mod.respawn = true
			mod.SPProfiles:set(current_profile_index, self._selected_profile_index)
			self:_change_profile(current_profile_index, self._selected_career_index)
		--else
		--	self:_change_career(current_profile_index, self._selected_career_index)
		--end
		
		self.parent:set_input_blocked(true)
	elseif back_pressed then
		self.parent:close_menu()
	end
end)

mod:hook(CharacterSelectionStateCharacter, "_update_profile_request", function (func, self)
	if self._pending_profile_request then
		local synchronizer = self.profile_synchronizer

		if self._despawning_player_unit_profile_change then
			if not Unit.alive(self._despawning_player_unit_profile_change) then
				synchronizer:request_select_profile(self._requested_profile_index, self.local_player_id)

				self._requested_profile_index = nil
				self._despawning_player_unit_profile_change = nil

				if self.is_server then
					Managers.state.network.network_server:peer_despawned_player(self.peer_id)
				end
			end
		else
			local result, result_local_player_id = synchronizer:profile_request_result()
			local local_player_id = self.local_player_id

			assert(not result or local_player_id == result_local_player_id, "Local player id mismatch between ui and request.")

			if result == "success" then
				local peer_id = self.peer_id
				local profile_index = synchronizer:profile_by_peer(peer_id, local_player_id)
				local player = self.player_manager:player(peer_id, local_player_id)

				player:set_profile_index(profile_index)
				synchronizer:clear_profile_request_result()
				self:_save_selected_profile(profile_index)
				
				-- Force to respawn the player
				if mod.respawn == true then
					self._respawn_player_unit = true
					mod.respawn = false
				else
					self._respawn_player_unit = nil
				end
				
				self._pending_profile_request = nil
				self._requested_career_index = nil

				self.parent:set_current_hero(self._selected_profile_index)
				self.parent:close_menu()
			elseif result == "failure" then
				local hero_attributes = Managers.backend:get_interface("hero_attributes")
				local hero_name = self._hero_name

				hero_attributes:set(hero_name, "career", self._career_index)

				self._respawn_player_unit = true

				self.parent:close_menu()
			end
		end
	end
end)

mod:hook(CharacterSelectionStateCharacter, "_update_available_profiles", function(func, self)
	mod.func_original_profile(function()
		local available_profiles = self._available_profiles
		local hero_widgets = self._hero_widgets
		local player = Managers.player:local_player()
		local profile_synchronizer = self.profile_synchronizer
		local own_player_profile_index = player ~= nil and player:profile_index()
		local own_player_career_index = player ~= nil and player:career_index()
		local widget_index = 1
		local is_button_enabled = true
		local selected_career_index = self._selected_career_index
		local selected_profile_index = self._selected_profile_index

		for i, profile_index in ipairs(ProfilePriority) do
			local profile_settings = SPProfiles[profile_index]
			local is_profile_available = not profile_synchronizer:owner(profile_index)
			available_profiles[profile_index] = is_profile_available
			local is_currently_played_profile = own_player_profile_index == profile_index
			local can_play_profile = is_currently_played_profile or is_profile_available
			local careers = profile_settings.careers

			for j, career in ipairs(careers) do
				local widget = hero_widgets[widget_index]
				local content = widget.content
				content.locked = false
				content.taken = false

				widget_index = widget_index + 1
			end
		end
	
		self:_set_select_button_enabled(is_button_enabled)
	end, self)
end)

mod:hook(CharacterSelectionStateCharacter, "_setup_hero_selection_widgets", mod.func_original_profile)
mod:hook(CharacterSelectionStateCharacter, "_align_hero_selection_frames", mod.func_original_profile)
mod:hook(CharacterSelectionStateCharacter, "_select_hero", function(func, self, profile_index, ...)
	if profile_index > 5 then
		return
	end
	
	mod.func_original_profile(func, self, profile_index, ...)
end)

mod:hook(CharacterSelectionStateCharacter, "_save_selected_profile", mod.func_fix_profile_index)