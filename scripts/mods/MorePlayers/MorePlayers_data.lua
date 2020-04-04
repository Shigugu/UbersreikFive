local mod = get_mod("MorePlayers")

-- Everything here is optional. You can remove unused parts.
return {
	name = "MorePlayers",                               -- Readable mod name
	description = mod:localize("mod_description"),  -- Mod description
	is_togglable = false,                            -- If the mod can be enabled/disabled
	is_mutator = false,                             -- If the mod is mutator
	allow_rehooking = true,
	mutator_settings = {},                          -- Extra settings, if it's mutator
	options = {
		widgets = {}
	}
}