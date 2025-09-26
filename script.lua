---@diagnostic disable: undefined-global, lowercase-global, need-check-nil

local auto_defender = {}

local tab = Menu.Create("General", "Auto Defender", "Auto Defender", "Auto Defender")
local info_group = tab:Create("Info", 0)
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
        type = "target_self",
        modifier = "modifier_item_glimmer_cape_fade",
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
    lotus = {
        item_name = "item_lotus_orb",
        icon = "panorama/images/items/lotus_orb_png.vtex_c",
        display_name = "Lotus Orb",
        type = "target_self",
        modifier = "modifier_item_lotus_orb_active",
    },
    crimson = {
        item_name = "item_crimson_guard",
        icon = "panorama/images/items/crimson_guard_png.vtex_c",
        display_name = "Crimson Guard",
        type = "no_target",
        modifier = "modifier_item_crimson_guard_extra",
    },
    blade_mail = {
        item_name = "item_blade_mail",
        icon = "panorama/images/items/blade_mail_png.vtex_c",
        display_name = "Blade Mail",
        type = "no_target",
        modifier = "modifier_item_blade_mail_reflect",
    },
    eul = {
        item_name = "item_cyclone",
        icon = "panorama/images/items/cyclone_png.vtex_c",
        display_name = "Eul's Scepter",
        type = "target_self",
        modifier = "modifier_eul_cyclone",
    },
    wind_waker = {
        item_name = "item_wind_waker",
        icon = "panorama/images/items/wind_waker_png.vtex_c",
        display_name = "Wind Waker",
        type = "target_self",
        modifier = "modifier_wind_waker_cyclone",
    },
    force = {
        item_name = "item_force_staff",
        icon = "panorama/images/items/force_staff_png.vtex_c",
        display_name = "Force Staff",
        type = "escape_self",
        modifier = "modifier_item_forcestaff_active",
        search_range = 1600,
    },
    hurricane = {
        item_name = "item_hurricane_pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        display_name = "Hurricane Pike",
        type = "escape_self",
        modifier = "modifier_item_hurricane_pike_active",
        search_range = 1600,
    },
    atos = {
        item_name = "item_rod_of_atos",
        icon = "panorama/images/items/rod_of_atos_png.vtex_c",
        display_name = "Rod of Atos",
        type = "target_enemy",
        enemy_modifier = "modifier_rod_of_atos_debuff",
        range = 1100,
    },
    hex = {
        item_name = "item_sheepstick",
        icon = "panorama/images/items/sheepstick_png.vtex_c",
        display_name = "Scythe of Vyse",
        type = "target_enemy",
        enemy_modifier = "modifier_sheepstick_debuff",
        range = 800,
    },
    abyssal = {
        item_name = "item_abyssal_blade",
        icon = "panorama/images/items/abyssal_blade_png.vtex_c",
        display_name = "Abyssal Blade",
        type = "target_enemy",
        enemy_modifier = "modifier_abyssal_blade_debuff",
        range = 600,
    },
    diffusal = {
        item_name = "item_diffusal_blade",
        icon = "panorama/images/items/diffusal_blade_png.vtex_c",
        display_name = "Diffusal Blade",
        type = "target_enemy",
        enemy_modifier = "modifier_item_diffusal_blade_slow",
        range = 600,
    },
    gleipnir = {
        item_name = "item_gleipnir",
        icon = "panorama/images/items/gleipnir_png.vtex_c",
        display_name = "Gleipnir",
        type = "position_enemy",
        enemy_modifier = "modifier_gleipnir_root",
        range = 1100,
    },
    bloodthorn = {
        item_name = "item_bloodthorn",
        icon = "panorama/images/items/bloodthorn_png.vtex_c",
        display_name = "Bloodthorn",
        type = "target_enemy",
        enemy_modifier = "modifier_bloodthorn_debuff",
        range = 900,
    },
    silver = {
        item_name = "item_silver_edge",
        icon = "panorama/images/items/silver_edge_png.vtex_c",
        display_name = "Silver Edge",
        type = "no_target",
        modifier = "modifier_item_silver_edge_windwalk",
        requires_enemy = true,
        search_range = 1200,
    },
    shadow_blade = {
        item_name = "item_invis_sword",
        icon = "panorama/images/items/invis_sword_png.vtex_c",
        display_name = "Shadow Blade",
        type = "no_target",
        modifier = "modifier_item_invis_sword_windwalk",
        requires_enemy = true,
        search_range = 1200,
    },
    disperser = {
        item_name = "item_disperser",
        icon = "panorama/images/items/disperser_png.vtex_c",
        display_name = "Disperser",
        type = "target_self",
        modifier = "modifier_item_disperser_active",
    },
    pipe = {
        item_name = "item_pipe",
        icon = "panorama/images/items/pipe_png.vtex_c",
        display_name = "Pipe of Insight",
        type = "no_target",
        modifier = "modifier_item_pipe_barrier",
    },
    ethereal = {
        item_name = "item_ethereal_blade",
        icon = "panorama/images/items/ethereal_blade_png.vtex_c",
        display_name = "Ethereal Blade",
        type = "target_self",
        modifier = "modifier_item_ethereal_blade_ethereal",
    },
    nullifier = {
        item_name = "item_nullifier",
        icon = "panorama/images/items/nullifier_png.vtex_c",
        display_name = "Nullifier",
        type = "target_enemy",
        enemy_modifier = "modifier_item_nullifier_mute",
        range = 900,
    },
    dagon = {
        item_names = {
            "item_dagon",
            "item_dagon_2",
            "item_dagon_3",
            "item_dagon_4",
            "item_dagon_5",
        },
        icon = "panorama/images/items/dagon_png.vtex_c",
        display_name = "Dagon",
        type = "target_enemy",
        range = 900,
    },
    blood_grenade = {
        item_name = "item_blood_grenade",
        icon = "panorama/images/items/blood_grenade_png.vtex_c",
        display_name = "Blood Grenade",
        type = "position_enemy",
        enemy_modifier = "modifier_item_blood_grenade_slow",
        range = 900,
        requires_charges = true,
    },
    halberd = {
        item_name = "item_heavens_halberd",
        icon = "panorama/images/items/heavens_halberd_png.vtex_c",
        display_name = "Heaven's Halberd",
        type = "target_enemy",
        enemy_modifier = "modifier_heavens_halberd_debuff",
        range = 600,
    },
    urn = {
        item_name = "item_urn_of_shadows",
        icon = "panorama/images/items/urn_of_shadows_png.vtex_c",
        display_name = "Urn of Shadows",
        type = "target_self",
        modifier = "modifier_item_urn_heal",
        requires_charges = true,
    },
    spirit_vessel = {
        item_name = "item_spirit_vessel",
        icon = "panorama/images/items/spirit_vessel_png.vtex_c",
        display_name = "Spirit Vessel",
        type = "target_self",
        modifier = "modifier_item_spirit_vessel_heal",
        requires_charges = true,
    },
    blink = {
        item_name = "item_blink",
        icon = "panorama/images/items/blink_png.vtex_c",
        display_name = "Blink Dagger",
        type = "escape_position",
        range = 1200,
        escape_distance = 1150,
    },
    overwhelming_blink = {
        item_name = "item_overwhelming_blink",
        icon = "panorama/images/items/overwhelming_blink_png.vtex_c",
        display_name = "Overwhelming Blink",
        type = "escape_position",
        range = 1200,
        escape_distance = 1150,
    },
    swift_blink = {
        item_name = "item_swift_blink",
        icon = "panorama/images/items/swift_blink_png.vtex_c",
        display_name = "Swift Blink",
        type = "escape_position",
        range = 1200,
        escape_distance = 1150,
    },
    arcane_blink = {
        item_name = "item_arcane_blink",
        icon = "panorama/images/items/arcane_blink_png.vtex_c",
        display_name = "Arcane Blink",
        type = "escape_position",
        range = 1200,
        escape_distance = 1150,
    },
    solar_crest = {
        item_name = "item_solar_crest",
        icon = "panorama/images/items/solar_crest_png.vtex_c",
        display_name = "Solar Crest",
        type = "target_self",
        modifier = "modifier_item_solar_crest_armor_addition",
    },
    drums = {
        item_name = "item_ancient_janggo",
        icon = "panorama/images/items/ancient_janggo_png.vtex_c",
        display_name = "Drum of Endurance",
        type = "no_target",
        modifier = "modifier_item_ancient_janggo_active",
    },
    boots_of_bearing = {
        item_name = "item_boots_of_bearing",
        icon = "panorama/images/items/boots_of_bearing_png.vtex_c",
        display_name = "Boots of Bearing",
        type = "no_target",
        modifier = "modifier_item_boots_of_bearing_active",
    },
}

local priority_items = {
    { "glimmer", ITEM_DEFINITIONS.glimmer.icon, true },
    { "ghost", ITEM_DEFINITIONS.ghost.icon, true },
    { "bkb", ITEM_DEFINITIONS.bkb.icon, true },
    { "lotus", ITEM_DEFINITIONS.lotus.icon, false },
    { "crimson", ITEM_DEFINITIONS.crimson.icon, false },
    { "blade_mail", ITEM_DEFINITIONS.blade_mail.icon, false },
    { "eul", ITEM_DEFINITIONS.eul.icon, false },
    { "wind_waker", ITEM_DEFINITIONS.wind_waker.icon, false },
    { "force", ITEM_DEFINITIONS.force.icon, false },
    { "hurricane", ITEM_DEFINITIONS.hurricane.icon, false },
    { "disperser", ITEM_DEFINITIONS.disperser.icon, false },
    { "pipe", ITEM_DEFINITIONS.pipe.icon, false },
    { "ethereal", ITEM_DEFINITIONS.ethereal.icon, false },
    { "nullifier", ITEM_DEFINITIONS.nullifier.icon, false },
    { "dagon", ITEM_DEFINITIONS.dagon.icon, false },
    { "blood_grenade", ITEM_DEFINITIONS.blood_grenade.icon, false },
    { "halberd", ITEM_DEFINITIONS.halberd.icon, false },
    { "urn", ITEM_DEFINITIONS.urn.icon, false },
    { "spirit_vessel", ITEM_DEFINITIONS.spirit_vessel.icon, false },
    { "blink", ITEM_DEFINITIONS.blink.icon, false },
    { "overwhelming_blink", ITEM_DEFINITIONS.overwhelming_blink.icon, false },
    { "swift_blink", ITEM_DEFINITIONS.swift_blink.icon, false },
    { "arcane_blink", ITEM_DEFINITIONS.arcane_blink.icon, false },
    { "solar_crest", ITEM_DEFINITIONS.solar_crest.icon, false },
    { "drums", ITEM_DEFINITIONS.drums.icon, false },
    { "boots_of_bearing", ITEM_DEFINITIONS.boots_of_bearing.icon, false },
    { "atos", ITEM_DEFINITIONS.atos.icon, false },
    { "hex", ITEM_DEFINITIONS.hex.icon, false },
    { "abyssal", ITEM_DEFINITIONS.abyssal.icon, false },
    { "bloodthorn", ITEM_DEFINITIONS.bloodthorn.icon, false },
    { "diffusal", ITEM_DEFINITIONS.diffusal.icon, false },
    { "gleipnir", ITEM_DEFINITIONS.gleipnir.icon, false },
    { "silver", ITEM_DEFINITIONS.silver.icon, false },
    { "shadow_blade", ITEM_DEFINITIONS.shadow_blade.icon, false },
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

local DEFAULT_SEARCH_RANGE = 1200

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

local function get_inventory_item(hero, definition)
    if definition.item_name then
        return NPC.GetItem(hero, definition.item_name, true)
    end

    if definition.item_names then
        for _, name in ipairs(definition.item_names) do
            local item = NPC.GetItem(hero, name, true)
            if item then
                return item
            end
        end
    end

    return nil
end

local function get_effective_cast_range(hero, ability, definition)
    local range = Ability.GetCastRange(ability)
    if not range or range < 0 then
        range = 0
    end

    local bonus = NPC.GetCastRangeBonus(hero)
    if bonus and bonus > 0 then
        range = range + bonus
    end

    if definition and definition.range then
        range = math.max(range, definition.range)
    end

    if range <= 0 then
        range = definition and definition.search_range or DEFAULT_SEARCH_RANGE
    end

    return range
end

local function find_enemy_target(hero, ability, definition)
    local range = get_effective_cast_range(hero, ability, definition)
    if range <= 0 then
        return nil
    end

    local enemies = Entity.GetHeroesInRadius(hero, range, Enum.TeamType.TEAM_ENEMY, true, true)
    if not enemies or #enemies == 0 then
        return nil
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil
    end

    local closest_enemy
    local closest_distance = math.huge

    for _, enemy in ipairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
            if not definition.enemy_modifier or not NPC.HasModifier(enemy, definition.enemy_modifier) then
                local enemy_pos = Entity.GetAbsOrigin(enemy)
                if enemy_pos then
                    local distance = hero_pos:Distance2D(enemy_pos)
                    if distance < closest_distance then
                        closest_distance = distance
                        closest_enemy = enemy
                    end
                end
            end
        end
    end

    return closest_enemy
end

local function find_closest_enemy(hero, range)
    if range <= 0 then
        return nil
    end

    local enemies = Entity.GetHeroesInRadius(hero, range, Enum.TeamType.TEAM_ENEMY, true, true)
    if not enemies or #enemies == 0 then
        return nil
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil
    end

    local closest_enemy
    local closest_distance = math.huge

    for _, enemy in ipairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
            local enemy_pos = Entity.GetAbsOrigin(enemy)
            if enemy_pos then
                local distance = hero_pos:Distance2D(enemy_pos)
                if distance < closest_distance then
                    closest_distance = distance
                    closest_enemy = enemy
                end
            end
        end
    end

    return closest_enemy
end

local function normalize_flat_vector(vector)
    if not vector then
        return nil
    end

    local length = vector:Length2D()
    if length <= 0 then
        return nil
    end

    vector.x = vector.x / length
    vector.y = vector.y / length
    vector.z = 0

    return vector
end

local function face_direction(hero, direction)
    if not hero or not direction then
        return
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return
    end

    if not Players or not Player or not Player.PrepareUnitOrders or not Players.GetLocal then
        return
    end

    local player = Players.GetLocal()
    if not player then
        return
    end

    local move_target = hero_pos + direction * 50
    move_target.z = hero_pos.z
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        move_target,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero,
        false,
        false
    )
end

local function get_escape_direction(hero, ability, definition)
    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil, nil
    end

    local search_range = definition and definition.search_range or DEFAULT_SEARCH_RANGE
    if ability then
        search_range = math.max(search_range, get_effective_cast_range(hero, ability, definition))
    end

    local enemy = find_closest_enemy(hero, search_range)
    if not enemy then
        return nil, nil
    end

    local enemy_pos = Entity.GetAbsOrigin(enemy)
    if not enemy_pos then
        return nil, nil
    end

    local direction = hero_pos - enemy_pos
    direction = normalize_flat_vector(direction)

    if not direction then
        return nil, nil
    end

    return direction, enemy
end

local ESCAPE_TURN_DELAY = 0.2
local pending_escape_casts = {}
local escape_input_blockers = {}
local escape_input_blocked = false

local function apply_input_block_state(blocked)
    if blocked == escape_input_blocked then
        return
    end

    if Input then
        if Input.BlockInput then
            Input.BlockInput(blocked)
        end

        local enable_state = not blocked

        if Input.SetInputEnabled then
            Input.SetInputEnabled(enable_state)
        end

        if Input.SetEnabled then
            Input.SetEnabled(enable_state)
        end

        if Input.SetGameInputEnabled then
            Input.SetGameInputEnabled(enable_state)
        end
    end

    if Engine then
        if Engine.BlockInput then
            Engine.BlockInput(blocked)
        end

        local enable_state = not blocked

        if Engine.SetInputEnabled then
            Engine.SetInputEnabled(enable_state)
        end

        if Engine.SetGameInputEnabled then
            Engine.SetGameInputEnabled(enable_state)
        end
    end

    escape_input_blocked = blocked
end

local function refresh_escape_input_block()
    for _, active in pairs(escape_input_blockers) do
        if active then
            apply_input_block_state(true)
            return
        end
    end

    apply_input_block_state(false)
end

local function set_escape_input_block(item_key, enabled)
    if enabled then
        escape_input_blockers[item_key] = true
    else
        escape_input_blockers[item_key] = nil
    end

    refresh_escape_input_block()
end

local function clear_pending_escape(item_key)
    pending_escape_casts[item_key] = nil
    set_escape_input_block(item_key, false)
end

local function reset_escape_states()
    pending_escape_casts = {}
    escape_input_blockers = {}
    apply_input_block_state(false)
end

local function needs_new_escape(direction, enemy, pending)
    if not pending then
        return true
    end

    if pending.enemy ~= enemy then
        return true
    end

    local pending_dir = pending.direction
    if not pending_dir or not direction then
        return true
    end

    local dot = pending_dir.x * direction.x + pending_dir.y * direction.y
    if dot < 0.95 then
        return true
    end

    return false
end

local function cast_item(hero, item_key, game_time)
    local definition = ITEM_DEFINITIONS[item_key]
    if not definition then
        return false
    end

    local is_escape_item = definition.type == "escape_self"

    if is_recently_cast(item_key, game_time) then
        if is_escape_item then
            clear_pending_escape(item_key)
        end
        return false
    end

    local item = get_inventory_item(hero, definition)
    if not item then
        if is_escape_item then
            clear_pending_escape(item_key)
        end
        return false
    end

    if definition.modifier and NPC.HasModifier(hero, definition.modifier) then
        if is_escape_item then
            clear_pending_escape(item_key)
        end
        return false
    end

    if not Ability.IsReady(item) then
        if is_escape_item then
            clear_pending_escape(item_key)
        end
        return false
    end

    if definition.requires_charges then
        local charges = Ability.GetCurrentCharges(item)
        if not charges or charges <= 0 then
            if is_escape_item then
                clear_pending_escape(item_key)
            end
            return false
        end
    end

    local mana = NPC.GetMana(hero)
    if not Ability.IsCastable(item, mana) then
        if is_escape_item then
            clear_pending_escape(item_key)
        end
        return false
    end

    if not can_use_item(hero) then
        if is_escape_item then
            clear_pending_escape(item_key)
        end
        return false
    end

    if definition.requires_enemy then
        local range = get_effective_cast_range(hero, item, definition)
        local enemies = Entity.GetHeroesInRadius(hero, range, Enum.TeamType.TEAM_ENEMY, true, true)
        if not enemies or #enemies == 0 then
            if is_escape_item then
                clear_pending_escape(item_key)
            end
            return false
        end
    end

    if definition.type == "no_target" then
        Ability.CastNoTarget(item)
    elseif definition.type == "target_self" then
        Ability.CastTarget(item, hero)
    elseif definition.type == "target_enemy" then
        local target = find_enemy_target(hero, item, definition)
        if not target then
            return false
        end

        Ability.CastTarget(item, target)
    elseif definition.type == "position_enemy" then
        local target = find_enemy_target(hero, item, definition)
        if not target then
            return false
        end

        local target_pos = Entity.GetAbsOrigin(target)
        if not target_pos then
            return false
        end

        Ability.CastPosition(item, target_pos)
    elseif definition.type == "escape_self" then
        local direction, enemy = get_escape_direction(hero, item, definition)
        if not direction then
            clear_pending_escape(item_key)
            return false
        end

        local pending = pending_escape_casts[item_key]

        if needs_new_escape(direction, enemy, pending) then
            pending_escape_casts[item_key] = {
                ready_time = game_time + ESCAPE_TURN_DELAY,
                direction = direction,
                enemy = enemy,
            }
            set_escape_input_block(item_key, true)
            face_direction(hero, direction)
            return false
        end

        pending.direction = direction

        if game_time < pending.ready_time then
            face_direction(hero, pending.direction)
            return false
        end

        face_direction(hero, pending.direction)
        Ability.CastTarget(item, hero)
        clear_pending_escape(item_key)
    elseif definition.type == "escape_position" then
        local direction = get_escape_direction(hero, item, definition)
        if not direction then
            return false
        end

        local hero_pos = Entity.GetAbsOrigin(hero)
        if not hero_pos then
            return false
        end

        local distance = definition.escape_distance or get_effective_cast_range(hero, item, definition)
        if distance <= 0 then
            distance = 1150
        end

        local cast_position = hero_pos + direction * distance
        cast_position.z = hero_pos.z

        Ability.CastPosition(item, cast_position)
    else
        return false
    end

    mark_cast(item_key, game_time)

    return true
end

function auto_defender.OnUpdate()
    if not Engine.IsInGame() then
        last_cast_times = {}
        reset_escape_states()
        return
    end

    if not ui.enable:Get() then
        reset_escape_states()
        return
    end

    local hero = Heroes.GetLocal()
    if not hero or NPC.IsIllusion(hero) or not Entity.IsAlive(hero) or Entity.IsDormant(hero) then
        reset_escape_states()
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
        reset_escape_states()
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
    reset_escape_states()
end

function auto_defender.OnScriptUnload()
    reset_escape_states()
end

return auto_defender
