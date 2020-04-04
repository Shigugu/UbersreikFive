--[[
	Patching the network settings to allow more players
]]--
local mod = get_mod("MorePlayers")

-- Because on initialization of the game this class doesnt exit yet we create a skeleton
StateTitleScreenInitNetwork = class(StateTitleScreenInitNetwork) -- Kludge
StateTitleScreenInitNetwork._init_network = function(self) end

mod:hook(StateTitleScreenInitNetwork, "_init_network", function(func, self)
	local auto_join_setting = Development.parameter("auto_join")

	Development.set_parameter("auto_join", nil)

	local development_port = script_data.server_port or GameSettingsDevelopment.network_port
	development_port = development_port + StateTitleScreenInitNetwork.lobby_port_increment
	StateTitleScreenInitNetwork.lobby_port_increment = StateTitleScreenInitNetwork.lobby_port_increment + 1
	local lobby_port = (LEVEL_EDITOR_TEST and GameSettingsDevelopment.editor_lobby_port) or development_port
	self._network_options = {
		project_hash = "bulldozer",
		max_members = mod.NUM_PLAYERS,
		config_file_name = "global",
		lobby_port = lobby_port
	}

	if not rawget(_G, "LobbyInternal") or not LobbyInternal.network_initialized() then
		require("scripts/network/lobby_xbox_live")
		LobbyInternal.init_client(self._network_options)
	end

	self._network_state = "_create_session"
end)