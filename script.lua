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
        ApplyTooltip(agent_script.ui.auto_cast, "Автоматически применять направленные способности юнитов по их цели.")
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

local function ShouldAutoCast()
    return agent_script.ui.auto_cast and agent_script.ui.auto_cast:Get()
end

local function AcquireAttackTarget(hero_pos)
    if not my_hero then
        return nil
    end

    local hero_team = Entity.GetTeamNum(my_hero)
    local search_radius = GetAttackRadius()
    local enemies = NPCs.InRadius(hero_pos, search_radius, hero_team, Enum.TeamType.TEAM_ENEMY) or {}

    local best_target = nil
    local best_score = -math.huge

    for _, enemy in ipairs(enemies) do
        if Entity.IsAlive(enemy) and not NPC.IsCourier(enemy) then
            local enemy_pos = Entity.GetAbsOrigin(enemy)
            local distance = hero_pos:Distance(enemy_pos)
            local score = -distance

            if NPC.IsHero(enemy) then
                score = score + 1000
            elseif NPC.IsCreep(enemy) then
                if NPC.IsLaneCreep(enemy) then
                    score = score - 50
                else
                    score = score + 100
                end
            end

            if score > best_score then
                best_score = score
                best_target = enemy
            end
        end
    end

    return best_target
end

local function GetUnitHealthPercent(unit)
    if not unit or not Entity.IsAlive(unit) then
        return 0
    end

    local health = Entity.GetHealth(unit) or 0
    local max_health = Entity.GetMaxHealth(unit) or 0

    if max_health <= 0 then
        return 0
    end

    return (health / max_health) * 100
end

local function GetAbilitySpecialValue(ability, key, default)
    if not ability or not key then
        return default
    end

    if type(Ability.GetLevelSpecialValueFor) == "function" then
        local level = Ability.GetLevel(ability)
        if level and level > 0 then
            local ok, value = pcall(Ability.GetLevelSpecialValueFor, ability, key, level - 1)
            if ok and type(value) == "number" then
                return value
            end
        end
    end

    if type(Ability.GetSpecialValueFor) == "function" then
        local ok, value = pcall(Ability.GetSpecialValueFor, ability, key)
        if ok and type(value) == "number" then
            return value
        end
    end

    return default
end

local function GetAbilityCharges(ability)
    if not ability then
        return nil
    end

    if type(Ability.GetCurrentCharges) == "function" then
        return Ability.GetCurrentCharges(ability)
    end

    if type(Ability.GetCurrentAbilityCharges) == "function" then
        return Ability.GetCurrentAbilityCharges(ability)
    end

    return nil
end

local ABILITY_DATA = {
    mud_golem_hurl_boulder = {
        type = "target",
        display = "Hurl Boulder",
        range_buffer = 50,
    },
    ancient_rock_golem_hurl_boulder = {
        type = "target",
        display = "Ancient Boulder",
        range_buffer = 75,
    },
    dark_troll_warlord_ensnare = {
        type = "target",
        display = "Ensnare",
        range_buffer = 25,
        only_heroes = true,
    },
    harpy_storm_chain_lightning = {
        type = "target",
        display = "Chain Lightning",
        range_buffer = 50,
    },
    satyr_mindstealer_mana_burn = {
        type = "target",
        display = "Mana Burn",
        range_buffer = 25,
        only_heroes = true,
        min_mana_on_target = 75,
    },
    satyr_soulstealer_mana_burn = {
        type = "target",
        display = "Mana Burn",
        range_buffer = 25,
        only_heroes = true,
        min_mana_on_target = 75,
    },
    satyr_hellcaller_shockwave = {
        type = "point",
        display = "Shockwave",
        fixed_range = 800,
    },
    centaur_khan_war_stomp = {
        type = "no_target",
        display = "War Stomp",
        radius = 315,
        min_enemies = 1,
    },
    polar_furbolg_ursa_warrior_thunder_clap = {
        type = "no_target",
        display = "Thunder Clap",
        radius = 315,
        min_enemies = 1,
    },
    hellbear_smasher_slam = {
        type = "no_target",
        display = "Slam",
        radius = 350,
        min_enemies = 1,
    },
    black_dragon_fireball = {
        type = "point",
        display = "Fireball",
        fixed_range = 750,
    },
    ancient_black_dragon_fireball = {
        type = "point",
        display = "Fireball",
        fixed_range = 750,
    },
    ogre_magi_frost_armor = {
        type = "ally_target",
        display = "Frost Armor",
        buff_modifier = "modifier_ogre_magi_frost_armor",
        prefer_hero = true,
    },
    ogre_mauler_smash = {
        type = "point",
        display = "Ogre Smash",
        fixed_range = 350,
        range_buffer = 50,
    },
    forest_troll_high_priest_heal = {
        type = "ally_target",
        display = "Heal",
        prefer_hero = true,
        only_heroes = true,
        max_ally_health_pct = 99.5,
    },
    dark_troll_warlord_raise_dead = {
        type = "no_target",
        display = "Raise Dead",
        requires_charges = true,
        min_enemies = 0,
    },
    axe_berserkers_call = {
        type = "no_target",
        display = "Berserker's Call",
        radius = 325,
        min_enemies = 1,
    },
    axe_battle_hunger = {
        type = "target",
        display = "Battle Hunger",
        range_buffer = 25,
        only_heroes = true,
        avoid_enemy_modifier = "modifier_axe_battle_hunger",
        exclude_illusions = true,
    },
    axe_culling_blade = {
        type = "target",
        display = "Culling Blade",
        range_buffer = 25,
        only_heroes = true,
        exclude_illusions = true,
        execute_threshold_values = { 250, 350, 450 },
        execute_threshold_special = "kill_threshold",
    },
}

local function GetAbilityMetadata(name)
    if not name then
        return nil
    end

    return ABILITY_DATA[name]
end

local function IsInExtendedRange(unit_pos, target_pos, ability, metadata)
    if not unit_pos or not target_pos then
        return false
    end

    local buffer = (metadata and metadata.range_buffer) or 0
    local fixed_range = metadata and metadata.fixed_range
    local cast_range = fixed_range or (Ability.GetCastRange and Ability.GetCastRange(ability)) or 0

    if cast_range <= 0 then
        cast_range = (metadata and metadata.radius) or 250
    end

    return unit_pos:Distance(target_pos) <= (cast_range + buffer)
end

local function CountEnemiesAround(position, radius)
    if not my_hero or not position or radius <= 0 then
        return 0, 0
    end

    local hero_team = Entity.GetTeamNum(my_hero)
    local enemies = NPCs.InRadius(position, radius, hero_team, Enum.TeamType.TEAM_ENEMY) or {}
    local total = 0
    local hero_count = 0

    for _, enemy in ipairs(enemies) do
        if Entity.IsAlive(enemy) and not NPC.IsCourier(enemy) then
            total = total + 1
            if NPC.IsHero(enemy) then
                hero_count = hero_count + 1
            end
        end
    end

    return total, hero_count
end

local function AllySatisfiesMetadata(ally, metadata)
    if not ally or not metadata then
        return false
    end

    if metadata.only_heroes and not NPC.IsHero(ally) then
        return false
    end

    if metadata.only_creeps and not NPC.IsCreep(ally) then
        return false
    end

    if metadata.max_ally_health_pct then
        local health_pct = GetUnitHealthPercent(ally)
        if health_pct >= metadata.max_ally_health_pct then
            return false
        end
    end

    if metadata.min_ally_health_pct then
        local health_pct = GetUnitHealthPercent(ally)
        if health_pct <= metadata.min_ally_health_pct then
            return false
        end
    end

    if metadata.buff_modifier and NPC.HasModifier(ally, metadata.buff_modifier) then
        return false
    end

    return true
end

local function ChooseAllyTarget(unit, metadata)
    if not metadata then
        return nil
    end

    if metadata.prefer_hero and my_hero and Entity.IsAlive(my_hero) and AllySatisfiesMetadata(my_hero, metadata) then
        return my_hero
    end

    local unit_pos = unit and Entity.GetAbsOrigin(unit)
    if not unit_pos then
        return nil
    end

    local hero_team = my_hero and Entity.GetTeamNum(my_hero)
    local allies = NPCs.InRadius(unit_pos, 900, hero_team, Enum.TeamType.TEAM_FRIEND)
    if allies then
        for _, ally in ipairs(allies) do
            if Entity.IsAlive(ally) and ally ~= unit and not NPC.IsCourier(ally) and AllySatisfiesMetadata(ally, metadata) then
                return ally
            end
        end
    end

    return nil
end

local function EnemySatisfiesMetadata(enemy, metadata, ability)
    if not enemy or not metadata then
        return false
    end

    if not Entity.IsAlive(enemy) then
        return false
    end

    if metadata.only_heroes and not NPC.IsHero(enemy) then
        return false
    end

    if metadata.only_creeps and not NPC.IsCreep(enemy) then
        return false
    end

    if metadata.exclude_illusions and NPC.IsIllusion(enemy) then
        return false
    end

    if metadata.min_mana_on_target and NPC.GetMana(enemy) < metadata.min_mana_on_target then
        return false
    end

    if metadata.max_enemy_health_pct then
        local health_pct = GetUnitHealthPercent(enemy)
        if health_pct > metadata.max_enemy_health_pct then
            return false
        end
    end

    if metadata.max_enemy_health and Entity.GetHealth(enemy) > metadata.max_enemy_health then
        return false
    end

    if metadata.avoid_enemy_modifier and NPC.HasModifier(enemy, metadata.avoid_enemy_modifier) then
        return false
    end

    if ability and (metadata.execute_threshold_values or metadata.execute_threshold_special or metadata.execute_threshold) then
        local threshold = metadata.execute_threshold or 0

        if metadata.execute_threshold_values then
            local level = Ability.GetLevel(ability)
            if level and level > 0 then
                threshold = metadata.execute_threshold_values[level] or metadata.execute_threshold_values[#metadata.execute_threshold_values]
            else
                threshold = metadata.execute_threshold_values[1]
            end
        end

        if metadata.execute_threshold_special then
            local special_value = GetAbilitySpecialValue(ability, metadata.execute_threshold_special, threshold)
            if type(special_value) == "number" then
                threshold = special_value
            end
        end

        if threshold and threshold > 0 and Entity.GetHealth(enemy) > threshold then
            return false
        end
    end

    return true
end

local function TryCastAbility(unit, ability, metadata, current_target)
    if not metadata then
        return nil
    end

    if NPC.IsChannellingAbility(unit) then
        return nil
    end

    local mana = NPC.GetMana(unit)
    if not Ability.IsReady(ability) or not Ability.IsCastable(ability, mana) then
        return nil
    end

    local ability_name = Ability.GetName(ability) or "ability"
    local unit_pos = Entity.GetAbsOrigin(unit)

    if metadata.type == "target" then
        local target = current_target

        if target and not EnemySatisfiesMetadata(target, metadata, ability) then
            target = nil
        end

        if target then
            local target_pos = Entity.GetAbsOrigin(target)
            if not IsInExtendedRange(unit_pos, target_pos, ability, metadata) then
                target = nil
            end
        end

        if not target then
            local hero_team = my_hero and Entity.GetTeamNum(my_hero)
            local search_radius = (metadata.fixed_range or (Ability.GetCastRange and Ability.GetCastRange(ability)) or 600)
            search_radius = search_radius + (metadata.range_buffer or 0) + (metadata.search_radius_bonus or 0)

            local enemies = (hero_team and NPCs.InRadius(unit_pos, search_radius, hero_team, Enum.TeamType.TEAM_ENEMY)) or {}
            local best_target = nil
            local best_score = -math.huge

            for _, enemy in ipairs(enemies) do
                if EnemySatisfiesMetadata(enemy, metadata, ability) then
                    local enemy_pos = Entity.GetAbsOrigin(enemy)
                    if IsInExtendedRange(unit_pos, enemy_pos, ability, metadata) then
                        local score = -unit_pos:Distance(enemy_pos)
                        if NPC.IsHero(enemy) then
                            score = score + 250
                        end
                        if current_target and enemy == current_target then
                            score = score + 500
                        end
                        if score > best_score then
                            best_score = score
                            best_target = enemy
                        end
                    end
                end
            end

            target = best_target
        end

        if not target then
            return nil
        end

        Ability.CastTarget(ability, target)
        return metadata.display or ability_name
    elseif metadata.type == "point" then
        local target = current_target

        if target and not EnemySatisfiesMetadata(target, metadata, ability) then
            target = nil
        end

        if target then
            local target_pos = Entity.GetAbsOrigin(target)
            if not IsInExtendedRange(unit_pos, target_pos, ability, metadata) then
                target = nil
            end
        end

        if not target then
            local hero_team = my_hero and Entity.GetTeamNum(my_hero)
            local search_radius = (metadata.fixed_range or (Ability.GetCastRange and Ability.GetCastRange(ability)) or 600)
            search_radius = search_radius + (metadata.range_buffer or 0) + (metadata.search_radius_bonus or 0)
            local enemies = (hero_team and NPCs.InRadius(unit_pos, search_radius, hero_team, Enum.TeamType.TEAM_ENEMY)) or {}
            local best_target = nil
            local best_distance = math.huge

            for _, enemy in ipairs(enemies) do
                if EnemySatisfiesMetadata(enemy, metadata, ability) then
                    local enemy_pos = Entity.GetAbsOrigin(enemy)
                    if IsInExtendedRange(unit_pos, enemy_pos, ability, metadata) then
                        local distance = unit_pos:Distance(enemy_pos)
                        if distance < best_distance then
                            best_distance = distance
                            best_target = enemy
                        end
                    end
                end
            end

            target = best_target
        end

        if not target then
            return nil
        end

        local target_pos = Entity.GetAbsOrigin(target)
        Ability.CastPosition(ability, target_pos)
        return metadata.display or ability_name
    elseif metadata.type == "no_target" then
        if metadata.requires_charges then
            local charges = GetAbilityCharges(ability)
            if not charges or charges <= 0 then
                return nil
            end
        end

        local radius = metadata.radius or (Ability.GetCastRange and Ability.GetCastRange(ability)) or 0
        if radius <= 0 then
            radius = 250
        end

        local total, hero_count = CountEnemiesAround(unit_pos, radius)
        local relevant_count = metadata.only_heroes and hero_count or total
        if relevant_count < (metadata.min_enemies or 1) then
            return nil
        end

        Ability.CastNoTarget(ability)
        return metadata.display or ability_name
    elseif metadata.type == "ally_target" then
        local ally = ChooseAllyTarget(unit, metadata)
        if not ally or not Entity.IsAlive(ally) then
            return nil
        end

        Ability.CastTarget(ability, ally)
        return metadata.display or ability_name
    end

    return nil
end

local function TryUseAbilities(unit, current_target)
    if not ShouldAutoCast() or not unit then
        return nil
    end

    for slot = 0, 5 do
        local ability = NPC.GetAbilityByIndex(unit, slot)
        if ability and Ability.GetLevel(ability) > 0 then
            local metadata = GetAbilityMetadata(Ability.GetName(ability))
            local cast_name = TryCastAbility(unit, ability, metadata, current_target)
            if cast_name then
                return cast_name
            end
        end
    end

    return nil
end

local function IssueFollowOrders()
    if not my_hero or not local_player then
        return
    end

    local hero_pos = Entity.GetAbsOrigin(my_hero)
    local current_time = GlobalVars.GetCurTime()

    local follow_distance = GetFollowDistance()
    local current_target = nil

    if ShouldAutoAttack() then
        current_target = AcquireAttackTarget(hero_pos)
    end

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

            local ability_cast = TryUseAbilities(unit, current_target)
            if not ability_cast and not current_target then
                ability_cast = TryUseAbilities(unit, nil)
            end

            if ability_cast then
                follower.last_action = string.format("Использую: %s", ability_cast)
                follower.next_action_time = current_time + ORDER_COOLDOWN
                goto continue
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
            elseif distance > follow_distance then
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
