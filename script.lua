---@diagnostic disable: undefined-global, lowercase-global

local pudge_tp_hook = {}

local HERO_NAME = "npc_dota_hero_pudge"
local HERO_ICON = "panorama/images/heroes/icons/" .. HERO_NAME .. "_png.vtex_c"
local HOOK_ABILITY_NAME = "pudge_meat_hook"

local function safe_menu_create(...)
    local ok, menu = pcall(Menu.Create, ...)
    if ok then
        return menu
    end
    return nil
end

local function safe_icon(target, icon)
    if target and target.Icon then
        pcall(target.Icon, target, icon)
    end
end

local function create_group(parent, label, order)
    if not parent then
        return nil
    end

    if parent.Create then
        local ok, group
        if order ~= nil then
            ok, group = pcall(parent.Create, parent, label, order)
        else
            ok, group = pcall(parent.Create, parent, label)
        end

        if ok and group then
            return group
        end
    end

    return parent
end

local automation_tab = safe_menu_create("Heroes", "Hero List", "Pudge", "Auto Hook", "Teleport")
if not automation_tab then
    automation_tab = safe_menu_create("Heroes", "Hero List", "Pudge", "Auto Hook")
end
if not automation_tab then
    automation_tab = safe_menu_create("Heroes", "Hero List", "Pudge")
end
if not automation_tab then
    automation_tab = safe_menu_create("Heroes")
end
safe_icon(automation_tab, HERO_ICON)

local general_group = create_group(create_group(automation_tab, "General", 1), "Settings", 1) or automation_tab
local timing_group = create_group(create_group(automation_tab, "Timing", 2), "Adjustments", 1) or automation_tab
local filters_group = create_group(create_group(automation_tab, "Filters", 3), "Targets", 1) or automation_tab

local priority_tab = safe_menu_create("Heroes", "Hero List", "Pudge", "Auto Hook", "Manual Priority")
if not priority_tab then
    priority_tab = automation_tab
end
safe_icon(priority_tab, HERO_ICON)
local priority_group = create_group(create_group(priority_tab, "Enemy Targets", 4), "List", 1) or priority_tab

local ui = {}
ui.enabled = general_group:Switch("Enable teleport hook", true, HERO_ICON)
ui.pause_after_manual = general_group:Slider("Pause after manual orders", 0, 2000, 650, function(value)
    return string.format("%.1f s", value / 1000)
end)
ui.same_target_cooldown = general_group:Slider("Same target cooldown", 0, 4000, 1500, function(value)
    return string.format("%.1f s", value / 1000)
end)

ui.cast_lead = timing_group:Slider("Hook lead adjustment", -400, 400, 50, function(value)
    return string.format("%d ms", value)
end)
ui.max_distance = timing_group:Slider("Maximum hook distance", 800, 1800, 1400, "%d")
ui.min_distance = timing_group:Slider("Minimum hook distance", 0, 600, 0, "%d")

ui.require_visible = filters_group:Switch("Require visible target", false)
ui.ignore_illusions = filters_group:Switch("Ignore illusions", true)
ui.require_priority = filters_group:Switch("Only hook prioritized enemies", false)

ui.enabled:ToolTip("Automatically casts Meat Hook at the end location of enemy teleports.")
ui.pause_after_manual:ToolTip("Delay automation after you manually issue an order to Pudge.")
ui.same_target_cooldown:ToolTip("Prevent re-hook attempts on the same enemy within this cooldown window.")
ui.cast_lead:ToolTip("Timing adjustment applied before the teleport completes. Positive values fire earlier.")
ui.max_distance:ToolTip("Skip teleports that land beyond this distance from Pudge.")
ui.min_distance:ToolTip("Skip teleports that land closer than this distance from Pudge.")
ui.require_visible:ToolTip("Only hook when the destination is visible to your team.")
ui.ignore_illusions:ToolTip("Ignore teleporting illusions when deciding to hook.")
ui.require_priority:ToolTip("Only hook enemies that are enabled in the manual priority list.")

local enemy_controls = {}
local last_priority_refresh = -1
local processed_teleport_indices = {}
local canceled_teleport_indices = {}
local recent_hook_times = {}
local active_target = nil
local last_manual_order_time = -math.huge

local function now()
    if GameRules and GameRules.GetGameTime then
        return GameRules.GetGameTime()
    end
    return os.clock()
end

local function is_enemy_hero(me, ent)
    if not me or not ent then
        return false
    end
    if not Entity.IsHero(ent) or not Entity.IsAlive(ent) then
        return false
    end
    return Entity.GetTeamNum(ent) ~= Entity.GetTeamNum(me)
end

local function is_entity_visible(ent)
    if not ent then
        return false
    end
    if Entity.IsDormant then
        return not Entity.IsDormant(ent)
    end
    return true
end

local function is_entity_illusion(ent)
    if not ent or not NPC.IsHero then
        return false
    end
    if NPC.IsIllusion then
        return NPC.IsIllusion(ent)
    end
    return false
end

local function vector_distance(a, b)
    if not a or not b then
        return math.huge
    end
    local ax, ay = a.x or 0, a.y or 0
    local bx, by = b.x or 0, b.y or 0
    local dx = ax - bx
    local dy = ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function get_hook_ability(hero)
    if not hero then
        return nil
    end
    return NPC.GetAbility(hero, HOOK_ABILITY_NAME)
end

local function get_hook_range(hero, ability)
    ability = ability or get_hook_ability(hero)
    if not ability then
        return 0
    end
    local level = Ability.GetLevel and Ability.GetLevel(ability) or 0
    if not level or level <= 0 then
        return 0
    end
    local range = Ability.GetLevelSpecialValueFor and Ability.GetLevelSpecialValueFor(ability, "hook_distance", level - 1)
    if not range or range <= 0 then
        if Ability.GetCastRange then
            range = Ability.GetCastRange(ability)
        end
    end
    if not range or range <= 0 then
        range = 1300
    end
    return range
end

local function get_hook_speed(ability)
    if not ability then
        return 1600
    end
    local level = Ability.GetLevel and Ability.GetLevel(ability) or 0
    if level and level > 0 and Ability.GetLevelSpecialValueFor then
        local value = Ability.GetLevelSpecialValueFor(ability, "hook_speed", level - 1)
        if value and value > 0 then
            return value
        end
    end
    return 1600
end

local function get_cast_point(ability)
    if ability and Ability.GetCastPoint then
        local cast_point = Ability.GetCastPoint(ability)
        if cast_point then
            return cast_point
        end
    end
    return 0.3
end

local function enemy_control_key(ent)
    if not ent then
        return nil
    end
    if Entity.GetPlayerOwnerID then
        return string.format("%d", Entity.GetPlayerOwnerID(ent))
    end
    if Entity.GetIndex then
        return tostring(Entity.GetIndex(ent))
    end
    return NPC.GetUnitName(ent)
end

local function refresh_enemy_controls(hero)
    local t = now()
    if last_priority_refresh + 1.0 > t then
        return
    end
    last_priority_refresh = t

    if not priority_group then
        return
    end

    local existing = {}
    for key, controls in pairs(enemy_controls) do
        existing[key] = controls
    end

    local local_hero = hero or Heroes.GetLocal()
    if not local_hero then
        return
    end

    local all_heroes = Heroes.GetAll and Heroes.GetAll() or {}
    for _, enemy in ipairs(all_heroes) do
        if is_enemy_hero(local_hero, enemy) then
            local key = enemy_control_key(enemy)
            if key and not enemy_controls[key] then
                local display_name = NPC.GetUnitName(enemy)
                if Engine and Engine.GetDisplayNameByUnitName then
                    local friendly = Engine.GetDisplayNameByUnitName(display_name)
                    if friendly then
                        display_name = friendly
                    end
                end
                local row = priority_group:Create(display_name)
                local enable = row:Switch("Enable", true)
                local weight = row:Slider("Priority", 0, 100, 50, "%d")
                enemy_controls[key] = {
                    enable = enable,
                    weight = weight,
                    row = row,
                }
            end
            existing[key] = nil
        end
    end

    for key, controls in pairs(existing) do
        if controls and controls.row and controls.row.Destroy then
            pcall(controls.row.Destroy, controls.row)
        end
        enemy_controls[key] = nil
    end
end

local function get_enemy_weight(ent)
    local key = enemy_control_key(ent)
    if not key then
        return 0
    end
    local controls = enemy_controls[key]
    if not controls then
        return ui.require_priority and 0 or 50
    end
    if controls.enable and not controls.enable:Get() then
        return 0
    end
    if controls.weight then
        return controls.weight:Get() or 0
    end
    return 50
end

local function should_consider_target(hero, target, pos)
    if not hero or not target or not pos then
        return false
    end
    if not is_enemy_hero(hero, target) then
        return false
    end
    if ui.ignore_illusions:Get() and is_entity_illusion(target) then
        return false
    end
    if ui.require_visible:Get() and not is_entity_visible(target) then
        return false
    end
    local weight = get_enemy_weight(target)
    if ui.require_priority:Get() and weight <= 0 then
        return false
    end
    local ability = get_hook_ability(hero)
    if not ability then
        return false
    end
    local range = math.min(get_hook_range(hero, ability), ui.max_distance:Get())
    local origin = Entity.GetAbsOrigin(hero)
    local distance = vector_distance(origin, pos)
    if distance > range then
        return false
    end
    if distance < ui.min_distance:Get() then
        return false
    end
    local cooldown = ui.same_target_cooldown:Get() / 1000
    local key = enemy_control_key(target)
    if cooldown > 0 and key and recent_hook_times[key] and (now() - recent_hook_times[key]) < cooldown then
        return false
    end
    return true
end

local function cleanup_index_maps()
    local t = now()
    for idx, ts in pairs(processed_teleport_indices) do
        if (t - ts) > 6.0 then
            processed_teleport_indices[idx] = nil
        end
    end
    for idx, info in pairs(canceled_teleport_indices) do
        if (t - (info.time or 0)) > 6.0 then
            canceled_teleport_indices[idx] = nil
        end
    end
    for key, ts in pairs(recent_hook_times) do
        if (t - ts) > 15.0 then
            recent_hook_times[key] = nil
        end
    end
end

local function clear_active_target()
    active_target = nil
end

local function cast_hook(hero, ability, position)
    if not hero or not ability or not position then
        return false
    end

    if Ability.IsCastable and not Ability.IsCastable(ability, NPC.GetMana(hero)) then
        return false
    end
    if Ability.IsInAbilityPhase and Ability.IsInAbilityPhase(ability) then
        return false
    end
    if Ability.IsChannelling and Ability.IsChannelling(ability) then
        return false
    end

    local player = Players.GetLocal()
    if not player then
        return false
    end

    local pos = Vector(position.x, position.y, 0)
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
        nil,
        pos,
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero,
        false,
        false,
        false,
        true
    )
    return true
end

local function schedule_target(hero, rec)
    local ability = get_hook_ability(hero)
    if not ability then
        return
    end

    local pos = rec.position
    local target = rec.target
    processed_teleport_indices[rec.index] = now()
    if not should_consider_target(hero, target, pos) then
        return
    end

    local origin = Entity.GetAbsOrigin(hero)
    if not origin then
        return
    end

    local distance = vector_distance(origin, pos)
    local hook_speed = get_hook_speed(ability)
    local travel_time = distance / math.max(hook_speed, 1)
    local cast_point = get_cast_point(ability)
    local lead_adjust = (ui.cast_lead:Get() or 0) / 1000

    local cast_time = rec.end_time - travel_time - cast_point - lead_adjust
    local current_time = now()
    if cast_time < current_time then
        cast_time = current_time
    end

    active_target = {
        target = target,
        position = pos,
        cast_time = cast_time,
        end_time = rec.end_time,
        index = rec.index,
    }
end

local function try_acquire_target(hero)
    if not LIB_HEROES_DATA or not LIB_HEROES_DATA.teleport_time then
        return
    end

    for idx, rec in pairs(LIB_HEROES_DATA.teleport_time) do
        if rec and rec.name == "teleport_end" and not processed_teleport_indices[idx] then
            if rec.target and rec.position and rec.end_time then
                rec.index = idx
                schedule_target(hero, rec)
                if active_target then
                    return
                end
            else
                processed_teleport_indices[idx] = now()
            end
        end
    end
end

function pudge_tp_hook.OnPrepareUnitOrders(event)
    if not event then
        return
    end
    if event.issuer and event.issuer ~= Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY then
        return
    end
    if event.player and event.player ~= Players.GetLocal() then
        return
    end
    last_manual_order_time = now()
end

function pudge_tp_hook.OnUpdate()
    local hero = Heroes.GetLocal()
    if not hero then
        clear_active_target()
        return
    end

    if NPC.GetUnitName(hero) ~= HERO_NAME then
        clear_active_target()
        return
    end

    if not ui.enabled:Get() then
        clear_active_target()
        return
    end

    local ability = get_hook_ability(hero)
    if not ability then
        clear_active_target()
        return
    end

    local ability_level = Ability.GetLevel and Ability.GetLevel(ability) or 0
    if ability_level <= 0 then
        clear_active_target()
        return
    end

    refresh_enemy_controls(hero)
    cleanup_index_maps()

    if now() - last_manual_order_time < (ui.pause_after_manual:Get() / 1000) then
        return
    end

    if not active_target then
        try_acquire_target(hero)
    end

    if not active_target then
        return
    end

    local cancel_info = canceled_teleport_indices[active_target.index]
    if cancel_info then
        clear_active_target()
        return
    end

    local target = active_target.target
    if not target or not Entity.IsAlive(target) then
        clear_active_target()
        return
    end

    if ui.ignore_illusions:Get() and is_entity_illusion(target) then
        clear_active_target()
        return
    end

    local cast_time = active_target.cast_time or 0
    local current_time = now()
    if current_time + 0.01 < cast_time then
        return
    end

    if current_time > (active_target.end_time or current_time) + 0.3 then
        clear_active_target()
        return
    end

    if cast_hook(hero, ability, active_target.position) then
        local key = enemy_control_key(target)
        if key then
            recent_hook_times[key] = current_time
        end
    end
    clear_active_target()
end

function pudge_tp_hook.OnParticleDestroy(data)
    if not data then
        return
    end
    canceled_teleport_indices[data.index] = { time = now() }
    if active_target and active_target.index == data.index then
        clear_active_target()
    end
end

return pudge_tp_hook
