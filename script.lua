---@diagnostic disable: undefined-global, lowercase-global

local bristle_auto_back = {}

local HERO_NAME = "npc_dota_hero_bristleback"
local HERO_ICON = "panorama/images/heroes/icons/" .. HERO_NAME .. "_png.vtex_c"

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

local function safe_tooltip(control, text)
    if control and control.ToolTip then
        pcall(control.ToolTip, control, text)
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

local automation_tab = safe_menu_create("Heroes", "Hero List", "Bristleback", "Auto Back")
if not automation_tab then
    automation_tab = safe_menu_create("Heroes", "Hero List", "Bristleback")
end
if not automation_tab then
    automation_tab = safe_menu_create("Heroes")
end
safe_icon(automation_tab, HERO_ICON)

local general_group = create_group(create_group(automation_tab, "General", 1), "Settings", 1) or automation_tab
local behavior_group = create_group(create_group(automation_tab, "Behavior", 2), "Turning", 1) or automation_tab
local awareness_group = create_group(create_group(automation_tab, "Awareness", 3), "Filters", 1) or automation_tab

local priority_tab = safe_menu_create("Heroes", "Hero List", "Bristleback", "Auto Back", "Manual Priority")
if not priority_tab then
    priority_tab = automation_tab
end
safe_icon(priority_tab, HERO_ICON)
local priority_group = create_group(create_group(priority_tab, "Enemy Heroes", 4), "List", 1) or priority_tab

local function format_seconds_ms(value)
    return string.format("%.1f s", value / 1000)
end

local ui = {}
ui.enabled = general_group:Switch("Enable auto back", true, HERO_ICON)
ui.idle_delay = general_group:Slider("Idle delay", 0, 2000, 400, format_seconds_ms)
ui.manual_pause = general_group:Slider("Pause after manual orders", 0, 2000, 600, format_seconds_ms)
ui.require_priority = general_group:Switch("Require manual priority", false)

ui.radius = behavior_group:Slider("Detection radius", 300, 1800, 900, "%d")
ui.turn_distance = behavior_group:Slider("Turn offset distance", 0, 300, 140, "%d")
ui.hold_delay = behavior_group:Slider("Hold delay after move", 0, 1000, 200, format_seconds_ms)
ui.reissue_delay = behavior_group:Slider("Reissue interval", 50, 1000, 250, function(value)
    return string.format("%d ms", value)
end)
ui.stick_time = behavior_group:Slider("Stick with current target", 0, 3000, 1000, format_seconds_ms)

ui.require_visible = awareness_group:Switch("Require visible enemies", false)
ui.ignore_illusions = awareness_group:Switch("Ignore illusions", true)
ui.face_only_alive = awareness_group:Switch("Only consider alive heroes", true)

safe_tooltip(ui.enabled, "Automatically turns Bristleback so his back faces dangerous enemies while you are idle.")
safe_tooltip(ui.idle_delay, "Time you must remain idle before the automation can turn Bristleback.")
safe_tooltip(ui.manual_pause, "Delay the automation after you issue manual orders or move commands.")
safe_tooltip(ui.require_priority, "Only react to enemies that are enabled in the manual priority list.")
safe_tooltip(ui.radius, "Maximum distance to scan for threatening enemy heroes.")
safe_tooltip(ui.turn_distance, "How far a move command is issued to rotate Bristleback's facing away from the enemy.")
safe_tooltip(ui.hold_delay, "Delay before issuing a hold order after the turning move.")
safe_tooltip(ui.reissue_delay, "Minimum time between automated move orders toward the same enemy.")
safe_tooltip(ui.stick_time, "Keep focusing the same enemy for this duration before switching to a new target.")
safe_tooltip(ui.require_visible, "Ignore enemies that are not currently visible to your team.")
safe_tooltip(ui.ignore_illusions, "Filter out enemy illusions from consideration.")
safe_tooltip(ui.face_only_alive, "Skip enemies that are dead or have not yet spawned.")

local enemy_controls = {}
local last_priority_refresh = -1
local last_manual_order_time = -math.huge
local last_move_time = -math.huge
local last_turn_time = -math.huge
local last_position = nil
local pending_hold_time = nil
local current_target_key = nil
local current_target_until = -math.huge

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
    if not Entity.IsHero(ent) then
        return false
    end
    if ui.face_only_alive:Get() and not Entity.IsAlive(ent) then
        return false
    end
    return Entity.GetTeamNum(ent) ~= Entity.GetTeamNum(me)
end

local function is_entity_illusion(ent)
    if not ent then
        return false
    end
    if NPC and NPC.IsIllusion then
        local ok, result = pcall(NPC.IsIllusion, ent)
        if ok then
            return result and true or false
        end
    end
    return false
end

local function is_entity_visible(ent)
    if not ent then
        return false
    end
    if Entity and Entity.IsDormant then
        local ok, dormant = pcall(Entity.IsDormant, ent)
        if ok and dormant then
            return false
        end
    end
    if NPC and NPC.IsVisible then
        local ok, visible = pcall(NPC.IsVisible, ent)
        if ok then
            return visible and true or false
        end
    end
    if Entity and Entity.IsVisible then
        local ok, visible = pcall(Entity.IsVisible, ent)
        if ok then
            return visible and true or false
        end
    end
    return true
end

local function vector_distance(a, b)
    if not a or not b then
        return math.huge
    end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function vector_sub(a, b)
    return { x = (a.x or 0) - (b.x or 0), y = (a.y or 0) - (b.y or 0), z = (a.z or 0) - (b.z or 0) }
end

local function vector_length(v)
    return math.sqrt((v.x or 0) ^ 2 + (v.y or 0) ^ 2)
end

local function vector_normalize(v)
    local length = vector_length(v)
    if length <= 0 then
        return { x = 0, y = 0, z = 0 }, 0
    end
    return { x = v.x / length, y = v.y / length, z = 0 }, length
end

local function enemy_control_key(ent)
    if not ent then
        return nil
    end
    if Entity and Entity.GetPlayerOwnerID then
        return tostring(Entity.GetPlayerOwnerID(ent))
    end
    if Entity and Entity.GetIndex then
        return tostring(Entity.GetIndex(ent))
    end
    return NPC.GetUnitName(ent)
end

local function refresh_enemy_controls(hero)
    local t = now()
    if last_priority_refresh + 1 > t then
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

    local all = Heroes.GetAll and Heroes.GetAll() or {}
    for _, enemy in ipairs(all) do
        if is_enemy_hero(local_hero, enemy) then
            local key = enemy_control_key(enemy)
            if key and not enemy_controls[key] then
                local display_name = NPC.GetUnitName(enemy)
                if Engine and Engine.GetDisplayNameByUnitName then
                    local ok, friendly = pcall(Engine.GetDisplayNameByUnitName, display_name)
                    if ok and friendly then
                        display_name = friendly
                    end
                end
                local row = priority_group:Create(display_name)
                local enable = row:Switch("Enable", true)
                local weight = row:Slider("Priority", 0, 100, 50, "%d")
                enemy_controls[key] = {
                    row = row,
                    enable = enable,
                    weight = weight,
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
        return ui.require_priority:Get() and 0 or 50
    end
    if controls.enable and controls.enable.Get and not controls.enable:Get() then
        return 0
    end
    if controls.weight and controls.weight.Get then
        local value = controls.weight:Get()
        if value then
            return value
        end
    end
    return 50
end

local function should_consider(hero, enemy)
    if not is_enemy_hero(hero, enemy) then
        return false
    end
    if ui.ignore_illusions:Get() and is_entity_illusion(enemy) then
        return false
    end
    if ui.require_visible:Get() and not is_entity_visible(enemy) then
        return false
    end
    if ui.require_priority:Get() and get_enemy_weight(enemy) <= 0 then
        return false
    end
    local hero_pos = Entity.GetAbsOrigin(hero)
    local enemy_pos = Entity.GetAbsOrigin(enemy)
    if not hero_pos or not enemy_pos then
        return false
    end
    local distance = vector_distance(hero_pos, enemy_pos)
    if distance > ui.radius:Get() then
        return false
    end
    return true
end

local function pick_target(hero)
    local best_enemy = nil
    local best_score = -math.huge
    local best_distance = math.huge
    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        return nil
    end

    local all = Heroes.GetAll and Heroes.GetAll() or {}
    for _, enemy in ipairs(all) do
        if should_consider(hero, enemy) then
            local weight = get_enemy_weight(enemy)
            if weight > 0 then
                local distance = vector_distance(hero_pos, Entity.GetAbsOrigin(enemy))
                local score = weight * 1000 - distance
                if score > best_score or (math.abs(score - best_score) < 0.001 and distance < best_distance) then
                    best_enemy = enemy
                    best_score = score
                    best_distance = distance
                end
            end
        end
    end
    return best_enemy
end

local function issue_move_order(hero, position)
    local player = Players.GetLocal()
    if not player then
        return false
    end
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        Vector(position.x, position.y, position.z or 0),
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero,
        false,
        false,
        false,
        true
    )
    return true
end

local function issue_hold_order(hero)
    local player = Players.GetLocal()
    if not player then
        return false
    end
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION,
        nil,
        nil,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero,
        false,
        false,
        false,
        true
    )
    return true
end

local function turn_toward_enemy(hero, enemy)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local enemy_pos = Entity.GetAbsOrigin(enemy)
    if not hero_pos or not enemy_pos then
        return false
    end
    local direction, length = vector_normalize(vector_sub(hero_pos, enemy_pos))
    if length <= 10 then
        return false
    end
    local offset = ui.turn_distance:Get()
    local target_pos = {
        x = hero_pos.x + direction.x * offset,
        y = hero_pos.y + direction.y * offset,
        z = hero_pos.z or 0,
    }
    if issue_move_order(hero, target_pos) then
        last_turn_time = now()
        pending_hold_time = last_turn_time + (ui.hold_delay:Get() / 1000)
        return true
    end
    return false
end

local function reset_state()
    pending_hold_time = nil
    current_target_key = nil
    current_target_until = -math.huge
end

function bristle_auto_back.OnPrepareUnitOrders(event)
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
    reset_state()
end

function bristle_auto_back.OnUpdate()
    local hero = Heroes.GetLocal()
    if not hero then
        reset_state()
        return
    end
    if NPC.GetUnitName(hero) ~= HERO_NAME then
        reset_state()
        return
    end
    if not ui.enabled:Get() then
        reset_state()
        return
    end

    refresh_enemy_controls(hero)

    local current_time = now()

    local hero_pos = Entity.GetAbsOrigin(hero)
    if hero_pos then
        if last_position then
            local distance = vector_distance(hero_pos, last_position)
            if distance > 5 then
                last_move_time = current_time
            end
        else
            last_move_time = current_time
        end
        last_position = hero_pos
    end

    if pending_hold_time and current_time >= pending_hold_time then
        if issue_hold_order(hero) then
            pending_hold_time = nil
        else
            pending_hold_time = current_time + 0.2
        end
    end

    local pause_until = math.max(last_manual_order_time + (ui.manual_pause:Get() / 1000), last_move_time + (ui.idle_delay:Get() / 1000))
    if current_time < pause_until then
        return
    end

    if NPC and NPC.IsChannelling and NPC.IsChannelling(hero) then
        return
    end
    if NPC and NPC.IsStunned and NPC.IsStunned(hero) then
        return
    end

    local target = nil
    if current_target_key and current_time <= current_target_until then
        local all = Heroes.GetAll and Heroes.GetAll() or {}
        for _, enemy in ipairs(all) do
            if enemy_control_key(enemy) == current_target_key and should_consider(hero, enemy) then
                target = enemy
                break
            end
        end
    end

    if not target then
        target = pick_target(hero)
    end

    if not target then
        reset_state()
        return
    end

    local key = enemy_control_key(target)
    if not key then
        return
    end

    local reissue_window = ui.reissue_delay:Get() / 1000
    if current_target_key == key and (now() - last_turn_time) < reissue_window then
        return
    end

    if turn_toward_enemy(hero, target) then
        current_target_key = key
        current_target_until = now() + (ui.stick_time:Get() / 1000)
    end
end

return bristle_auto_back
