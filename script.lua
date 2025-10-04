local agent_script = {}

local FOLLOW_DISTANCE = 300
local ORDER_COOLDOWN = 0.3

local RAISE_DEAD_NAMES = {
    dark_troll_warlord_raise_dead = true,
    dark_troll_summoner_raise_dead = true,
    dark_troll_warlord_raise_dead_datadriven = true,
}

local tracked_units = {}

local my_hero = nil
local local_player = nil
local local_player_id = nil
local debug_font = nil

local function ResetState()
    tracked_units = {}
    my_hero = nil
    local_player = nil
    local_player_id = nil
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

    local hero_player_id = Hero.GetPlayerID(my_hero)
    if hero_player_id ~= nil then
        return hero_player_id
    end

    local player = Players.GetLocal()
    if player and type(Player.GetPlayerID) == "function" then
        return Player.GetPlayerID(player)
    end

    return nil
end

local function IsDarkTrollSummoner(unit)
    if not unit then
        return false
    end

    local unit_name = NPC.GetUnitName(unit)
    if not unit_name then
        return false
    end

    return unit_name == "npc_dota_neutral_dark_troll_warlord" or unit_name == "npc_dota_neutral_dark_troll_summoner"
end

local function IsControlledDarkTroll(unit)
    if not unit or not Entity.IsAlive(unit) then
        return false
    end

    if unit == my_hero then
        return false
    end

    if NPC.IsCourier(unit) then
        return false
    end

    if not IsDarkTrollSummoner(unit) then
        return false
    end

    if local_player_id and not NPC.IsControllableByPlayer(unit, local_player_id) then
        return false
    end

    if not my_hero then
        return false
    end

    return Entity.GetTeamNum(unit) == Entity.GetTeamNum(my_hero)
end

local function GetAbilityCharges(ability)
    if not ability then
        return nil
    end

    local readers = {
        "GetCurrentAbilityCharges",
        "GetCurrentCharges",
        "GetRemainingCharges",
        "GetCharges",
    }

    for _, reader in ipairs(readers) do
        local getter = Ability[reader]
        if type(getter) == "function" then
            local ok, value = pcall(getter, ability)
            if ok and type(value) == "number" then
                return value
            end
        end
    end

    return nil
end

local function FindRaiseDeadAbility(unit)
    if not unit then
        return nil
    end

    for slot = 0, 23 do
        local ability = NPC.GetAbilityByIndex(unit, slot)
        if ability then
            local name = Ability.GetName(ability)
            if name and RAISE_DEAD_NAMES[name] then
                return ability
            end
        end
    end

    return nil
end

local function TryCastRaiseDead(unit, data, current_time)
    local ability = FindRaiseDeadAbility(unit)
    if not ability then
        return false
    end

    if type(Ability.GetLevel) == "function" and Ability.GetLevel(ability) <= 0 then
        return false
    end

    local ready = false

    local charges = GetAbilityCharges(ability)
    if charges and charges > 0 then
        ready = true
    end

    if not ready then
        if type(Ability.IsReady) == "function" then
            ready = Ability.IsReady(ability)
        elseif type(Ability.IsCastable) == "function" then
            ready = Ability.IsCastable(ability, NPC.GetMana(unit))
        end
    end

    if not ready then
        return false
    end

    Ability.CastNoTarget(ability)
    data.last_action = "Raise Dead"
    data.next_order_time = current_time + ORDER_COOLDOWN
    return true
end

local function MoveTowardsHero(unit, data, current_time)
    if not my_hero or not Entity.IsAlive(my_hero) then
        data.last_action = "Герой недоступен"
        return
    end

    if not local_player then
        return
    end

    local hero_pos = Entity.GetAbsOrigin(my_hero)
    local unit_pos = Entity.GetAbsOrigin(unit)

    if not hero_pos or not unit_pos then
        return
    end

    local distance = hero_pos:Distance(unit_pos)
    if distance <= FOLLOW_DISTANCE then
        data.last_action = "Рядом с героем"
        return
    end

    Player.PrepareUnitOrders(
        local_player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        hero_pos,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        unit
    )

    data.last_action = "Следую за героем"
    data.next_order_time = current_time + ORDER_COOLDOWN
end

local function ProcessUnit(unit, data, current_time)
    if TryCastRaiseDead(unit, data, current_time) then
        return
    end

    if current_time < (data.next_order_time or 0) then
        return
    end

    MoveTowardsHero(unit, data, current_time)
end

function agent_script.OnUpdate()
    if not Engine.IsInGame() then
        ResetState()
        return
    end

    my_hero = Heroes.GetLocal()
    local_player = Players.GetLocal()

    if not my_hero or not local_player then
        ResetState()
        return
    end

    local_player_id = GetPlayerID()
    if not local_player_id then
        return
    end

    local now = GlobalVars.GetCurTime()
    local next_tracked = {}

    for _, unit in ipairs(NPCs.GetAll()) do
        if IsControlledDarkTroll(unit) then
            local handle = Entity.GetIndex(unit)
            local data = tracked_units[handle]
            if not data then
                data = {
                    next_order_time = 0,
                    last_action = "Ожидаю",
                }
            end

            ProcessUnit(unit, data, now)

            data.unit = unit
            next_tracked[handle] = data
        end
    end

    tracked_units = next_tracked
end

function agent_script.OnDraw()
    if not my_hero then
        return
    end

    local font = EnsureFont()

    for _, data in pairs(tracked_units) do
        local unit = data.unit
        if unit and Entity.IsAlive(unit) and data.last_action then
            local origin = Entity.GetAbsOrigin(unit)
            if origin then
                local offset = NPC.GetHealthBarOffset(unit) or 0
                local screen_pos, visible = Render.WorldToScreen(origin + Vector(0, 0, offset + 20))
                if visible then
                    Render.Text(font, 12, data.last_action, screen_pos, Color(180, 220, 255, 255))
                end
            end
        end
    end
end

function agent_script.OnGameEnd()
    ResetState()
end

return agent_script

