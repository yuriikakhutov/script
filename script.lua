local agent_script = {}

local FOLLOW_DISTANCE = 300
local ORDER_COOLDOWN = 0.3

local my_hero = nil
local local_player = nil
local local_player_id = nil
local debug_font = nil

local followers = {}

local function ResetState()
    my_hero = nil
    local_player = nil
    local_player_id = nil
    followers = {}
end

local function EnsureFont()
    if not debug_font then
        debug_font = Render.LoadFont("Arial", 12, Enum.FontCreate.FONTFLAG_OUTLINE)
    end
    return debug_font
end

local function GetPlayerID()
    if not my_hero then
        return nil
    end

    local player_id = Hero.GetPlayerID(my_hero)
    if player_id == nil then
        local player = Players.GetLocal()
        if player then
            player_id = Player.GetPlayerID(player)
        end
    end

    return player_id
end

local function IsControlledUnit(unit)
    if not unit or not Entity.IsAlive(unit) then
        return false
    end

    if unit == my_hero then
        return false
    end

    if local_player_id and not NPC.IsControllableByPlayer(unit, local_player_id) then
        return false
    end

    local hero_team = Entity.GetTeamNum(my_hero)
    if Entity.GetTeamNum(unit) ~= hero_team then
        return false
    end

    return true
end

local function UpdateFollowers()
    local current_time = GlobalVars.GetCurTime()
    local next_followers = {}

    for _, unit in ipairs(NPCs.GetAll()) do
        if my_hero and IsControlledUnit(unit) then
            local handle = Entity.GetIndex(unit)
            local follower = followers[handle]
            if not follower then
                follower = {
                    unit = unit,
                    next_action_time = 0,
                }
            else
                follower.unit = unit
            end

            follower.last_seen_time = current_time
            next_followers[handle] = follower
        end
    end

    followers = next_followers
end

local function IssueFollowOrders()
    if not my_hero or not local_player then
        return
    end

    local hero_pos = Entity.GetAbsOrigin(my_hero)
    local current_time = GlobalVars.GetCurTime()

    for handle, follower in pairs(followers) do
        local unit = follower.unit
        if unit and Entity.IsAlive(unit) then
            if follower.next_action_time == nil then
                follower.next_action_time = 0
            end

            if current_time < follower.next_action_time then
                goto continue
            end

            local unit_pos = Entity.GetAbsOrigin(unit)
            local distance = hero_pos:Distance(unit_pos)

            if distance > FOLLOW_DISTANCE then
                Player.PrepareUnitOrders(
                    local_player,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    hero_pos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    unit
                )
                follower.last_action = "Двигаюсь к герою"
                follower.next_action_time = current_time + ORDER_COOLDOWN
            else
                follower.last_action = "В радиусе"
                follower.next_action_time = current_time + ORDER_COOLDOWN
            end
        end
        ::continue::
    end
end

function agent_script.OnUpdate()
    if not Engine.IsInGame() then
        ResetState()
        return
    end

    my_hero = Heroes.GetLocal()
    local_player = Players.GetLocal()

    if not my_hero or not Entity.IsAlive(my_hero) or not local_player then
        ResetState()
        return
    end

    local_player_id = GetPlayerID()
    if not local_player_id then
        return
    end

    UpdateFollowers()
    IssueFollowOrders()
end

function agent_script.OnDraw()
    if not my_hero then
        return
    end

    local font = EnsureFont()

    for _, follower in pairs(followers) do
        local unit = follower.unit
        if unit and Entity.IsAlive(unit) and follower.last_action then
            local unit_origin = Entity.GetAbsOrigin(unit)
            local offset = NPC.GetHealthBarOffset(unit) or 0
            local display_position = unit_origin + Vector(0, 0, offset + 20)
            local screen_position, is_visible = Render.WorldToScreen(display_position)
            if is_visible then
                Render.Text(font, 12, follower.last_action, screen_position, Color(180, 220, 255, 255))
            end
        end
    end
end

function agent_script.OnGameEnd()
    ResetState()
end

return agent_script
