local agent_script = {}

agent_script.ui = {}

local DEFAULT_FOLLOW_DISTANCE = 300
local DEFAULT_ATTACK_RADIUS = 900
local ORDER_COOLDOWN = 0.3

local my_hero = nil
local local_player = nil
local local_player_id = nil
local debug_font = nil

local menu_initialized = false

local followers = {}

local function EnsureMenu()
    if menu_initialized then
        return
    end

    local scripts_tab = Menu.Create("Scripts", "Other", "Unit Followers")
    if not scripts_tab then
        return
    end

    if type(scripts_tab.Icon) == "function" then
        scripts_tab:Icon("\u{f0c1}")
    end

    local main_group = nil
    if type(scripts_tab.Create) == "function" then
        main_group = scripts_tab:Create("Основные настройки")
    end

    local target_group = main_group or scripts_tab

    if target_group and type(target_group.Create) == "function" then
        local nested_group = target_group:Create("Поведение")
        if nested_group then
            target_group = nested_group
        end
    end

    if not target_group then
        return
    end

    local function ApplyTooltip(control, text)
        if control and type(control.ToolTip) == "function" then
            control:ToolTip(text)
        end
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.enable = target_group:Switch("Включить скрипт", true, "\u{f205}")
        ApplyTooltip(agent_script.ui.enable, "Автоматически перемещать всех контролируемых юнитов к герою.")
    end

    if type(target_group.Slider) == "function" then
        agent_script.ui.follow_distance = target_group:Slider("Дистанция следования", 100, 800, DEFAULT_FOLLOW_DISTANCE, "%d")
        ApplyTooltip(agent_script.ui.follow_distance, "На каком расстоянии от героя должны находиться контролируемые юниты.")
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.auto_attack = target_group:Switch("Автоатака", true, "\u{f0e7}")
        ApplyTooltip(agent_script.ui.auto_attack, "Автоматически атаковать ближайших врагов в радиусе.")
    end

    if type(target_group.Slider) == "function" then
        agent_script.ui.attack_radius = target_group:Slider("Радиус атаки", 300, 1200, DEFAULT_ATTACK_RADIUS, "%d")
        ApplyTooltip(agent_script.ui.attack_radius, "Расстояние вокруг героя, в пределах которого ищутся цели для атаки.")
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.auto_cast = target_group:Switch("Авто использование навыков", true, "\u{f0a4}")
        ApplyTooltip(agent_script.ui.auto_cast, "Заглушка для будущей автоматизации навыков.")

        agent_script.ui.cast_on_creeps = target_group:Switch("Использовать навыки на крипов", true, "\u{f06d}")
        ApplyTooltip(agent_script.ui.cast_on_creeps, "Определяет, можно ли взаимодействовать с крипами (используется для фильтрации целей).")
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.debug = target_group:Switch("Отображать отладку", true, "\u{f05a}")
        ApplyTooltip(agent_script.ui.debug, "Показывать текстовое состояние над юнитами.")
    end

    menu_initialized = true
end

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

local function AllowCreepTargets()
    if agent_script.ui.cast_on_creeps then
        return agent_script.ui.cast_on_creeps:Get()
    end

    return true
end

local function IsControlledUnit(unit)
    if not unit or not Entity.IsAlive(unit) then
        return false
    end

    if unit == my_hero then
        return false
    end

    if NPC.IsCourier(unit) then
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

local function GetFollowDistance()
    if agent_script.ui.follow_distance then
        return agent_script.ui.follow_distance:Get()
    end

    return DEFAULT_FOLLOW_DISTANCE
end

local function GetAttackRadius()
    if agent_script.ui.attack_radius then
        return agent_script.ui.attack_radius:Get()
    end

    return DEFAULT_ATTACK_RADIUS
end

local function ShouldAutoAttack()
    return agent_script.ui.auto_attack and agent_script.ui.auto_attack:Get()
end

local function FindAllyAnchor(unit)
    if my_hero and Entity.IsAlive(my_hero) then
        local hero_pos = Entity.GetAbsOrigin(my_hero)
        return my_hero, hero_pos
    end

    if not unit or not my_hero then
        return nil, nil
    end

    local hero_team = Entity.GetTeamNum(my_hero)
    local unit_pos = Entity.GetAbsOrigin(unit)
    if not unit_pos then
        return nil, nil
    end

    local nearest_ally = nil
    local best_distance = math.huge

    for _, hero in ipairs(Heroes.GetAll()) do
        if hero ~= my_hero and Entity.IsAlive(hero) and Entity.GetTeamNum(hero) == hero_team and not NPC.IsIllusion(hero) then
            local hero_pos = Entity.GetAbsOrigin(hero)
            if hero_pos then
                local distance = unit_pos:Distance(hero_pos)
                if distance < best_distance then
                    best_distance = distance
                    nearest_ally = hero
                end
            end
        end
    end

    if nearest_ally then
        return nearest_ally, Entity.GetAbsOrigin(nearest_ally)
    end

    return nil, nil
end

local function AcquireAttackTarget(unit_pos, anchor_pos, radius_override)
    if not my_hero or not unit_pos then
        return nil
    end

    local hero_team = Entity.GetTeamNum(my_hero)
    local search_radius = radius_override or GetAttackRadius()
    local centers = {}

    if anchor_pos then
        centers[#centers + 1] = anchor_pos
    end

    centers[#centers + 1] = unit_pos

    local include_creeps = AllowCreepTargets()

    local function FindBest(team_type, predicate)
        local best_target = nil
        local best_distance = math.huge

        for _, center in ipairs(centers) do
            local units = NPCs.InRadius(center, search_radius, hero_team, team_type) or {}
            for _, candidate in ipairs(units) do
                if Entity.IsAlive(candidate) and not NPC.IsCourier(candidate) and Entity.GetTeamNum(candidate) ~= hero_team and predicate(candidate) then
                    local candidate_pos = Entity.GetAbsOrigin(candidate)
                    if candidate_pos then
                        local distance = center:Distance(candidate_pos)
                        if distance < best_distance then
                            best_distance = distance
                            best_target = candidate
                        end
                    end
                end
            end
        end

        return best_target
    end

    local target = FindBest(Enum.TeamType.TEAM_ENEMY, function(enemy)
        return NPC.IsHero(enemy)
    end)

    if target then
        return target
    end

    target = FindBest(Enum.TeamType.TEAM_ENEMY, function(enemy)
        if not NPC.IsCreep(enemy) then
            return false
        end

        if not include_creeps then
            return false
        end

        return true
    end)

    if target then
        return target
    end

    if include_creeps then
        target = FindBest(Enum.TeamType.TEAM_NEUTRAL, function(enemy)
            return NPC.IsCreep(enemy)
        end)
    end

    return target
end

local function IssueFollowOrders()
    if not local_player then
        return
    end

    local current_time = GlobalVars.GetCurTime()
    local follow_distance = GetFollowDistance()
    local attack_radius = GetAttackRadius()
    local auto_attack = ShouldAutoAttack()

    local hero_pos = my_hero and Entity.GetAbsOrigin(my_hero)

    for _, follower in pairs(followers) do
        local unit = follower.unit
        if not unit or not Entity.IsAlive(unit) then
            goto continue
        end

        if follower.next_action_time and current_time < follower.next_action_time then
            goto continue
        end

        local unit_pos = Entity.GetAbsOrigin(unit)
        if not unit_pos then
            goto continue
        end

        local anchor_unit, anchor_pos = FindAllyAnchor(unit)
        local leash_target = anchor_pos or hero_pos
        local anchor_distance = nil

        if leash_target then
            anchor_distance = unit_pos:Distance(leash_target)
        end

        local current_target = nil
        if auto_attack then
            current_target = AcquireAttackTarget(unit_pos, leash_target, attack_radius)
        end

        if current_target and Entity.IsAlive(current_target) then
            Player.PrepareUnitOrders(
                local_player,
                Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                current_target,
                nil,
                nil,
                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                unit
            )

            local target_name = NPC.GetUnitName(current_target) or "цель"
            follower.last_action = string.format("Атакую: %s", target_name)
            follower.next_action_time = current_time + ORDER_COOLDOWN
        else
            local move_position = leash_target
            if not move_position and hero_pos then
                move_position = hero_pos
            end

            if move_position and anchor_distance and anchor_distance > follow_distance then
                Player.PrepareUnitOrders(
                    local_player,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    move_position,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    unit
                )

                if anchor_unit then
                    local anchor_name = NPC.GetUnitName(anchor_unit) or "союзник"
                    follower.last_action = string.format("Следую к: %s", anchor_name)
                else
                    follower.last_action = "Двигаюсь к герою"
                end

                follower.next_action_time = current_time + ORDER_COOLDOWN
            elseif move_position then
                if anchor_unit then
                    local anchor_name = NPC.GetUnitName(anchor_unit) or "союзник"
                    follower.last_action = string.format("Рядом с: %s", anchor_name)
                else
                    follower.last_action = "В радиусе"
                end
                follower.next_action_time = current_time + ORDER_COOLDOWN
            else
                follower.last_action = "Ожидаю"
                follower.next_action_time = current_time + ORDER_COOLDOWN
            end
        end

        ::continue::
    end
end

function agent_script.OnUpdate()
    EnsureMenu()

    if agent_script.ui.enable and not agent_script.ui.enable:Get() then
        return
    end

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

    UpdateFollowers()
    IssueFollowOrders()
end

function agent_script.OnDraw()
    if not my_hero then
        return
    end

    if agent_script.ui.debug and not agent_script.ui.debug:Get() then
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
