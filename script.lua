---@diagnostic disable: undefined-global, lowercase-global, need-check-nil

local auto_hex = {}

local menu = Menu.Create("General", "Auto Hex", "Auto Hex", "Auto Hex")
local activation_group = menu:Create("Activation")
local behavior_group = menu:Create("Behavior", 1)
local sources_group = menu:Create("Hex Sources", 2)

local ui = {
    enable = activation_group:Switch("Enable", true),
    reaction_window = behavior_group:Slider("Invisibility memory", 100, 2000, 900, function(value)
        return string.format("%.0f ms", value)
    end),
    unseen_threshold = behavior_group:Slider("Minimum unseen duration", 0, 2000, 300, function(value)
        return string.format("%.0f ms", value)
    end),
    range_buffer = behavior_group:Slider("Range buffer", 0, 400, 75, "%d"),
    skip_magic_immunity = behavior_group:Switch("Skip magic immune targets", true),
}

local HEX_SOURCES = {
    {
        key = "sheepstick",
        kind = "item",
        names = { "item_sheepstick" },
        icon = "panorama/images/items/sheepstick_png.vtex_c",
    },
    {
        key = "lion_hex",
        kind = "ability",
        names = { "lion_voodoo" },
        icon = "panorama/images/spellicons/lion_voodoo_png.vtex_c",
    },
    {
        key = "shadow_shaman_hex",
        kind = "ability",
        names = { "shadow_shaman_voodoo", "rhasta_voodoo" },
        icon = "panorama/images/spellicons/shadow_shaman_voodoo_png.vtex_c",
    },
    {
        key = "witch_doctor_voodoo",
        kind = "item",
        names = { "item_voodoo_mask" },
        icon = "panorama/images/items/voodoo_mask_png.vtex_c",
    },
}

local SOURCE_BY_KEY = {}
local source_items = {}
for index, definition in ipairs(HEX_SOURCES) do
    SOURCE_BY_KEY[definition.key] = definition
    source_items[index] = { definition.key, definition.icon, true }
end

local source_widget = sources_group:MultiSelect("Sources", source_items, true)
source_widget:DragAllowed(true)
source_widget:ToolTip("Select usable hex sources and drag to adjust priority.")

local INVISIBILITY_MODIFIERS = {
    modifier_invisible = true,
    modifier_bounty_hunter_wind_walk = true,
    modifier_broodmother_spin_web_invisibility = true,
    modifier_clinkz_wind_walk = true,
    modifier_weaver_shukuchi = true,
    modifier_riki_permanent_invisibility = true,
    modifier_nyx_assassin_vendetta = true,
    modifier_sand_king_sandstorm_invis = true,
    modifier_templar_assassin_meld = true,
    modifier_mirana_moonlight_shadow = true,
    modifier_treant_natures_guise = true,
    modifier_slark_shadow_dance = true,
    modifier_phantom_assassin_blur_active = true,
    modifier_dark_willow_shadow_realm = true,
    modifier_hoodwink_scurry = true,
    modifier_invoker_ghost_walk_self = true,
    modifier_item_invisibility_edge_windwalk = true,
    modifier_item_silver_edge_windwalk = true,
    modifier_item_glimmer_cape_fade = true,
    modifier_item_shadow_amulet_invisibility = true,
    modifier_item_shadow_amulet_fade = true,
    modifier_rune_invis = true,
    modifier_smoke_of_deceit = true,
}

local INVISIBLE_HEROES = {
    npc_dota_hero_bounty_hunter = true,
    npc_dota_hero_clinkz = true,
    npc_dota_hero_riki = true,
    npc_dota_hero_weaver = true,
    npc_dota_hero_nyx_assassin = true,
    npc_dota_hero_broodmother = true,
    npc_dota_hero_templar_assassin = true,
    npc_dota_hero_sand_king = true,
    npc_dota_hero_mirana = true,
    npc_dota_hero_treant = true,
    npc_dota_hero_slark = true,
    npc_dota_hero_phantom_assassin = true,
    npc_dota_hero_invoker = true,
    npc_dota_hero_dark_willow = true,
    npc_dota_hero_hoodwink = true,
}

local INVISIBILITY_ITEMS = {
    item_invis_sword = true,
    item_silver_edge = true,
    item_glimmer_cape = true,
    item_shadow_amulet = true,
}

local CONTROL_BLOCKERS = {
    Enum.ModifierState.MODIFIER_STATE_STUNNED,
    Enum.ModifierState.MODIFIER_STATE_HEXED,
    Enum.ModifierState.MODIFIER_STATE_MUTED,
    Enum.ModifierState.MODIFIER_STATE_SILENCED,
    Enum.ModifierState.MODIFIER_STATE_FROZEN,
    Enum.ModifierState.MODIFIER_STATE_COMMAND_RESTRICTED,
}

local DEFAULT_HEX_RANGE = 575.0
local SOURCE_REFRESH_DELAY = 0.25
local MIN_HEX_INTERVAL = 0.2

local enemy_states = setmetatable({}, { __mode = "k" })
local active_sources = {}
local next_source_refresh = 0.0

local function seconds(widget)
    return (widget:Get() or 0) / 1000.0
end

local function reset_state()
    enemy_states = setmetatable({}, { __mode = "k" })
    active_sources = {}
    next_source_refresh = 0.0
end

local function can_control(hero)
    if not hero or not Entity.IsAlive(hero) then
        return false
    end

    for _, state in ipairs(CONTROL_BLOCKERS) do
        if NPC.HasState(hero, state) then
            return false
        end
    end

    if NPC.IsChannellingAbility(hero) then
        return false
    end

    return true
end

local function has_invis_item(enemy)
    if not enemy then
        return false
    end

    for name in pairs(INVISIBILITY_ITEMS) do
        if NPC.GetItem(enemy, name, true) then
            return true
        end
    end

    return false
end

local function is_invisible(enemy)
    if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then
        return true
    end

    for modifier in pairs(INVISIBILITY_MODIFIERS) do
        if NPC.HasModifier(enemy, modifier) then
            return true
        end
    end

    return false
end

local function refresh_sources(hero, current_time)
    if current_time < next_source_refresh then
        return
    end

    next_source_refresh = current_time + SOURCE_REFRESH_DELAY
    active_sources = {}

    if not hero then
        return
    end

    local order = source_widget:List()
    for i = 1, #order do
        local key = order[i]
        if source_widget:Get(key) then
            local definition = SOURCE_BY_KEY[key]
            if definition then
                local ability = nil

                if definition.kind == "item" then
                    for _, name in ipairs(definition.names) do
                        ability = NPC.GetItem(hero, name, true)
                        if ability then
                            break
                        end
                    end
                else
                    for _, name in ipairs(definition.names) do
                        ability = NPC.GetAbility(hero, name)
                        if ability then
                            break
                        end
                    end
                end

                if ability then
                    active_sources[#active_sources + 1] = {
                        ability = ability,
                        definition = definition,
                        key = key,
                    }
                end
            end
        end
    end
end

local function is_source_ready(hero, entry)
    if not entry or not entry.ability then
        return false
    end

    local ability = entry.ability
    if not Ability.IsReady(ability) then
        return false
    end

    if not Ability.IsCastable(ability, NPC.GetMana(hero)) then
        return false
    end

    return true
end

local function get_cast_range(hero, ability)
    local range = Ability.GetCastRange(ability)
    if not range or range < 0 then
        range = 0
    end

    local bonus = NPC.GetCastRangeBonus(hero)
    if bonus and bonus > 0 then
        range = range + bonus
    end

    if range <= 0 then
        range = DEFAULT_HEX_RANGE
    end

    return range + (ui.range_buffer:Get() or 0)
end

local function hero_can_invis(enemy, state, current_time, reaction_window)
    if not enemy then
        return false
    end

    if state.last_invisible_time and current_time - state.last_invisible_time <= reaction_window then
        return true
    end

    local unit_name = NPC.GetUnitName(enemy)
    if unit_name and INVISIBLE_HEROES[unit_name] then
        return true
    end

    if state.has_invis_item then
        return true
    end

    return false
end

local function attempt_hex(hero, enemy, state, current_time)
    if current_time - (state.last_hex_time or -math.huge) < MIN_HEX_INTERVAL then
        return false
    end

    if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_HEXED) then
        return false
    end

    if ui.skip_magic_immunity:Get() and NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
        return false
    end

    local hero_position = Entity.GetAbsOrigin(hero)
    local enemy_position = Entity.GetAbsOrigin(enemy)
    if not hero_position or not enemy_position then
        return false
    end

    for _, entry in ipairs(active_sources) do
        if is_source_ready(hero, entry) then
            local range = get_cast_range(hero, entry.ability)
            if hero_position:Distance2D(enemy_position) <= range then
                Ability.CastTarget(entry.ability, enemy)
                state.last_hex_time = current_time
                entry.last_cast_time = current_time
                return true
            end
        end
    end

    return false
end

local function update_enemy(hero, enemy, current_time, reaction_window, unseen_threshold)
    local state = enemy_states[enemy]
    if not state then
        state = {
            was_visible = Entity.IsVisible(enemy),
            last_invisible_time = nil,
            last_unseen_start = nil,
            last_hex_time = 0.0,
            has_invis_item = has_invis_item(enemy),
        }
        enemy_states[enemy] = state
    end

    local visible = Entity.IsVisible(enemy)
    local invisible = is_invisible(enemy)

    if visible then
        state.has_invis_item = has_invis_item(enemy)
    elseif state.was_visible then
        state.last_unseen_start = current_time
    end

    if invisible then
        state.last_invisible_time = current_time
    end

    local became_visible = visible and not state.was_visible

    if became_visible then
        local capable = hero_can_invis(enemy, state, current_time, reaction_window * 3.0)
        if capable then
            local invis_recent = state.last_invisible_time and (current_time - state.last_invisible_time <= reaction_window)
            local unseen_recent = state.last_unseen_start and (current_time - state.last_unseen_start >= unseen_threshold)

            if (invis_recent or unseen_recent) then
                attempt_hex(hero, enemy, state, current_time)
            end
        end

        state.last_unseen_start = nil
    end

    state.was_visible = visible
    state.was_invisible = invisible
end

local function process_enemies(hero, current_time)
    local heroes = Heroes.GetAll()
    if not heroes then
        return
    end

    local reaction_window = seconds(ui.reaction_window)
    local unseen_threshold = seconds(ui.unseen_threshold)

    for i = 1, #heroes do
        local enemy = heroes[i]
        if enemy and enemy ~= hero and Entity.IsHero(enemy) then
            if not Entity.IsSameTeam(enemy, hero) and not NPC.IsIllusion(enemy) and not Entity.IsDormant(enemy) then
                update_enemy(hero, enemy, current_time, reaction_window, unseen_threshold)
            end
        end
    end
end

function auto_hex.OnUpdate()
    if not Engine.IsInGame() then
        reset_state()
        return
    end

    if not ui.enable:Get() then
        return
    end

    local hero = Heroes.GetLocal()
    if not hero or NPC.IsIllusion(hero) or not Entity.IsAlive(hero) or Entity.IsDormant(hero) then
        return
    end

    if not can_control(hero) then
        return
    end

    local current_time = GameRules.GetGameTime()
    refresh_sources(hero, current_time)

    if #active_sources == 0 then
        return
    end

    process_enemies(hero, current_time)
end

return auto_hex
