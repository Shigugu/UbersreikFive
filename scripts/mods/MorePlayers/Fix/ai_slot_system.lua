--[[
	The AI slot missed SLOT_COLORS ids
	
	Fix:
		I added more SLOT_COLORS in the array.
]]--
local mod = get_mod("MorePlayers")

local SLOT_COLORS = {
	{
		"aqua_marine",
		"cadet_blue",
		"corn_flower_blue",
		"dodger_blue",
		"sky_blue",
		"midnight_blue",
		"medium_purple",
		"blue_violet",
		"dark_slate_blue"
	},
	{
		"dark_green",
		"green",
		"lime",
		"light_green",
		"dark_sea_green",
		"spring_green",
		"sea_green",
		"medium_aqua_marine",
		"light_sea_green"
	},
	{
		"maroon",
		"dark_red",
		"brown",
		"firebrick",
		"crimson",
		"red",
		"tomato",
		"coral",
		"indian_red",
		"light_coral"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow"
	}
}

local SLOT_RADIUS = 0.5
local SLOT_POSITION_CHECK_INDEX = {
	CHECK_LEFT = 0,
	CHECK_RIGHT = 2,
	CHECK_MIDDLE = 1
}
local SLOT_POSITION_CHECK_INDEX_SIZE = table.size(SLOT_POSITION_CHECK_INDEX)
local SLOT_POSITION_CHECK_RADIANS = {
	[SLOT_POSITION_CHECK_INDEX.CHECK_LEFT] = math.degrees_to_radians(-90),
	[SLOT_POSITION_CHECK_INDEX.CHECK_RIGHT] = math.degrees_to_radians(90)
}

local function create_target_slots(target_unit, target_unit_extension, color_index)
	local all_slots = target_unit_extension.all_slots

	for slot_type, slot_data in pairs(all_slots) do
		local total_slots_count = slot_data.total_slots_count
		local slots = slot_data.slots
		local use_wait_slots = slot_data.use_wait_slots

		for i = 1, total_slots_count, 1 do
			local slot = {
				target_unit = target_unit,
				queue = {},
				original_absolute_position = Vector3Box(0, 0, 0),
				absolute_position = Vector3Box(0, 0, 0),
				ghost_position = Vector3Box(0, 0, 0),
				queue_direction = Vector3Box(0, 0, 0),
				position_right = Vector3Box(0, 0, 0),
				position_left = Vector3Box(0, 0, 0),
				index = i,
				anchor_weight = 0,
				type = slot_type,
				radians = math.degrees_to_radians(360 / total_slots_count),
				priority = slot_data.priority,
				position_check_index = SLOT_POSITION_CHECK_INDEX.CHECK_MIDDLE
			}
			local j = (i - 1) % 9 + 1
			slot.debug_color_name = SLOT_COLORS[color_index][j]
			slots[i] = slot
		end
	end
end

local AGGROABLE_SLOT_COLOR_INDEX = 5
local dummy_input = {}

mod:hook(AISlotSystem, "on_add_extension", function(func, self, world, unit, extension_name, extension_init_data)
	local extension = {}

	ScriptUnit.set_extension(unit, "ai_slot_system", extension, dummy_input)

	self.unit_extension_data[unit] = extension

	if extension_name == "AIPlayerSlotExtension" or extension_name == "AIAggroableSlotExtension" then
		local debug_color_index = nil

		if extension_name == "AIPlayerSlotExtension" then
			debug_color_index = extension_init_data.profile_index
		elseif extension_name == "AIAggroableSlotExtension" then
			debug_color_index = AGGROABLE_SLOT_COLOR_INDEX
			local _, is_level_unit = Managers.state.network:game_object_or_level_id(unit)

			if is_level_unit then
				POSITION_LOOKUP[unit] = Unit.world_position(unit, 0)
			end
		end

		extension.all_slots = {}

		for slot_type, setting in pairs(SlotSettings) do
			local unit_data_var_name = (slot_type == "normal" and "ai_slots_count") or "ai_slots_count_" .. slot_type
			local total_slots_count = Unit.get_data(unit, unit_data_var_name) or setting.count
			local slot_data = {
				total_slots_count = total_slots_count,
				slot_radians = math.degrees_to_radians(360 / total_slots_count),
				slots_count = 0,
				use_wait_slots = setting.use_wait_slots,
				priority = setting.priority,
				disabled_slots_count = 0,
				slots = {}
			}
			extension.all_slots[slot_type] = slot_data
		end

		local target_index = #self.target_units + 1
		extension.dogpile = 0
		extension.position = Vector3Box(POSITION_LOOKUP[unit])
		extension.moved_at = 0
		extension.next_slot_status_update_at = 0
		extension.valid_target = true
		extension.index = target_index
		extension.debug_color_name = SLOT_COLORS[debug_color_index][1]
		extension.num_occupied_slots = 0

		create_target_slots(unit, extension, debug_color_index)

		self.target_units[target_index] = unit
		local target_units = self.target_units
		local nav_world = self.nav_world
		local traverse_logic = self._traverse_logic
		local unit_extension_data = self.unit_extension_data

		self:update_target_slots(0, unit, target_units, unit_extension_data, extension, nav_world, traverse_logic)
	end

	if extension_name == "AIEnemySlotExtension" then
		extension.target = nil
		extension.target_position = Vector3Box()
		extension.improve_wait_slot_position_t = 0
		self.update_slots_ai_units[#self.update_slots_ai_units + 1] = unit
	end

	return extension
end)