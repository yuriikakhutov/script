---@diagnostic disable: undefined-global, lowercase-global, param-type-mismatch

local auto_defender = {}

local tab = Menu.Create("General", "Auto Defender", "Auto Defender", "Auto Defender")

local activation_group = tab:Create("Activation")
local priority_group = tab:Create("Item Priority", 1)
local threshold_group = tab:Create("Health Thresholds", 2)
local enemy_group = tab:Create("Enemy Checks", 3)

local ui = {
    enable = activation_group:Switch("Enable", true),
}

ui.enemy_range = enemy_group:Slider("Enemy detection range", 200, 2000, 900, "%d")

local ITEM_DEFINITIONS = {
    {
        id = "glimmer",
        ability_names = { "item_glimmer_cape" },
        display_name = "Glimmer Cape",
        icon = "panorama/images/items/glimmer_cape_png.vtex_c",
        cast = "target_self",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_glimmer_cape_fade",
    },
    {
        id = "ghost",
        ability_names = { "item_ghost" },
        display_name = "Ghost Scepter",
        icon = "panorama/images/items/ghost_scepter_png.vtex_c",
        cast = "no_target",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_ghost_state",
    },
    {
        id = "bkb",
        ability_names = { "item_black_king_bar" },
        display_name = "Black King Bar",
        icon = "panorama/images/items/black_king_bar_png.vtex_c",
        cast = "no_target",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_black_king_bar_immune",
        allow_while_channeling = false,
    },
    {
        id = "lotus",
        ability_names = { "item_lotus_orb" },
        display_name = "Lotus Orb",
        icon = "panorama/images/items/lotus_orb_png.vtex_c",
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_lotus_orb_active",
    },
    {
        id = "crimson",
        ability_names = { "item_crimson_guard" },
        display_name = "Crimson Guard",
        icon = "panorama/images/items/crimson_guard_png.vtex_c",
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_crimson_guard_nostack",
    },
    {
        id = "blade_mail",
        ability_names = { "item_blade_mail" },
        display_name = "Blade Mail",
        icon = "panorama/images/items/blade_mail_png.vtex_c",
        cast = "no_target",
        threshold_default = 50,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_blade_mail_reflect",
    },
    {
        id = "pipe",
        ability_names = { "item_pipe" },
        display_name = "Pipe of Insight",
        icon = "panorama/images/items/pipe_png.vtex_c",
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_pipe_barrier",
    },
    {
        id = "solar_crest",
        ability_names = { "item_solar_crest" },
        display_name = "Solar Crest",
        icon = "panorama/images/items/solar_crest_png.vtex_c",
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_solar_crest_armor",
    },
    {
        id = "drum",
        ability_names = { "item_ancient_janggo" },
        display_name = "Drum of Endurance",
        icon = "panorama/images/items/ancient_janggo_png.vtex_c",
        cast = "no_target",
        threshold_default = 55,
        enemy_toggle = true,
        enemy_required_default = true,
    },
    {
        id = "bearing",
        ability_names = { "item_boots_of_bearing" },
        display_name = "Boots of Bearing",
        icon = "panorama/images/items/boots_of_bearing_png.vtex_c",
        cast = "no_target",
        threshold_default = 55,
        enemy_toggle = true,
        enemy_required_default = true,
    },
    {
        id = "force",
        ability_names = { "item_force_staff" },
        display_name = "Force Staff",
        icon = "panorama/images/items/force_staff_png.vtex_c",
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
    },
    {
        id = "hurricane",
        ability_names = { "item_hurricane_pike" },
        display_name = "Hurricane Pike",
        icon = "panorama/images/items/hurricane_pike_png.vtex_c",
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
    },
    {
        id = "blink",
        ability_names = { "item_blink" },
        display_name = "Blink Dagger",
        icon = "panorama/images/items/blink_png.vtex_c",
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "swift_blink",
        ability_names = { "item_swift_blink" },
        display_name = "Swift Blink",
        icon = "panorama/images/items/swift_blink_png.vtex_c",
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "arcane_blink",
        ability_names = { "item_arcane_blink" },
        display_name = "Arcane Blink",
        icon = "panorama/images/items/arcane_blink_png.vtex_c",
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "overwhelming_blink",
        ability_names = { "item_overwhelming_blink" },
        display_name = "Overwhelming Blink",
        icon = "panorama/images/items/overwhelming_blink_png.vtex_c",
        cast = "blink_escape",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        blink_range = 1200,
    },
    {
        id = "eul",
        ability_names = { "item_cyclone" },
        display_name = "Eul's Scepter",
        icon = "panorama/images/items/cyclone_png.vtex_c",
        cast = "target_self",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_eul_cyclone",
    },
    {
        id = "wind_waker",
        ability_names = { "item_wind_waker" },
        display_name = "Wind Waker",
        icon = "panorama/images/items/wind_waker_png.vtex_c",
        cast = "target_self",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_wind_waker_cyclone",
    },
    {
        id = "ethereal",
        ability_names = { "item_ethereal_blade" },
        display_name = "Ethereal Blade",
        icon = "panorama/images/items/ethereal_blade_png.vtex_c",
        cast = "target_self",
        threshold_default = 35,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_ethereal_blade",
    },
    {
        id = "disperser",
        ability_names = { "item_disperser" },
        display_name = "Disperser",
        icon = "panorama/images/items/disperser_png.vtex_c",
        cast = "no_target",
        threshold_default = 40,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_item_disperser_speed",
    },
    {
        id = "urn",
        ability_names = { "item_urn_of_shadows" },
        display_name = "Urn of Shadows",
        icon = "panorama/images/items/urn_of_shadows_png.vtex_c",
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = false,
        modifier = "modifier_item_urn_heal",
    },
    {
        id = "vessel",
        ability_names = { "item_spirit_vessel" },
        display_name = "Spirit Vessel",
        icon = "panorama/images/items/spirit_vessel_png.vtex_c",
        cast = "target_self",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = false,
        modifier = "modifier_item_spirit_vessel_heal",
    },
    {
        id = "blood_grenade",
        ability_names = { "item_blood_grenade" },
        display_name = "Blood Grenade",
        icon = "panorama/images/items/blood_grenade_png.vtex_c",
        cast = "enemy_position",
        threshold_default = 35,
        requires_enemy = true,
        cast_range_override = 900,
    },
    {
        id = "nullifier",
        ability_names = { "item_nullifier" },
        display_name = "Nullifier",
        icon = "panorama/images/items/nullifier_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 35,
        requires_enemy = true,
    },
    {
        id = "dagon",
        ability_names = { "item_dagon", "item_dagon_2", "item_dagon_3", "item_dagon_4", "item_dagon_5" },
        display_name = "Dagon",
        icon = "panorama/images/items/dagon_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "halberd",
        ability_names = { "item_heavens_halberd" },
        display_name = "Heaven's Halberd",
        icon = "panorama/images/items/heavens_halberd_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "atos",
        ability_names = { "item_rod_of_atos" },
        display_name = "Rod of Atos",
        icon = "panorama/images/items/rod_of_atos_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "hex",
        ability_names = { "item_sheepstick" },
        display_name = "Scythe of Vyse",
        icon = "panorama/images/items/sheepstick_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "abyssal",
        ability_names = { "item_abyssal_blade" },
        display_name = "Abyssal Blade",
        icon = "panorama/images/items/abyssal_blade_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "diffusal",
        ability_names = { "item_diffusal_blade", "item_diffusal_blade_2" },
        display_name = "Diffusal Blade",
        icon = "panorama/images/items/diffusal_blade_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "gleipnir",
        ability_names = { "item_gleipnir" },
        display_name = "Gleipnir",
        icon = "panorama/images/items/gleipnir_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "bloodthorn",
        ability_names = { "item_bloodthorn" },
        display_name = "Bloodthorn",
        icon = "panorama/images/items/bloodthorn_png.vtex_c",
        cast = "target_enemy",
        threshold_default = 40,
        requires_enemy = true,
    },
    {
        id = "silver_edge",
        ability_names = { "item_silver_edge" },
        display_name = "Silver Edge",
        icon = "panorama/images/items/silver_edge_png.vtex_c",
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_invisible",
    },
    {
        id = "shadow_blade",
        ability_names = { "item_invis_sword" },
        display_name = "Shadow Blade",
        icon = "panorama/images/items/invis_sword_png.vtex_c",
        cast = "no_target",
        threshold_default = 45,
        enemy_toggle = true,
        enemy_required_default = true,
        modifier = "modifier_invisible",
    },
}

local ITEM_BY_ID = {}
local priority_items = {}
ui.thresholds = {}
ui.enemy_toggles = {}

for _, def in ipairs(ITEM_DEFINITIONS) do
    ITEM_BY_ID[def.id] = def
    table.insert(priority_items, { def.id, def.icon or "", true })
    ui.thresholds[def.id] = threshold_group:Slider(def.display_name .. " health %", 1, 100, def.threshold_default or 50, "%d%%")
    if def.enemy_toggle then
        ui.enemy_toggles[def.id] = enemy_group:Switch(def.display_name .. " requires nearby enemy", def.enemy_required_default ~= false)
    end
end

ui.priority = priority_group:MultiSelect("Enabled items", priority_items, true)
ui.priority:DragAllowed(true)

local CAST_RETRY_DELAY = 0.25
local FOUNTAIN_POS = {
    [Enum.TeamNum.TEAM_RADIANT] = Vector(-7072, -6540, 384),
    [Enum.TeamNum.TEAM_DIRE] = Vector(7032, 6460, 384),
}

local recent_casts = {}

local function find_item(hero, def)
    if not def.ability_names then
        return nil
    end

    for _, name in ipairs(def.ability_names) do
        local item = NPC.GetItem(hero, name, true)
        if item then
            return item
        end
    end

    return nil
end

local function item_on_cooldown(hero, ability)
    if not ability then
        return true
    end

    if not Ability.IsReady(ability) then
        return true
    end

    if not Ability.IsCastable(ability, NPC.GetMana(hero)) then
        return true
    end

    if Ability.IsInAbilityPhase(ability) then
        return true
    end

    if Ability.IsChannelling(ability) then
        return true
    end

    if Item.RequiresCharges(ability) and Item.GetCurrentCharges(ability) <= 0 then
        return true
    end

    return false
end

local function within_cast_range(hero, ability, target, override_range)
    if not target then
        return false
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    local target_pos = Entity.GetAbsOrigin(target)
    local range = override_range or Ability.GetCastRange(ability)

    if range < 0 then
        range = override_range or 0
    end

    range = range + NPC.GetCastRangeBonus(hero)

    if range <= 0 then
        return true
    end

    return hero_pos:Distance2D(target_pos) <= range
end

local function get_nearest_enemy(hero, enemies)
    if not enemies then
        return nil
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    local best
    local best_dist = math.huge

    for _, enemy in ipairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) and not NPC.IsIllusion(enemy) then
            local dist = hero_pos:Distance2D(Entity.GetAbsOrigin(enemy))
            if dist < best_dist then
                best_dist = dist
                best = enemy
            end
        end
    end

    return best
end

local function select_enemy_target(hero, ability, def, enemies)
    local target = get_nearest_enemy(hero, enemies)
    if not target then
        return nil
    end

    local override = def.cast_range_override
    if within_cast_range(hero, ability, target, override) then
        return target
    end

    return nil
end

local function compute_escape_position(hero, def, hero_pos, nearest_enemy, team)
    local fountain = FOUNTAIN_POS[team]
    local direction

    if fountain then
        direction = (fountain - hero_pos):Normalized()
    elseif nearest_enemy then
        local enemy_pos = Entity.GetAbsOrigin(nearest_enemy)
        direction = (hero_pos - enemy_pos):Normalized()
    else
        local forward = Entity.GetForwardPosition(hero, 100)
        direction = (forward - hero_pos):Normalized()
    end

    if not direction then
        return nil
    end

    local distance = def.blink_range or 1200
    return hero_pos + direction:Scaled(distance)
end

local function try_cast(hero, ability, def, hero_pos, enemies, nearest_enemy, team)
    local ability_index = Ability.GetIndex(ability)
    local now = GameRules.GetGameTime()
    local last = recent_casts[ability_index]

    if last and now - last < CAST_RETRY_DELAY then
        return false
    end

    recent_casts[ability_index] = now

    if def.cast == "no_target" then
        Ability.CastNoTarget(ability)
        return true
    elseif def.cast == "target_self" then
        Ability.CastTarget(ability, hero)
        return true
    elseif def.cast == "target_enemy" then
        local target = select_enemy_target(hero, ability, def, enemies)
        if target then
            Ability.CastTarget(ability, target)
            return true
        end
    elseif def.cast == "enemy_position" then
        local target = select_enemy_target(hero, ability, def, enemies)
        if target then
            Ability.CastPosition(ability, Entity.GetAbsOrigin(target))
            return true
        end
    elseif def.cast == "blink_escape" then
        local pos = compute_escape_position(hero, def, hero_pos, nearest_enemy, team)
        if pos then
            Ability.CastPosition(ability, pos)
            return true
        end
    end

    return false
end

function auto_defender.OnUpdate()
    if not ui.enable:Get() then
        return
    end

    local hero = Heroes.GetLocal()
    if not hero or not Entity.IsAlive(hero) or Entity.IsDormant(hero) or NPC.IsIllusion(hero) then
        return
    end

    local health = Entity.GetHealth(hero)
    local max_health = math.max(Entity.GetMaxHealth(hero), 1)
    local health_pct = (health / max_health) * 100
    local team = Entity.GetTeamNum(hero)

    local is_channeling = NPC.IsChannellingAbility(hero)

    local hero_pos = Entity.GetAbsOrigin(hero)
    local enemy_range = ui.enemy_range:Get()

    local enemy_list
    local nearest_enemy

    local function ensure_enemy_info()
        if enemy_list then
            return
        end

        enemy_list = Heroes.InRadius(hero_pos, enemy_range, team, Enum.TeamType.TEAM_ENEMY, true, true) or {}
        nearest_enemy = get_nearest_enemy(hero, enemy_list)
    end

    local items_in_order = ui.priority:List()
    if not items_in_order then
        return
    end

    for _, item_id in ipairs(items_in_order) do
        if not ui.priority:Get(item_id) then
            goto continue
        end

        local def = ITEM_BY_ID[item_id]
        if not def then
            goto continue
        end

        local threshold_slider = ui.thresholds[item_id]
        local threshold = threshold_slider and threshold_slider:Get() or 0
        if threshold <= 0 or health_pct > threshold then
            goto continue
        end

        if is_channeling and not def.allow_while_channeling then
            goto continue
        end

        local ability = find_item(hero, def)
        if not ability or item_on_cooldown(hero, ability) then
            goto continue
        end

        if def.modifier and NPC.HasModifier(hero, def.modifier) then
            goto continue
        end

        if def.enemy_toggle then
            local toggle = ui.enemy_toggles[item_id]
            if toggle and toggle:Get() then
                ensure_enemy_info()
                if not nearest_enemy then
                    goto continue
                end
            end
        elseif def.requires_enemy then
            ensure_enemy_info()
            if not nearest_enemy then
                goto continue
            end
        end

        ensure_enemy_info()

        try_cast(hero, ability, def, hero_pos, enemy_list, nearest_enemy, team)

        ::continue::
    end
end

function auto_defender.OnGameStart()
    recent_casts = {}
end

auto_defender.OnGameEnd = auto_defender.OnGameStart

auto_defender.OnScriptLoad = auto_defender.OnGameStart

return auto_defender
