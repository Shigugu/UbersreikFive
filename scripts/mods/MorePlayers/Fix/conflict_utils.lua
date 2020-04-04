--[[
	The Conflict director needs to figure out what players are alone.
	It does this with a local variable that only has been alocated with local NUM_PLAYERS
	
	fix:
		Patch "max_cluster_score" and adjust the algorithem to more players
	
	Made by Zaphio
]]--
local mod = get_mod("MorePlayers")
--local DebugMenu = get_mod("DebugMenu")

local loneliness = {}
local max_cluster_score = { }

for i=1, mod.NUM_PLAYERS do
    max_cluster_score[i] = i*(i-1) / 2
end

mod:hook(ConflictUtils, "cluster_weight_and_loneliness", function (func, positions, min_dist)
    local distance_squared = Vector3.distance_squared
    local min_dist_sq = min_dist * min_dist
    local num_positions = #positions

    if num_positions == 1 then
        return 1, 1, 100
    elseif num_positions == 0 then
        return 0, 0, 0
    end

    for i=1, num_positions do
        loneliness[i] = 0
    end

    local utility_sum = 0
    for i=1, num_positions do
        local pos_i = positions[i]
        for j=i+1, num_positions do
            local pos_j = positions[j]
            local dist_sq_i_j = distance_squared(pos_i, pos_j)
            utility_sum = utility_sum + (dist_sq_i_j < min_dist and 1 or 0)
            loneliness[i] = loneliness[i] + dist_sq_i_j
            loneliness[j] = loneliness[j] + dist_sq_i_j
        end
    end

    local cluster_utility = utility_sum / max_cluster_score[num_positions]
    local loneliest_value = 0
    local loneliest_index = 1

    for i = 1, num_positions, 1 do
        if loneliest_value < loneliness[i] then
            loneliest_value = loneliness[i]
            loneliest_index = i
        end
    end

    loneliest_value = math.sqrt(loneliest_value) / num_positions

    return cluster_utility, loneliest_index, loneliest_value, loneliness
end)

--[[
	Because this function is doing herpy derpy i take first position and say this is the only cluster
	
	Needs a better fix in the future
]]--
mod:hook(ConflictUtils, "cluster_positions", function(func, positions, min_dist)
	mod:debug("ConflictUtils.cluster_positions()")
	
	local clusters = {positions[1]}
	local clusters_sizes = {1}
	
	return clusters, clusters_sizes
end)

--[[
-- Test the cluster_positions function for errors
mod:command("cluster", "", function(...)
	local clusters, clusters_sizes = ConflictUtils.cluster_positions(PLAYER_AND_BOT_POSITIONS, 7)
end)
]]--