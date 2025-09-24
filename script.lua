---@diagnostic disable: undefined-global, lowercase-global, need-check-nil

local auto_defender = {}

local tab = Menu.Create("General", "Auto Defender", "Auto Defender", "Auto Defender")
local activation_group = tab:Create("Activation")
local priority_group = tab:Create("Item Priority", 1)
local threshold_group = tab:Create("Item Thresholds", 2)

local ui = {
    enable = activation_group:Switch("Enable", true),
}

local ITEM_DEFINITIONS = {
    glimmer = {
        item_name = "item_glimmer_cape",
        icon = "panorama/images/items/glimmer_cape_png.vtex_c",
        display_name = "Glimmer Cape",
        type = "target",
        modifier = "modifier_item_glimmer_cape",
    },
    ghost = {
        item_name = "item_ghost",
        icon = "panorama/images/items/ghost_scepter_png.vtex_c",
        display_name = "Ghost Scepter",
        type = "no_target",
        modifier = "modifier_ghost_state",
    },
    bkb = {
        item_name = "item_black_king_bar",
        icon = "panorama/images/items/black_king_bar_png.vtex_c",
        display_name = "Black King Bar",
        type = "no_target",
        modifier = "modifier_black_king_bar_immune",
    },
    force = {
        item_name = "item_force_staff",
        icon = "panorama/images/items/force_staff_png.vtex_c",
        display_name = "Force Staff",
        type = "target",
        modifier = "modifier_item_forcestaff_active",
    },
    hurricane = {
        item_name = "item_hurricane_pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        display_name = "Hurricane Pike",
        type = "target",
        modifier = "modifier_item_hurricane_pike",
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

local item_thresholds = {}

for _, item in ipairs(priority_items) do
    local key = item[1]
    local definition = ITEM_DEFINITIONS[key]
    if definition then
        item_thresholds[key] = threshold_group:Slider(
            definition.display_name,
            1,
            100,
            50,
            function(value)
                return string.format("%d%%", value)
            end
        )
    end
end

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

    local game_time = GameRules.GetGameTime()
    local items_to_use = get_enabled_items()

    if #items_to_use == 0 then
        return
    end

    for _, key in ipairs(items_to_use) do
        local threshold_slider = item_thresholds[key]
        if threshold_slider and health_percent <= threshold_slider:Get() then
            cast_item(hero, key, game_time)
        end
    end
end

function auto_defender.OnGameEnd()
    last_cast_times = {}
end

return auto_defender
