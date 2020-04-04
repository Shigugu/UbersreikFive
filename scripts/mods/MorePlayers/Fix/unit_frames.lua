--[[
	The Player ui 
	
	Fix:
		Redeclair the functions that use this local variable and let it run by my mod variable NUM_PLAYERS
]]--
local mod = get_mod("MorePlayers")
--local DebugMenu = get_mod("DebugMenu")

mod:hook(UnitFramesHandler, "_create_team_members_unit_frames", function(func, self)
    local unit_frames = self._unit_frames

    for i = 1, mod.NUM_PLAYERS - 1, 1 do
        local unit_frame = self:_create_unit_frame_by_type("team", i)
        unit_frames[#unit_frames + 1] = unit_frame
    end

    self:_align_team_member_frames()
	
	-- Debug
	--DebugMenu.app.list:setList(self)
end)

mod:hook(UnitFramesHandler, "_align_team_member_frames", function(func, self)
    local start_offset_y = -100
    local start_offset_x = 80
    local spacing = 220
    local is_visible = self._is_visible
    local unit_frames = self._unit_frames

    local position_x = start_offset_x
    local position_y = start_offset_y

    for i = 2, #unit_frames do
        local unit_frame = unit_frames[i]
        local widget = unit_frame.widget
        local player_data = unit_frame.player_data
        local peer_id = player_data.peer_id
        local connecting_peer_id = player_data.connecting_peer_id

        if (peer_id or connecting_peer_id) and is_visible then
            widget:set_position(position_x, position_y)

            if i % 5 == 0 then
                position_x = position_x + spacing
                position_y = start_offset_y
            else
                position_y = position_y - spacing
            end

            widget:set_visible(true)
        else
            widget:set_visible(false)
        end
    end
end)

mod:hook(UnitFramesHandler, "_sync_player_stats", function (func, self, unit_frame)
	if not unit_frame.sync then
		return
	end
	
	func(self, unit_frame)
	
	local data = unit_frame.data
	local widget = unit_frame.widget
	local player_data = unit_frame.player_data
	
	local profile_index = self.profile_synchronizer:profile_by_peer(player_data.peer_id, player_data.local_player_id)
	
	if not profile_index or not player_data.player then
		return
	end
	
	local display_name = string.format("%s: %s", profile_index, UIRenderer.crop_text(player_data.player:name(), 17))
	
	data.display_name = display_name
	widget:set_player_name(display_name)
end)

mod:hook(UnitFrameUI, "_create_ui_elements", function(func, self, frame_index)
    local definitions = self.definitions
    local scenegraph_definition = self.definitions.scenegraph_definition
    self.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
    local widgets = {}

    for name, definition in pairs(definitions.widget_definitions) do
        widgets[name] = UIWidget.init(definition)
    end

    self._widgets = widgets
    self._default_widgets = {
        default_dynamic = widgets.default_dynamic,
        default_static = widgets.default_static,
    }
    self._portrait_widgets = {
        portrait_static = widgets.portrait_static,
    }
    self._equipment_widgets = {
        loadout_dynamic = widgets.loadout_dynamic,
        loadout_static = widgets.loadout_static,
    }
    self._health_widgets = {
        health_dynamic = widgets.health_dynamic,
    }
    self._ability_widgets = {
        ability_dynamic = widgets.ability_dynamic,
    }

    UIRenderer.clear_scenegraph_queue(self.ui_renderer)

    self.slot_equip_animations = {}
    self.bar_animations = {}

    self:reset()

	if frame_index then
		local gui = self.ui_renderer.gui_retained
		local hp_bar_color_tint_name = "teammate_hp_bar_color_tint_" .. frame_index
		local hp_bar_name = "teammate_hp_bar_" .. frame_index
		
		-- Clone
		if frame_index > 3 then
			Gui.clone_material_from_template(gui, hp_bar_color_tint_name, "teammate_hp_bar_color_tint_1")
			Gui.clone_material_from_template(gui, hp_bar_name, "teammate_hp_bar_1")
		end
		
		-- Set texture_id
		self:_widget_by_name("health_dynamic").content.hp_bar.texture_id = hp_bar_color_tint_name
		self:_widget_by_name("health_dynamic").content.total_health_bar.texture_id = hp_bar_name
	end

    self:set_visible(false)
    self:set_dirty()
end)


mod:hook(UIAtlasHelper, "has_texture_by_name", function (func, texture_name)
	for i = 1, mod.NUM_PLAYERS do
		local color_tint = "teammate_hp_bar_color_tint_" .. tostring(i)
		local hp_bar = "teammate_hp_bar_" .. tostring(i)
		
		if color_tint == texture_name or hp_bar == texture_name then
			return true
		end
	end
	
	return func(texture_name)
end)

mod:hook(UIAtlasHelper, "get_atlas_settings_by_texture_name", function(func, texture_name)
	for i = 1, mod.NUM_PLAYERS do
		local color_tint = "teammate_hp_bar_color_tint_" .. tostring(i)
		local hp_bar = "teammate_hp_bar_" .. tostring(i)
		
		if color_tint == texture_name or hp_bar == texture_name then
			return
		end
	end
	
	return func(texture_name)
end)

--[[
	██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗ 
	██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝ 
	██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗
	██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║
	██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝
	╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ 
]]--
--[[
mod:hook(UnitFramesHandler, "init", function (func, self, ...)
	mod:debug("UnitFramesHandler.init()")
	
	DebugMenu.app.list:setList(self)
	
	return func(self, ...)
end)
]]--