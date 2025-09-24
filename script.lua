---@diagnostic disable: undefined-global, lowercase-global

local bristle_turn = {}

local HERO_NAME = "npc_dota_hero_bristleback"
local ORDER_IDENTIFIER = "bristleback_auto_turn"
local HERO_ICON = "panorama/images/heroes/icons/" .. HERO_NAME .. "_png.vtex_c"

local hero_menu = Menu.Create("Heroes", "Bristleback")
local auto_back_menu = hero_menu:Create("Auto Back")
local general_group = auto_back_menu:Create("General")
local behavior_group = auto_back_menu:Create("Behavior")
local awareness_group = auto_back_menu:Create("Awareness")
local priority_group = auto_back_menu:Create("Manual Priority", 1)

local ui = {}
ui.enable = general_group:Switch("Enable auto back", true, HERO_ICON)
ui.radius = general_group:Slider("Enemy detection radius", 300, 1600, 900, "%d")
ui.idle_delay = general_group:Slider("Idle delay", 0, 2000, 400, function(value)
    return string.format("%.0f ms", value)
end)
ui.angle_tolerance = general_group:Slider("Angle tolerance", 5, 90, 25, function(value)
    return string.format("%d°", value)
end)
ui.turn_distance = general_group:Slider("Turn offset distance", 15, 150, 60, "%d")
ui.hold_delay = general_group:Slider("Hold delay", 0, 500, 120, function(value)
    return string.format("%d ms", value)
end)
ui.order_cooldown = behavior_group:Slider("Minimum delay between orders", 0, 1000, 200, function(value)
    return string.format("%d ms", value)
end)
ui.pause_while_running = behavior_group:Switch("Require hero to be stationary", true, HERO_ICON)
ui.pause_while_attacking = behavior_group:Switch("Pause while attacking", true, HERO_ICON)
ui.pause_while_casting = behavior_group:Switch("Pause while channeling", true, HERO_ICON)
ui.pause_while_turning = behavior_group:Switch("Pause while already turning", true, HERO_ICON)
ui.sticky_time = behavior_group:Slider("Target stick duration", 0, 2000, 500, function(value)
    return string.format("%d ms", value)
end)
ui.ignore_invisible = awareness_group:Switch("Ignore enemies that are not visible", true, HERO_ICON)
ui.include_illusions = awareness_group:Switch("Consider enemy illusions", false, HERO_ICON)
ui.max_priority = awareness_group:Slider("Max priority value to consider", 1, 10, 10, function(value)
    return string.format("≤ %d", value)
end)

ui.idle_delay:ToolTip("Minimal time without player input before script acts.")
ui.radius:ToolTip("Maximum distance to scan for enemy heroes.")
ui.angle_tolerance:ToolTip("How precise Bristleback should face away from the current threat.")
ui.turn_distance:ToolTip("Offset distance used for short movement order that forces the turn.")
ui.hold_delay:ToolTip("Delay before sending Hold Position after the turn movement order.")
ui.order_cooldown:ToolTip("Minimum time between automation orders so the hero does not stutter.")
ui.pause_while_running:ToolTip("Wait for Bristleback to stop moving before forcing a turn.")
ui.pause_while_attacking:ToolTip("Skip turning while Bristleback is in an attack animation.")
ui.pause_while_casting:ToolTip("Skip turning while Bristleback is channeling spells.")
ui.pause_while_turning:ToolTip("Avoid issuing new orders if Bristleback is already turning.")
ui.sticky_time:ToolTip("Keep focusing the same enemy for the selected time window.")
ui.ignore_invisible:ToolTip("Prevent reacting to enemies that are currently not visible.")
ui.include_illusions:ToolTip("Allow illusions to be considered as threats.")
ui.max_priority:ToolTip("Ignore enemies whose manual priority is above this value.")

local next_priority_default = 1
local enemy_controls = {}
local last_user_order_time = -1000
local last_auto_order_time = -1000
local pending_hold_time = 0
local tracked_target = nil
local tracked_target_expire = 0

local function clamp(value, min_value, max_value)
    if value < min_value then return min_value end
    if value > max_value then return max_value end
    return value
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

local function ensure_enemy_controls(local_hero)
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
                    local priority_slider = priority_group:Slider(display_name .. " priority", 1, 10, next_priority_default, function(value)
                        return string.format("#%d", value)
                    end)
                    priority_slider:ToolTip("Lower number = higher priority when several enemies are nearby.")
                    enemy_controls[unit_name] = {
                        switch = enable_switch,
                        slider = priority_slider,
                        hero = hero,
                        display = display_name,
                    }
                    next_priority_default = clamp(next_priority_default + 1, 1, 10)
                else
                    controls.hero = hero
                end
            end
        end
    end

    for _, controls in pairs(enemy_controls) do
        local has_hero = controls.hero ~= nil
        controls.switch:Visible(has_hero)
        controls.slider:Visible(has_hero)
        controls.slider:Disabled(not controls.switch:Get())
    end
end

local function get_best_target(local_hero)
    local detection_radius = ui.radius:Get()
    local heroes_in_radius = Entity.GetHeroesInRadius(local_hero, detection_radius, Enum.TeamType.TEAM_ENEMY, true, true)
    if not heroes_in_radius or #heroes_in_radius == 0 then
        return nil
    end

    local hero_position = Entity.GetAbsOrigin(local_hero)
    local best_target = nil
    local best_priority = math.huge
    local best_distance = math.huge

    for i = 1, #heroes_in_radius do
        local enemy = heroes_in_radius[i]
        if enemy and Entity.IsHero(enemy) and Entity.IsAlive(enemy) then
            if NPC.IsIllusion(enemy) and not ui.include_illusions:Get() then
                goto continue
            end
            if ui.ignore_invisible:Get() and not Entity.IsVisible(enemy) then
                goto continue
            end
            local unit_name = NPC.GetUnitName(enemy)
            local controls = unit_name and enemy_controls[unit_name]
            if controls and controls.switch:Get() then
                local priority = controls.slider:Get()
                if priority > ui.max_priority:Get() then
                    goto continue
                end
                local distance = Entity.GetAbsOrigin(enemy):Distance2D(hero_position)
                if priority < best_priority or (priority == best_priority and distance < best_distance) then
                    best_target = enemy
                    best_priority = priority
                    best_distance = distance
                end
            end
            ::continue::
        end
    end

    return best_target
end

local function issue_turn_orders(local_player, local_hero, desired_forward)
    local hero_position = Entity.GetAbsOrigin(local_hero)
    local turn_offset = desired_forward:Normalized():Scaled(ui.turn_distance:Get())
    local target_position = hero_position + turn_offset

    Player.PrepareUnitOrders(
        local_player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        target_position,
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

local function is_hero_idle(local_hero)
    if ui.pause_while_running:Get() and NPC.IsRunning(local_hero) then return false end
    if ui.pause_while_attacking:Get() and NPC.IsAttacking(local_hero) then return false end
    if ui.pause_while_casting:Get() and NPC.IsChannellingAbility(local_hero) then return false end
    if ui.pause_while_turning:Get() and NPC.IsTurning(local_hero) then return false end
    return true
end

local function is_ready_for_new_order(current_time)
    local min_gap = ui.order_cooldown:Get() / 1000.0
    if current_time - last_auto_order_time < min_gap then
        return false
    end
    return true
end

function bristle_turn.OnPrepareUnitOrders(data)
    if not data or not data.player or data.player ~= Players.GetLocal() then
        return true
    end

    if data.identifier == ORDER_IDENTIFIER then
        return true
    end

    local local_hero = Heroes.GetLocal()
    if not local_hero then
        return true
    end

    if data.npc == local_hero then
        last_user_order_time = GameRules.GetGameTime()
        pending_hold_time = 0
    end

    return true
end

function bristle_turn.OnUpdate()
    local local_hero = Heroes.GetLocal()
    if not local_hero or NPC.GetUnitName(local_hero) ~= HERO_NAME then
        tracked_target = nil
        return
    end

    if not Entity.IsAlive(local_hero) or NPC.IsIllusion(local_hero) then
        pending_hold_time = 0
        tracked_target = nil
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

    if not ui.enable:Get() then
        pending_hold_time = 0
        tracked_target = nil
        return
    end

    ensure_enemy_controls(local_hero)

    if tracked_target and current_time >= tracked_target_expire then
        tracked_target = nil
    end

    if current_time - last_user_order_time < (ui.idle_delay:Get() / 1000.0) then
        return
    end

    if not is_hero_idle(local_hero) then
        return
    end

    if not is_ready_for_new_order(current_time) then
        return
    end

    local hero_position = Entity.GetAbsOrigin(local_hero)

    local target = tracked_target
    if target then
        if not Entity.IsHero(target) or not Entity.IsAlive(target) then
            target = nil
            tracked_target = nil
        else
            local unit_name = NPC.GetUnitName(target)
            local controls = unit_name and enemy_controls[unit_name]
            if not controls or not controls.switch:Get() then
                target = nil
                tracked_target = nil
            else
                local priority = controls.slider:Get()
                if priority > ui.max_priority:Get() then
                    target = nil
                    tracked_target = nil
                end
            end
        end
    end

    if target then
        if NPC.IsIllusion(target) and not ui.include_illusions:Get() then
            target = nil
            tracked_target = nil
        elseif ui.ignore_invisible:Get() and not Entity.IsVisible(target) then
            target = nil
            tracked_target = nil
        else
            local detection_radius = ui.radius:Get()
            local target_distance = Entity.GetAbsOrigin(target):Distance2D(hero_position)
            if target_distance > detection_radius + 50 then
                target = nil
                tracked_target = nil
            end
        end
    end

    if not target then
        target = get_best_target(local_hero)
        if target and ui.sticky_time:Get() > 0 then
            tracked_target = target
            tracked_target_expire = current_time + (ui.sticky_time:Get() / 1000.0)
        end
    end

    if not target then
        return
    end

    local enemy_position = Entity.GetAbsOrigin(target)
    local to_enemy = enemy_position - hero_position
    if to_enemy:Length2D() < 1 then
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
    if target and ui.sticky_time:Get() > 0 then
        tracked_target = target
        tracked_target_expire = current_time + (ui.sticky_time:Get() / 1000.0)
    end
end

return bristle_turn
