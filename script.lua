---@diagnostic disable: undefined-global, lowercase-global, param-type-mismatch

local auto_defender = {}

--#region UI setup

local MAIN_FIRST_TAB = "General"
local MAIN_SECTION = "Auto Defender"

local overview_tab = Menu.Create(MAIN_FIRST_TAB, MAIN_SECTION, "Overview")
local overview_page = overview_tab:Create("Overview")

local info_group = overview_page:Create("Info")
local activation_group = overview_page:Create("Activation")
local detection_group = overview_page:Create("Enemy Detection")

info_group:Label("Author: GhostyPowa")

local function create_section_tab(second_name, third_name)
    local second_tab = Menu.Create(MAIN_FIRST_TAB, MAIN_SECTION, second_name)
    local third_tab = second_tab:Create(third_name or second_name)
    local toggles = third_tab:Create("Toggles")
    local priority = third_tab:Create("Priority")
    local thresholds = third_tab:Create("Thresholds")
    local enemy_checks = third_tab:Create("Enemy Checks")
    priority:Label("Lower priority value means the item attempts earlier")
    return {
        toggles = toggles,
        priority = priority,
        thresholds = thresholds,
        enemy = enemy_checks,
    }
end

local SECTION_LAYOUT = {
    { id = "defensive", second = "Defensive", third = "Defensive Items" },
    { id = "escape", second = "Escape", third = "Escape Tools" },
    { id = "utility", second = "Utility", third = "Utility Combos" },
    { id = "offensive", second = "Offensive", third = "Offensive Items" },
}

local section_groups = {}
for _, section in ipairs(SECTION_LAYOUT) do
    section_groups[section.id] = create_section_tab(section.second, section.third)
end

local ui = {
    enable = activation_group:Switch("Enable", true),
    escape_turn_delay = activation_group:Slider("Force/Hurricane turn delay (ms)", 0, 500, 200, "%dms"),
    enemy_range = detection_group:Slider("Enemy detection range", 200, 2000, 900, "%d"),
    items = {},
}

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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "escape",
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
        category = "escape",
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
        category = "escape",
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
        category = "escape",
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
        category = "escape",
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
        category = "escape",
    },
    {
        id = "meteor",
        display_name = "Meteor Hammer",
        icon = "panorama/images/items/meteor_hammer_png.vtex_c",
        ability_names = { "item_meteor_hammer" },
        cast = "meteor_combo",
        no_threshold = true,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 600,
        category = "utility",
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
        category = "offensive",
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
        category = "defensive",
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
        category = "defensive",
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
        category = "defensive",
    },
    {
        id = "eul",
        display_name = "Eul's Scepter of Divinity",
        icon = "panorama/images/items/cyclone_png.vtex_c",
        ability_names = { "item_cyclone" },
        cast = "eul_combo",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_eul_cyclone",
        category = "utility",
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
        category = "defensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
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
        category = "offensive",
    },
    {
        id = "wind_waker",
        display_name = "Wind Waker",
        icon = "panorama/images/items/wind_waker_png.vtex_c",
        ability_names = { "item_wind_waker" },
        cast = "eul_combo",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_wind_waker",
        category = "utility",
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
        category = "offensive",
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
        category = "offensive",
    },
}

local ITEM_BY_ID = {}
local BLINK_ITEM_IDS = { "blink", "swift_blink", "arcane_blink", "overwhelming_blink" }
--#endregion

local function apply_icon(widget, icon)
    if not widget or not icon then
        return
    end
    if widget.SetImage then
        widget:SetImage(icon)
    elseif widget.SetIcon then
        widget:SetIcon(icon)
    elseif widget.Image then
        widget:Image(icon)
    elseif widget.Icon then
        widget:Icon(icon)
    end
end

for index, def in ipairs(ITEM_DEFINITIONS) do
    ITEM_BY_ID[def.id] = def
    local section = section_groups[def.category or "defensive"] or section_groups.defensive
    local entry = {}
    entry.enabled = section.toggles:Switch(def.display_name, true)
    apply_icon(entry.enabled, def.icon)
    entry.priority = section.priority:Slider(def.display_name .. " priority", 1, #ITEM_DEFINITIONS, index, "%d")
    apply_icon(entry.priority, def.icon)
    if not def.no_threshold then
        entry.threshold = section.thresholds:Slider(def.display_name .. " threshold", 1, 100, def.threshold_default or 50, "%d%%")
        apply_icon(entry.threshold, def.icon)
    end
    if def.enemy_toggle then
        entry.requires_enemy = section.enemy:Switch(def.display_name .. " requires enemy", def.enemy_required_default or false)
        apply_icon(entry.requires_enemy, def.icon)
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

local is_channeling_ability = NPC.IsChannelingAbility or NPC.IsChannellingAbility

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
        if a.def.cast == "eul_combo" and b.def.cast == "blink_escape" then
            return true
        end
        if a.def.cast == "blink_escape" and b.def.cast == "eul_combo" then
            return false
        end
        if a.order == b.order then
            return a.def.id < b.def.id
        end
        return a.order < b.order
    end)
    return queue
end

local function has_ready_eul_combo(hero, detection_enemies, current_health)
    current_health = current_health or health_percent(hero)
    for _, def in ipairs(ITEM_DEFINITIONS) do
        if def.cast == "eul_combo" then
            local widgets = ui.items[def.id]
            if widgets and widgets.enabled:Get() then
                local threshold = widgets.threshold and widgets.threshold:Get()
                if not threshold or current_health <= threshold then
                    local ability = find_item(hero, def.ability_names)
                    if ability and ability_is_valid(hero, ability) and can_cast_now(def, hero, ability, detection_enemies) then
                        return true
                    end
                end
            end
        end
    end
    return false
end
--#endregion

--#region Pending escape handling
local pending_escapes = {}
local pending_eul_blink = nil

local function clear_pending(def_id)
    if def_id then
        pending_escapes[def_id] = nil
        if pending_eul_blink and pending_eul_blink.def and pending_eul_blink.def.id == def_id then
            pending_eul_blink = nil
        end
        return
    end
    for key in pairs(pending_escapes) do
        pending_escapes[key] = nil
    end
    pending_eul_blink = nil
end

local function find_ready_blink(hero, detection_enemies)
    local current_health = health_percent(hero)
    for _, id in ipairs(BLINK_ITEM_IDS) do
        local def = ITEM_BY_ID[id]
        if def then
            local widgets = ui.items[def.id]
            if widgets and widgets.enabled:Get() then
                local ability = find_item(hero, def.ability_names)
                if ability and ability_is_valid(hero, ability) and can_cast_now(def, hero, ability, detection_enemies) then
                    if not widgets.threshold or current_health <= widgets.threshold:Get() then
                        return def, ability
                    end
                end
            end
        end
    end
    return nil, nil
end

local function queue_blink_after_eul(eul_def, hero, detection_enemies)
    local blink_def, blink_ability = find_ready_blink(hero, detection_enemies)
    if not blink_def or not blink_ability then
        return false
    end
    local blink_distance = blink_def.blink_range or 1200
    local enemy = find_closest_enemy(hero, math.max(ui.enemy_range:Get() or 0, blink_distance))
    if not enemy then
        return false
    end
    local escape_position = compute_escape_position(hero, enemy, blink_distance)
    pending_eul_blink = {
        def = blink_def,
        ability = blink_ability,
        enemy = enemy,
        escape_position = escape_position,
        distance = blink_distance,
        wait_modifier = eul_def and eul_def.modifier or "modifier_eul_cyclone",
        expire_time = GameRules.GetGameTime() + 3.5,
    }
    return true
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
        local def = ITEM_BY_ID[def_id]
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
        local def = ITEM_BY_ID[def_id]
        if not def then
            pending_escapes[def_id] = nil
        else
            if current_time >= entry.execute_time then
                if is_channeling_ability and is_channeling_ability(hero) then
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

local function process_pending_eul_blink(hero, detection_enemies)
    if not pending_eul_blink then
        return
    end
    local entry = pending_eul_blink
    local blink_def = entry.def
    if not blink_def then
        pending_eul_blink = nil
        return
    end
    local widgets = ui.items[blink_def.id]
    if not widgets or not widgets.enabled:Get() then
        pending_eul_blink = nil
        return
    end
    local current_health = health_percent(hero)
    if widgets.threshold and current_health > widgets.threshold:Get() then
        pending_eul_blink = nil
        return
    end
    if entry.wait_modifier and NPC.HasModifier(hero, entry.wait_modifier) then
        if entry.expire_time and GameRules.GetGameTime() > entry.expire_time then
            pending_eul_blink = nil
        end
        return
    end
    if is_channeling_ability and is_channeling_ability(hero) then
        return
    end
    if not entry.ability or Ability.GetOwner(entry.ability) ~= hero then
        pending_eul_blink = nil
        return
    end
    if not ability_is_valid(hero, entry.ability) then
        pending_eul_blink = nil
        return
    end
    if not can_cast_now(blink_def, hero, entry.ability, detection_enemies) then
        pending_eul_blink = nil
        return
    end
    local enemy = entry.enemy
    if not enemy or not Entity.IsAlive(enemy) or Entity.IsDormant(enemy) or NPC.IsIllusion(enemy) then
        enemy = find_closest_enemy(hero, math.max(ui.enemy_range:Get() or 0, entry.distance or blink_def.blink_range or 1200))
    end
    local cast_position = entry.escape_position
    if enemy then
        cast_position = compute_escape_position(hero, enemy, entry.distance or blink_def.blink_range or 1200)
    end
    if not cast_position then
        pending_eul_blink = nil
        return
    end
    Ability.CastPosition(entry.ability, cast_position)
    pending_eul_blink = nil
end
--#endregion

--#region Casting logic
local function cast_eul_combo(def, hero, ability, detection_enemies)
    Ability.CastTarget(ability, hero)
    queue_blink_after_eul(def, hero, detection_enemies)
    return true
end

local function cast_meteor_combo(def, hero, ability, detection_enemies)
    local glimmer_def = ITEM_BY_ID.glimmer
    if not glimmer_def then
        return false
    end
    local glimmer_widgets = ui.items[glimmer_def.id]
    if not glimmer_widgets or not glimmer_widgets.enabled:Get() then
        return false
    end

    local glimmer_threshold = glimmer_widgets.threshold and glimmer_widgets.threshold:Get() or glimmer_def.threshold_default or 50
    if health_percent(hero) > glimmer_threshold then
        return false
    end

    local casted_glimmer = false
    local glimmer = find_item(hero, glimmer_def.ability_names)
    if glimmer and ability_is_valid(hero, glimmer) and can_cast_now(glimmer_def, hero, glimmer, detection_enemies) then
        Ability.CastTarget(glimmer, hero)
        casted_glimmer = true
    end

    if not casted_glimmer then
        if not (glimmer_def.modifier and NPC.HasModifier(hero, glimmer_def.modifier)) then
            return false
        end
    end

    local target = find_enemy_for_ability(hero, ability, def)
    if not target then
        return false
    end
    local enemy_pos = Entity.GetAbsOrigin(target)
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
        if pending_eul_blink then
            return false
        end
        local current_health = health_percent(hero)
        if has_ready_eul_combo(hero, detection_enemies, current_health) then
            return false
        end
        local search_radius = math.max(ui.enemy_range:Get() or 0, def.blink_range or 1200)
        local enemy = find_closest_enemy(hero, search_radius)
        if not enemy then
            return false
        end
        local blink_distance = def.blink_range or 1200
        local escape_position = compute_escape_position(hero, enemy, blink_distance)
        Ability.CastPosition(ability, escape_position)
        return true
    elseif def.cast == "force_escape" then
        local search_radius = math.max(ui.enemy_range:Get() or 0, def.escape_distance or 600)
        local enemy = find_closest_enemy(hero, search_radius)
        if not enemy then
            return false
        end
        return queue_force_escape(def, hero, ability, enemy)
    elseif def.cast == "eul_combo" then
        return cast_eul_combo(def, hero, ability, detection_enemies)
    elseif def.cast == "meteor_combo" then
        return cast_meteor_combo(def, hero, ability, detection_enemies)
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
    process_pending_eul_blink(hero, detection_enemies)

    if is_channeling_ability and is_channeling_ability(hero) then
        -- allow only items that explicitly opt-in
        local queue = build_priority_queue()
        for _, item in ipairs(queue) do
            local def = item.def
            if def.allow_while_channeling then
                local widgets = ui.items[def.id]
                if widgets then
                    local should_cast = true
                    if widgets.threshold then
                        should_cast = current_health <= widgets.threshold:Get()
                    end
                    if should_cast then
                        cast_item(def, hero, detection_enemies)
                    end
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
            local should_cast = true
            if widgets.threshold then
                should_cast = current_health <= widgets.threshold:Get()
            end
            if should_cast then
                cast_item(def, hero, detection_enemies)
            end
        end
    end
end

function auto_defender.OnGameEnd()
    clear_pending()
end

return auto_defender
