--[[
	The Player ui 
	
	Fix:
		- Redeclair the functions that use this local variable and let it run by my mod variable NUM_PLAYERS
		- Add scroll functionality to the player list to be able to see the information of all players and to kick everyone again :D
		- Prevent FPS drop on a lot of players
]]--
local mod = get_mod("MorePlayers")
--local DebugMenu = get_mod("DebugMenu")

mod.IngamePlayerListUI = {
	player_list = {
		position_x = -175,
		scroll_speed = 75,
		
		--[[
			Before we draw we want to check if player has scrolled and update the player list position
		]]--
		before_draw = function(self)
			local player_list = self.ui_scenegraph.player_list
			local mod_player_list = mod.IngamePlayerListUI.player_list
			
			if Mouse.pressed(Mouse.button_id("wheel_down")) then
				player_list.position[1] = player_list.position[1] - mod_player_list.scroll_speed
			end
			
			if Mouse.pressed(Mouse.button_id("wheel_up")) then
				player_list.position[1] = player_list.position[1] + mod_player_list.scroll_speed
			end
		end,
		
		--[[
			Check if widget is in screen range. If false it wont be draw on the screen.
			Without this check there was a heavy fps drop when you have many players
		]]--
		isInsideWindow = function(self, widget)
			local player_list = self.ui_scenegraph.player_list
			
			-- Debug
			--mod:echo("player_list = {%s, %s, %s}", player_list.position[1], player_list.position[2], player_list.position[3])
			--mod:echo("widget = {%s, %s, %s}", widget.offset[1], widget.offset[2], widget.offset[3])
			
			local x = player_list.position[1] + widget.offset[1]
			
			if x < -1000 or x > 1000 then
				return false
			end
			
			return true
		end,
		
		--[[
			When we activate or deactivate the player list window we want to store the orginal position and restore it when its closed
		]]--
		set_active = function(self, active)
			local player_list = self.ui_scenegraph.player_list
			local mod_player_list = mod.IngamePlayerListUI.player_list
			
			if player_list then
				if active then
					mod_player_list.position_x = player_list.position[1]
				else
					player_list.position[1] = mod_player_list.position_x
				end
			end
		end
	},
}

local definitions = local_require("scripts/ui/views/ingame_player_list_ui_definitions")
local PLAYER_LIST_SIZE = definitions.PLAYER_LIST_SIZE
local console_cursor_definition = definitions.console_cursor_definition
mod:hook(IngamePlayerListUI, "create_ui_elements", function(func, self)
	-- Debug
	--DebugMenu.app.list:setList(self)
	
    local scenegraph_definition = definitions.scenegraph_definition
    self.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
    local static_widget_definitions = definitions.static_widget_definitions
    local static_widgets = {}
    local static_widgets_by_name = {}

    for name, defintion in pairs(static_widget_definitions) do
        local widget = UIWidget.init(defintion)
        static_widgets[#static_widgets + 1] = widget
        static_widgets_by_name[name] = widget
    end

    self._static_widgets = static_widgets
    self._static_widgets_by_name = static_widgets_by_name
    local widget_definitions = definitions.widget_definitions
    local widgets = {}
    local widgets_by_name = {}

    for name, defintion in pairs(widget_definitions) do
        local widget = UIWidget.init(defintion)
        widgets[#widgets + 1] = widget
        widgets_by_name[name] = widget
    end

    self._widgets = widgets
    self._widgets_by_name = widgets_by_name
    local mutator_summary1_widget = widgets_by_name.mutator_summary1
    mutator_summary1_widget.content.item = {
        mutators = {}
    }
    local mutator_summary2_widget = widgets_by_name.mutator_summary2
    mutator_summary2_widget.content.item = {
        mutators = {}
    }
    local specific_widget_definitions = definitions.specific_widget_definitions
    self.input_description_text_widget = UIWidget.init(specific_widget_definitions.input_description_text)
    self.background = UIWidget.init(specific_widget_definitions.background)
    self.private_checkbox_widget = UIWidget.init(specific_widget_definitions.private_checkbox)
    static_widgets_by_name.banner_top_edge.offset[3] = 1
    local banner_bottom_edge = static_widgets_by_name.banner_bottom_edge
    local banner_bottom_edge_scenegraph_id = banner_bottom_edge.scenegraph_id
    banner_bottom_edge.offset[2] = scenegraph_definition[banner_bottom_edge_scenegraph_id].size[2] - 2
    banner_bottom_edge.offset[3] = 1
    local player_list_widgets = {}

    for i = 1, mod.NUM_PLAYERS do
        player_list_widgets[i] = UIWidget.init(definitions.player_widget_definition(i))
    end

    self.player_list_widgets = player_list_widgets
    self.popup_list = UIWidget.init(definitions.popup_widget_definition)
    self._console_cursor = UIWidget.init(console_cursor_definition)
end)

mod:hook(IngamePlayerListUI, "draw", function (func, self, dt)
	mod.IngamePlayerListUI.player_list.before_draw(self)

	local ui_renderer = self.ui_renderer
	local ui_top_renderer = self.ui_top_renderer
	local ui_scenegraph = self.ui_scenegraph
	local input_manager = self.input_manager
	local input_service = input_manager:get_service("player_list_input")
	local gamepad_active = input_manager:is_device_active("gamepad")
	local render_settings = self.render_settings

	self:_update_fade_in_duration(dt)
	UIRenderer.begin_pass(ui_top_renderer, ui_scenegraph, input_service, dt, nil, render_settings)

	if not gamepad_active and not self.cursor_active then
		UIRenderer.draw_widget(ui_top_renderer, self.input_description_text_widget)
	end

	local player_portrait_widget = self._player_portrait_widget

	if player_portrait_widget then
		UIRenderer.draw_widget(ui_top_renderer, player_portrait_widget)
	end

	local static_widgets = self._static_widgets

	if static_widgets then
		for i = 1, #static_widgets, 1 do
			local widget = static_widgets[i]

			UIRenderer.draw_widget(ui_top_renderer, widget)
		end
	end

	local widgets = self._widgets

	if widgets then
		for i = 1, #widgets, 1 do
			local widget = widgets[i]

			UIRenderer.draw_widget(ui_top_renderer, widget)
		end
	end

	if self.private_setting_enabled then
		UIRenderer.draw_widget(ui_top_renderer, self.private_checkbox_widget)
	end

	if gamepad_active then
		UIRenderer.draw_widget(ui_top_renderer, self._console_cursor)
	end

	local players = self.players
	local num_players = self.num_players

	for i = 1, num_players, 1 do
		local player = players[i]
		local widget = player.widget
		
		if mod.IngamePlayerListUI.player_list.isInsideWindow(self, widget) then
			UIRenderer.draw_widget(ui_top_renderer, widget)
			
			local portrait_widget = player.portrait_widget
			if portrait_widget then
				UIRenderer.draw_widget(ui_top_renderer, portrait_widget)
			end
		end
	end

	if self.viewport_widget then
		UIRenderer.draw_widget(ui_top_renderer, self.viewport_widget)
	end

	UIRenderer.end_pass(ui_top_renderer)
	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)
	UIRenderer.draw_widget(ui_renderer, self.background)
	UIRenderer.end_pass(ui_renderer)
end)

--[[
	Backup the orginal x position of player_list when activate and restore x position when closed.
]]--
mod:hook(IngamePlayerListUI, "set_active", function(func, self, active)
	mod.IngamePlayerListUI.player_list.set_active(self, active)
	
	func(self, active)
end)
