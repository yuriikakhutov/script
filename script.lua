---@diagnostic disable: undefined-global, lowercase-global

local bristleback_auto_back = {}

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

local automation_tab = safe_menu_create("Heroes", "Hero List", "Bristleback", "Auto Back", "Automation")
if not automation_tab then
    automation_tab = safe_menu_create("Heroes", "Hero List", "Bristleback", "Auto Back")
end
if not automation_tab then
    automation_tab = safe_menu_create("Heroes", "Hero List", "Bristleback")
end
if not automation_tab then
    automation_tab = safe_menu_create("Heroes")
end
safe_icon(automation_tab, HERO_ICON)

local general_group = create_group(create_group(automation_tab, "General", 1), "Settings", 1) or automation_tab
local behavior_group = create_group(create_group(automation_tab, "Behavior", 2), "Options", 1) or automation_tab
local awareness_group = create_group(create_group(automation_tab, "Awareness", 3), "Filters", 1) or automation_tab
local visuals_group = create_group(create_group(automation_tab, "Visuals", 4), "Status", 1) or automation_tab

local priority_tab = safe_menu_create("Heroes", "Hero List", "Bristleback", "Auto Back", "Manual Priority")
if not priority_tab then
    priority_tab = automation_tab
end
safe_icon(priority_tab, HERO_ICON)
local priority_group = create_group(create_group(priority_tab, "Enemy Targets", 5), "List", 1) or priority_tab

local ui = {}
ui.enabled = general_group:Switch("Enable auto back", true, HERO_ICON)
ui.idle_delay = general_group:Slider("Idle takeover delay", 0, 3000, 650, function(value)
    return string.format("%.1f s", value / 1000)
end)
ui.recheck_rate = general_group:Slider("Retarget interval", 100, 1500, 250, function(value)
    return string.format("%d ms", value)
end)
ui.turn_distance = general_group:Slider("Turn step distance", 25, 300, 110, "%d")
ui.hold_delay = general_group:Slider("Hold order delay", 0, 1200, 220, function(value)
    return string.format("%d ms", value)
end)

ui.pause_casting = behavior_group:Switch("Pause while casting", true)
ui.pause_attacking = behavior_group:Switch("Pause while attacking", true)
ui.pause_moving = behavior_group:Switch("Pause while moving", true)
ui.keep_sticky = behavior_group:Switch("Keep last valid target", true)
ui.back_angle = behavior_group:Slider("Back alignment tolerance", 10, 90, 32, function(value)
    return string.format("%d°", value)
end)

ui.search_radius = awareness_group:Slider("Detection radius", 200, 1600, 900, "%d")
ui.ignore_invisible = awareness_group:Switch("Ignore unseen enemies", true)
ui.ignore_illusions = awareness_group:Switch("Ignore illusions", true)
ui.require_idle = awareness_group:Switch("Only turn while idle", true)

ui.render_status = visuals_group:Switch("Render status text", false)
ui.status_color = visuals_group:ColorPicker("Status color", 255, 220, 100, 210)

ui.enabled:ToolTip("Automatically pivots Bristleback so his rear faces the most threatening enemy when you are idle.")
ui.idle_delay:ToolTip("Delay after your last manual order before automation takes control.")
ui.recheck_rate:ToolTip("How often the script re-evaluates which enemy to face.")
ui.turn_distance:ToolTip("Distance in front of Bristleback used for the turning move command.")
ui.hold_delay:ToolTip("Optional delay before issuing a hold command to cancel unwanted walking.")
ui.pause_casting:ToolTip("Skip automation while Bristleback is casting abilities or items.")
ui.pause_attacking:ToolTip("Skip automation while Bristleback is attacking a target.")
ui.pause_moving:ToolTip("Skip automation while Bristleback is already moving under manual orders.")
ui.keep_sticky:ToolTip("Keep focusing the last valid target until it becomes invalid.")
ui.back_angle:ToolTip("Maximum allowed angle difference between Bristleback's rear and the enemy.")
ui.search_radius:ToolTip("Maximum distance to consider enemy heroes for auto turning.")
ui.ignore_invisible:ToolTip("Ignore enemies that are currently not visible.")
ui.ignore_illusions:ToolTip("Ignore illusions when selecting a target.")
ui.require_idle:ToolTip("Only attempt to turn when Bristleback appears idle or has stopped moving.")
ui.render_status:ToolTip("Draw the current automation status near Bristleback.")

local enemy_controls = {}
local last_refresh_time = -1
local last_manual_order_time = -math.huge
local last_auto_order_time = -math.huge
local next_hold_time = 0
local pending_hold = false
local current_target = nil
local status_font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_OUTLINE)

local function npc_is_moving(hero)
    if NPC.IsMoving then
        return NPC.IsMoving(hero)
    end
    if Entity.GetVelocity then
        local velocity = Entity.GetVelocity(hero)
        return velocity and (velocity:Length() > 0.5)
    end
    return false
end

local function npc_is_channeling(hero)
    if NPC.IsChannelingAbility then
        return NPC.IsChannelingAbility(hero)
    end
    return false
end

local function npc_is_attacking(hero)
    if NPC.IsAttacking then
        return NPC.IsAttacking(hero)
    end
    return false
end

local function npc_is_dormant(hero)
    if NPC.IsDormant then
        return NPC.IsDormant(hero)
    end
    return false
end

local function npc_is_illusion(hero)
    if NPC.IsIllusion then
        return NPC.IsIllusion(hero)
    end
    return false
end

local function now()
    if GameRules and GameRules.GetGameTime then
        return GameRules.GetGameTime()
    end
    return 0
end

local function get_display_name(unit_name)
    if not unit_name then
        return "Unknown"
    end
    local display_name = Engine.GetDisplayNameByUnitName and Engine.GetDisplayNameByUnitName(unit_name)
    if display_name and display_name ~= "" then
        return display_name
    end
    return unit_name
end

local function refresh_enemy_controls(local_hero, t)
    if not priority_group or not local_hero then
        return
    end

    if last_refresh_time > 0 and (t - last_refresh_time) < 0.5 then
        return
    end
    last_refresh_time = t

    local seen = {}
    local enemies = Heroes.GetAll() or {}
    for i = 1, #enemies do
        local hero = enemies[i]
        if hero and hero ~= local_hero and Entity.IsHero(hero) and not Entity.IsSameTeam(hero, local_hero) then
            local idx = Entity.GetIndex(hero)
            seen[idx] = hero
            if not enemy_controls[idx] then
                local name = get_display_name(NPC.GetUnitName(hero))
                local hero_group = priority_group:Create(name)
                if hero_group then
                    safe_icon(hero_group, "panorama/images/heroes/icons/" .. (NPC.GetUnitName(hero) or "npc_dota_hero_bristleback") .. "_png.vtex_c")
                    local entry = {
                        hero = hero,
                        switch = hero_group:Switch("Enable", true),
                        priority = hero_group:Slider("Priority", 0, 10, 5, "%d")
                    }
                    if entry.switch then
                        entry.switch:ToolTip("Toggle whether automation should consider this enemy hero.")
                    end
                    if entry.priority then
                        entry.priority:ToolTip("Higher values make the automation prefer this hero over others in range.")
                    end
                    enemy_controls[idx] = entry
                end
            else
                enemy_controls[idx].hero = hero
            end
        end
    end

    for idx, entry in pairs(enemy_controls) do
        if not seen[idx] then
            enemy_controls[idx] = nil
        end
    end
end

local function is_enemy_valid(local_hero, enemy)
    if not enemy or not local_hero then
        return false
    end
    if not Entity.IsAlive(enemy) then
        return false
    end
    if npc_is_dormant(enemy) then
        return false
    end
    if ui.ignore_invisible:Get() and not Entity.IsVisible(enemy) then
        return false
    end
    if ui.ignore_illusions:Get() and npc_is_illusion(enemy) then
        return false
    end
    if Entity.IsSameTeam(enemy, local_hero) then
        return false
    end
    return true
end

local function get_priority_for(enemy)
    if not enemy then
        return -math.huge
    end
    local idx = Entity.GetIndex(enemy)
    local entry = enemy_controls[idx]
    if not entry then
        return 0
    end
    if entry.switch and not entry.switch:Get() then
        return -math.huge
    end
    if entry.priority then
        return entry.priority:Get()
    end
    return 0
end

local function angle_of(vec)
    return math.atan2(vec.y, vec.x)
end

local function normalize_radians(angle)
    while angle > math.pi do
        angle = angle - 2 * math.pi
    end
    while angle < -math.pi do
        angle = angle + 2 * math.pi
    end
    return angle
end

local function degrees(angle)
    return angle * 180 / math.pi
end

local function angle_between(a, b)
    return degrees(math.abs(normalize_radians(a - b)))
end

local function get_forward_angle(hero)
    local forward = Entity.GetForward(hero)
    if not forward then
        return 0
    end
    return angle_of(forward)
end

local function get_back_angle(hero)
    local forward_angle = get_forward_angle(hero)
    return normalize_radians(forward_angle + math.pi)
end

local function is_idle(hero)
    if not hero then
        return false
    end
    if NPC.IsStunned(hero) then
        return false
    end
    if ui.pause_casting:Get() and npc_is_channeling(hero) then
        return false
    end
    if ui.pause_attacking:Get() and npc_is_attacking(hero) then
        return false
    end
    if ui.pause_moving:Get() and npc_is_moving(hero) then
        return false
    end
    if ui.require_idle:Get() then
        return not npc_is_moving(hero)
    end
    return true
end

local function select_target(local_hero, t)
    local origin = Entity.GetAbsOrigin(local_hero)
    if not origin then
        return nil
    end

    local best, best_score = nil, -math.huge
    local heroes = Heroes.GetAll() or {}
    local radius = ui.search_radius:Get()
    for i = 1, #heroes do
        local enemy = heroes[i]
        if enemy and enemy ~= local_hero and is_enemy_valid(local_hero, enemy) then
            local enemy_origin = Entity.GetAbsOrigin(enemy)
            if enemy_origin then
                local distance = (enemy_origin - origin):Length2D()
                if distance <= radius then
                    local priority = get_priority_for(enemy)
                    if priority > -math.huge then
                        local score = priority * 1000 - distance
                        if score > best_score then
                            best = enemy
                            best_score = score
                        end
                    end
                end
            end
        end
    end

    if best then
        return {
            enemy = best,
            acquired = t
        }
    end
    return nil
end

local function ensure_target(local_hero, t)
    if current_target and current_target.enemy then
        if not is_enemy_valid(local_hero, current_target.enemy) then
            current_target = nil
        else
            local origin = Entity.GetAbsOrigin(local_hero)
            local enemy_origin = Entity.GetAbsOrigin(current_target.enemy)
            if origin and enemy_origin then
                if (enemy_origin - origin):Length2D() > ui.search_radius:Get() * 1.1 then
                    current_target = nil
                end
            end
        end
    end

    if current_target then
        return current_target
    end

    local new_target = select_target(local_hero, t)
    current_target = new_target
    return current_target
end

local function issue_turn_order(local_hero, target, t)
    local hero_origin = Entity.GetAbsOrigin(local_hero)
    local enemy_origin = Entity.GetAbsOrigin(target.enemy)
    if not hero_origin or not enemy_origin then
        return
    end

    local direction = (enemy_origin - hero_origin):Normalized()
    local move_position = hero_origin - direction:Scaled(ui.turn_distance:Get())

    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, move_position, nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, local_hero)

    last_auto_order_time = t
    if ui.hold_delay:Get() > 0 then
        next_hold_time = t + ui.hold_delay:Get() / 1000
        pending_hold = true
    else
        pending_hold = false
    end
end

local function issue_hold_order(local_hero, t)
    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION, nil, nil, nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, local_hero)
    pending_hold = false
    last_auto_order_time = t
end

function bristleback_auto_back.OnPrepareUnitOrders(order)
    if not order or not order.units then
        return
    end
    local local_hero = Heroes.GetLocal()
    if not local_hero then
        return
    end
    for i = 1, #order.units do
        if order.units[i] == local_hero then
            last_manual_order_time = now()
            pending_hold = false
            next_hold_time = 0
            if not ui.keep_sticky:Get() then
                current_target = nil
            end
            break
        end
    end
end

function bristleback_auto_back.OnUpdate()
    local local_hero = Heroes.GetLocal()
    if not local_hero then
        return
    end

    if NPC.GetUnitName(local_hero) ~= HERO_NAME then
        return
    end

    if not Entity.IsAlive(local_hero) then
        return
    end

    if not ui.enabled:Get() then
        return
    end

    local t = now()
    refresh_enemy_controls(local_hero, t)

    local idle_delay = ui.idle_delay:Get() / 1000
    if t - last_manual_order_time < idle_delay then
        return
    end

    if not is_idle(local_hero) then
        return
    end

    local target = ensure_target(local_hero, t)
    if not target or not target.enemy then
        return
    end

    local hero_origin = Entity.GetAbsOrigin(local_hero)
    local enemy_origin = Entity.GetAbsOrigin(target.enemy)
    if not hero_origin or not enemy_origin then
        return
    end

    local to_enemy = (enemy_origin - hero_origin)
    if to_enemy:Length2D() < 1 then
        return
    end
    local enemy_angle = angle_of(to_enemy)
    local back_angle = get_back_angle(local_hero)
    local delta = angle_between(enemy_angle, back_angle)

    if delta > ui.back_angle:Get() then
        if (t - last_auto_order_time) * 1000 >= ui.recheck_rate:Get() then
            issue_turn_order(local_hero, target, t)
        end
    elseif pending_hold and t >= next_hold_time then
        issue_hold_order(local_hero, t)
    else
        pending_hold = false
    end
end

function bristleback_auto_back.OnDraw()
    if not ui.render_status:Get() then
        return
    end

    if not Render or not Render.WorldToScreen then
        return
    end

    local local_hero = Heroes.GetLocal()
    if not local_hero or NPC.GetUnitName(local_hero) ~= HERO_NAME then
        return
    end

    local position = Entity.GetAbsOrigin(local_hero)
    if not position then
        return
    end

    local screen = Render.WorldToScreen(position)
    if not screen then
        return
    end

    local status_text
    if not ui.enabled:Get() then
        status_text = "Auto Back: Off"
    else
        if current_target and current_target.enemy then
            local name = get_display_name(NPC.GetUnitName(current_target.enemy))
            status_text = string.format("Auto Back: %s", name)
        else
            status_text = "Auto Back: Idle"
        end
    end

    local color = ui.status_color:Get()
    local size = Render.TextSize(status_font, 16, status_text)
    local pos = Vec2(screen.x - size.x / 2, screen.y - 45)
    Render.Text(status_font, 16, status_text, Vec2(pos.x + 1, pos.y + 1), Color(0, 0, 0, 200))
    Render.Text(status_font, 16, status_text, pos, color)
end

return bristleback_auto_back
