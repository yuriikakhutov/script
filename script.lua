local agent_script = {}
agent_script.ui = {}

local STATES = {
    FOLLOWING = "FOLLOWING",
    FIGHTING = "FIGHTING",
    SUPPORTING = "SUPPORTING",
    MANUAL_OVERRIDE = "MANUAL",
}

local my_hero, local_player = nil, nil
local font = nil
local agent_manager = {}
local shared_attack_target = nil
local shared_attack_position = nil
local shared_command_expire_time = 0

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function Distance(a, b)
    return a:Distance(b)
end

local function EnsureFont()
    if not font then
        font = Render.LoadFont("Arial", 12, Enum.FontCreate.FONTFLAG_OUTLINE)
    end
    return font
end

local function ClearSharedCommand()
    shared_attack_target = nil
    shared_attack_position = nil
    shared_command_expire_time = 0
end

local function SetSharedAttackTarget(target)
    if target and Entity.IsAlive(target) and my_hero and not Entity.IsSameTeam(target, my_hero) then
        shared_attack_target = target
        shared_attack_position = nil
        shared_command_expire_time = GlobalVars.GetCurTime() + 3.0
    else
        ClearSharedCommand()
    end
end

local function SetSharedAttackPosition(position)
    if position then
        shared_attack_position = position
        shared_attack_target = nil
        shared_command_expire_time = GlobalVars.GetCurTime() + 3.0
    else
        ClearSharedCommand()
    end
end

local function GetHeroFollowDistance(creep_data)
    if creep_data and creep_data.follow_distance then
        return creep_data.follow_distance
    end
    return agent_script.ui.default_follow_distance and agent_script.ui.default_follow_distance:Get() or 300
end

local function IsDominatedCreep(unit)
    if not unit or not Entity.IsAlive(unit) then
        return false
    end
    if NPC.IsLaneCreep(unit) then
        return false
    end
    if NPC.IsRoshan and NPC.IsRoshan(unit) then
        return false
    end
    if NPC.IsHero(unit) or NPC.IsIllusion(unit) or NPC.IsCourier(unit) then
        return false
    end

    if not my_hero then
        return false
    end

    if local_player and not NPC.IsControllableByPlayer(unit, local_player) then
        return false
    end

    local unit_team = Entity.GetTeamNum(unit)
    local hero_team = Entity.GetTeamNum(my_hero)

    if unit_team ~= hero_team and unit_team ~= Enum.TeamNum.TEAM_NEUTRAL then
        return false
    end

    local unit_name = NPC.GetUnitName(unit)
    return unit_name and agent_script.creep_data[unit_name] ~= nil
end

local function BuildContext(agent)
    local hero_origin = Entity.GetAbsOrigin(my_hero)
    local unit_origin = Entity.GetAbsOrigin(agent.unit)
    local context = {
        hero = my_hero,
        hero_origin = hero_origin,
        unit_origin = unit_origin,
        allies = {},
        enemies = {},
        closest_enemy_hero = nil,
        closest_enemy_hero_distance = math.huge,
        closest_enemy_unit = nil,
        closest_enemy_unit_distance = math.huge,
        primary_target = nil,
        primary_target_distance = math.huge,
    }

    for handle, other_agent in pairs(agent_manager) do
        if other_agent.unit ~= agent.unit and Entity.IsAlive(other_agent.unit) then
            table.insert(context.allies, other_agent.unit)
        end
    end

    for _, enemy in pairs(Heroes.GetAll()) do
        if not Entity.IsSameTeam(enemy, my_hero) and Entity.IsAlive(enemy) and NPC.IsVisible(enemy) and not NPC.IsIllusion(enemy) then
            local distance = Distance(unit_origin, Entity.GetAbsOrigin(enemy))
            if distance < context.closest_enemy_hero_distance then
                context.closest_enemy_hero = enemy
                context.closest_enemy_hero_distance = distance
            end
            table.insert(context.enemies, enemy)
        end
    end

    local search_radius = math.max((agent.creep_data and agent.creep_data.engage_distance or 700) + 400, 1200)
    local units = Entity.GetUnitsInRadius(agent.unit, search_radius, Enum.TeamType.TEAM_ENEMY, true, true)
    if units then
        for _, enemy in ipairs(units) do
            if Entity.IsAlive(enemy) and not NPC.IsCourier(enemy) then
                local distance = Distance(unit_origin, Entity.GetAbsOrigin(enemy))
                if distance < context.closest_enemy_unit_distance then
                    context.closest_enemy_unit = enemy
                    context.closest_enemy_unit_distance = distance
                end
            end
        end
    end

    if context.closest_enemy_hero then
        context.primary_target = context.closest_enemy_hero
        context.primary_target_distance = context.closest_enemy_hero_distance
    elseif context.closest_enemy_unit then
        context.primary_target = context.closest_enemy_unit
        context.primary_target_distance = context.closest_enemy_unit_distance
    end

    return context
end

local Agent = {}
Agent.__index = Agent

function Agent.new(unit, creep_data)
    return setmetatable({
        unit = unit,
        creep_data = creep_data,
        state = STATES.FOLLOWING,
        next_action_time = 0,
        manual_override_until = 0,
        thought = "Инициализация",
        target = nil,
        attack_move_position = nil,
    }, Agent)
end

function Agent:IssueOrder(order, target, position, ability)
    Player.PrepareUnitOrders(
        local_player,
        order,
        target,
        position,
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        self.unit
    )
end

function Agent:Attack(target)
    if not target then
        return
    end
    self:IssueOrder(Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET, target)
end

function Agent:MoveTo(position)
    self:IssueOrder(Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, position)
end

function Agent:HoldPosition()
    self:IssueOrder(Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION)
end

local function CastAbilityTarget(ability, target)
    Ability.CastTarget(ability, target)
end

local function CastAbilityNoTarget(ability)
    Ability.CastNoTarget(ability)
end

local function CastAbilityPosition(ability, position)
    Ability.CastPosition(ability, position)
end

local function HasToggleEnabled(creep_name, ability_id)
    local creep_settings = agent_script.ui.creep_settings[creep_name]
    if not creep_settings or not creep_settings.abilities then
        return true
    end
    local toggle = creep_settings.abilities[ability_id]
    if not toggle then
        return true
    end
    return toggle:Get()
end

local function UseCreepAbilities(agent, context)
    local creep_name = NPC.GetUnitName(agent.unit)
    local creep_data = agent.creep_data
    if not creep_data or not creep_data.abilities then
        return false
    end

    for _, ability_data in ipairs(creep_data.abilities) do
        if HasToggleEnabled(creep_name, ability_data.id) then
            local ability = NPC.GetAbility(agent.unit, ability_data.ability_name)
            if ability and Ability.IsReady(ability) then
                if ability_data.condition(agent, ability, context) then
                    ability_data.execute(agent, ability, context)
                    agent.thought = ability_data.thought or ("Использую " .. ability_data.display_name)
                    return true
                end
            end
        end
    end

    return false
end

local function EvaluateState(agent, context)
    local time_now = GlobalVars.GetCurTime()

    if time_now < agent.manual_override_until then
        agent.state = STATES.MANUAL_OVERRIDE
        agent.thought = string.format("Ручной контроль (%.1fs)", agent.manual_override_until - time_now)
        return
    elseif agent.state == STATES.MANUAL_OVERRIDE then
        agent.state = STATES.FOLLOWING
    end

    if shared_command_expire_time > time_now then
        if shared_attack_target and Entity.IsAlive(shared_attack_target) and not Entity.IsSameTeam(shared_attack_target, my_hero) then
            agent.state = STATES.FIGHTING
            agent.target = shared_attack_target
            return
        elseif shared_attack_position then
            agent.state = STATES.SUPPORTING
            agent.attack_move_position = shared_attack_position
            agent.target = nil
            return
        end
    else
        ClearSharedCommand()
    end

    if context.primary_target and context.primary_target_distance <= agent.creep_data.engage_distance then
        agent.state = STATES.FIGHTING
        agent.target = context.primary_target
        return
    end

    agent.state = STATES.FOLLOWING
    agent.target = nil
    agent.attack_move_position = nil
end

local function ExecuteState(agent, context)
    local time_now = GlobalVars.GetCurTime()
    if time_now < agent.next_action_time then
        return
    end

    if agent.state == STATES.FIGHTING then
        if agent.target and Entity.IsAlive(agent.target) then
            if UseCreepAbilities(agent, context) then
                agent.next_action_time = time_now + 0.2
                return
            end
            local unit_origin = Entity.GetAbsOrigin(agent.unit)
            local target_origin = Entity.GetAbsOrigin(agent.target)
            local attack_range = NPC.GetAttackRange(agent.unit) + NPC.GetAttackRangeBonus(agent.unit) + NPC.GetHullRadius(agent.unit) + NPC.GetHullRadius(agent.target)
            if Distance(unit_origin, target_origin) > attack_range then
                agent:MoveTo(target_origin)
                agent.thought = "Преследую цель"
            else
                agent:Attack(agent.target)
                agent.thought = "Атакую"
            end
        else
            agent.state = STATES.FOLLOWING
            agent.target = nil
            agent.attack_move_position = nil
        end
        agent.next_action_time = time_now + 0.4
        return
    end

    if agent.state == STATES.SUPPORTING then
        if shared_command_expire_time <= time_now then
            agent.state = STATES.FOLLOWING
            agent.attack_move_position = nil
        else
            local destination = agent.attack_move_position or context.hero_origin
            if destination then
                agent:MoveTo(destination)
                agent.thought = "Поддерживаю атаку"
            else
                agent.state = STATES.FOLLOWING
            end
        end
        agent.next_action_time = time_now + 0.35
        return
    end

    if UseCreepAbilities(agent, context) then
        agent.next_action_time = time_now + 0.3
        return
    end

    local follow_distance = GetHeroFollowDistance(agent.creep_data)
    local hero_origin = context.hero_origin
    local unit_origin = context.unit_origin
    local distance_to_hero = Distance(hero_origin, unit_origin)

    if distance_to_hero > follow_distance then
        agent:MoveTo(hero_origin)
        agent.thought = "Следую за героем"
    else
        agent:HoldPosition()
        agent.thought = "Ожидаю"
    end

    agent.next_action_time = time_now + 0.4
end

local function CleanupAgents()
    for handle, agent in pairs(agent_manager) do
        if not agent.unit or not Entity.IsAlive(agent.unit) then
            agent_manager[handle] = nil
        elseif not NPC.IsControllableByPlayer(agent.unit, local_player or Players.GetLocal()) then
            agent_manager[handle] = nil
        elseif not agent_script.creep_data[NPC.GetUnitName(agent.unit) or ""] then
            agent_manager[handle] = nil
        end
    end
end

local function RefreshAgents()
    CleanupAgents()

    local hero_origin = Entity.GetAbsOrigin(my_hero)

    for _, unit in ipairs(NPCs.GetAll()) do
        if Entity.IsAlive(unit) and Distance(hero_origin, Entity.GetAbsOrigin(unit)) <= 3500 then
            if IsDominatedCreep(unit) then
                local handle = Entity.GetIndex(unit)
                local unit_name = NPC.GetUnitName(unit)
                if not agent_manager[handle] then
                    agent_manager[handle] = Agent.new(unit, agent_script.creep_data[unit_name])
                else
                    agent_manager[handle].creep_data = agent_script.creep_data[unit_name]
                    agent_manager[handle].unit = unit
                end
            end
        end
    end
end

local function CreateMenu()
    local main_tab = Menu.Create("Scripts", "Other", "AI Доминированные Крипы")
    if not main_tab then
        return
    end

    main_tab:Icon("\u{f6ff}")

    local main_group = main_tab:Create("Main")
    local settings_group = main_group:Create("Настройки")
    agent_script.ui.enable = settings_group:Switch("Включить AI", true, "\u{f544}")
    agent_script.ui.debug_draw = settings_group:Switch("Отображать отладку", true, "\u{f05a}")
    agent_script.ui.default_follow_distance = settings_group:Slider("Дистанция следования (по умолчанию)", 150, 600, 300, "%d")

    agent_script.ui.creep_settings = {}

    local abilities_group = main_group:Create("Способности крипов")

    local creep_names = {}
    for creep_name in pairs(agent_script.creep_data) do
        table.insert(creep_names, creep_name)
    end
    table.sort(creep_names)

    for _, creep_name in ipairs(creep_names) do
        local creep_data = agent_script.creep_data[creep_name]
        local group = abilities_group:Create(creep_data.display_name)
        agent_script.ui.creep_settings[creep_name] = {
            enable = group:Switch("Активировать", true, creep_data.icon or "\u{f0fb}")
        }

        agent_script.ui.creep_settings[creep_name].abilities = {}
        if creep_data.abilities then
            for _, ability_data in ipairs(creep_data.abilities) do
                agent_script.ui.creep_settings[creep_name].abilities[ability_data.id] = group:Switch(
                    ability_data.display_name,
                    ability_data.default ~= false,
                    ability_data.icon or "\u{f0e7}"
                )
            end
        end
    end
end

local function InitializeCreepData()
    agent_script.creep_data = {
        npc_dota_neutral_centaur_khan = {
            display_name = "Centaur Conqueror",
            engage_distance = 600,
            follow_distance = 260,
            icon = "panorama/images/minimap/centaur_khan_png.vtex_c",
            abilities = {
                {
                    id = "centaur_warstomp",
                    ability_name = "centaur_khan_warstomp",
                    display_name = "War Stomp",
                    icon = "panorama/images/spellicons/centaur_khan_warstomp_png.vtex_c",
                    condition = function(agent, ability, context)
                        return context.primary_target and context.primary_target_distance <= 250 and not NPC.IsMagicImmune(context.primary_target)
                    end,
                    execute = function(agent, ability)
                        CastAbilityNoTarget(ability)
                    end,
                    thought = "Оглушаю варстомпом",
                },
            },
        },
        npc_dota_neutral_dark_troll_warlord = {
            display_name = "Dark Troll Summoner",
            engage_distance = 700,
            follow_distance = 275,
            icon = "panorama/images/minimap/dark_troll_warlord_png.vtex_c",
            abilities = {
                {
                    id = "dark_troll_ensnare",
                    ability_name = "dark_troll_warlord_ensnare",
                    display_name = "Ensnare",
                    icon = "panorama/images/spellicons/dark_troll_warlord_ensnare_png.vtex_c",
                    condition = function(agent, ability, context)
                        return context.primary_target and context.primary_target_distance <= 550 and not NPC.IsMagicImmune(context.primary_target)
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.primary_target)
                    end,
                    thought = "Сеткую врага",
                },
                {
                    id = "dark_troll_raise_dead",
                    ability_name = "dark_troll_warlord_raise_dead",
                    display_name = "Raise Dead",
                    icon = "panorama/images/spellicons/dark_troll_warlord_raise_dead_png.vtex_c",
                    condition = function(agent, ability, context)
                        return context.primary_target ~= nil and NPC.GetMana(agent.unit) >= Ability.GetManaCost(ability)
                    end,
                    execute = function(agent, ability)
                        CastAbilityNoTarget(ability)
                    end,
                    thought = "Призываю скелетов",
                },
            },
        },
        npc_dota_neutral_satyr_trickster = {
            display_name = "Satyr Mindstealer",
            engage_distance = 650,
            follow_distance = 270,
            icon = "panorama/images/minimap/satyr_trickster_png.vtex_c",
            abilities = {
                {
                    id = "satyr_purge",
                    ability_name = "satyr_trickster_purge",
                    display_name = "Purge",
                    icon = "panorama/images/spellicons/satyr_trickster_purge_png.vtex_c",
                    condition = function(agent, ability, context)
                        if not context.primary_target or context.primary_target_distance > 600 then
                            return false
                        end
                        return not NPC.IsMagicImmune(context.primary_target)
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.primary_target)
                    end,
                    thought = "Снимаю баф врага",
                },
            },
        },
        npc_dota_neutral_satyr_hellcaller = {
            display_name = "Satyr Tormentor",
            engage_distance = 700,
            follow_distance = 300,
            icon = "panorama/images/minimap/satyr_hellcaller_png.vtex_c",
            abilities = {
                {
                    id = "satyr_shockwave",
                    ability_name = "satyr_hellcaller_shockwave",
                    display_name = "Shockwave",
                    icon = "panorama/images/spellicons/satyr_hellcaller_shockwave_png.vtex_c",
                    condition = function(agent, ability, context)
                        if not context.primary_target or context.primary_target_distance > 900 then
                            return false
                        end
                        return true
                    end,
                    execute = function(agent, ability, context)
                        local position = Entity.GetAbsOrigin(context.primary_target)
                        CastAbilityPosition(ability, position)
                    end,
                    thought = "Запускаю шоквейв",
                },
            },
        },
        npc_dota_neutral_ogre_magi = {
            display_name = "Ogre Frostmage",
            engage_distance = 650,
            follow_distance = 280,
            icon = "panorama/images/minimap/ogre_magi_png.vtex_c",
            abilities = {
                {
                    id = "ogre_frost_armor",
                    ability_name = "ogre_magi_frost_armor",
                    display_name = "Frost Armor",
                    icon = "panorama/images/spellicons/ogre_magi_frost_armor_png.vtex_c",
                    condition = function(agent, ability, context)
                        local hero = context.hero
                        if not hero or not Entity.IsAlive(hero) then
                            return false
                        end
                        if NPC.HasModifier(hero, "modifier_ogre_magi_frost_armor") then
                            return false
                        end
                        if not Ability.IsReady(ability) then
                            return false
                        end
                        return true
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.hero)
                    end,
                    thought = "Накладываю броню",
                },
            },
        },
        npc_dota_neutral_alpha_wolf = {
            display_name = "Alpha Wolf",
            engage_distance = 700,
            follow_distance = 250,
            icon = "panorama/images/minimap/alpha_wolf_png.vtex_c",
            abilities = {
                {
                    id = "alpha_howl",
                    ability_name = "alpha_wolf_howl",
                    display_name = "Howl",
                    icon = "panorama/images/spellicons/alpha_wolf_howl_png.vtex_c",
                    condition = function(agent, ability, context)
                        if not context.primary_target or context.primary_target_distance > 900 then
                            return false
                        end
                        return true
                    end,
                    execute = function(agent, ability)
                        CastAbilityNoTarget(ability)
                    end,
                    thought = "Усиливаю союзников",
                },
            },
        },
        npc_dota_neutral_mud_golem = {
            display_name = "Mud Golem",
            engage_distance = 650,
            follow_distance = 260,
            icon = "panorama/images/minimap/mud_golem_png.vtex_c",
            abilities = {
                {
                    id = "mud_golem_hurl_boulder",
                    ability_name = "mud_golem_hurl_boulder",
                    display_name = "Hurl Boulder",
                    icon = "panorama/images/spellicons/mud_golem_hurl_boulder_png.vtex_c",
                    condition = function(agent, ability, context)
                        if not context.primary_target or context.primary_target_distance > 700 then
                            return false
                        end
                        return not NPC.IsMagicImmune(context.primary_target)
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.primary_target)
                    end,
                    thought = "Оглушаю булыжником",
                },
            },
        },
        npc_dota_neutral_granite_golem = {
            display_name = "Granite Golem",
            engage_distance = 800,
            follow_distance = 320,
            icon = "panorama/images/minimap/ancient_golem_png.vtex_c",
            abilities = {
                {
                    id = "granite_golem_hurl_boulder",
                    ability_name = "ancient_golem_boulder",
                    display_name = "Granite Boulder",
                    icon = "panorama/images/spellicons/ancient_golem_boulder_png.vtex_c",
                    condition = function(agent, ability, context)
                        if not context.primary_target or context.primary_target_distance > 700 then
                            return false
                        end
                        return not NPC.IsMagicImmune(context.primary_target)
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.primary_target)
                    end,
                    thought = "Запускаю валун",
                },
            },
        },
        npc_dota_neutral_black_dragon = {
            display_name = "Black Dragon",
            engage_distance = 900,
            follow_distance = 340,
            icon = "panorama/images/minimap/black_dragon_png.vtex_c",
            abilities = {
                {
                    id = "black_dragon_fireball",
                    ability_name = "black_dragon_fireball",
                    display_name = "Fireball",
                    icon = "panorama/images/spellicons/black_dragon_fireball_png.vtex_c",
                    condition = function(agent, ability, context)
                        if not context.primary_target or context.primary_target_distance > 900 then
                            return false
                        end
                        return true
                    end,
                    execute = function(agent, ability, context)
                        local position = Entity.GetAbsOrigin(context.primary_target)
                        CastAbilityPosition(ability, position)
                    end,
                    thought = "Огненное дыхание",
                },
            },
        },
        npc_dota_neutral_thunderhide = {
            display_name = "Ancient Thunderhide",
            engage_distance = 850,
            follow_distance = 320,
            icon = "panorama/images/minimap/ancient_thunderhide_png.vtex_c",
            abilities = {
                {
                    id = "thunderhide_slam",
                    ability_name = "ancient_thunderhide_slam",
                    display_name = "Slam",
                    icon = "panorama/images/spellicons/ancient_thunderhide_slam_png.vtex_c",
                    condition = function(agent, ability, context)
                        return context.primary_target and context.primary_target_distance <= 250 and not NPC.IsMagicImmune(context.primary_target)
                    end,
                    execute = function(agent, ability)
                        CastAbilityNoTarget(ability)
                    end,
                    thought = "Оглушаю топотом",
                },
                {
                    id = "thunderhide_frenzy",
                    ability_name = "ancient_thunderhide_frenzy",
                    display_name = "Frenzy",
                    icon = "panorama/images/spellicons/ancient_thunderhide_frenzy_png.vtex_c",
                    condition = function(agent, ability, context)
                        local hero = context.hero
                        if not hero or not Entity.IsAlive(hero) then
                            return false
                        end
                        if NPC.HasModifier(hero, "modifier_ancient_thunderhide_frenzy") then
                            return false
                        end
                        return true
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.hero)
                    end,
                    thought = "Разгоняю героя",
                },
            },
        },
        npc_dota_neutral_forest_troll_high_priest = {
            display_name = "Forest Troll Priest",
            engage_distance = 600,
            follow_distance = 260,
            icon = "panorama/images/minimap/forest_troll_high_priest_png.vtex_c",
            abilities = {
                {
                    id = "troll_heal",
                    ability_name = "forest_troll_high_priest_heal",
                    display_name = "Heal",
                    icon = "panorama/images/spellicons/forest_troll_high_priest_heal_png.vtex_c",
                    condition = function(agent, ability, context)
                        local hero = context.hero
                        if not hero or not Entity.IsAlive(hero) then
                            return false
                        end
                        if Entity.GetHealth(hero) >= Entity.GetMaxHealth(hero) * 0.95 then
                            return false
                        end
                        return true
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.hero)
                    end,
                    thought = "Лечу героя",
                },
            },
        },
        npc_dota_neutral_ice_shaman = {
            display_name = "Ice Shaman",
            engage_distance = 800,
            follow_distance = 300,
            icon = "panorama/images/minimap/ancient_ice_shaman_png.vtex_c",
            abilities = {
                {
                    id = "ice_shaman_hex",
                    ability_name = "ancient_ice_shaman_freeze",
                    display_name = "Freeze",
                    icon = "panorama/images/spellicons/ancient_ice_shaman_freeze_png.vtex_c",
                    condition = function(agent, ability, context)
                        return context.primary_target and context.primary_target_distance <= 700 and not NPC.IsMagicImmune(context.primary_target)
                    end,
                    execute = function(agent, ability, context)
                        CastAbilityTarget(ability, context.primary_target)
                    end,
                    thought = "Замораживаю",
                },
            },
        },
    }

    for creep_name, creep_data in pairs(agent_script.creep_data) do
        creep_data.engage_distance = clamp(creep_data.engage_distance or 700, 300, 1200)
    end
end

function agent_script.OnUpdate()
    if not agent_script.ui.enable or not agent_script.ui.enable:Get() then
        ClearSharedCommand()
        return
    end

    if not Engine.IsInGame() then
        ClearSharedCommand()
        return
    end

    my_hero = Heroes.GetLocal()
    local_player = Players.GetLocal()

    if not my_hero or not Entity.IsAlive(my_hero) or not local_player then
        agent_manager = {}
        ClearSharedCommand()
        return
    end

    RefreshAgents()

    for handle, agent in pairs(agent_manager) do
        if agent and Entity.IsAlive(agent.unit) then
            if agent_script.ui.creep_settings then
                local creep_name = NPC.GetUnitName(agent.unit)
                local creep_settings = agent_script.ui.creep_settings[creep_name]
                if creep_settings and creep_settings.enable and not creep_settings.enable:Get() then
                    agent.thought = "Исключен настройками"
                    goto continue
                end
            end

            local context = BuildContext(agent)
            EvaluateState(agent, context)
            ExecuteState(agent, context)
        end
        ::continue::
    end
end

function agent_script.OnDraw()
    if not agent_script.ui.debug_draw or not agent_script.ui.debug_draw:Get() then
        return
    end
    if not Engine.IsInGame() then
        return
    end
    if not my_hero then
        return
    end

    local draw_font = EnsureFont()

    for _, agent in pairs(agent_manager) do
        if agent and agent.unit and Entity.IsAlive(agent.unit) then
            local origin = Entity.GetAbsOrigin(agent.unit)
            local offset = Vector(0, 0, NPC.GetHealthBarOffset(agent.unit) + 20)
            local screen_pos, visible = Render.WorldToScreen(origin + offset)
            if visible then
                Render.Text(draw_font, 12, string.format("[%s] %s", agent.state, agent.thought or ""), screen_pos, Color(180, 220, 255, 255))
            end
        end
    end
end

function agent_script.OnPrepareUnitOrders(data)
    if not agent_script.ui.enable or not agent_script.ui.enable:Get() then
        return true
    end

    if not data then
        return true
    end

    local player = data.player or Players.GetLocal()
    if not player then
        return true
    end

    if data.orderIssuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY then
        return true
    end

    local time_now = GlobalVars.GetCurTime()

    local hero_in_command = false
    if my_hero then
        if data.npc and data.npc == my_hero then
            hero_in_command = true
        elseif data.units then
            for _, unit in ipairs(data.units) do
                if unit == my_hero then
                    hero_in_command = true
                    break
                end
            end
        end
    end

    if hero_in_command then
        if data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET and data.target then
            SetSharedAttackTarget(data.target)
        elseif data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE then
            if data.position then
                SetSharedAttackPosition(data.position)
            end
        elseif data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET and data.target then
            if data.ability and not Entity.IsSameTeam(data.target, my_hero) then
                SetSharedAttackTarget(data.target)
            end
        elseif data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION and data.position then
            SetSharedAttackPosition(data.position)
        elseif data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_STOP or data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION then
            ClearSharedCommand()
        elseif data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION then
            ClearSharedCommand()
        end
    end

    local selected_units = Player.GetSelectedUnits(player)
    if selected_units then
        for _, unit in ipairs(selected_units) do
            local handle = Entity.GetIndex(unit)
            local agent = agent_manager[handle]
            if agent then
                agent.manual_override_until = time_now + 4.0
            end
        end
    end

    return true
end

function agent_script.OnGameEnd()
    agent_manager = {}
    my_hero = nil
    local_player = nil
    ClearSharedCommand()
end

InitializeCreepData()
CreateMenu()

return agent_script
