---@diagnostic disable: undefined-global, lowercase-global

local bristle_turn = {}

local HERO_NAME = "npc_dota_hero_bristleback"
local ORDER_IDENTIFIER = "bristleback_auto_turn"
local HERO_ICON = "panorama/images/heroes/icons/" .. HERO_NAME .. "_png.vtex_c"

local menu_tab = Menu.Create("Heroes", "Bristleback", "Auto Back", "Main")
local general_group = menu_tab:Create("General")
local priority_group = menu_tab:Create("Manual Priority", 1)

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

ui.idle_delay:ToolTip("Minimal time without player input before script acts.")
ui.radius:ToolTip("Maximum distance to scan for enemy heroes.")
ui.angle_tolerance:ToolTip("How precise Bristleback should face away from the current threat.")
ui.turn_distance:ToolTip("Offset distance used for short movement order that forces the turn.")
ui.hold_delay:ToolTip("Delay before sending Hold Position after the turn movement order.")

local next_priority_default = 1
local enemy_controls = {}
local last_user_order_time = -1000
local last_auto_order_time = -1000
local pending_hold_time = 0

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
            if not NPC.IsIllusion(hero) then
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
        if enemy and Entity.IsHero(enemy) and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
            local unit_name = NPC.GetUnitName(enemy)
            local controls = unit_name and enemy_controls[unit_name]
            if controls and controls.switch:Get() then
                local priority = controls.slider:Get()
                local distance = Entity.GetAbsOrigin(enemy):Distance2D(hero_position)
                if priority < best_priority or (priority == best_priority and distance < best_distance) then
                    best_target = enemy
                    best_priority = priority
                    best_distance = distance
                end
            end
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
    if NPC.IsRunning(local_hero) then return false end
    if NPC.IsAttacking(local_hero) then return false end
    if NPC.IsChannellingAbility(local_hero) then return false end
    if NPC.IsTurning(local_hero) then return false end
    return true
end

local function is_ready_for_new_order(current_time)
    if current_time - last_auto_order_time < 0.2 then
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
        return
    end

    if not Entity.IsAlive(local_hero) or NPC.IsIllusion(local_hero) then
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

    if not ui.enable:Get() then
        pending_hold_time = 0
        return
    end

    ensure_enemy_controls(local_hero)

    if current_time - last_user_order_time < (ui.idle_delay:Get() / 1000.0) then
        return
    end

    if not is_hero_idle(local_hero) then
        return
    end

    if not is_ready_for_new_order(current_time) then
        return
    end

    local target = get_best_target(local_hero)
    if not target then
        return
    end

    local hero_position = Entity.GetAbsOrigin(local_hero)
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
end

return bristle_turn
