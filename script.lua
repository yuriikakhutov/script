---@diagnostic disable: undefined-global, lowercase-global, param-type-mismatch

local auto_defender = {}

--#region UI setup
local tab = Menu.Create("General", "Auto Defender", "Auto Defender", "Auto Defender")

local info_group = tab:Create("Info")
local activation_group = tab:Create("Activation", 1)
local items_group = tab:Create("Items", 2)
local priority_group = tab:Create("Priority", 3)
local threshold_group = tab:Create("Health Thresholds", 4)
local enemy_group = tab:Create("Enemy Checks", 5)

info_group:Label("Author: GhostyPowa")

local ui = {
    enable = activation_group:Switch("Enable", true),
    escape_turn_delay = activation_group:Slider("Force/Hurricane turn delay (ms)", 0, 500, 200, "%dms"),
    enemy_range = enemy_group:Slider("Enemy detection range", 200, 2000, 900, "%d"),
    items = {},
}

priority_group:Label("Lower priority value means the item attempts earlier")

--#endregion

--#region Item definitions
local ITEM_DEFINITIONS = {
    {
        id = "glimmer",
        display_name = "Glimmer Cape",
        icon = "panorama/images/items/glimmer_cape_png.vtex_c",
        ability_names = { "item_glimmer_cape" },
        cast = "target_self",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_glimmer_cape_fade",
    },
    {
        id = "ghost",
        display_name = "Ghost Scepter",
        icon = "panorama/images/items/ghost_scepter_png.vtex_c",
        ability_names = { "item_ghost" },
        cast = "target_self",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_ghost_state",
    },
    {
        id = "bkb",
        display_name = "Black King Bar",
        icon = "panorama/images/items/black_king_bar_png.vtex_c",
        ability_names = { "item_black_king_bar" },
        cast = "no_target",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_black_king_bar_immune",
    },
    {
        id = "pipe",
        display_name = "Pipe of Insight",
        icon = "panorama/images/items/pipe_png.vtex_c",
        ability_names = { "item_pipe" },
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_pipe_barrier",
    },
    {
        id = "crimson",
        display_name = "Crimson Guard",
        icon = "panorama/images/items/crimson_guard_png.vtex_c",
        ability_names = { "item_crimson_guard" },
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_crimson_guard_nostack",
    },
    {
        id = "blade_mail",
        display_name = "Blade Mail",
        icon = "panorama/images/items/blade_mail_png.vtex_c",
        ability_names = { "item_blade_mail" },
        cast = "no_target",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_blade_mail_reflect",
    },
    {
        id = "lotus",
        display_name = "Lotus Orb",
        icon = "panorama/images/items/lotus_orb_png.vtex_c",
        ability_names = { "item_lotus_orb" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_lotus_orb_active",
    },
    {
        id = "solar_crest",
        display_name = "Solar Crest",
        icon = "panorama/images/items/solar_crest_png.vtex_c",
        ability_names = { "item_solar_crest" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_solar_crest_armor",
    },
    {
        id = "drum",
        display_name = "Drum of Endurance",
        icon = "panorama/images/items/ancient_janggo_png.vtex_c",
        ability_names = { "item_ancient_janggo" },
        cast = "no_target",
        threshold_default = 55,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_charges = true,
    },
    {
        id = "bearing",
        display_name = "Boots of Bearing",
        icon = "panorama/images/items/boots_of_bearing_png.vtex_c",
        ability_names = { "item_boots_of_bearing" },
        cast = "no_target",
        threshold_default = 55,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_charges = true,
    },
    {
        id = "force",
        display_name = "Force Staff",
        icon = "panorama/images/items/force_staff_png.vtex_c",
        ability_names = { "item_force_staff" },
        cast = "force_escape",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        escape_distance = 600,
        active_modifier = "modifier_item_force_staff_active",
    },
    {
        id = "hurricane",
        display_name = "Hurricane Pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        ability_names = { "item_hurricane_pike" },
        cast = "force_escape",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        escape_distance = 600,
        active_modifier = "modifier_item_hurricane_pike",
    },
    {
        id = "blink",
        display_name = "Blink Dagger",
        icon = "panorama/images/items/blink_png.vtex_c",
        ability_names = { "item_blink" },
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "swift_blink",
        display_name = "Swift Blink",
        icon = "panorama/images/items/swift_blink_png.vtex_c",
        ability_names = { "item_swift_blink" },
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "arcane_blink",
        display_name = "Arcane Blink",
        icon = "panorama/images/items/arcane_blink_png.vtex_c",
        ability_names = { "item_arcane_blink" },
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "overwhelming_blink",
        display_name = "Overwhelming Blink",
        icon = "panorama/images/items/overwhelming_blink_png.vtex_c",
        ability_names = { "item_overwhelming_blink" },
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "meteor",
        display_name = "Meteor Hammer",
        icon = "panorama/images/items/meteor_hammer_png.vtex_c",
        ability_names = { "item_meteor_hammer" },
        cast = "meteor_combo",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 600,
    },
    {
        id = "blood_grenade",
        display_name = "Blood Grenade",
        icon = "panorama/images/items/blood_grenade_png.vtex_c",
        ability_names = { "item_blood_grenade" },
        cast = "position_enemy",
        threshold_default = 60,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_charges = true,
        cast_range_override = 900,
    },
    {
        id = "urn",
        display_name = "Urn of Shadows",
        icon = "panorama/images/items/urn_of_shadows_png.vtex_c",
        ability_names = { "item_urn_of_shadows" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_charges = true,
    },
    {
        id = "vessel",
        display_name = "Spirit Vessel",
        icon = "panorama/images/items/spirit_vessel_png.vtex_c",
        ability_names = { "item_spirit_vessel" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_charges = true,
    },
    {
        id = "disperser",
        display_name = "Disperser",
        icon = "panorama/images/items/disperser_png.vtex_c",
        ability_names = { "item_disperser" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_disperser_speed",
    },
    {
        id = "ethereal",
        display_name = "Ethereal Blade",
        icon = "panorama/images/items/ethereal_blade_png.vtex_c",
        ability_names = { "item_ethereal_blade" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_ethereal_blade_ethereal",
    },
    {
        id = "halberd",
        display_name = "Heaven's Halberd",
        icon = "panorama/images/items/heavens_halberd_png.vtex_c",
        ability_names = { "item_heavens_halberd" },
        cast = "target_enemy",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 600,
    },
    {
        id = "atos",
        display_name = "Rod of Atos",
        icon = "panorama/images/items/rod_of_atos_png.vtex_c",
        ability_names = { "item_rod_of_atos" },
        cast = "target_enemy",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 1100,
    },
    {
        id = "gleipnir",
        display_name = "Gleipnir",
        icon = "panorama/images/items/gleipnir_png.vtex_c",
        ability_names = { "item_gleipnir" },
        cast = "position_enemy",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 1100,
    },
    {
        id = "diffusal",
        display_name = "Diffusal Blade",
        icon = "panorama/images/items/diffusal_blade_png.vtex_c",
        ability_names = { "item_diffusal_blade", "item_diffusal_blade_2" },
        cast = "target_enemy",
        threshold_default = 55,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 600,
    },
    {
        id = "nullifier",
        display_name = "Nullifier",
        icon = "panorama/images/items/nullifier_png.vtex_c",
        ability_names = { "item_nullifier" },
        cast = "target_enemy",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 900,
    },
    {
        id = "orchid",
        display_name = "Orchid Malevolence",
        icon = "panorama/images/items/orchid_png.vtex_c",
        ability_names = { "item_orchid" },
        cast = "target_enemy",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 900,
    },
    {
        id = "bloodthorn",
        display_name = "Bloodthorn",
        icon = "panorama/images/items/bloodthorn_png.vtex_c",
        ability_names = { "item_bloodthorn" },
        cast = "target_enemy",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 900,
    },
    {
        id = "hex",
        display_name = "Scythe of Vyse",
        icon = "panorama/images/items/sheepstick_png.vtex_c",
        ability_names = { "item_sheepstick" },
        cast = "target_enemy",
        threshold_default = 40,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 800,
    },
    {
        id = "abyssal",
        display_name = "Abyssal Blade",
        icon = "panorama/images/items/abyssal_blade_png.vtex_c",
        ability_names = { "item_abyssal_blade" },
        cast = "target_enemy",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 600,
    },
    {
        id = "dagon",
        display_name = "Dagon",
        icon = "panorama/images/items/dagon_5_png.vtex_c",
        ability_names = {
            "item_dagon_5",
            "item_dagon_4",
            "item_dagon_3",
            "item_dagon_2",
            "item_dagon",
        },
        cast = "target_enemy",
        threshold_default = 60,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 800,
    },
    {
        id = "wind_waker",
        display_name = "Wind Waker",
        icon = "panorama/images/items/wind_waker_png.vtex_c",
        ability_names = { "item_wind_waker" },
        cast = "target_self",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_wind_waker",
    },
    {
        id = "silver_edge",
        display_name = "Silver Edge",
        icon = "panorama/images/items/silver_edge_png.vtex_c",
        ability_names = { "item_silver_edge" },
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 600,
    },
    {
        id = "shadow_blade",
        display_name = "Shadow Blade",
        icon = "panorama/images/items/shadow_blade_png.vtex_c",
        ability_names = { "item_invis_sword" },
        cast = "no_target",
        threshold_default = 55,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_invisible",
    },
}
--#endregion

for index, def in ipairs(ITEM_DEFINITIONS) do
    local entry = {}
    entry.enabled = items_group:Switch(def.display_name, true)
    entry.priority = priority_group:Slider(def.display_name .. " priority", 1, #ITEM_DEFINITIONS, index, "%d")
    entry.threshold = threshold_group:Slider(def.display_name .. " threshold", 1, 100, def.threshold_default or 50, "%d%%")
    if def.enemy_toggle then
        entry.requires_enemy = enemy_group:Switch(def.display_name .. " requires enemy", def.enemy_required_default or false)
    end
    ui.items[def.id] = entry
end

--#region Helpers
local function get_local_hero()
    local hero = Heroes.GetLocal()
    if not hero then
        return nil
    end
    if not Entity.IsAlive(hero) then
        return nil
    end
    if Entity.IsDormant(hero) then
        return nil
    end
    if NPC.IsIllusion(hero) then
        return nil
    end
    return hero
end

local function health_percent(hero)
    local health = Entity.GetHealth(hero)
    local max_health = Entity.GetMaxHealth(hero)
    if max_health <= 0 then
        return 100
    end
    return (health / max_health) * 100
end

local function find_item(hero, names)
    for _, name in ipairs(names) do
        local ability = NPC.GetItem(hero, name, true)
        if ability then
            return ability
        end
    end
    return nil
end

local function ability_is_valid(hero, ability)
    if not ability then
        return false
    end
    if Ability.IsPassive(ability) then
        return false
    end
    if Ability.IsHidden(ability) then
        return false
    end
    if Ability.GetOwner(ability) ~= hero then
        return false
    end
    if not Ability.IsActivated(ability) then
        return false
    end
    if not Ability.IsReady(ability) then
        return false
    end
    if not Ability.IsCastable(ability, NPC.GetMana(hero)) then
        return false
    end
    return true
end

local function item_has_charges(ability)
    if not ability then
        return false
    end
    local charges = Ability.GetCurrentCharges(ability)
    if charges == nil then
        return true
    end
    return charges > 0
end

local function collect_enemies(hero, radius)
    local enemies = Entity.GetHeroesInRadius(hero, radius, Enum.TeamType.TEAM_ENEMY, true, true)
    local result = {}
    if not enemies then
        return result
    end
    for _, enemy in ipairs(enemies) do
        if enemy ~= hero and Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) and not NPC.IsIllusion(enemy) then
            table.insert(result, enemy)
        end
    end
    return result
end

local function find_closest_enemy(hero, search_radius)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local enemies = collect_enemies(hero, search_radius)
    local closest, best_distance = nil, math.huge
    for _, enemy in ipairs(enemies) do
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        local distance = hero_pos:Distance(enemy_pos)
        if distance < best_distance then
            best_distance = distance
            closest = enemy
        end
    end
    return closest, best_distance
end

local function find_enemy_for_ability(hero, ability, def)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local cast_range = def.cast_range_override or Ability.GetCastRange(ability)
    if not cast_range or cast_range <= 0 then
        cast_range = 600
    end
    local bonus = NPC.GetCastRangeBonus(hero) or 0
    cast_range = cast_range + bonus + 50
    local search_radius = math.max(cast_range, ui.enemy_range:Get())
    local enemies = collect_enemies(hero, search_radius)
    local best_enemy, best_distance = nil, math.huge
    for _, enemy in ipairs(enemies) do
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        local distance = hero_pos:Distance(enemy_pos)
        if distance <= cast_range and distance < best_distance then
            best_distance = distance
            best_enemy = enemy
        end
    end
    return best_enemy, best_distance
end

local function compute_escape_position(hero, enemy, distance)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local direction
    if enemy then
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        direction = hero_pos - enemy_pos
    else
        local forward = Entity.GetForwardPosition(hero, 10)
        direction = hero_pos - forward
    end
    if math.abs(direction.x) < 0.001 and math.abs(direction.y) < 0.001 then
        direction = Vector(1, 0, 0)
    end
    direction.z = 0
    local normalized = direction:Normalized()
    local target = hero_pos + normalized:Scaled(distance)
    target.z = hero_pos.z
    return target
end

local function can_cast_now(def, hero, ability, detection_enemies)
    if def.modifier and NPC.HasModifier(hero, def.modifier) then
        return false
    end
    if def.requires_charges and not item_has_charges(ability) then
        return false
    end
    if def.active_modifier and NPC.HasModifier(hero, def.active_modifier) then
        return false
    end
    if def.enemy_toggle then
        local toggle = ui.items[def.id].requires_enemy
        if toggle and toggle:Get() and (#detection_enemies == 0) then
            return false
        end
    end
    return true
end

local function build_priority_queue()
    local queue = {}
    for _, def in ipairs(ITEM_DEFINITIONS) do
        local widgets = ui.items[def.id]
        if widgets and widgets.enabled:Get() then
            table.insert(queue, {
                def = def,
                order = widgets.priority:Get(),
            })
        end
    end
    table.sort(queue, function(a, b)
        if a.order == b.order then
            return a.def.id < b.def.id
        end
        return a.order < b.order
    end)
    return queue
end
--#endregion

--#region Pending escape handling
local pending_escapes = {}

local function clear_pending(def_id)
    if def_id then
        pending_escapes[def_id] = nil
        return
    end
    for key in pairs(pending_escapes) do
        pending_escapes[key] = nil
    end
end

local function queue_force_escape(def, hero, ability, closest_enemy)
    if pending_escapes[def.id] then
        return true
    end
    if def.active_modifier and NPC.HasModifier(hero, def.active_modifier) then
        return false
    end
    local distance = def.escape_distance or 600
    local escape_position = compute_escape_position(hero, closest_enemy, distance)
    local player = Players.GetLocal()
    if player then
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            escape_position,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
            hero,
            false,
            false,
            nil,
            true
        )
    end
    local delay = (ui.escape_turn_delay:Get() or 0) / 1000
    pending_escapes[def.id] = {
        ability = ability,
        ability_index = Ability.GetIndex(ability),
        execute_time = GameRules.GetGameTime() + delay,
        threshold_widget = ui.items[def.id].threshold,
    }
    return true
end

local function process_pending_escapes(hero, detection_enemies)
    for def_id, entry in pairs(pending_escapes) do
        local def
        for _, candidate in ipairs(ITEM_DEFINITIONS) do
            if candidate.id == def_id then
                def = candidate
                break
            end
        end
        if not def then
            pending_escapes[def_id] = nil
        else
            if not entry.ability or Ability.GetOwner(entry.ability) ~= hero then
                pending_escapes[def_id] = nil
            else
                local threshold = entry.threshold_widget and entry.threshold_widget:Get() or def.threshold_default or 0
                if health_percent(hero) > threshold then
                    pending_escapes[def_id] = nil
                elseif def.enemy_toggle then
                    local toggle = ui.items[def.id].requires_enemy
                    if toggle and toggle:Get() and (#detection_enemies == 0) then
                        pending_escapes[def_id] = nil
                    end
                end
            end
        end
    end

    local current_time = GameRules.GetGameTime()
    for def_id, entry in pairs(pending_escapes) do
        local def
        for _, candidate in ipairs(ITEM_DEFINITIONS) do
            if candidate.id == def_id then
                def = candidate
                break
            end
        end
        if not def then
            pending_escapes[def_id] = nil
        else
            if current_time >= entry.execute_time then
                if NPC.IsChannellingAbility(hero) then
                    entry.execute_time = current_time + 0.05
                else
                    if ability_is_valid(hero, entry.ability) then
                        Ability.CastTarget(entry.ability, hero)
                    end
                    pending_escapes[def_id] = nil
                end
            end
        end
    end
end
--#endregion

--#region Casting logic
local function cast_meteor_combo(hero, ability, detection_enemies)
    local glimmer_def = ITEM_DEFINITIONS[1]
    local glimmer_widgets = ui.items[glimmer_def.id]
    if glimmer_widgets and glimmer_widgets.enabled:Get() then
        local glimmer = find_item(hero, glimmer_def.ability_names)
        if glimmer and ability_is_valid(hero, glimmer) and can_cast_now(glimmer_def, hero, glimmer, detection_enemies) then
            local glimmer_threshold = glimmer_widgets.threshold:Get()
            if health_percent(hero) <= glimmer_threshold then
                Ability.CastTarget(glimmer, hero)
            end
        end
    end
    local target = find_enemy_for_ability(hero, ability, { cast_range_override = 600 })
    if not target then
        return false
    end
    local hero_pos = Entity.GetAbsOrigin(hero)
    local enemy_pos = Entity.GetAbsOrigin(target)
    if hero_pos:Distance(enemy_pos) > 650 then
        return false
    end
    Ability.CastPosition(ability, enemy_pos)
    return true
end

local function cast_item(def, hero, detection_enemies)
    local ability = find_item(hero, def.ability_names)
    if not ability then
        return false
    end
    if not ability_is_valid(hero, ability) then
        return false
    end
    if not can_cast_now(def, hero, ability, detection_enemies) then
        return false
    end

    if def.cast == "target_self" then
        Ability.CastTarget(ability, hero)
        return true
    elseif def.cast == "no_target" then
        Ability.CastNoTarget(ability)
        return true
    elseif def.cast == "target_enemy" then
        local enemy = find_enemy_for_ability(hero, ability, def)
        if not enemy then
            return false
        end
        Ability.CastTarget(ability, enemy)
        return true
    elseif def.cast == "position_enemy" then
        local enemy = find_enemy_for_ability(hero, ability, def)
        if not enemy then
            return false
        end
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        Ability.CastPosition(ability, enemy_pos)
        return true
    elseif def.cast == "blink_escape" then
        local enemy = find_closest_enemy(hero, ui.enemy_range:Get())
        if not enemy then
            return false
        end
        local blink_distance = def.blink_range or 1200
        local escape_position = compute_escape_position(hero, enemy, blink_distance)
        Ability.CastPosition(ability, escape_position)
        return true
    elseif def.cast == "force_escape" then
        local enemy = find_closest_enemy(hero, ui.enemy_range:Get())
        if not enemy then
            return false
        end
        return queue_force_escape(def, hero, ability, enemy)
    elseif def.cast == "meteor_combo" then
        return cast_meteor_combo(hero, ability, detection_enemies)
    end
    return false
end
--#endregion

function auto_defender.OnUpdate()
    if not ui.enable:Get() then
        clear_pending()
        return
    end

    local hero = get_local_hero()
    if not hero then
        clear_pending()
        return
    end

    local current_health = health_percent(hero)
    local detection_enemies = collect_enemies(hero, ui.enemy_range:Get())

    process_pending_escapes(hero, detection_enemies)

    if NPC.IsChannellingAbility(hero) then
        -- allow only items that explicitly opt-in
        local queue = build_priority_queue()
        for _, item in ipairs(queue) do
            local def = item.def
            if def.allow_while_channeling then
                local widgets = ui.items[def.id]
                if widgets and current_health <= widgets.threshold:Get() then
                    cast_item(def, hero, detection_enemies)
                end
            end
        end
        return
    end

    local queue = build_priority_queue()
    for _, item in ipairs(queue) do
        local def = item.def
        local widgets = ui.items[def.id]
        if widgets then
            local threshold = widgets.threshold:Get()
            if current_health <= threshold then
                cast_item(def, hero, detection_enemies)
            end
        end
    end
end

function auto_defender.OnGameEnd()
    clear_pending()
end

return auto_defender
