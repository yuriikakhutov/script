---@diagnostic disable: undefined-global, lowercase-global

local bristle_auto_back = {}

local HERO_NAME = "npc_dota_hero_bristleback"
local HERO_ICON = "panorama/images/heroes/icons/" .. HERO_NAME .. "_png.vtex_c"
local ORDER_IDENTIFIER = "bristleback_auto_back_order"

local automation_tab = Menu.Create("Heroes", "Hero List", "Bristleback", "Auto Back", "Automation")
automation_tab:Icon(HERO_ICON)
local general_group = automation_tab:Create("General")
local behavior_group = automation_tab:Create("Behavior")
local awareness_group = automation_tab:Create("Awareness")

local priority_tab = Menu.Create("Heroes", "Hero List", "Bristleback", "Auto Back", "Manual Priority")
priority_tab:Icon(HERO_ICON)
local priority_group = priority_tab:Create("Enemy Targets", 1)

local ui = {}
ui.enabled = general_group:Switch("Enable", true, HERO_ICON)
ui.radius = general_group:Slider("Enemy detection radius", 300, 2000, 900, "%d")
ui.min_enemies = general_group:Slider("Minimum enemies nearby", 1, 5, 1, "%d")
ui.idle_delay = general_group:Slider("Idle delay", 0, 2000, 350, function(value)
    return string.format("%d ms", value)
end)
ui.angle_tolerance = general_group:Slider("Angle tolerance", 5, 90, 25, function(value)
    return string.format("%d°", value)
end)
ui.turn_distance = general_group:Slider("Turn offset distance", 15, 180, 70, "%d")
ui.hold_delay = general_group:Slider("Hold delay", 0, 600, 150, function(value)
    return string.format("%d ms", value)
end)

ui.order_cooldown = behavior_group:Slider("Minimum delay between orders", 0, 1000, 200, function(value)
    return string.format("%d ms", value)
end)
ui.pause_running = behavior_group:Switch("Pause while moving", true, HERO_ICON)
ui.pause_attacking = behavior_group:Switch("Pause while attacking", true, HERO_ICON)
ui.pause_casting = behavior_group:Switch("Pause while casting", true, HERO_ICON)
ui.pause_turning = behavior_group:Switch("Pause while already turning", true, HERO_ICON)
ui.sticky_time = behavior_group:Slider("Target stick duration", 0, 3000, 600, function(value)
    return string.format("%d ms", value)
end)

ui.ignore_invisible = awareness_group:Switch("Ignore invisible enemies", true, HERO_ICON)
ui.include_illusions = awareness_group:Switch("Include illusions", false, HERO_ICON)
ui.max_priority = awareness_group:Slider("Maximum priority value", 1, 10, 10, function(value)
    return string.format("≤ %d", value)
end)
ui.render_status = awareness_group:Switch("Render status", false, HERO_ICON)

ui.enabled:ToolTip("Automatically keep Bristleback's rear toward nearby enemies when idle.")
ui.radius:ToolTip("Maximum distance to scan for enemy heroes.")
ui.min_enemies:ToolTip("Only turn when at least this many valid enemies are nearby.")
ui.idle_delay:ToolTip("Required time since last player order before automation takes over.")
ui.angle_tolerance:ToolTip("How closely Bristleback must face away before no turn is sent.")
ui.turn_distance:ToolTip("Short movement offset to force Bristleback to turn.")
ui.hold_delay:ToolTip("Delay before sending Hold Position after turning.")
ui.order_cooldown:ToolTip("Minimum delay between automated orders to avoid stutter.")
ui.pause_running:ToolTip("Skip turning if Bristleback is already moving under player control.")
ui.pause_attacking:ToolTip("Skip turning while Bristleback is attacking.")
ui.pause_casting:ToolTip("Skip turning while Bristleback is channeling or casting.")
ui.pause_turning:ToolTip("Skip new orders while Bristleback is already turning.")
ui.sticky_time:ToolTip("Keep focusing the same enemy for the configured duration.")
ui.ignore_invisible:ToolTip("Ignore enemies that are currently not visible.")
ui.include_illusions:ToolTip("Allow illusion heroes to be considered as threats.")
ui.max_priority:ToolTip("Enemies with a higher manual priority value are ignored.")
ui.render_status:ToolTip("Draw the current automation state above Bristleback.")

local enemy_controls = {}
local next_priority_seed = 1
local last_refresh_time = -1
local last_user_order_time = -1000
local last_auto_order_time = -1000
local pending_hold_time = 0
local tracked_target = nil
local tracked_target_expire = 0
local status_font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_OUTLINE)

local function clamp(value, min_value, max_value)
    if value < min_value then return min_value end
    if value > max_value then return max_value end
    return value
end

local function is_entity_moving(entity)
    if NPC.IsRunning then
        return NPC.IsRunning(entity)
    end
    if Entity.IsMoving then
        return Entity.IsMoving(entity)
    end
    if Entity.GetVelocity then
        local velocity = Entity.GetVelocity(entity)
        if velocity then
            return velocity:Length2D() > 5
        end
    end
    return false
end

local function is_entity_turning(entity)
    if NPC.IsTurning then
        return NPC.IsTurning(entity)
    end
    if Entity.IsTurning then
        return Entity.IsTurning(entity)
    end
    return false
end

local function get_display_name(unit_name)
    local name = Engine.GetDisplayNameByUnitName(unit_name)
    if name and name ~= "" then
        return name
    end
    local readable = unit_name:gsub("npc_dota_hero_", "")
    readable = readable:gsub("_", " ")
    return readable:sub(1, 1):upper() .. readable:sub(2)
end

local function refresh_enemy_controls(local_hero, current_time)
    if not local_hero then
        return
    end

    if last_refresh_time > 0 and current_time - last_refresh_time < 0.5 then
        return
    end
    last_refresh_time = current_time

    for _, entry in pairs(enemy_controls) do
        entry.hero = nil
    end

    local heroes = Heroes.GetAll()
    for i = 1, #heroes do
        local hero = heroes[i]
        if hero and hero ~= local_hero and Entity.IsHero(hero) and not Entity.IsSameTeam(hero, local_hero) then
            local unit_name = NPC.GetUnitName(hero)
            if unit_name then
                local controls = enemy_controls[unit_name]
                if not controls then
                    local display_name = get_display_name(unit_name)
                    local icon_path = "panorama/images/heroes/icons/" .. unit_name .. "_png.vtex_c"
                    local enable_switch = priority_group:Switch(display_name .. " enabled", true, icon_path)
                    enable_switch:ToolTip("Toggle consideration of this enemy hero.")
                    local priority_slider = priority_group:Slider(display_name .. " priority", 1, 10, next_priority_seed, function(value)
                        return string.format("#%d", value)
                    end)
                    priority_slider:ToolTip("Lower numbers are handled first when multiple enemies are nearby.")
                    enable_switch:SetCallback(function()
                        priority_slider:Disabled(not enable_switch:Get())
                    end, true)
                    enemy_controls[unit_name] = {
                        hero = hero,
                        switch = enable_switch,
                        slider = priority_slider,
                        icon = icon_path,
                    }
                    next_priority_seed = clamp(next_priority_seed + 1, 1, 10)
                else
                    controls.hero = hero
                end
            end
        end
    end

    for _, controls in pairs(enemy_controls) do
        local visible = controls.hero ~= nil
        controls.switch:Visible(visible)
        controls.slider:Visible(visible)
        controls.slider:Disabled(not controls.switch:Get())
    end
end

local function should_pause_for_player(local_hero)
    if ui.pause_running:Get() and is_entity_moving(local_hero) then return true end
    if ui.pause_attacking:Get() and NPC.IsAttacking(local_hero) then return true end
    if ui.pause_casting:Get() and NPC.IsChannellingAbility(local_hero) then return true end
    if ui.pause_turning:Get() and is_entity_turning(local_hero) then return true end
    return false
end

local function is_ready_for_order(current_time)
    local cooldown = ui.order_cooldown:Get() / 1000.0
    if current_time - last_auto_order_time < cooldown then
        return false
    end
    return true
end

local function enemy_is_valid(enemy)
    return enemy and Entity.IsHero(enemy) and Entity.IsAlive(enemy)
end

local function passes_awareness_filters(enemy)
    if not enemy then return false end
    if NPC.IsIllusion(enemy) and not ui.include_illusions:Get() then
        return false
    end
    if ui.ignore_invisible:Get() and not Entity.IsVisible(enemy) then
        return false
    end
    local unit_name = NPC.GetUnitName(enemy)
    if not unit_name then
        return false
    end
    local controls = enemy_controls[unit_name]
    if not controls or not controls.switch:Get() then
        return false
    end
    if controls.slider:Get() > ui.max_priority:Get() then
        return false
    end
    return true
end

local function select_target(local_hero)
    local hero_position = Entity.GetAbsOrigin(local_hero)
    local detection_radius = ui.radius:Get()

    local best_target = nil
    local best_priority = math.huge
    local best_distance = math.huge
    local candidate_count = 0

    local heroes = Heroes.GetAll()
    for i = 1, #heroes do
        local enemy = heroes[i]
        if enemy and enemy ~= local_hero and Entity.IsHero(enemy) and not Entity.IsSameTeam(enemy, local_hero) then
            local delta = Entity.GetAbsOrigin(enemy) - hero_position
            local distance = delta:Length2D()
            if distance <= detection_radius then
                if enemy_is_valid(enemy) and passes_awareness_filters(enemy) then
                    candidate_count = candidate_count + 1
                    local unit_name = NPC.GetUnitName(enemy)
                    local controls = enemy_controls[unit_name]
                    local priority = controls and controls.slider:Get() or math.huge

                    if priority < best_priority or (priority == best_priority and distance < best_distance) then
                        best_target = enemy
                        best_priority = priority
                        best_distance = distance
                    end
                end
            end
        end
    end

    return best_target, candidate_count
end

local function issue_turn_orders(local_player, local_hero, desired_forward)
    local hero_position = Entity.GetAbsOrigin(local_hero)
    local turn_offset = desired_forward:Normalized():Scaled(ui.turn_distance:Get())
    local move_position = hero_position + turn_offset

    Player.PrepareUnitOrders(
        local_player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        move_position,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_CURRENT_UNIT_ONLY,
        local_hero,
        false,
        false,
        true,
        true,
        ORDER_IDENTIFIER,
        false
    )

    last_auto_order_time = GameRules.GetGameTime()
    pending_hold_time = last_auto_order_time + (ui.hold_delay:Get() / 1000.0)
end

function bristle_auto_back.OnPrepareUnitOrders(data)
    if not data or data.identifier == ORDER_IDENTIFIER then
        return true
    end

    local local_player = Players.GetLocal()
    if not local_player or data.player ~= local_player then
        return true
    end

    local local_hero = Heroes.GetLocal()
    if data.npc and local_hero and data.npc == local_hero then
        last_user_order_time = GameRules.GetGameTime()
        pending_hold_time = 0
    end

    return true
end

function bristle_auto_back.OnUpdate()
    local local_hero = Heroes.GetLocal()
    if not local_hero or NPC.GetUnitName(local_hero) ~= HERO_NAME then
        tracked_target = nil
        pending_hold_time = 0
        return
    end

    if not Entity.IsAlive(local_hero) or NPC.IsIllusion(local_hero) then
        tracked_target = nil
        pending_hold_time = 0
        return
    end

    local current_time = GameRules.GetGameTime()

    if pending_hold_time > 0 and current_time >= pending_hold_time then
        local local_player = Players.GetLocal()
        if local_player then
            Player.HoldPosition(local_player, local_hero, false, true, true, ORDER_IDENTIFIER)
        end
        pending_hold_time = 0
        last_auto_order_time = current_time
    end

    if not ui.enabled:Get() then
        tracked_target = nil
        return
    end

    refresh_enemy_controls(local_hero, current_time)

    if tracked_target and current_time >= tracked_target_expire then
        tracked_target = nil
    end

    local idle_delay = ui.idle_delay:Get() / 1000.0
    if current_time - last_user_order_time < idle_delay then
        return
    end

    if should_pause_for_player(local_hero) then
        return
    end

    if not is_ready_for_order(current_time) then
        return
    end

    local best_candidate, candidate_count = select_target(local_hero)
    if candidate_count < ui.min_enemies:Get() then
        tracked_target = nil
        return
    end

    local hero_position = Entity.GetAbsOrigin(local_hero)
    local target = tracked_target

    if target then
        if not enemy_is_valid(target) or not passes_awareness_filters(target) then
            target = nil
            tracked_target = nil
        else
            local distance = (Entity.GetAbsOrigin(target) - hero_position):Length2D()
            if distance > ui.radius:Get() + 50 then
                target = nil
                tracked_target = nil
            end
        end
    end

    if not target then
        target = best_candidate
        if target and ui.sticky_time:Get() > 0 then
            tracked_target = target
            tracked_target_expire = current_time + (ui.sticky_time:Get() / 1000.0)
        end
    end

    if not target then
        return
    end

    local enemy_position = Entity.GetAbsOrigin(target)
    local direction_to_enemy = enemy_position - hero_position
    if direction_to_enemy:Length2D() < 1 then
        return
    end

    local desired_forward = (hero_position - enemy_position)
    if desired_forward:Length2D() < 1 then
        return
    end

    desired_forward = desired_forward:Normalized()
    local current_forward = Entity.GetRotation(local_hero):GetForward():Normalized()
    local dot = clamp(current_forward:Dot2D(desired_forward), -1, 1)
    local angle_difference = math.deg(math.acos(dot))
    if angle_difference <= ui.angle_tolerance:Get() then
        return
    end

    local local_player = Players.GetLocal()
    if not local_player then
        return
    end

    issue_turn_orders(local_player, local_hero, desired_forward)

    if ui.sticky_time:Get() > 0 then
        tracked_target = target
        tracked_target_expire = current_time + (ui.sticky_time:Get() / 1000.0)
    end
end

function bristle_auto_back.OnDraw()
    if not ui.render_status:Get() then
        return
    end

    local local_hero = Heroes.GetLocal()
    if not local_hero or NPC.GetUnitName(local_hero) ~= HERO_NAME then
        return
    end

    local origin = Entity.GetAbsOrigin(local_hero)
    local screen = Render.WorldToScreen(origin + Vector(0, 0, 210))
    if not screen then
        return
    end

    local status_text
    if not ui.enabled:Get() then
        status_text = "Auto back: disabled"
    elseif tracked_target and passes_awareness_filters(tracked_target) then
        local unit_name = NPC.GetUnitName(tracked_target)
        local controls = unit_name and enemy_controls[unit_name]
        local display_name = unit_name and get_display_name(unit_name) or "Enemy"
        local priority = controls and controls.slider:Get() or 0
        status_text = string.format("Auto back → %s (#%d)", display_name, priority)
    else
        status_text = "Auto back: searching"
    end

    local pos = Vec2(math.floor(screen.x), math.floor(screen.y))
    Render.Text(status_font, 16, status_text, Vec2(pos.x + 1, pos.y + 1), Color(0, 0, 0, 180))
    Render.Text(status_font, 16, status_text, pos, Color(245, 245, 247, 255))
end

return bristle_auto_back
