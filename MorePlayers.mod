return {
	run = function()
		fassert(rawget(_G, "new_mod"), "MorePlayers must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("MorePlayers", {
			mod_script       = "scripts/mods/MorePlayers/MorePlayers",
			mod_data         = "scripts/mods/MorePlayers/MorePlayers_data",
			mod_localization = "scripts/mods/MorePlayers/MorePlayers_localization"
		})
	end,
	packages = {
		"resource_packages/MorePlayers/MorePlayers"
	}
}
