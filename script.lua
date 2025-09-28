---@diagnostic disable: undefined-global, param-type-mismatch, cast-local-type, lowercase-global

local rubick = {}

--#region Menu
local tab = Menu.Create("Heroes", "Intelligence", "Rubick")
tab:LinkHero(Engine.GetHeroIDByName("npc_dota_hero_rubick"), Enum.Attributes.INT)
tab:Icon("panorama/images/heroes/icons/npc_dota_hero_rubick_png.vtex_c")
local group = tab:Create("Automation"):Create("Auto Spell Steal")

local ui = {}
ui.enabled = group:Switch("Enable", false, "panorama/images/spellicons/rubick_spell_steal_png.vtex_c")
ui.min_enemies = group:Slider("Minimum enemies", 1, 5, 1, "%d")
ui.health_limit = group:Slider("Target HP%", 0, 100, 100, function(value)
    return string.format("%d%%", value)
end)
ui.search_radius = group:Slider("Search radius", 600, 6000, 2200, "%d")
ui.range_buffer = group:Slider("Cast range buffer", 0, 500, 100, "%d")
--#endregion Menu

--#region State
local state = {
    hero = nil,
    team = nil,
    last_cast_frame = {},
}
--#endregion State

--#region Helpers
local function ability_index(ability)
    if not ability then return nil end
    return Entity.GetIndex(ability)
end

local function record_cast(ability)
    local idx = ability_index(ability)
    if not idx then return end
    state.last_cast_frame[idx] = GlobalVars.GetFrameCount()
end

local function recently_cast(ability, frames)
    local idx = ability_index(ability)
    if not idx then return false end
    local last = state.last_cast_frame[idx]
    if not last then return false end
    return GlobalVars.GetFrameCount() - last <= frames
end

local function has_flag(value, flag)
    if not value or not flag or flag == 0 then
        return false
    end
    return math.floor(value / flag) % 2 == 1
end

local function ability_ready(hero, ability)
    if not ability then return false end
    if Ability.IsPassive(ability) then return false end
    if Ability.IsHidden(ability) then return false end
    if Ability.GetLevel(ability) == 0 then return false end
    if not Ability.IsReady(ability) then return false end
    if not Ability.IsCastable(ability, NPC.GetMana(hero)) then return false end
    if recently_cast(ability, 6) then return false end
    local since_last_use = Ability.SecondsSinceLastUse(ability)
    if since_last_use >= 0 and since_last_use < 0.1 then
        return false
    end
    return true
end

local function compute_range(hero, ability, fallback)
    local range = Ability.GetCastRange(ability) or 0
    if range <= 0 then
        range = fallback or ui.search_radius:Get()
    end
    local bonus = NPC.GetCastRangeBonus(hero)
    if bonus then
        range = range + bonus
    end
    return range + ui.range_buffer:Get()
end

local function is_valid_enemy(hero, enemy)
    if not enemy then return false end
    if Entity.IsSameTeam(hero, enemy) then return false end
    if not Entity.IsAlive(enemy) then return false end
    if Entity.IsDormant(enemy) then return false end
    if NPC.IsIllusion(enemy) then return false end
    if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end
    if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_OUT_OF_GAME) then return false end
    return true
end

local function enemy_health_percent(enemy)
    local max_health = Entity.GetMaxHealth(enemy)
    if not max_health or max_health <= 0 then
        return 100
    end
    return (Entity.GetHealth(enemy) / max_health) * 100
end

local function collect_enemies(hero, radius)
    local pos = Entity.GetAbsOrigin(hero)
    local team = state.team or Entity.GetTeamNum(hero)
    local list = Heroes.InRadius(pos, radius, team, Enum.TeamType.TEAM_ENEMY, true, true)
    if not list then
        return {}
    end
    return list
end

local function filter_enemies(hero, enemies, range)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local filtered = {}
    for _, enemy in ipairs(enemies) do
        if is_valid_enemy(hero, enemy) then
            if enemy_health_percent(enemy) <= ui.health_limit:Get() then
                local distance = hero_pos:Distance2D(Entity.GetAbsOrigin(enemy))
                if distance <= range then
                    filtered[#filtered + 1] = enemy
                end
            end
        end
    end
    return filtered
end

local function select_unit_target(hero, ability, enemies, range)
    local candidates = filter_enemies(hero, enemies, range)
    local best, lowest_hp = nil, math.huge
    for _, enemy in ipairs(candidates) do
        local hp = Entity.GetHealth(enemy)
        if hp < lowest_hp then
            lowest_hp = hp
            best = enemy
        end
    end
    return best
end

local function select_point_target(hero, ability, enemies, range)
    local candidates = filter_enemies(hero, enemies, range)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local best, best_distance = nil, math.huge
    for _, enemy in ipairs(candidates) do
        local distance = hero_pos:Distance2D(Entity.GetAbsOrigin(enemy))
        if distance < best_distance then
            best_distance = distance
            best = enemy
        end
    end
    if not best then
        return nil
    end
    return Entity.GetAbsOrigin(best)
end

local function cast_unit_target(hero, ability, enemies)
    local range = compute_range(hero, ability, ui.search_radius:Get())
    local target = select_unit_target(hero, ability, enemies, range)
    if target then
        Ability.CastTarget(ability, target)
        record_cast(ability)
        return true
    end
    return false
end

local function cast_point_target(hero, ability, enemies)
    local range = compute_range(hero, ability, ui.search_radius:Get())
    local point = select_point_target(hero, ability, enemies, range)
    if point then
        Ability.CastPosition(ability, point)
        record_cast(ability)
        return true
    end
    return false
end

local function cast_no_target(hero, ability, enemies)
    local range = compute_range(hero, ability, ui.search_radius:Get())
    local candidates = filter_enemies(hero, enemies, range)
    if #candidates >= ui.min_enemies:Get() then
        Ability.CastNoTarget(ability)
        record_cast(ability)
        return true
    end
    return false
end

local function process_ability(hero, ability, enemies)
    if not ability_ready(hero, ability) then
        return false
    end

    local behavior = Ability.GetBehavior(ability)

    if has_flag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)
        or has_flag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET) then
        if cast_unit_target(hero, ability, enemies) then
            return true
        end
    end

    if has_flag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_POINT)
        or has_flag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING)
        or has_flag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_OPTIONAL_POINT) then
        if cast_point_target(hero, ability, enemies) then
            return true
        end
    end

    if has_flag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_NO_TARGET)
        or has_flag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_OPTIONAL_NO_TARGET) then
        if cast_no_target(hero, ability, enemies) then
            return true
        end
    end

    return false
end

local function update_stolen(hero)
    local search_radius = math.max(ui.search_radius:Get(), 1200)
    local enemies = collect_enemies(hero, search_radius)

    for i = 0, 23 do
        local ability = NPC.GetAbilityByIndex(hero, i)
        if ability and Ability.IsStolen(ability) then
            if process_ability(hero, ability, enemies) then
                return
            end
        end
    end
end

local function update_hero_reference()
    local hero = Heroes.GetLocal()
    if not hero or not Entity.IsHero(hero) then
        state.hero = nil
        state.team = nil
        state.last_cast_frame = {}
        return nil
    end

    if NPC.IsIllusion(hero) then
        state.hero = nil
        state.team = nil
        state.last_cast_frame = {}
        return nil
    end

    if NPC.GetUnitName(hero) ~= "npc_dota_hero_rubick" then
        state.hero = nil
        state.team = nil
        state.last_cast_frame = {}
        return nil
    end

    if state.hero ~= hero then
        state.hero = hero
        state.team = Entity.GetTeamNum(hero)
        state.last_cast_frame = {}
    end

    return state.hero
end
--#endregion Helpers

--#region Callbacks
function rubick.OnUpdate()
    if not ui.enabled:Get() then
        return
    end

    local hero = update_hero_reference()
    if not hero then
        return
    end

    if not Entity.IsAlive(hero) then
        return
    end

    if NPC.IsStunned(hero) or NPC.IsSilenced(hero) then
        return
    end

    if NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_HEXED)
        or NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_FROZEN)
        or NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_COMMAND_RESTRICTED) then
        return
    end

    if NPC.IsChannellingAbility(hero) then
        return
    end

    update_stolen(hero)
end
--#endregion Callbacks

return rubick
