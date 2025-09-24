---@diagnostic disable: undefined-global, lowercase-global

local script = {}

local HERO_NAME = "npc_dota_hero_bristleback"
local TURN_DISTANCE = 140
local DETECTION_RADIUS = 900
local IDLE_DELAY = 0.4
local MANUAL_PAUSE = 0.6
local REISSUE_INTERVAL = 0.25
local HOLD_DELAY = 0.2
local STICK_TIME = 1.0
local MOVE_EPSILON = 5

local MANUAL_PRIORITY = {
    npc_dota_hero_phantom_assassin = 3,
    npc_dota_hero_legion_commander = 2,
    npc_dota_hero_sven = 2,
    npc_dota_hero_axe = 1,
}

local last_manual_order_time = -math.huge
local last_move_time = -math.huge
local last_turn_time = -math.huge
local pending_hold_time = nil
local current_target = nil
local current_target_until = -math.huge
local last_position = nil

local function now()
    if GameRules and GameRules.GetGameTime then
        return GameRules.GetGameTime()
    end
    return os.clock()
end

local function vector_distance(a, b)
    if not a or not b then
        return math.huge
    end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function is_enemy_hero(me, ent)
    if not me or not ent then
        return false
    end
    if not Entity.IsHero(ent) then
        return false
    end
    if not Entity.IsAlive(ent) then
        return false
    end
    if NPC.IsIllusion(ent) then
        return false
    end
    return Entity.GetTeamNum(ent) ~= Entity.GetTeamNum(me)
end

local function reset_state()
    pending_hold_time = nil
    current_target = nil
    current_target_until = -math.huge
end

local function mark_manual_input()
    last_manual_order_time = now()
    reset_state()
end

function script.OnPrepareUnitOrders(event)
    if not event then
        return
    end
    if event.issuer and event.issuer ~= Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY then
        return
    end
    if event.player and event.player ~= Players.GetLocal() then
        return
    end
    mark_manual_input()
end

local function should_pause(current_time)
    local pause_until = last_manual_order_time + MANUAL_PAUSE
    local move_pause = last_move_time + IDLE_DELAY
    if move_pause > pause_until then
        pause_until = move_pause
    end
    return current_time < pause_until
end

local function choose_target(hero, hero_pos, current_time)
    local best_target = nil
    local best_priority = -math.huge
    local best_distance = math.huge

    local count = Heroes.Count() or 0
    for i = 1, count do
        local enemy = Heroes.Get(i)
        if is_enemy_hero(hero, enemy) then
            local enemy_pos = Entity.GetAbsOrigin(enemy)
            local distance = vector_distance(enemy_pos, hero_pos)
            if distance <= DETECTION_RADIUS then
                local key = NPC.GetUnitName(enemy) or ""
                local priority = MANUAL_PRIORITY[key] or 0
                if current_target == enemy and current_time <= current_target_until then
                    priority = priority + 1000
                end
                if priority > best_priority or (priority == best_priority and distance < best_distance) then
                    best_priority = priority
                    best_distance = distance
                    best_target = enemy
                end
            end
        end
    end

    return best_target
end

local function issue_move_order(hero, target_pos)
    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos or not target_pos then
        return false
    end
    local dx = (target_pos.x or 0) - (hero_pos.x or 0)
    local dy = (target_pos.y or 0) - (hero_pos.y or 0)
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then
        return false
    end
    local factor = TURN_DISTANCE / length
    local move_x = (hero_pos.x or 0) - dx * factor
    local move_y = (hero_pos.y or 0) - dy * factor
    local move_pos = Vector(move_x, move_y, hero_pos.z or 0)

    return Player.PrepareUnitOrders(
        Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        move_pos,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero
    )
end

local function issue_hold_order(hero)
    return Player.PrepareUnitOrders(
        Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION,
        nil,
        nil,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero
    )
end

local function maintain_target(hero, hero_pos)
    if not current_target then
        return nil
    end
    if not Entity.IsAlive(current_target) then
        return nil
    end
    local target_pos = Entity.GetAbsOrigin(current_target)
    if vector_distance(target_pos, hero_pos) > DETECTION_RADIUS then
        return nil
    end
    if NPC.IsIllusion(current_target) then
        return nil
    end
    return current_target
end

function script.OnUpdate()
    local hero = Heroes.GetLocal()
    if not hero or NPC.GetUnitName(hero) ~= HERO_NAME then
        reset_state()
        return
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    if not hero_pos then
        reset_state()
        return
    end

    local current_time = now()
    if last_position then
        if vector_distance(hero_pos, last_position) > MOVE_EPSILON then
            last_move_time = current_time
        end
    else
        last_move_time = current_time
    end
    last_position = hero_pos

    if pending_hold_time and current_time >= pending_hold_time then
        if issue_hold_order(hero) then
            pending_hold_time = nil
        else
            pending_hold_time = current_time + 0.2
        end
    end

    if should_pause(current_time) then
        return
    end

    local target = maintain_target(hero, hero_pos)
    if not target then
        target = choose_target(hero, hero_pos, current_time)
        if target then
            current_target = target
            current_target_until = current_time + STICK_TIME
        else
            current_target = nil
            return
        end
    end

    if (current_time - last_turn_time) < REISSUE_INTERVAL then
        return
    end

    local target_pos = Entity.GetAbsOrigin(target)
    if not target_pos then
        current_target = nil
        return
    end

    if issue_move_order(hero, target_pos) then
        last_turn_time = current_time
        pending_hold_time = current_time + HOLD_DELAY
    end
end

return script
