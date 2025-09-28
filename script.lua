---@diagnostic disable: undefined-global, lowercase-global, need-check-nil

local auto_defender = {}

local tab = Menu.Create("General", "Auto Defender", "Auto Defender", "Auto Defender")

local settings_root = tab
if type(tab.Gear) == "function" then
    local ok, gear_tab = pcall(tab.Gear, tab, "Settings")
    if ok and gear_tab then
        settings_root = gear_tab
    end
end

local GEAR_WIDGET_SCALE = 0.7
local NON_COMPACT_WIDGET_SCALE = 0.6
local base_widget_scale = GEAR_WIDGET_SCALE

if settings_root == tab then
    base_widget_scale = NON_COMPACT_WIDGET_SCALE
end

local function call_widget_method(widget, method_name, ...)
    if not widget or type(method_name) ~= "string" then
        return false
    end

    local method = widget[method_name]
    if type(method) ~= "function" then
        return false
    end

    local ok = pcall(method, widget, ...)
    return ok and true or false
end

local function apply_compact_style(widget, scale)
    if not widget then
        return
    end

    local effective_scale = scale or base_widget_scale or GEAR_WIDGET_SCALE

    if call_widget_method(widget, "SetScale", effective_scale) then
        return
    end

    if call_widget_method(widget, "SetScaleMultiplier", effective_scale) then
        return
    end

    if call_widget_method(widget, "SetSizeMultiplier", effective_scale) then
        return
    end

    if call_widget_method(widget, "SetWidthMultiplier", effective_scale) then
        return
    end

    if call_widget_method(widget, "SetHeightMultiplier", effective_scale) then
        return
    end

    if call_widget_method(widget, "SetItemHeightMultiplier", effective_scale) then
        return
    end

    call_widget_method(widget, "SetItemSizeMultiplier", effective_scale)
end

apply_compact_style(settings_root)

local function create_settings_group(label, order, allow_root)
    if settings_root ~= tab and type(settings_root) == "table" then
        if type(settings_root.Create) == "function" then
            local ok, group = pcall(settings_root.Create, settings_root, label, order)
            if ok and group then
                return group
            end
        end

        if allow_root and type(settings_root.Switch) == "function" then
            return settings_root
        end
    end

    if type(tab.Create) == "function" then
        local ok, group = pcall(tab.Create, tab, label, order)
        if ok and group then
            return group
        end
    end

    return settings_root
end

local info_group = create_settings_group("Info", 0)
if info_group.Label then
    info_group:Label("Author: GhostyPowa")
elseif info_group.Text then
    info_group:Text("Author: GhostyPowa")
else
    local author_display = info_group:Switch("Author: GhostyPowa", false)
    if author_display then
        apply_compact_style(author_display)
        if author_display.SetEnabled then
            author_display:SetEnabled(false)
        elseif author_display.Disable then
            author_display:Disable()
        elseif author_display.SetState then
            author_display:SetState(false)
        end
    end
end

apply_compact_style(info_group)

local activation_group = create_settings_group("Activation", nil, true)
local priority_group = create_settings_group("Item Priority", 1)
local threshold_group = create_settings_group("Item Thresholds", 2)
local enemy_range_group = create_settings_group("Enemy Range", 3)

local ui = {}
ui.enable = activation_group:Switch("Enable", true)
ui.meteor_combo = activation_group:Switch("Meteor Hammer Combo", true)

apply_compact_style(ui.enable)
apply_compact_style(ui.meteor_combo)
apply_compact_style(activation_group)
apply_compact_style(priority_group)
apply_compact_style(threshold_group)
apply_compact_style(enemy_range_group)

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
    shivas = {
        item_name = "item_shivas_guard",
        icon = "panorama/images/items/shivas_guard_png.vtex_c",
        display_name = "Shiva's Guard",
        type = "no_target",
        modifier = "modifier_item_shivas_guard_active",
        requires_enemy = true,
        search_range = 1200,
    },
    blade_mail = {
        item_name = "item_blade_mail",
        icon = "panorama/images/items/blade_mail_png.vtex_c",
        display_name = "Blade Mail",
        type = "no_target",
        modifier = "modifier_item_blade_mail_reflect",
        requires_enemy = true,
        search_range = 1200,
    },
    satanic = {
        item_name = "item_satanic",
        icon = "panorama/images/items/satanic_png.vtex_c",
        display_name = "Satanic",
        type = "no_target",
        modifier = "modifier_item_satanic_unholy_rage",
        requires_enemy = true,
        search_range = 1200,
    },
    mjollnir = {
        item_name = "item_mjollnir",
        icon = "panorama/images/items/mjollnir_png.vtex_c",
        display_name = "Mjollnir",
        type = "target_self",
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
        type = "target_enemy",
        search_range = 1600,
    },
    hurricane = {
        item_name = "item_hurricane_pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        display_name = "Hurricane Pike",
        type = "target_enemy",
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

local METEOR_COMBO_ITEM_KEY = "__meteor_combo"
local METEOR_HAMMER_DEFINITION = {
    item_name = "item_meteor_hammer",
    icon = "panorama/images/items/meteor_hammer_png.vtex_c",
    type = "position_enemy",
    range = 900,
}

local priority_defaults = {
    glimmer = true,
    ghost = true,
    bkb = true,
}

local priority_keys = {
    "glimmer",
    "ghost",
    "bkb",
    "lotus",
    "crimson",
    "shivas",
    "blade_mail",
    "satanic",
    "mjollnir",
    "eul",
    "wind_waker",
    "force",
    "hurricane",
    "disperser",
    "pipe",
    "ethereal",
    "nullifier",
    "dagon",
    "blood_grenade",
    "halberd",
    "urn",
    "spirit_vessel",
    "blink",
    "overwhelming_blink",
    "swift_blink",
    "arcane_blink",
    "solar_crest",
    "pavise",
    "drums",
    "boots_of_bearing",
    "atos",
    "hex",
    "abyssal",
    "bloodthorn",
    "orchid",
    "diffusal",
    "silver",
    "shadow_blade",
}

local DEFAULT_ICON_PATH = "panorama/images/items/emptyitembg_png.vtex_c"

local function resolve_item_icon(definition)
    local icon = definition.icon
    if type(icon) == "string" and icon ~= "" then
        return icon
    end

    local source = definition.item_name
    if not source then
        local names = definition.item_names
        if type(names) == "table" and #names > 0 then
            source = names[1]
        end
    end

    if type(source) == "string" then
        local prefix = "item_"
        if source:sub(1, #prefix) == prefix then
            source = source:sub(#prefix + 1)
        end

        if source ~= "" then
            return string.format("panorama/images/items/%s_png.vtex_c", source)
        end
    end

    return DEFAULT_ICON_PATH
end

local function apply_widget_icon(widget, icon_path)
    if not widget or type(icon_path) ~= "string" or icon_path == "" then
        return
    end

    local setters = {
        "SetImage",
        "SetIcon",
        "SetTexture",
        "SetTextureID",
    }

    for i = 1, #setters do
        local name = setters[i]
        local setter = widget[name]
        if type(setter) == "function" then
            setter(widget, icon_path)
            return
        end
    end

    if type(widget.Image) == "function" then
        widget:Image(icon_path)
    elseif type(widget.Icon) == "function" then
        widget:Icon(icon_path)
    end
end


apply_widget_icon(ui.meteor_combo, METEOR_HAMMER_DEFINITION.icon)

local priority_items = {}
for _, key in ipairs(priority_keys) do
    local definition = ITEM_DEFINITIONS[key]
    if definition then
        priority_items[#priority_items + 1] = {
            key,
            resolve_item_icon(definition),
            priority_defaults[key] or false,
        }
    end
end

local priority_widget = priority_group:MultiSelect("Items", priority_items, true)
apply_compact_style(priority_group)
apply_compact_style(priority_widget)
priority_widget:DragAllowed(true)
priority_widget:ToolTip("Drag to reorder priority. Enable items you want to use.")

local priority_order = {}
local item_thresholds = {}
local item_enemy_ranges = {}

local priority_delay_slider = priority_group:Slider(
    "Delay After Successful Cast (ms)",
    0,
    5000,
    0,
    function(value)
        return string.format("%.2fs", value / 1000.0)
    end
)
apply_compact_style(priority_delay_slider)

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
        local threshold_label = string.format("%s (%%)", definition.display_name)
        item_thresholds[key] = threshold_group:Slider(
            threshold_label,
            1,
            100,
            50,
            function(value)
                return string.format("%d%%", value)
            end
        )
        apply_compact_style(threshold_group)
        apply_compact_style(item_thresholds[key])
        apply_widget_icon(item_thresholds[key], resolve_item_icon(definition))

        local needs_enemy_range =
            definition.type == "target_enemy"
            or definition.type == "position_enemy"
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
            apply_compact_style(enemy_range_group)
            apply_compact_style(item_enemy_ranges[key])
            apply_widget_icon(item_enemy_ranges[key], resolve_item_icon(definition))
        end
    end
end

local CAST_COOLDOWN = 0.2
local last_cast_times = {}
local next_cast_available_time = 0.0

local CAST_RESULT_NONE = 0
local CAST_RESULT_CAST = 1

local CONTROL_BLOCKERS = {
    Enum.ModifierState.MODIFIER_STATE_STUNNED,
    Enum.ModifierState.MODIFIER_STATE_HEXED,
    Enum.ModifierState.MODIFIER_STATE_MUTED,
}

local function is_meteor_combo_enabled()
    local toggle = ui.meteor_combo
    if not toggle or type(toggle.Get) ~= "function" then
        return false
    end

    local value = toggle:Get()
    if type(value) == "boolean" then
        return value
    end

    return value ~= 0
end

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

local function cast_meteor_combo(hero, game_time)
    if not is_meteor_combo_enabled() then
        return false
    end

    if is_recently_cast(METEOR_COMBO_ITEM_KEY, game_time) then
        return false
    end

    local item = get_inventory_item(hero, METEOR_HAMMER_DEFINITION)
    if not item then
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

    local target = find_enemy_target(hero, item, METEOR_HAMMER_DEFINITION, METEOR_COMBO_ITEM_KEY)
    if not target then
        return false
    end

    local target_pos = Entity.GetAbsOrigin(target)
    if not target_pos then
        return false
    end

    Ability.CastPosition(item, target_pos)
    mark_cast(METEOR_COMBO_ITEM_KEY, game_time)

    return true
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

local function cast_item(hero, item_key, game_time)
    local definition = ITEM_DEFINITIONS[item_key]
    if not definition then
        return CAST_RESULT_NONE
    end

    if is_recently_cast(item_key, game_time) then
        return CAST_RESULT_NONE
    end

    local item = get_inventory_item(hero, definition)
    if not item then
        return CAST_RESULT_NONE
    end

    if definition.modifier and NPC.HasModifier(hero, definition.modifier) then
        return CAST_RESULT_NONE
    end

    if not Ability.IsReady(item) then
        return CAST_RESULT_NONE
    end

    if definition.requires_charges then
        local charges = Ability.GetCurrentCharges(item)
        if not charges or charges <= 0 then
            return CAST_RESULT_NONE
        end
    end

    local mana = NPC.GetMana(hero)
    if not Ability.IsCastable(item, mana) then
        return CAST_RESULT_NONE
    end

    if not can_use_item(hero) then
        return CAST_RESULT_NONE
    end

    if definition.requires_enemy then
        local range = get_enemy_search_range(hero, item, definition, item_key)
        local enemies = Entity.GetHeroesInRadius(hero, range, Enum.TeamType.TEAM_ENEMY, true, true)
        if not enemies or #enemies == 0 then
            return CAST_RESULT_NONE
        end
    end

    if definition.type == "no_target" then
        Ability.CastNoTarget(item)
    elseif definition.type == "target_self" then
        Ability.CastTarget(item, hero)
    elseif definition.type == "target_enemy" then
        local target = find_enemy_target(hero, item, definition, item_key)
        if not target then
            return CAST_RESULT_NONE
        end

        Ability.CastTarget(item, target)
    elseif definition.type == "position_enemy" then
        local target = find_enemy_target(hero, item, definition, item_key)
        if not target then
            return CAST_RESULT_NONE
        end

        local target_pos = Entity.GetAbsOrigin(target)
        if not target_pos then
            return CAST_RESULT_NONE
        end

        Ability.CastPosition(item, target_pos)
    elseif definition.type == "escape_position" then
        local direction = get_escape_direction(hero, item, definition, item_key)
        if not direction then
            return CAST_RESULT_NONE
        end

        local hero_pos = Entity.GetAbsOrigin(hero)
        if not hero_pos then
            return CAST_RESULT_NONE
        end

        local distance = definition.escape_distance or get_effective_cast_range(hero, item, definition)
        if distance <= 0 then
            distance = 1150
        end

        local cast_position = hero_pos + direction * distance
        cast_position.z = hero_pos.z

        Ability.CastPosition(item, cast_position)
    else
        return CAST_RESULT_NONE
    end

    mark_cast(item_key, game_time)

    if item_key == "glimmer" or item_key == "bkb" then
        cast_meteor_combo(hero, game_time)
    end

    return CAST_RESULT_CAST
end

function auto_defender.OnUpdate()
    if not Engine.IsInGame() then
        last_cast_times = {}
        next_cast_available_time = 0.0
        return
    end

    if not ui.enable:Get() then
        next_cast_available_time = 0.0
        return
    end

    local hero = Heroes.GetLocal()
    if not hero or NPC.IsIllusion(hero) or not Entity.IsAlive(hero) or Entity.IsDormant(hero) then
        next_cast_available_time = 0.0
        return
    end

    local max_health = Entity.GetMaxHealth(hero)
    if max_health <= 0 then
        return
    end

    local current_health = Entity.GetHealth(hero)
    local health_percent = (current_health / max_health) * 100.0

    local game_time = GameRules.GetGameTime()

    if next_cast_available_time > game_time then
        return
    end

    local items_to_use = get_enabled_items()

    if #items_to_use == 0 then
        return
    end

    for _, key in ipairs(items_to_use) do
        local threshold_slider = item_thresholds[key]
        if threshold_slider and health_percent <= threshold_slider:Get() then
            local result = cast_item(hero, key, game_time)

            if result == CAST_RESULT_CAST then
                if priority_delay_slider then
                    local delay_ms = priority_delay_slider:Get()
                    if delay_ms and delay_ms > 0 then
                        next_cast_available_time = game_time + (delay_ms / 1000.0)
                    else
                        next_cast_available_time = 0.0
                    end
                else
                    next_cast_available_time = 0.0
                end
                break
            end
        end
    end
end

function auto_defender.OnGameEnd()
    last_cast_times = {}
    next_cast_available_time = 0.0
end

return auto_defender
