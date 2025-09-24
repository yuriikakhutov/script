---@diagnostic disable: undefined-global, lowercase-global

local script = {}

local HERO_NAME = "npc_dota_hero_bristleback"

local ui = {}
local enemy_widgets = {}

local hero, player = nil, nil

local state = {
    last_activity_time = 0,
    last_turn_time = -math.huge,
    hold_after = 0,
    hold_sent = false,
    pause_until = 0,
    tracked_target = nil,
    stick_until = 0,
    next_refresh = 0,
}

local function now()
    if GameRules and GameRules.GetGameTime then
        return GameRules.GetGameTime()
    end
    return os.clock()
end

local function get_display_name(target)
    if not target then
        return "Unknown"
    end
    local unit_name = NPC.GetUnitName(target)
    if Engine and Engine.GetDisplayNameByUnitName then
        local pretty = Engine.GetDisplayNameByUnitName(unit_name)
        if pretty and #pretty > 0 then
            return pretty
        end
    end
    return unit_name or "Unknown"
end

local root = Menu.Create("Heroes", "Hero List", "Bristleback", "Auto Back")
root:Icon("\u{f0e7}")

local general = root:Create("General")
ui.enabled = general:Switch("Enabled", true)
ui.idle_delay = general:Slider("Idle delay", 0.0, 1.5, 0.3, "%.1f s")
ui.detection_radius = general:Slider("Detection radius", 300, 1600, 900, "%d")
ui.stick_time = general:Slider("Stick duration", 0.0, 3.0, 1.0, "%.1f s")

local behavior = root:Create("Behavior")
ui.angle_tolerance = behavior:Slider("Back angle tolerance", 5, 90, 25, "%d\u{00B0}")
ui.turn_distance = behavior:Slider("Turn move distance", 50, 350, 160, "%d")
ui.order_cooldown = behavior:Slider("Order cooldown", 0.1, 1.5, 0.45, "%.2f s")
ui.hold_delay = behavior:Slider("Hold delay", 0.0, 0.6, 0.20, "%.2f s")
ui.post_input_pause = behavior:Slider("Pause after player command", 0.0, 1.5, 0.60, "%.2f s")

local awareness = root:Create("Awareness")
ui.require_vision = awareness:Switch("Require vision", false)
ui.ignore_illusions = awareness:Switch("Ignore illusions", true)

local manual = root:Create("Manual Priority")
manual:Label("Enemy priority settings")

local function ensure_enemy_widgets()
    local t = now()
    if t < state.next_refresh then
        return
    end
    state.next_refresh = t + 0.5

    if not hero then
        return
    end

    local list = Heroes and Heroes.GetAll and Heroes.GetAll()
    if not list then
        return
    end

    for i = 1, #list do
        local candidate = list[i]
        if candidate and candidate ~= hero and Entity.IsHero(candidate) and not Entity.IsSameTeam(candidate, hero) then
            local id = Entity.GetIndex(candidate)
            local entry = enemy_widgets[id]
            if not entry then
                local switch = manual:Switch(get_display_name(candidate), true)
                switch:Icon("\u{f140}")
                local gear = switch:Gear("Priority")
                local slider = gear:Slider("Weight", 0, 100, 50, "%.0f")
                slider:Icon("\u{f24e}")
                switch:SetCallback(function()
                    local enabled = switch:Get()
                    slider:Disabled(not enabled)
                end, true)
                enemy_widgets[id] = {
                    switch = switch,
                    weight = slider,
                }
            end
            enemy_widgets[id].entity = candidate
        end
    end
end

local function enemy_enabled(enemy)
    local idx = Entity.GetIndex(enemy)
    local entry = enemy_widgets[idx]
    if not entry then
        return true, 50
    end
    if not entry.switch:Get() then
        return false, 0
    end
    return true, entry.weight:Get()
end

local function ensure_locals()
    hero = Heroes and Heroes.GetLocal and Heroes.GetLocal() or nil
    if not hero then
        player = nil
        return false
    end
    if NPC.GetUnitName(hero) ~= HERO_NAME then
        hero = nil
        player = nil
        return false
    end
    player = Players and Players.GetLocal and Players.GetLocal() or nil
    return player ~= nil
end

local function target_valid(target)
    if not target then
        return false
    end
    if not Entity.IsHero(target) then
        return false
    end
    if not Entity.IsAlive(target) then
        return false
    end
    if Entity.IsSameTeam(target, hero) then
        return false
    end
    if ui.ignore_illusions:Get() and NPC.IsIllusion(target) then
        return false
    end
    if ui.require_vision:Get() and Entity.IsDormant(target) then
        return false
    end
    return true
end

local function is_back_toward(hero_pos, rotation, enemy_pos)
    if not rotation or not rotation.GetForward then
        return false
    end
    local forward = rotation:GetForward()
    if not forward then
        return false
    end
    forward.z = 0
    if forward:Length2D() == 0 then
        return false
    end
    local to_enemy = enemy_pos - hero_pos
    to_enemy.z = 0
    if to_enemy:Length2D() == 0 then
        return true
    end
    forward = forward:Normalized()
    to_enemy = to_enemy:Normalized()
    local back = forward * -1
    local dot = math.max(-1, math.min(1, back.x * to_enemy.x + back.y * to_enemy.y))
    local angle = math.deg(math.acos(dot))
    return angle <= ui.angle_tolerance:Get()
end

local function pick_target(origin)
    local t = now()
    if state.tracked_target and target_valid(state.tracked_target) then
        local dist = (Entity.GetAbsOrigin(state.tracked_target) - origin):Length2D()
        if dist <= ui.detection_radius:Get() then
            if t <= state.stick_until then
                return state.tracked_target
            end
        end
    end

    local omitIllusions = ui.ignore_illusions:Get()
    local omitDormant = ui.require_vision:Get()
    local nearby = Entity.GetHeroesInRadius(hero, ui.detection_radius:Get(), Enum.TeamType.TEAM_ENEMY, omitIllusions, omitDormant)

    local best, best_score = nil, -math.huge
    if nearby then
        for i = 1, #nearby do
            local enemy = nearby[i]
            if target_valid(enemy) then
                local enabled, weight = enemy_enabled(enemy)
                if enabled and weight > 0 then
                    local enemy_pos = Entity.GetAbsOrigin(enemy)
                    local distance = (enemy_pos - origin):Length2D()
                    local score = weight * 1000 - distance
                    if score > best_score then
                        best = enemy
                        best_score = score
                    end
                end
            end
        end
    end

    state.tracked_target = best
    if best then
        state.stick_until = t + ui.stick_time:Get()
    else
        state.stick_until = 0
    end
    return best
end

local function issue_turn_order(hero_pos, enemy_pos)
    local direction = hero_pos - enemy_pos
    direction.z = 0
    if direction:Length2D() == 0 then
        return false
    end
    direction = direction:Normalized()
    local destination = hero_pos + direction:Scaled(ui.turn_distance:Get())
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        destination,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero
    )
    state.last_turn_time = now()
    state.hold_after = state.last_turn_time + ui.hold_delay:Get()
    state.hold_sent = false
    state.last_activity_time = state.last_turn_time
    return true
end

local function try_hold()
    if state.hold_after <= 0 or state.hold_sent then
        return
    end
    if now() < state.hold_after then
        return
    end
    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION,
        nil,
        nil,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero
    )
    state.hold_sent = true
    state.hold_after = 0
    state.last_activity_time = now()
end

local function hero_restricted()
    if NPC.IsStunned(hero) then
        return true
    end
    if NPC.HasState and Enum and Enum.ModifierState and Enum.ModifierState.MODIFIER_STATE_COMMAND_RESTRICTED then
        if NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_COMMAND_RESTRICTED) then
            return true
        end
    end
    if NPC.HasState and Enum and Enum.ModifierState and Enum.ModifierState.MODIFIER_STATE_HEXED then
        if NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_HEXED) then
            return true
        end
    end
    return false
end

function script.OnUpdate()
    if not ensure_locals() then
        return
    end

    ensure_enemy_widgets()

    if not ui.enabled:Get() then
        state.tracked_target = nil
        return
    end

    if not Entity.IsAlive(hero) then
        state.tracked_target = nil
        return
    end

    local t = now()
    if state.last_activity_time == 0 then
        state.last_activity_time = t
    end

    if NPC.IsRunning(hero) or NPC.IsAttacking(hero) or NPC.IsChannellingAbility(hero) then
        state.last_activity_time = t
    end

    try_hold()

    if t < state.pause_until then
        return
    end

    if hero_restricted() then
        return
    end

    if t - state.last_activity_time < ui.idle_delay:Get() then
        return
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    local target = pick_target(hero_pos)
    if not target then
        return
    end

    local rotation = Entity.GetRotation(hero)
    local enemy_pos = Entity.GetAbsOrigin(target)
    if is_back_toward(hero_pos, rotation, enemy_pos) then
        return
    end

    if t - state.last_turn_time < ui.order_cooldown:Get() then
        return
    end

    issue_turn_order(hero_pos, enemy_pos)
end

function script.OnPrepareUnitOrders(order)
    if not hero or not ui.enabled:Get() then
        return true
    end

    if order and order.npc and order.npc == hero then
        local t = now()
        state.last_activity_time = t
        state.pause_until = t + ui.post_input_pause:Get()
        state.tracked_target = nil
        state.stick_until = 0
        state.hold_after = 0
        state.hold_sent = true
    end

    return true
end

return script
