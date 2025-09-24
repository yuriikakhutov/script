---@diagnostic disable: undefined-global, lowercase-global, need-check-nil

local auto_defender = {}

local tab = Menu.Create("General", "Auto Defender", "Auto Defender", "Auto Defender")
local activation_group = tab:Create("Activation")
local priority_group = tab:Create("Item Priority", 1)
local behavior_group = tab:Create("Behavior", 2)

local ui = {
    enable = activation_group:Switch("Enable", true),
    threshold = activation_group:Slider("Health threshold", 10, 100, 50, function(value)
        return string.format("%d%%", value)
    end),
    cast_all = behavior_group:Switch("Cast all selected items together", false),
}

local ITEM_DEFINITIONS = {
    glimmer = {
        item_name = "item_glimmer_cape",
        icon = "panorama/images/items/glimmer_cape_png.vtex_c",
        type = "target",
        modifier = "modifier_item_glimmer_cape",
    },
    ghost = {
        item_name = "item_ghost",
        icon = "panorama/images/items/ghost_scepter_png.vtex_c",
        type = "no_target",
        modifier = "modifier_item_ghost_state",
    },
    bkb = {
        item_name = "item_black_king_bar",
        icon = "panorama/images/items/black_king_bar_png.vtex_c",
        type = "no_target",
        modifier = "modifier_black_king_bar_immune",
    },
    force = {
        item_name = "item_force_staff",
        icon = "panorama/images/items/force_staff_png.vtex_c",
        type = "target",
        modifier = "modifier_item_forcestaff_active",
        move_home = true,
    },
    hurricane = {
        item_name = "item_hurricane_pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        type = "target",
        modifier = "modifier_item_hurricane_pike",
        move_home = true,
    },
}

local priority_items = {
    { "glimmer", ITEM_DEFINITIONS.glimmer.icon, true },
    { "ghost", ITEM_DEFINITIONS.ghost.icon, true },
    { "bkb", ITEM_DEFINITIONS.bkb.icon, true },
    { "force", ITEM_DEFINITIONS.force.icon, false },
    { "hurricane", ITEM_DEFINITIONS.hurricane.icon, false },
}

local priority_widget = priority_group:MultiSelect("Items", priority_items, true)
priority_widget:DragAllowed(true)
priority_widget:ToolTip("Drag to reorder priority. Enable items you want to use.")

local BASE_POSITIONS = {
    [Enum.TeamNum.TEAM_RADIANT] = Vector(-7050.0, -6540.0, 384.0),
    [Enum.TeamNum.TEAM_DIRE] = Vector(7050.0, 6540.0, 384.0),
}

local CAST_COOLDOWN = 0.2
local last_cast_times = {}

local CONTROL_BLOCKERS = {
    Enum.ModifierState.MODIFIER_STATE_STUNNED,
    Enum.ModifierState.MODIFIER_STATE_HEXED,
    Enum.ModifierState.MODIFIER_STATE_MUTED,
}

local function can_use_item(hero)
    if not Entity.IsAlive(hero) then
        return false
    end

    for _, state in ipairs(CONTROL_BLOCKERS) do
        if NPC.HasState(hero, state) then
            return false
        end
    end

    return true
end

local function is_recently_cast(item_id, game_time)
    local last_time = last_cast_times[item_id]
    if not last_time then
        return false
    end
    return game_time - last_time < CAST_COOLDOWN
end

local function mark_cast(item_id, game_time)
    last_cast_times[item_id] = game_time
end

local function get_enabled_items()
    local ordered = priority_widget:List()
    local enabled = {}

    for _, key in ipairs(ordered) do
        if priority_widget:Get(key) then
            enabled[#enabled + 1] = key
        end
    end

    return enabled
end

local function move_to_base(hero)
    local team = Entity.GetTeamNum(hero)
    local destination = BASE_POSITIONS[team]

    if destination then
        NPC.MoveTo(hero, destination, false, false, false, true, nil, true)
    end
end

local function cast_item(hero, item_key, game_time)
    local definition = ITEM_DEFINITIONS[item_key]
    if not definition then
        return false
    end

    if is_recently_cast(item_key, game_time) then
        return false
    end

    local item = NPC.GetItem(hero, definition.item_name, true)
    if not item then
        return false
    end

    if definition.modifier and NPC.HasModifier(hero, definition.modifier) then
        return false
    end

    if not Ability.IsReady(item) then
        return false
    end

    local mana = NPC.GetMana(hero)
    if not Ability.IsCastable(item, mana) then
        return false
    end

    if not can_use_item(hero) then
        return false
    end

    if definition.type == "no_target" then
        Ability.CastNoTarget(item)
    elseif definition.type == "target" then
        Ability.CastTarget(item, hero)
    else
        return false
    end

    mark_cast(item_key, game_time)

    if definition.move_home then
        move_to_base(hero)
    end

    return true
end

function auto_defender.OnUpdate()
    if not Engine.IsInGame() then
        last_cast_times = {}
        return
    end

    if not ui.enable:Get() then
        return
    end

    local hero = Heroes.GetLocal()
    if not hero or NPC.IsIllusion(hero) or not Entity.IsAlive(hero) or Entity.IsDormant(hero) then
        return
    end

    local max_health = Entity.GetMaxHealth(hero)
    if max_health <= 0 then
        return
    end

    local current_health = Entity.GetHealth(hero)
    local health_percent = (current_health / max_health) * 100.0

    local threshold = ui.threshold:Get()
    if health_percent > threshold then
        return
    end

    local game_time = GameRules.GetGameTime()
    local items_to_use = get_enabled_items()

    if #items_to_use == 0 then
        return
    end

    if ui.cast_all:Get() then
        for _, key in ipairs(items_to_use) do
            cast_item(hero, key, game_time)
        end
    else
        for _, key in ipairs(items_to_use) do
            if cast_item(hero, key, game_time) then
                break
            end
        end
    end
end

function auto_defender.OnGameEnd()
    last_cast_times = {}
end

return auto_defender
