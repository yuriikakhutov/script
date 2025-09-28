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
local enemy_range_group = tab:Create("Enemy Range", 3)

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
        requires_enemy = true,
        search_range = 1200,
    },
    bkb = {
        item_name = "item_black_king_bar",
        icon = "panorama/images/items/black_king_bar_png.vtex_c",
        display_name = "Black King Bar",
        type = "no_target",
        modifier = "modifier_black_king_bar_immune",
        requires_enemy = true,
        search_range = 1200,
    },
    lotus = {
        item_name = "item_lotus_orb",
        icon = "panorama/images/items/lotus_orb_png.vtex_c",
        display_name = "Lotus Orb",
        type = "target_self",
        modifier = "modifier_item_lotus_orb_active",
        requires_enemy = true,
        search_range = 1200,
    },
    crimson = {
        item_name = "item_crimson_guard",
        icon = "panorama/images/items/crimson_guard_png.vtex_c",
        display_name = "Crimson Guard",
        type = "no_target",
        modifier = "modifier_item_crimson_guard_extra",
        requires_enemy = true,
        search_range = 1200,
    },
    blade_mail = {
        item_name = "item_blade_mail",
        icon = "panorama/images/items/blade_mail_png.vtex_c",
        display_name = "Blade Mail",
        type = "no_target",
        modifier = "modifier_item_blade_mail_reflect",
    },
    mjollnir = {
        item_name = "item_mjollnir",
        icon = "panorama/images/items/mjollnir_png.vtex_c",
        display_name = "Mjollnir",
        type = "no_target",
        modifier = "modifier_item_mjollnir_shield",
    },
    eul = {
        item_name = "item_cyclone",
        icon = "panorama/images/items/cyclone_png.vtex_c",
        display_name = "Eul's Scepter",
        type = "target_self",
        modifier = "modifier_eul_cyclone",
        requires_enemy = true,
        search_range = 1200,
    },
    wind_waker = {
        item_name = "item_wind_waker",
        icon = "panorama/images/items/wind_waker_png.vtex_c",
        display_name = "Wind Waker",
        type = "target_self",
        modifier = "modifier_wind_waker_cyclone",
        requires_enemy = true,
        search_range = 1200,
    },
    force = {
        item_name = "item_force_staff",
        icon = "panorama/images/items/force_staff_png.vtex_c",
        display_name = "Force Staff",
        type = "escape_self",
        modifier = "modifier_item_forcestaff_active",
        search_range = 1600,
        requires_facing = true,
    },
    hurricane = {
        item_name = "item_hurricane_pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        display_name = "Hurricane Pike",
        type = "escape_self",
        modifier = "modifier_item_hurricane_pike_active",
        search_range = 1600,
        requires_facing = true,
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
    orchid = {
        item_name = "item_orchid",
        icon = "panorama/images/items/orchid_png.vtex_c",
        display_name = "Orchid Malevolence",
        type = "target_enemy",
        enemy_modifier = "modifier_orchid_malevolence_debuff",
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
        requires_enemy = true,
        search_range = 1200,
    },
    ethereal = {
        item_name = "item_ethereal_blade",
        icon = "panorama/images/items/ethereal_blade_png.vtex_c",
        display_name = "Ethereal Blade",
        type = "target_self",
        modifier = "modifier_item_ethereal_blade_ethereal",
        requires_enemy = true,
        search_range = 1200,
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
        requires_enemy = true,
        search_range = 1200,
    },
    pavise = {
        item_name = "item_pavise",
        icon = "panorama/images/items/pavise_png.vtex_c",
        display_name = "Pavise",
        type = "target_self",
        modifier = "modifier_item_pavise_barrier",
        requires_enemy = true,
        search_range = 1200,
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
        requires_enemy = true,
        search_range = 1200,
    },
}

local priority_items = {
    { "glimmer", ITEM_DEFINITIONS.glimmer.icon, true },
    { "ghost", ITEM_DEFINITIONS.ghost.icon, true },
    { "bkb", ITEM_DEFINITIONS.bkb.icon, true },
    { "lotus", ITEM_DEFINITIONS.lotus.icon, false },
    { "crimson", ITEM_DEFINITIONS.crimson.icon, false },
    { "blade_mail", ITEM_DEFINITIONS.blade_mail.icon, false },
    { "mjollnir", ITEM_DEFINITIONS.mjollnir.icon, false },
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
    { "pavise", ITEM_DEFINITIONS.pavise.icon, false },
    { "drums", ITEM_DEFINITIONS.drums.icon, false },
    { "boots_of_bearing", ITEM_DEFINITIONS.boots_of_bearing.icon, false },
    { "atos", ITEM_DEFINITIONS.atos.icon, false },
    { "hex", ITEM_DEFINITIONS.hex.icon, false },
    { "abyssal", ITEM_DEFINITIONS.abyssal.icon, false },
    { "bloodthorn", ITEM_DEFINITIONS.bloodthorn.icon, false },
    { "orchid", ITEM_DEFINITIONS.orchid.icon, false },
    { "diffusal", ITEM_DEFINITIONS.diffusal.icon, false },
    { "gleipnir", ITEM_DEFINITIONS.gleipnir.icon, false },
    { "silver", ITEM_DEFINITIONS.silver.icon, false },
    { "shadow_blade", ITEM_DEFINITIONS.shadow_blade.icon, false },
}

local priority_widget = priority_group:MultiSelect("Items", priority_items, true)
priority_widget:DragAllowed(true)
priority_widget:ToolTip("Drag to reorder priority. Enable items you want to use.")

local priority_order = {}
local item_thresholds = {}
local item_enemy_ranges = {}

local DEFAULT_SEARCH_RANGE = 1200

local function refresh_priority_order()
    local ordered = {}

    if priority_widget and priority_widget.List then
        local list = priority_widget:List()

        if type(list) == "table" then
            local count = #list
            if count and count > 0 then
                for i = 1, count do
                    local key = list[i]
                    if type(key) == "string" then
                        ordered[#ordered + 1] = key
                    end
                end
            end

            if #ordered == 0 then
                local indexed = {}

                for key, value in pairs(list) do
                    if type(key) == "number" then
                        indexed[#indexed + 1] = { index = key, value = value }
                    end
                end

                if #indexed > 0 then
                    table.sort(indexed, function(a, b)
                        return a.index < b.index
                    end)

                    for _, entry in ipairs(indexed) do
                        if type(entry.value) == "string" then
                            ordered[#ordered + 1] = entry.value
                        elseif type(entry.value) == "table" then
                            local first = entry.value[1]
                            if type(first) == "string" then
                                ordered[#ordered + 1] = first
                            elseif type(entry.value.key) == "string" then
                                ordered[#ordered + 1] = entry.value.key
                            end
                        end
                    end
                end
            end

            if #ordered == 0 then
                local seen = {}

                for _, item in ipairs(priority_items) do
                    seen[item[1]] = true
                end

                for _, value in pairs(list) do
                    if type(value) == "string" and seen[value] then
                        ordered[#ordered + 1] = value
                        seen[value] = nil
                    elseif type(value) == "table" then
                        local key = value.key or value[1]
                        if type(key) == "string" and seen[key] then
                            ordered[#ordered + 1] = key
                            seen[key] = nil
                        end
                    end
                end

                for _, item in ipairs(priority_items) do
                    local key = item[1]
                    if seen[key] then
                        ordered[#ordered + 1] = key
                    end
                end
            end
        end
    end

    if #ordered == 0 then
        for _, item in ipairs(priority_items) do
            ordered[#ordered + 1] = item[1]
        end
    end

    priority_order = ordered
end

refresh_priority_order()

if priority_widget then
    if priority_widget.RegisterCallback then
        priority_widget:RegisterCallback(function()
            refresh_priority_order()
        end)
    end

    if priority_widget.RegisterDragCallback then
        priority_widget:RegisterDragCallback(function(order)
            if type(order) == "table" and #order > 0 then
                local copied = {}

                for i = 1, #order do
                    local key = order[i]
                    if type(key) == "string" then
                        copied[#copied + 1] = key
                    end
                end

                if #copied > 0 then
                    priority_order = copied
                    return
                end
            end

            refresh_priority_order()
        end)
    end
end

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

        local needs_enemy_range =
            definition.type == "target_enemy"
            or definition.type == "position_enemy"
            or definition.type == "escape_self"
            or definition.type == "escape_position"
            or definition.requires_enemy

        if needs_enemy_range then
            local default_range = definition.range or definition.search_range or DEFAULT_SEARCH_RANGE
            if not default_range or default_range <= 0 then
                default_range = DEFAULT_SEARCH_RANGE
            end

            item_enemy_ranges[key] = enemy_range_group:Slider(
                definition.display_name,
                100,
                3000,
                math.floor(default_range + 0.5),
                function(value)
                    return string.format("%d units", value)
                end
            )
        end
    end
end

local CAST_COOLDOWN = 0.2
local PRIORITY_CHAIN_DELAY = 0.35
local last_cast_times = {}
local next_priority_time = 0

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
    refresh_priority_order()

    local enabled = {}
    local seen = {}

    for _, key in ipairs(priority_order) do
        if not seen[key] then
            seen[key] = true
            if priority_widget:Get(key) then
                enabled[#enabled + 1] = key
            end
        end
    end

    for _, item in ipairs(priority_items) do
        local key = item[1]
        if not seen[key] then
            seen[key] = true
            if priority_widget:Get(key) then
                enabled[#enabled + 1] = key
            end
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

local function get_enemy_search_range(hero, ability, definition, item_key)
    local range = get_effective_cast_range(hero, ability, definition)

    if item_key then
        local slider = item_enemy_ranges[item_key]
        if slider then
            local configured = slider:Get()
            if configured and configured > 0 then
                if range <= 0 then
                    range = configured
                else
                    range = math.min(range, configured)
                end
            end
        end
    end

    return range
end

local function find_enemy_target(hero, ability, definition, item_key)
    local range = get_enemy_search_range(hero, ability, definition, item_key)
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

local ESCAPE_FACING_DOT_THRESHOLD = 0.985

local function get_forward_direction(hero)
    if not hero or not Entity or not Entity.GetRotation then
        return nil
    end

    local rotation = Entity.GetRotation(hero)
    if not rotation or rotation.y == nil then
        return nil
    end

    local yaw_radians = math.rad(rotation.y)
    local facing_x = math.cos(yaw_radians)
    local facing_y = math.sin(yaw_radians)

    return {
        x = facing_x,
        y = facing_y,
        z = 0,
    }
end

local function is_facing_direction(hero, direction)
    if not hero or not direction then
        return false
    end

    local forward = get_forward_direction(hero)
    if not forward then
        return true
    end

    local dot = forward.x * direction.x + forward.y * direction.y
    if dot > 1 then
        dot = 1
    elseif dot < -1 then
        dot = -1
    end

    return dot >= ESCAPE_FACING_DOT_THRESHOLD
end

local function is_channelling(hero)
    if not hero or not NPC or not NPC.IsChannellingAbility then
        return false
    end

    return NPC.IsChannellingAbility(hero)
end

local ESCAPE_MIN_TURN_DELAY = 0.25
local ESCAPE_TURN_RETRY_DELAY = 0.05
local ESCAPE_PREP_BLOCK_DURATION = 0.45
local ESCAPE_POST_CAST_BLOCK_DURATION = 0.6
local ESCAPE_STOP_COOLDOWN = 0.05
local escape_block_end_time = 0
local escape_last_stop_time = 0
local escape_last_face_time = 0
local allowed_escape_sequences = {}
local ESCAPE_TURN_GRACE_PERIOD = 0.18
local pending_escape_casts = {}
local ESCAPE_ORDER_IDENTIFIER = "auto_defender_escape"

local function face_direction(hero, direction)
    if not hero or not direction then
        return
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return
    end

    if is_channelling(hero) then
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
        false,
        false,
        false,
        ESCAPE_ORDER_IDENTIFIER
    )

    if GameRules and GameRules.GetGameTime then
        local now = GameRules.GetGameTime()
        if now then
            escape_last_face_time = now
        end
    end
end

local function get_escape_direction(hero, ability, definition, item_key)
    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil, nil
    end

    local search_range = get_enemy_search_range(hero, ability, definition, item_key)

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

local function clear_pending_escape(item_key)
    pending_escape_casts[item_key] = nil
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

local function is_escape_blocking(game_time)
    return game_time and game_time < escape_block_end_time
end

local function issue_stop_order(hero, game_time)
    if not hero or is_channelling(hero) then
        return
    end

    if not game_time then
        return
    end

    if escape_last_face_time > 0 and game_time < escape_last_face_time + ESCAPE_TURN_GRACE_PERIOD then
        return
    end

    if game_time < escape_last_stop_time + ESCAPE_STOP_COOLDOWN then
        return
    end

    if not Players or not Player or not Player.PrepareUnitOrders or not Players.GetLocal then
        return
    end

    local player = Players.GetLocal()
    if not player then
        return
    end

    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_STOP,
        nil,
        nil,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero,
        false,
        false,
        false,
        false,
        ESCAPE_ORDER_IDENTIFIER
    )

    escape_last_stop_time = game_time
end

local function activate_escape_block(hero, game_time, duration)
    if not game_time then
        return
    end

    local block_duration = duration
    if not block_duration or block_duration <= 0 then
        block_duration = ESCAPE_PREP_BLOCK_DURATION
    end

    local block_until = game_time + block_duration
    if block_until > escape_block_end_time then
        escape_block_end_time = block_until
    end

    issue_stop_order(hero, game_time)
end

local function clear_escape_block()
    escape_block_end_time = 0
    escape_last_stop_time = 0
    escape_last_face_time = 0
    allowed_escape_sequences = {}
end

local function does_order_include_hero(data, hero)
    if not data or not hero then
        return false
    end

    if data.npc == hero then
        return true
    end

    local units = data.units
    if not units then
        return false
    end

    if type(units) == "table" then
        for _, unit in pairs(units) do
            if unit == hero then
                return true
            end
        end
        return false
    end

    local get_length = units.GetLength or units.Length or units.Count or units.Size
    local get_value = units.Get or units.GetValue or units.At or units.GetByIndex
    if get_length and get_value then
        local length = get_length(units)
        if length then
            for i = 1, length do
                local unit = get_value(units, i)
                if not unit and i == 1 then
                    unit = get_value(units, 0)
                end
                if unit == hero then
                    return true
                end
            end
        end
    end

    return false
end

local function should_block_order(data)
    if not data or data.identifier == ESCAPE_ORDER_IDENTIFIER then
        return false
    end

    if not Engine.IsInGame() then
        return false
    end

    if not ui.enable or not ui.enable:Get() then
        return false
    end

    local hero = Heroes.GetLocal()
    if not hero or not does_order_include_hero(data, hero) then
        return false
    end

    local game_time = GameRules.GetGameTime()
    if not game_time then
        return false
    end

    return is_escape_blocking(game_time)
end

function auto_defender.OnPrepareUnitOrders(data)
    if data and data.identifier == ESCAPE_ORDER_IDENTIFIER and data.sequenceNumber then
        allowed_escape_sequences[data.sequenceNumber] = true
    end

    if should_block_order(data) then
        return false
    end

    return true
end

function auto_defender.OnExecuteOrder(data)
    if data and data.identifier == ESCAPE_ORDER_IDENTIFIER then
        if data.sequenceNumber then
            allowed_escape_sequences[data.sequenceNumber] = nil
        end
        return true
    end

    if data and data.sequenceNumber and allowed_escape_sequences[data.sequenceNumber] then
        allowed_escape_sequences[data.sequenceNumber] = nil
        return true
    end

    if should_block_order(data) then
        return false
    end

    return true
end

local function cast_item(hero, item_key, game_time)
    local definition = ITEM_DEFINITIONS[item_key]
    if not definition then
        return false
    end

    if is_escape_blocking(game_time) and definition.type ~= "escape_self" then
        return false
    end

    if is_recently_cast(item_key, game_time) then
        return false
    end

    local item = get_inventory_item(hero, definition)
    if not item then
        return false
    end

    if definition.modifier and NPC.HasModifier(hero, definition.modifier) then
        return false
    end

    if not Ability.IsReady(item) then
        return false
    end

    if definition.requires_charges then
        local charges = Ability.GetCurrentCharges(item)
        if not charges or charges <= 0 then
            return false
        end
    end

    local mana = NPC.GetMana(hero)
    if not Ability.IsCastable(item, mana) then
        return false
    end

    if not can_use_item(hero) then
        return false
    end

    if definition.requires_enemy then
        local range = get_enemy_search_range(hero, item, definition, item_key)
        local enemies = Entity.GetHeroesInRadius(hero, range, Enum.TeamType.TEAM_ENEMY, true, true)
        if not enemies or #enemies == 0 then
            return false
        end
    end

    if definition.type == "no_target" then
        Ability.CastNoTarget(item, false, false, false, ESCAPE_ORDER_IDENTIFIER)
    elseif definition.type == "target_self" then
        Ability.CastTarget(item, hero, false, false, false, ESCAPE_ORDER_IDENTIFIER)
    elseif definition.type == "target_enemy" then
        local target = find_enemy_target(hero, item, definition, item_key)
        if not target then
            return false
        end

        Ability.CastTarget(item, target, false, false, false, ESCAPE_ORDER_IDENTIFIER)
    elseif definition.type == "position_enemy" then
        local target = find_enemy_target(hero, item, definition, item_key)
        if not target then
            return false
        end

        local target_pos = Entity.GetAbsOrigin(target)
        if not target_pos then
            return false
        end

        Ability.CastPosition(item, target_pos, false, false, false, ESCAPE_ORDER_IDENTIFIER)
    elseif definition.type == "escape_self" then
        local direction, enemy = get_escape_direction(hero, item, definition, item_key)
        if not direction then
            clear_pending_escape(item_key)
            return false
        end

        if not definition.requires_facing then
            clear_pending_escape(item_key)
            Ability.CastTarget(item, hero, false, false, false, ESCAPE_ORDER_IDENTIFIER)
            activate_escape_block(hero, game_time, ESCAPE_POST_CAST_BLOCK_DURATION)
        else
            local pending = pending_escape_casts[item_key]

            if needs_new_escape(direction, enemy, pending) then
                pending_escape_casts[item_key] = {
                    ready_time = game_time + ESCAPE_MIN_TURN_DELAY,
                    direction = direction,
                    enemy = enemy,
                }
                activate_escape_block(hero, game_time, ESCAPE_PREP_BLOCK_DURATION + ESCAPE_MIN_TURN_DELAY)
                if not is_channelling(hero) then
                    face_direction(hero, direction)
                end
                return false
            end

            pending.direction = direction
            pending.enemy = enemy
            if not pending.ready_time then
                pending.ready_time = game_time + ESCAPE_MIN_TURN_DELAY
            end
            activate_escape_block(hero, game_time, ESCAPE_PREP_BLOCK_DURATION)

            if game_time < pending.ready_time then
                if not is_channelling(hero) then
                    face_direction(hero, pending.direction)
                end
                return false
            end

            if not is_facing_direction(hero, pending.direction) then
                pending.ready_time = game_time + ESCAPE_TURN_RETRY_DELAY
                activate_escape_block(hero, game_time, ESCAPE_PREP_BLOCK_DURATION + ESCAPE_TURN_RETRY_DELAY)
                if not is_channelling(hero) then
                    face_direction(hero, pending.direction)
                end
                return false
            end

            if not is_channelling(hero) then
                face_direction(hero, pending.direction)
            end
            Ability.CastTarget(item, hero, false, false, false, ESCAPE_ORDER_IDENTIFIER)
            activate_escape_block(hero, game_time, ESCAPE_POST_CAST_BLOCK_DURATION)
            clear_pending_escape(item_key)
        end
    elseif definition.type == "escape_position" then
        local direction = get_escape_direction(hero, item, definition, item_key)
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

        Ability.CastPosition(item, cast_position, false, false, false, ESCAPE_ORDER_IDENTIFIER)
        activate_escape_block(hero, game_time, ESCAPE_POST_CAST_BLOCK_DURATION)
    else
        return false
    end

    mark_cast(item_key, game_time)

    return true
end

function auto_defender.OnUpdate()
    if not Engine.IsInGame() then
        last_cast_times = {}
        pending_escape_casts = {}
        clear_escape_block()
        next_priority_time = 0
        return
    end

    if not ui.enable:Get() then
        clear_escape_block()
        next_priority_time = 0
        return
    end

    local hero = Heroes.GetLocal()
    if not hero or NPC.IsIllusion(hero) or not Entity.IsAlive(hero) or Entity.IsDormant(hero) then
        pending_escape_casts = {}
        clear_escape_block()
        next_priority_time = 0
        return
    end

    local max_health = Entity.GetMaxHealth(hero)
    if max_health <= 0 then
        return
    end

    local current_health = Entity.GetHealth(hero)
    local health_percent = (current_health / max_health) * 100.0

    local game_time = GameRules.GetGameTime()
    if is_escape_blocking(game_time) then
        issue_stop_order(hero, game_time)
    end

    if next_priority_time > 0 then
        if game_time and game_time < next_priority_time then
            return
        end
        next_priority_time = 0
    end

    local items_to_use = get_enabled_items()

    if #items_to_use == 0 then
        return
    end

    for _, key in ipairs(items_to_use) do
        local threshold_slider = item_thresholds[key]
        if threshold_slider and health_percent <= threshold_slider:Get() then
            if cast_item(hero, key, game_time) then
                if game_time then
                    next_priority_time = game_time + PRIORITY_CHAIN_DELAY
                end
                break
            end
        end
    end
end

function auto_defender.OnGameEnd()
    last_cast_times = {}
    pending_escape_casts = {}
    clear_escape_block()
    next_priority_time = 0
end

return auto_defender
