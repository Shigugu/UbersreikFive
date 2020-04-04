--[[
	Network needs to be configured the total players you want to play.
]]--
local mod = get_mod("MorePlayers")

mod:hook(StateLoading, "setup_network_options", function(func, self)
	if not self._network_options then
		local development_port = script_data.server_port or script_data.settings.server_port or GameSettingsDevelopment.network_port

		if PLATFORM == "win32" then
			development_port = development_port + LOBBY_PORT_INCREMENT
		end

		local lobby_port = (LEVEL_EDITOR_TEST and GameSettingsDevelopment.editor_lobby_port) or development_port
		local network_options = {
			map = "None",
			project_hash = "bulldozer",
			max_members = mod.NUM_PLAYERS,
			config_file_name = "global",
			lobby_port = lobby_port,
			server_port = script_data.server_port or script_data.settings.server_port,
			query_port = script_data.query_port or script_data.settings.query_port,
			steam_port = script_data.steam_port or script_data.settings.steam_port,
			ip_address = Network.default_network_address()
		}
		self._network_options = network_options
	end
end)
