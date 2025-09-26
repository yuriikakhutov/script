---@diagnostic disable: undefined-global, lowercase-global, need-check-nil

local auto_defender = {}

--#region UI setup
local MAIN_FIRST_TAB = "General"
local MAIN_SECTION = "Auto Defender"

local overview_tab = Menu.Create(MAIN_FIRST_TAB, MAIN_SECTION, "Overview")
local overview_page = overview_tab:Create("Overview")

local info_group = overview_page:Create("Info")
local activation_group = overview_page:Create("Activation")
local detection_group = overview_page:Create("Enemy Detection")

if info_group.Label then
    info_group:Label("Author: GhostyPowa")
elseif info_group.Text then
    info_group:Text("Author: GhostyPowa")
else
    local author_display = info_group:Switch("Author: GhostyPowa", false)
    if author_display then
        if author_display.SetEnabled then
            author_display:SetEnabled(false)
        elseif author_display.Disable then
            author_display:Disable()
        elseif author_display.SetState then
            author_display:SetState(false)
        end
    end
end

local function create_section_tab(second_name, third_name)
    local second_tab = Menu.Create(MAIN_FIRST_TAB, MAIN_SECTION, second_name)
    local third_tab = second_tab:Create(third_name or second_name)
    local toggles = third_tab:Create("Toggles")
    local priority = third_tab:Create("Priority")
    local thresholds = third_tab:Create("Thresholds")
    local enemy_checks = third_tab:Create("Enemy Checks")
    if priority.Label then
        priority:Label("Lower value means higher priority")
    end
    return {
        toggles = toggles,
        priority = priority,
        thresholds = thresholds,
        enemy = enemy_checks,
    }
end

local section_groups = {
    defensive = create_section_tab("Defensive", "Defensive Items"),
    escape = create_section_tab("Escape", "Escape Tools"),
    utility = create_section_tab("Utility", "Utility Combos"),
    offensive = create_section_tab("Offensive", "Offensive Items"),
}

local ui = {
    enable = activation_group:Switch("Enable", true),
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
        cast = "no_target",
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
        id = "crimson",
        display_name = "Crimson Guard",
        icon = "panorama/images/items/crimson_guard_png.vtex_c",
        ability_names = { "item_crimson_guard" },
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_crimson_guard_extra",
        category = "defensive",
    },
    {
        id = "blade_mail",
        display_name = "Blade Mail",
        icon = "panorama/images/items/blade_mail_png.vtex_c",
        ability_names = { "item_blade_mail" },
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_blade_mail_reflect",
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
        modifier = "modifier_item_solar_crest_armor_addition",
        category = "defensive",
    },
    {
        id = "drums",
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
        id = "boots_of_bearing",
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
        id = "disperser",
        display_name = "Disperser",
        icon = "panorama/images/items/disperser_png.vtex_c",
        ability_names = { "item_disperser" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_disperser_active",
        category = "defensive",
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
        id = "urn",
        display_name = "Urn of Shadows",
        icon = "panorama/images/items/urn_of_shadows_png.vtex_c",
        ability_names = { "item_urn_of_shadows" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_charges = true,
        modifier = "modifier_item_urn_heal",
        category = "defensive",
    },
    {
        id = "spirit_vessel",
        display_name = "Spirit Vessel",
        icon = "panorama/images/items/spirit_vessel_png.vtex_c",
        ability_names = { "item_spirit_vessel" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_charges = true,
        modifier = "modifier_item_spirit_vessel_heal",
        category = "defensive",
    },
    {
        id = "eul",
        display_name = "Eul's Scepter",
        icon = "panorama/images/items/cyclone_png.vtex_c",
        ability_names = { "item_cyclone" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_eul_cyclone",
        category = "utility",
    },
    {
        id = "wind_waker",
        display_name = "Wind Waker",
        icon = "panorama/images/items/wind_waker_png.vtex_c",
        ability_names = { "item_wind_waker" },
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_wind_waker",
        category = "utility",
    },
    {
        id = "meteor",
        display_name = "Meteor Hammer",
        icon = "panorama/images/items/meteor_hammer_png.vtex_c",
        ability_names = { "item_meteor_hammer" },
        cast = "meteor_combo",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 600,
        category = "utility",
    },
    {
        id = "force",
        display_name = "Force Staff",
        icon = "panorama/images/items/force_staff_png.vtex_c",
        ability_names = { "item_force_staff" },
        cast = "escape_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 800,
        category = "escape",
    },
    {
        id = "hurricane",
        display_name = "Hurricane Pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        ability_names = { "item_hurricane_pike" },
        cast = "escape_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 800,
        category = "escape",
    },
    {
        id = "blink",
        display_name = "Blink Dagger",
        icon = "panorama/images/items/blink_png.vtex_c",
        ability_names = { "item_blink" },
        cast = "escape_position",
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
        cast = "escape_position",
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
        cast = "escape_position",
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
        cast = "escape_position",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
        category = "escape",
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
        id = "dagon",
        display_name = "Dagon",
        icon = "panorama/images/items/dagon_png.vtex_c",
        ability_names = {
            "item_dagon",
            "item_dagon_2",
            "item_dagon_3",
            "item_dagon_4",
            "item_dagon_5",
        },
        cast = "target_enemy",
        threshold_default = 60,
        enemy_toggle = true,
        enemy_required_default = true,
        cast_range_override = 800,
        category = "offensive",
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
        id = "silver",
        display_name = "Silver Edge",
        icon = "panorama/images/items/silver_edge_png.vtex_c",
        ability_names = { "item_silver_edge" },
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        requires_enemy = true,
        cast_range_override = 1200,
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
        requires_enemy = true,
        cast_range_override = 1200,
        category = "offensive",
    },
}

local ITEM_BY_ID = {}
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
local CAST_COOLDOWN = 0.2
local last_cast_times = {}

local CONTROL_BLOCKERS = {
    Enum.ModifierState.MODIFIER_STATE_STUNNED,
    Enum.ModifierState.MODIFIER_STATE_HEXED,
    Enum.ModifierState.MODIFIER_STATE_MUTED,
}

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
    if not max_health or max_health <= 0 then
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

local function can_use_item(hero)
    if not hero then
        return false
    end
    for _, state in ipairs(CONTROL_BLOCKERS) do
        if NPC.HasState(hero, state) then
            return false
        end
    end
    return true
end

local function collect_enemies(hero, radius)
    local enemies = {}
    local raw = Entity.GetHeroesInRadius(hero, radius, Enum.TeamType.TEAM_ENEMY, true, true)
    if raw then
        for _, enemy in ipairs(raw) do
            if enemy ~= hero and Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) and not NPC.IsIllusion(enemy) then
                table.insert(enemies, enemy)
            end
        end
    end
    return enemies
end

local function flat_distance(a, b)
    if not a or not b then
        return math.huge
    end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function find_closest_enemy(hero, radius)
    local enemies = collect_enemies(hero, radius)
    if #enemies == 0 then
        return nil
    end
    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil
    end
    local closest = nil
    local best_distance = math.huge
    for _, enemy in ipairs(enemies) do
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        local distance = flat_distance(hero_pos, enemy_pos)
        if distance < best_distance then
            best_distance = distance
            closest = enemy
        end
    end
    return closest
end

local function get_effective_cast_range(hero, ability, def)
    local range = 0
    if ability then
        range = Ability.GetCastRange(ability) or 0
    end
    range = math.max(range, def.cast_range_override or 0)
    local bonus = NPC.GetCastRangeBonus(hero) or 0
    range = range + bonus
    if range <= 0 then
        range = ui.enemy_range:Get()
    end
    return range
end

local function find_enemy_target(hero, ability, def)
    local range = get_effective_cast_range(hero, ability, def)
    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil
    end
    local enemies = collect_enemies(hero, range)
    local closest
    local best_distance = math.huge
    for _, enemy in ipairs(enemies) do
        if not def.enemy_modifier or not NPC.HasModifier(enemy, def.enemy_modifier) then
            local enemy_pos = Entity.GetAbsOrigin(enemy)
            local distance = flat_distance(hero_pos, enemy_pos)
            if distance < best_distance then
                best_distance = distance
                closest = enemy
            end
        end
    end
    return closest
end

local function normalize_flat_vector(vec)
    if not vec then
        return nil
    end
    vec.z = 0
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y)
    if length <= 0 then
        return nil
    end
    return Vector(vec.x / length, vec.y / length, 0)
end

local function compute_escape_position(hero, distance)
    local enemy = find_closest_enemy(hero, ui.enemy_range:Get())
    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil
    end
    local direction
    if enemy then
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        if enemy_pos then
            direction = Vector(hero_pos.x - enemy_pos.x, hero_pos.y - enemy_pos.y, 0)
        end
    end
    direction = normalize_flat_vector(direction or Vector(1, 0, 0))
    if not direction then
        return nil
    end
    local target = Vector(hero_pos.x + direction.x * distance, hero_pos.y + direction.y * distance, hero_pos.z)
    return target
end

local function can_cast_now(def, hero, ability, detection_enemies)
    if not can_use_item(hero) then
        return false
    end
    if def.modifier and NPC.HasModifier(hero, def.modifier) then
        return false
    end
    if def.requires_charges and not item_has_charges(ability) then
        return false
    end
    if def.enemy_toggle then
        local toggle = ui.items[def.id].requires_enemy
        if toggle and toggle.Get and toggle:Get() and (#detection_enemies == 0) then
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

--#region Casting helpers
local function cast_meteor_combo(def, hero, ability, detection_enemies, current_health)
    if #detection_enemies == 0 then
        return false
    end
    local glimmer_def = ITEM_BY_ID.glimmer
    if glimmer_def then
        local glimmer_widgets = ui.items[glimmer_def.id]
        if glimmer_widgets and glimmer_widgets.enabled:Get() then
            local glimmer_threshold = glimmer_widgets.threshold and glimmer_widgets.threshold:Get() or glimmer_def.threshold_default or 50
            if current_health <= glimmer_threshold then
                local glimmer = find_item(hero, glimmer_def.ability_names)
                if glimmer and ability_is_valid(hero, glimmer) and can_cast_now(glimmer_def, hero, glimmer, detection_enemies) then
                    if not is_recently_cast(glimmer_def.id, GameRules.GetGameTime()) then
                        Ability.CastTarget(glimmer, hero)
                        mark_cast(glimmer_def.id, GameRules.GetGameTime())
                    end
                end
            end
        end
    end
    local target = find_enemy_target(hero, ability, def)
    if not target then
        return false
    end
    local enemy_pos = Entity.GetAbsOrigin(target)
    if not enemy_pos then
        return false
    end
    Ability.CastPosition(ability, enemy_pos)
    return true
end

local function cast_item(def, hero, detection_enemies, current_health)
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
    elseif def.cast == "no_target" then
        Ability.CastNoTarget(ability)
    elseif def.cast == "target_enemy" then
        local target = find_enemy_target(hero, ability, def)
        if not target then
            return false
        end
        Ability.CastTarget(ability, target)
    elseif def.cast == "position_enemy" then
        local target = find_enemy_target(hero, ability, def)
        if not target then
            return false
        end
        local enemy_pos = Entity.GetAbsOrigin(target)
        if not enemy_pos then
            return false
        end
        Ability.CastPosition(ability, enemy_pos)
    elseif def.cast == "escape_self" then
        local escape_position = compute_escape_position(hero, 600)
        if not escape_position then
            return false
        end
        Ability.CastTarget(ability, hero)
    elseif def.cast == "escape_position" then
        local blink_distance = def.blink_range or 1200
        local target_pos = compute_escape_position(hero, blink_distance)
        if not target_pos then
            return false
        end
        Ability.CastPosition(ability, target_pos)
    elseif def.cast == "meteor_combo" then
        return cast_meteor_combo(def, hero, ability, detection_enemies, current_health)
    else
        return false
    end
    return true
end
--#endregion

function auto_defender.OnUpdate()
    if not ui.enable:Get() then
        return
    end

    if not Engine.IsInGame() then
        last_cast_times = {}
        return
    end

    local hero = get_local_hero()
    if not hero then
        return
    end

    if NPC.IsChannelingAbility(hero) then
        return
    end

    local current_health = health_percent(hero)
    local detection_enemies = collect_enemies(hero, ui.enemy_range:Get())
    local game_time = GameRules.GetGameTime()

    local queue = build_priority_queue()
    for _, item in ipairs(queue) do
        local def = item.def
        local widgets = ui.items[def.id]
        if widgets then
            local should_cast = true
            if widgets.threshold and current_health > widgets.threshold:Get() then
                should_cast = false
            end
            if should_cast and not is_recently_cast(def.id, game_time) then
                if cast_item(def, hero, detection_enemies, current_health) then
                    mark_cast(def.id, game_time)
                end
            end
        end
    end
end

function auto_defender.OnGameEnd()
    last_cast_times = {}
end

return auto_defender
