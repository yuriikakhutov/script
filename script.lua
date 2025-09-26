---@diagnostic disable: undefined-global, lowercase-global

local auto_defender = {}

--#region menu configuration
local MAIN_TAB = "General"
local MAIN_SECTION = "Auto Defender"

local overview_tab = Menu.Create(MAIN_TAB, MAIN_SECTION, "Overview")
local overview_page = overview_tab:Create("Overview")

local info_group = overview_page:Create("Info")
local activation_group = overview_page:Create("Activation")
local toggles_group = overview_page:Create("Item Toggles")
local priorities_group = overview_page:Create("Item Priorities")
local thresholds_group = overview_page:Create("Item Thresholds")
local enemy_group = overview_page:Create("Enemy Checks")

info_group:Label("Author: GhostyPowa")

local ui = {
    enable = activation_group:Switch("Enable Auto Defender", true),
    cast_all = activation_group:Switch("Cast all enabled items when low", false),
    enemy_range = activation_group:Slider("Enemy detection range", 200, 2000, 900, "%d"),
    items = {},
}

local ITEM_LIST = {
    {
        id = "glimmer",
        display_name = "Glimmer Cape",
        ability_names = { "item_glimmer_cape" },
        cast = "target_self",
        threshold_default = 50,
        priority_default = 10,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_glimmer_cape_fade",
    },
    {
        id = "ghost",
        display_name = "Ghost Scepter",
        ability_names = { "item_ghost" },
        cast = "target_self",
        threshold_default = 50,
        priority_default = 15,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_ghost_state",
    },
    {
        id = "bkb",
        display_name = "Black King Bar",
        ability_names = { "item_black_king_bar" },
        cast = "no_target",
        threshold_default = 50,
        priority_default = 20,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_black_king_bar_immune",
    },
    {
        id = "force",
        display_name = "Force Staff",
        ability_names = { "item_force_staff" },
        cast = "force_escape",
        threshold_default = 45,
        priority_default = 30,
        enemy_toggle = true,
        enemy_required_default = true,
    },
    {
        id = "hurricane",
        display_name = "Hurricane Pike",
        ability_names = { "item_hurricane_pike" },
        cast = "force_escape",
        threshold_default = 45,
        priority_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
    },
}

for _, def in ipairs(ITEM_LIST) do
    local item_ui = {}
    item_ui.toggle = toggles_group:Switch(def.display_name .. " enabled", true)
    item_ui.priority = priorities_group:Slider(def.display_name .. " priority", 1, 100, def.priority_default or 50, "%d")
    item_ui.threshold = thresholds_group:Slider(def.display_name .. " health %", 1, 100, def.threshold_default or 50, "%d%%")

    if def.enemy_toggle then
        item_ui.enemy_check = enemy_group:Switch(def.display_name .. " requires nearby enemy", def.enemy_required_default ~= false)
    end

    ui.items[def.id] = item_ui
end
--#endregion

--#region helpers
local DIRE_FOUNTAIN = Vector(7045, 6545, 512)
local RADIANT_FOUNTAIN = Vector(-7065, -6525, 512)

local function reset_state()
    auto_defender.pending_casts = {}
    auto_defender.last_cast_time = {}
end

reset_state()

local function get_channel_check()
    if NPC.IsChannelingAbility then
        return NPC.IsChannelingAbility
    end

    if NPC.IsChannellingAbility then
        return NPC.IsChannellingAbility
    end

    return function()
        return false
    end
end

local is_channeling = get_channel_check()

local function get_local_hero()
    if not Engine.IsInGame() then
        return nil
    end

    local hero = Heroes.GetLocal()
    if not hero or not Entity.IsAlive(hero) then
        return nil
    end

    return hero
end

local function get_health_percent(hero)
    local health = Entity.GetHealth(hero) or 0
    local max_health = Entity.GetMaxHealth(hero) or 1

    if max_health <= 0 then
        return 0
    end

    return (health / max_health) * 100
end

local function ability_is_ready(hero, ability)
    if not ability then
        return false
    end

    if Ability.IsHidden and Ability.IsHidden(ability) then
        return false
    end

    if Ability.IsCooldownReady and not Ability.IsCooldownReady(ability) then
        return false
    end

    if Ability.IsReady and not Ability.IsReady(ability) then
        return false
    end

    if Ability.IsInAbilityPhase and Ability.IsInAbilityPhase(ability) then
        return false
    end

    local mana_cost = Ability.GetManaCost and Ability.GetManaCost(ability) or 0
    if NPC.GetMana and NPC.GetMana(hero) < mana_cost then
        return false
    end

    if Ability.GetCurrentCharges then
        local charges = Ability.GetCurrentCharges(ability)
        if charges ~= nil and charges > 0 and charges < 1 then
            return false
        end
    end

    return true
end

local function vector_distance(a, b)
    if not a or not b then
        return math.huge
    end

    local ax, ay = a.x or a[1] or 0, a.y or a[2] or 0
    local bx, by = b.x or b[1] or 0, b.y or b[2] or 0
    local dx = ax - bx
    local dy = ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function find_closest_enemy(hero, range)
    if not hero then
        return nil
    end

    range = range or 1200

    if NPC.GetHeroesInRadius and Enum and Enum.TeamType then
        local enemies = NPC.GetHeroesInRadius(hero, range, Enum.TeamType.TEAM_ENEMY)
        if enemies then
            for _, enemy in ipairs(enemies) do
                if enemy and Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) and not NPC.IsIllusion(enemy) then
                    return enemy
                end
            end
        end
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    local closest
    local closest_distance = math.huge

    for _, enemy in ipairs(Heroes.GetAll()) do
        if enemy ~= hero and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) and not Entity.IsSameTeam(hero, enemy) then
            local enemy_pos = Entity.GetAbsOrigin(enemy)
            local distance = vector_distance(hero_pos, enemy_pos)
            if distance <= range and distance < closest_distance then
                closest = enemy
                closest_distance = distance
            end
        end
    end

    return closest
end

local function find_ability(hero, def)
    for _, ability_name in ipairs(def.ability_names) do
        if NPC.GetItem then
            local ability = NPC.GetItem(hero, ability_name, true)
            if ability then
                return ability
            end
        end

        if NPC.GetAbility then
            local ability = NPC.GetAbility(hero, ability_name)
            if ability then
                return ability
            end
        end
    end

    return nil
end

local function hero_has_modifier(hero, modifier_name)
    if not modifier_name or modifier_name == "" then
        return false
    end

    if NPC.HasModifier then
        return NPC.HasModifier(hero, modifier_name)
    end

    return false
end

local function get_fountain_position(hero)
    if not hero or not Entity.GetTeamNum then
        return nil
    end

    local team = Entity.GetTeamNum(hero)
    if not team or not Enum or not Enum.TeamType then
        return nil
    end

    if team == Enum.TeamType.TEAM_DIRE then
        return DIRE_FOUNTAIN
    end

    if team == Enum.TeamType.TEAM_RADIANT then
        return RADIANT_FOUNTAIN
    end

    return nil
end

local function order_move_to(hero, position)
    if not hero or not position or not Player or not Player.PrepareUnitOrders or not Players or not Players.GetLocal then
        return
    end

    if not Enum or not Enum.UnitOrder or not Enum.PlayerOrderIssuer then
        return
    end

    local player_id = Players.GetLocal()
    Player.PrepareUnitOrders(
        player_id,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        position,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero
    )
end

local function cast_item(def, ability, hero, enemy)
    if not ability or not hero then
        return false
    end

    if not def.allow_while_channeling and is_channeling(hero) then
        return false
    end

    local now = GameRules and GameRules.GetGameTime and GameRules.GetGameTime() or os.clock()
    local last_cast = auto_defender.last_cast_time[def.id]
    if last_cast and now - last_cast < 0.1 then
        return false
    end

    if def.cast == "target_self" then
        Ability.CastTarget(ability, hero)
    elseif def.cast == "no_target" then
        Ability.CastNoTarget(ability)
    elseif def.cast == "force_escape" then
        Ability.CastTarget(ability, hero)

        local fountain = get_fountain_position(hero)
        if not fountain and enemy then
            local hero_pos = Entity.GetAbsOrigin(hero)
            local enemy_pos = Entity.GetAbsOrigin(enemy)
            local dx = (hero_pos.x or 0) - (enemy_pos.x or 0)
            local dy = (hero_pos.y or 0) - (enemy_pos.y or 0)
            local length = math.sqrt(dx * dx + dy * dy)
            if length > 0 then
                local distance = 600
                fountain = Vector((hero_pos.x or 0) + (dx / length) * distance, (hero_pos.y or 0) + (dy / length) * distance, hero_pos.z or 0)
            end
        end

        if fountain then
            order_move_to(hero, fountain)
        end
    else
        return false
    end

    auto_defender.last_cast_time[def.id] = now
    return true
end

local function enemy_is_required(def, item_ui)
    if not def.enemy_toggle then
        return false
    end

    if item_ui.enemy_check and item_ui.enemy_check.Get then
        return item_ui.enemy_check:Get()
    end

    return def.enemy_required_default == true
end

local function collect_ready_items(hero, health_pct)
    local ready = {}
    local enemy_range = ui.enemy_range:Get()

    for _, def in ipairs(ITEM_LIST) do
        local controls = ui.items[def.id]
        if controls and controls.toggle:Get() then
            local threshold = controls.threshold:Get()
            if health_pct <= threshold then
                local ability = find_ability(hero, def)
                if ability and ability_is_ready(hero, ability) and not hero_has_modifier(hero, def.modifier) then
                    local enemy
                    if enemy_is_required(def, controls) then
                        enemy = find_closest_enemy(hero, enemy_range)
                        if not enemy then
                            goto continue
                        end
                    end

                    table.insert(ready, {
                        def = def,
                        ability = ability,
                        enemy = enemy,
                        priority = controls.priority:Get(),
                    })
                end
            end
        end

        ::continue::
    end

    table.sort(ready, function(a, b)
        if a.priority == b.priority then
            return a.def.id < b.def.id
        end
        return a.priority < b.priority
    end)

    return ready
end
--#endregion

--#region callbacks
function auto_defender.OnUpdate()
    if not ui.enable:Get() then
        return
    end

    local hero = get_local_hero()
    if not hero then
        return
    end

    local health_pct = get_health_percent(hero)
    local ready_items = collect_ready_items(hero, health_pct)

    for index, entry in ipairs(ready_items) do
        local casted = cast_item(entry.def, entry.ability, hero, entry.enemy)
        if casted and not ui.cast_all:Get() then
            break
        end
    end
end

function auto_defender.OnScriptLoad()
    reset_state()
end

function auto_defender.OnGameEnd()
    reset_state()
end

function auto_defender.OnScriptUnload()
    reset_state()
end
--#endregion

return auto_defender
