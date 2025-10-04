local agent_script = {}

agent_script.ui = {}

local DEFAULT_FOLLOW_DISTANCE = 300
local DEFAULT_ATTACK_RADIUS = 900
local ORDER_COOLDOWN = 0.3
local TEAM_NEUTRAL = Enum.TeamNum and Enum.TeamNum.TEAM_NEUTRAL or 4

local ABILITY_DATA = {
    mud_golem_hurl_boulder = {
        behavior = "target",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        range_buffer = 50,
        prefer_heroes = true,
        message = "Бросаю валун",
        aliases = {
            "ancient_rock_golem_hurl_boulder",
        },
    },
    mud_golem_rock_destroy = {
        behavior = "no_target",
        radius = 300,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Взрываю осколок",
    },
    ogre_bruiser_ogre_smash = {
        behavior = "point",
        target = "enemy",
        require_attack_target = true,
        allow_creeps = true,
        allow_neutrals = true,
        fixed_range = 350,
        range_buffer = 50,
        message = "Размазываю врага",
        aliases = {
            "ogre_mauler_smash",
        },
    },
    ogre_magi_frost_armor = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        include_self = true,
        avoid_modifier = "modifier_ogre_magi_frost_armor",
        message = "Накладываю ледяную броню",
    },
    forest_troll_high_priest_heal = {
        behavior = "target",
        target = "ally",
        prefer_heroes = true,
        ally_max_health_pct = 0.9,
        message = "Лечу союзника",
    },
    dark_troll_warlord_ensnare = {
        behavior = "target",
        target = "enemy",
        prefer_attack_target = true,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Бросаю сеть",
    },
    dark_troll_warlord_raise_dead = {
        behavior = "no_target",
        requires_charges = true,
        ignore_charge_count = true,
        always_cast = true,
        ignore_is_castable = true,
        min_enemies = 0,
        message = "Призываю скелетов",
        aliases = {
            "dark_troll_summoner_raise_dead",
            "dark_troll_warlord_raise_dead_datadriven",
        },
    },
    satyr_hellcaller_shockwave = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        min_enemies = 1,
        fixed_range = 800,
        message = "Шоковая волна",
    },
    satyr_trickster_purge = {
        behavior = "target",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        message = "Пургую цель",
    },
    satyr_mindstealer_mana_burn = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        allow_neutrals = true,
        min_mana_on_target = 75,
        message = "Выжигаю ману",
    },
    satyr_soulstealer_mana_burn = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        allow_neutrals = true,
        min_mana_on_target = 75,
        message = "Выжигаю ману",
    },
    harpy_storm_chain_lightning = {
        behavior = "target",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        message = "Цепная молния",
    },
    harpy_scout_takeoff = {
        behavior = "toggle",
        message = "Взмываю в воздух",
    },
    centaur_khan_war_stomp = {
        behavior = "no_target",
        radius = 315,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Оглушаю копытом",
        aliases = {
            "neutral_centaur_khan_war_stomp",
        },
    },
    polar_furbolg_ursa_warrior_thunder_clap = {
        behavior = "no_target",
        radius = 315,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Грохочу лапами",
        aliases = {
            "hellbear_smasher_thunder_clap",
        },
    },
    hellbear_smasher_slam = {
        behavior = "no_target",
        radius = 350,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Сокрушаю врагов",
    },
    ancient_thunderhide_slam = {
        behavior = "no_target",
        radius = 315,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Удар молнии",
        aliases = {
            "thunderhide_slam",
        },
    },
    ancient_thunderhide_frenzy = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        include_self = false,
        message = "Ускоряю союзника",
        aliases = {
            "thunderhide_frenzy",
        },
    },
    big_thunder_lizard_slam = {
        behavior = "no_target",
        radius = 350,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Грозовой удар",
    },
    big_thunder_lizard_frenzy = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        include_self = false,
        message = "Вдохновляю на атаку",
    },
    ancient_black_dragon_fireball = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        min_enemies = 1,
        fixed_range = 750,
        message = "Огненный шар",
        aliases = {
            "black_dragon_fireball",
        },
    },
    wildwing_ripper_tornado = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        fixed_range = 800,
        message = "Запускаю торнадо",
        is_channeled = true,
        aliases = {
            "enraged_wildkin_tornado",
        },
    },
    wildwing_ripper_hurricane = {
        behavior = "target",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        message = "Подбрасываю врага",
        aliases = {
            "enraged_wildkin_hurricane",
        },
    },
    giant_wolf_intimidate = {
        behavior = "no_target",
        radius = 375,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Пугаю врага",
    },
    alpha_wolf_howl = {
        behavior = "no_target",
        radius = 900,
        min_enemies = 0,
        always_cast = true,
        message = "Боевой вой",
    },
    fel_beast_haunt = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        allow_neutrals = true,
        range_buffer = 50,
        message = "Насылаю ужас",
    },
    ghost_frost_attack = {
        behavior = "target",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        message = "Ослабляю врага",
    },
    ancient_rumblehide_spell = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        min_enemies = 1,
        fixed_range = 900,
        message = "Ударная волна",
    },
    prowler_shaman_overgrowth = {
        behavior = "no_target",
        radius = 350,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Корни врагов",
    },
    prowler_acolyte_heal = {
        behavior = "target",
        target = "ally",
        prefer_heroes = true,
        ally_max_health_pct = 0.85,
        message = "Лечу союзника",
    },
    frogmen_arm_of_the_deep = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        min_enemies = 1,
        fixed_range = 300,
        range_buffer = 50,
        message = "Удар глубин",
    },
    frogmen_tendrils_of_the_deep = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        min_enemies = 1,
        fixed_range = 325,
        range_buffer = 50,
        message = "Щупальца глубин",
    },
    frogmen_congregation_of_the_deep = {
        behavior = "no_target",
        radius = 325,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Прилив глубин",
    },
    frogmen_water_bubble_small = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        prefer_heroes = true,
        include_self = true,
        ally_max_health_pct = 0.95,
        message = "Малый пузырь защиты",
    },
    frogmen_water_bubble_medium = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        prefer_heroes = true,
        include_self = true,
        ally_max_health_pct = 0.95,
        message = "Средний пузырь защиты",
    },
    frogmen_water_bubble_large = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        prefer_heroes = true,
        include_self = true,
        ally_max_health_pct = 0.95,
        message = "Большой пузырь защиты",
    },
}

local function ExpandAbilityAliases()
    local copies = {}

    for ability_name, metadata in pairs(ABILITY_DATA) do
        if metadata.aliases then
            for _, alias in ipairs(metadata.aliases) do
                if type(alias) == "string" then
                    copies[#copies + 1] = { alias, metadata }
                end
            end
        end
    end

    for _, pair in ipairs(copies) do
        local alias, metadata = pair[1], pair[2]
        if ABILITY_DATA[alias] == nil then
            ABILITY_DATA[alias] = metadata
        end
    end
end

ExpandAbilityAliases()

local tracked_units = {}
local my_hero = nil
local local_player = nil
local local_player_id = nil
local debug_font = nil
local menu_initialized = false

local function EnsureFont()
    if not debug_font then
        debug_font = Render.LoadFont("Arial", 12, Enum.FontCreate.FONTFLAG_OUTLINE)
    end
    return debug_font
end

local function ResetState()
    tracked_units = {}
    my_hero = nil
    local_player = nil
    local_player_id = nil
end

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
        local nested = target_group:Create("Поведение")
        if nested then
            target_group = nested
        end
    end

    if not target_group then
        return
    end

    local function Tooltip(control, text)
        if control and type(control.ToolTip) == "function" then
            control:ToolTip(text)
        end
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.enable = target_group:Switch("Включить скрипт", true, "\u{f205}")
        Tooltip(agent_script.ui.enable, "Автоматически управлять подконтрольными юнитами.")
    end

    if type(target_group.Slider) == "function" then
        agent_script.ui.follow_distance = target_group:Slider("Дистанция следования", 100, 800, DEFAULT_FOLLOW_DISTANCE, "%d")
        Tooltip(agent_script.ui.follow_distance, "На каком расстоянии от героя держатся юниты.")
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.auto_attack = target_group:Switch("Автоатака", true, "\u{f0e7}")
        Tooltip(agent_script.ui.auto_attack, "Атаковать врагов поблизости автоматически.")
    end

    if type(target_group.Slider) == "function" then
        agent_script.ui.attack_radius = target_group:Slider("Радиус атаки", 300, 1200, DEFAULT_ATTACK_RADIUS, "%d")
        Tooltip(agent_script.ui.attack_radius, "Радиус поиска целей для атаки.")
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.auto_cast = target_group:Switch("Авто навыки", true, "\u{f0a4}")
        Tooltip(agent_script.ui.auto_cast, "Использовать способности юнитов автоматически.")

        agent_script.ui.cast_on_creeps = target_group:Switch("Каст по крипам", true, "\u{f06d}")
        Tooltip(agent_script.ui.cast_on_creeps, "Разрешить применять способности по вражеским и нейтральным крипам.")
    end

    if type(target_group.Switch) == "function" then
        agent_script.ui.debug = target_group:Switch("Отладка", true, "\u{f05a}")
        Tooltip(agent_script.ui.debug, "Показывать статус над юнитами.")
    end

    menu_initialized = true
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

local function AllowCreepTargets()
    if agent_script.ui.cast_on_creeps then
        return agent_script.ui.cast_on_creeps:Get()
    end

    return true
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

local function GetUnitHealthPercent(unit)
    if not unit or not Entity.IsAlive(unit) then
        return 0
    end

    local max_health = Entity.GetMaxHealth(unit)
    if not max_health or max_health <= 0 then
        return 0
    end

    local health = Entity.GetHealth(unit) or 0
    return health / max_health
end

local function GetAbilityCharges(ability)
    if not ability then
        return nil
    end

    local readers = {
        "GetCurrentAbilityCharges",
        "GetCurrentCharges",
        "GetRemainingCharges",
        "GetSecondaryCharges",
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

local function GetAbilityCastRange(ability, metadata)
    if metadata and metadata.fixed_range then
        return metadata.fixed_range
    end

    if type(Ability.GetCastRange) == "function" then
        local range = Ability.GetCastRange(ability)
        if range and range > 0 then
            return range
        end
    end

    if metadata and metadata.radius then
        return metadata.radius
    end

    return DEFAULT_ATTACK_RADIUS
end

local function GetAbilityRadius(ability, metadata)
    if metadata and metadata.radius then
        return metadata.radius
    end

    if type(Ability.GetAOERadius) == "function" then
        local radius = Ability.GetAOERadius(ability)
        if radius and radius > 0 then
            return radius
        end
    end

    return nil
end

local function IsAbilityReady(unit, ability, metadata)
    if not ability then
        return false
    end

    if type(Ability.GetLevel) == "function" and Ability.GetLevel(ability) <= 0 then
        return false
    end

    if type(Ability.IsHidden) == "function" and Ability.IsHidden(ability) then
        return false
    end

    if type(Ability.IsPassive) == "function" and Ability.IsPassive(ability) then
        return false
    end

    local needs_fallback_ready_check = false

    if metadata and metadata.requires_charges then
        local charges = GetAbilityCharges(ability)
        if charges ~= nil and charges <= 0 then
            if metadata.ignore_charge_count then
                needs_fallback_ready_check = true
            else
                return false
            end
        end
    end

    local skip_castable_check = metadata and metadata.ignore_is_castable

    if skip_castable_check then
        if needs_fallback_ready_check then
            local fallback_ready = false
            if type(Ability.IsReady) == "function" then
                fallback_ready = Ability.IsReady(ability)
            elseif type(Ability.IsCastable) == "function" and unit then
                fallback_ready = Ability.IsCastable(ability, NPC.GetMana(unit))
            else
                fallback_ready = true
            end

            if not fallback_ready then
                return false
            end
        end
    else
        if type(Ability.IsReady) == "function" then
            if not Ability.IsReady(ability) then
                return false
            end
        elseif type(Ability.IsCastable) == "function" and unit then
            if not Ability.IsCastable(ability, NPC.GetMana(unit)) then
                return false
            end
        end
    end

    if unit and type(NPC.IsSilenced) == "function" and NPC.IsSilenced(unit) then
        return false
    end

    return true
end

local function ValidateEnemyTarget(enemy, metadata, context)
    if not enemy or not Entity.IsAlive(enemy) then
        return false
    end

    if NPC.IsCourier(enemy) or NPC.IsIllusion(enemy) then
        return false
    end

    local team = Entity.GetTeamNum(enemy)
    if team == context.hero_team then
        return false
    end

    local is_hero = NPC.IsHero(enemy)
    local is_creep = NPC.IsCreep(enemy) and not is_hero

    local allow_creeps = metadata.allow_creeps
    if allow_creeps == nil then
        allow_creeps = true
    end

    local allow_neutrals = metadata.allow_neutrals
    if allow_neutrals == nil then
        allow_neutrals = allow_creeps
    end

    if is_creep then
        if not allow_creeps then
            return false
        end

        if not context.allow_creeps then
            return false
        end
    end

    if team == TEAM_NEUTRAL and not allow_neutrals then
        return false
    end

    if metadata.only_heroes and not is_hero then
        return false
    end

    if metadata.min_mana_on_target and NPC.GetMana(enemy) < metadata.min_mana_on_target then
        return false
    end

    if metadata.max_enemy_health_pct and GetUnitHealthPercent(enemy) > metadata.max_enemy_health_pct then
        return false
    end

    if metadata.avoid_modifier and NPC.HasModifier(enemy, metadata.avoid_modifier) then
        return false
    end

    return true
end

local function ValidateAllyTarget(ally, metadata, context)
    if not ally or not Entity.IsAlive(ally) then
        return false
    end

    if NPC.IsCourier(ally) then
        return false
    end

    if Entity.GetTeamNum(ally) ~= context.hero_team then
        return false
    end

    if metadata.include_self == false and ally == context.unit then
        return false
    end

    if metadata.ally_max_health_pct and GetUnitHealthPercent(ally) > metadata.ally_max_health_pct then
        return false
    end

    if metadata.ally_min_health_pct and GetUnitHealthPercent(ally) < metadata.ally_min_health_pct then
        return false
    end

    if metadata.avoid_modifier and NPC.HasModifier(ally, metadata.avoid_modifier) then
        return false
    end

    return true
end

local function CountEnemies(center, radius, metadata, context)
    if not center or not radius then
        return 0
    end

    local count = 0
    local enemies = NPCs.InRadius(center, radius, context.hero_team, Enum.TeamType.TEAM_ENEMY) or {}
    for _, enemy in ipairs(enemies) do
        if ValidateEnemyTarget(enemy, metadata, context) then
            count = count + 1
        end
    end

    if context.allow_creeps and (metadata.allow_neutrals or metadata.allow_creeps) then
        local neutrals = NPCs.InRadius(center, radius, context.hero_team, Enum.TeamType.TEAM_NEUTRAL) or {}
        for _, enemy in ipairs(neutrals) do
            if ValidateEnemyTarget(enemy, metadata, context) then
                count = count + 1
            end
        end
    end

    return count
end

local function FindBestEnemyTarget(metadata, context, cast_range)
    local attack_target = context.current_target
    if attack_target and ValidateEnemyTarget(attack_target, metadata, context) then
        local pos = Entity.GetAbsOrigin(attack_target)
        if pos and context.unit_pos:Distance(pos) <= cast_range + (metadata.range_buffer or 0) then
            return attack_target
        end
        if metadata.require_attack_target then
            return nil
        end
    elseif metadata.require_attack_target then
        return nil
    end

    local centers = { context.unit_pos }
    if context.anchor_pos then
        centers[#centers + 1] = context.anchor_pos
    end

    local best_target = nil
    local best_score = -math.huge

    for _, center in ipairs(centers) do
        local enemies = NPCs.InRadius(center, cast_range, context.hero_team, Enum.TeamType.TEAM_ENEMY) or {}
        for _, enemy in ipairs(enemies) do
            if ValidateEnemyTarget(enemy, metadata, context) then
                local enemy_pos = Entity.GetAbsOrigin(enemy)
                if enemy_pos then
                    local distance = context.unit_pos:Distance(enemy_pos)
                    if distance <= cast_range + (metadata.range_buffer or 0) then
                        local score = -distance
                        if metadata.prefer_heroes and NPC.IsHero(enemy) then
                            score = score + 200
                        end
                        if metadata.prefer_low_health then
                            score = score + (1 - GetUnitHealthPercent(enemy)) * 100
                        end
                        if score > best_score then
                            best_score = score
                            best_target = enemy
                        end
                    end
                end
            end
        end

        if context.allow_creeps and metadata.allow_neutrals then
            local neutrals = NPCs.InRadius(center, cast_range, context.hero_team, Enum.TeamType.TEAM_NEUTRAL) or {}
            for _, enemy in ipairs(neutrals) do
                if ValidateEnemyTarget(enemy, metadata, context) then
                    local enemy_pos = Entity.GetAbsOrigin(enemy)
                    if enemy_pos then
                        local distance = context.unit_pos:Distance(enemy_pos)
                        if distance <= cast_range + (metadata.range_buffer or 0) then
                            local score = -distance
                            if metadata.prefer_low_health then
                                score = score + (1 - GetUnitHealthPercent(enemy)) * 50
                            end
                            if score > best_score then
                                best_score = score
                                best_target = enemy
                            end
                        end
                    end
                end
            end
        end
    end

    return best_target
end

local function FindBestAllyTarget(metadata, context, cast_range)
    if metadata.prefer_anchor and context.anchor_unit and Entity.IsAlive(context.anchor_unit) then
        local anchor_pos = Entity.GetAbsOrigin(context.anchor_unit)
        if anchor_pos and context.unit_pos:Distance(anchor_pos) <= cast_range + (metadata.range_buffer or 0) then
            if ValidateAllyTarget(context.anchor_unit, metadata, context) then
                return context.anchor_unit
            end
        end
    end

    if metadata.include_self and ValidateAllyTarget(context.unit, metadata, context) then
        return context.unit
    end

    local centers = { context.unit_pos }
    if context.anchor_pos then
        centers[#centers + 1] = context.anchor_pos
    end

    local best_target = nil
    local best_score = -math.huge

    for _, center in ipairs(centers) do
        local allies = NPCs.InRadius(center, cast_range, context.hero_team, Enum.TeamType.TEAM_FRIEND) or {}
        for _, ally in ipairs(allies) do
            if ally ~= context.unit and ValidateAllyTarget(ally, metadata, context) then
                local ally_pos = Entity.GetAbsOrigin(ally)
                if ally_pos then
                    local distance = context.unit_pos:Distance(ally_pos)
                    if distance <= cast_range + (metadata.range_buffer or 0) then
                        local score = -distance
                        if metadata.prefer_heroes and NPC.IsHero(ally) then
                            score = score + 100
                        end
                        if metadata.prefer_anchor and context.anchor_unit and ally == context.anchor_unit then
                            score = score + 50
                        end
                        if score > best_score then
                            best_score = score
                            best_target = ally
                        end
                    end
                end
            end
        end
    end

    return best_target
end

local function SelectCastPosition(metadata, context, cast_range)
    if metadata.position_source == "self" then
        return context.unit_pos
    end

    if metadata.position_source == "anchor" and context.anchor_pos then
        return context.anchor_pos
    end

    if metadata.prefer_attack_target and context.current_target then
        local pos = Entity.GetAbsOrigin(context.current_target)
        if pos and context.unit_pos:Distance(pos) <= cast_range + (metadata.range_buffer or 0) then
            return pos
        end
    end

    local target = FindBestEnemyTarget(metadata, context, cast_range)
    if target then
        return Entity.GetAbsOrigin(target)
    end

    if metadata.cast_self then
        return context.unit_pos
    end

    return nil
end

local function ShouldCastNoTargetAbility(metadata, context, ability)
    if metadata.always_cast then
        return true
    end

    local radius = metadata.radius or GetAbilityRadius(ability, metadata)
    local center = context.unit_pos

    if metadata.global_range and context.anchor_pos then
        center = context.anchor_pos
        radius = metadata.global_range
    end

    if not radius then
        return false
    end

    local enemies = CountEnemies(center, radius, metadata, context)
    if metadata.min_enemies then
        return enemies >= metadata.min_enemies
    end

    return enemies > 0
end

local function TryCastAbility(context, ability, metadata)
    local cast_range = GetAbilityCastRange(ability, metadata)

    if metadata.behavior == "target" then
        if metadata.target == "ally" then
            local ally = FindBestAllyTarget(metadata, context, cast_range)
            if ally then
                Ability.CastTarget(ability, ally)
                return true, metadata.message or "Поддерживаю союзника"
            end
        else
            local enemy = FindBestEnemyTarget(metadata, context, cast_range)
            if enemy then
                Ability.CastTarget(ability, enemy)
                return true, metadata.message or "Атакую способность"
            end
        end
    elseif metadata.behavior == "point" then
        local position = SelectCastPosition(metadata, context, cast_range)
        if position then
            Ability.CastPosition(ability, position)
            return true, metadata.message or "Кидаю способность"
        end
    elseif metadata.behavior == "no_target" then
        if ShouldCastNoTargetAbility(metadata, context, ability) then
            Ability.CastNoTarget(ability)
            return true, metadata.message or "Активирую способность"
        end
    elseif metadata.behavior == "toggle" then
        if type(Ability.GetToggleState) == "function" and not Ability.GetToggleState(ability) then
            Ability.Toggle(ability)
            return true, metadata.message or "Включаю способность"
        end
    end

    return false
end

local function TryCastAbilities(follower, unit, context, current_time)
    if type(NPC.IsChannellingAbility) == "function" and NPC.IsChannellingAbility(unit) then
        return false
    end

    local auto_cast_enabled = ShouldAutoCast()

    for slot = 0, 23 do
        local ability = NPC.GetAbilityByIndex(unit, slot)
        if ability then
            local metadata = ABILITY_DATA[Ability.GetName(ability) or ""]
            if metadata and (auto_cast_enabled or metadata.always_cast) then
                if IsAbilityReady(unit, ability, metadata) then
                    local success, message = TryCastAbility(context, ability, metadata)
                    if success then
                        follower.last_action = message
                        follower.next_action_time = current_time + (metadata.post_cast_delay or ORDER_COOLDOWN)
                        return true
                    end
                end
            end
        end
    end

    return false
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

    if not my_hero then
        return false
    end

    local player_controls_unit = true
    if local_player_id then
        player_controls_unit = NPC.IsControllableByPlayer(unit, local_player_id)
    end

    if not player_controls_unit then
        local owner = Entity.GetOwner and Entity.GetOwner(unit) or nil
        if owner then
            if owner == my_hero then
                player_controls_unit = true
            elseif local_player_id and NPC.IsControllableByPlayer(owner, local_player_id) then
                player_controls_unit = true
            else
                local owner_handle = Entity.GetIndex(owner)
                if tracked_units[owner_handle] then
                    player_controls_unit = true
                end
            end
        end
    end

    if not player_controls_unit then
        return false
    end

    return Entity.GetTeamNum(unit) == Entity.GetTeamNum(my_hero)
end

local function UpdateFollowers()
    local current_time = GlobalVars.GetCurTime()
    local next_tracked = {}

    for _, unit in ipairs(NPCs.GetAll()) do
        if IsControlledUnit(unit) then
            local handle = Entity.GetIndex(unit)
            local data = tracked_units[handle]
            if not data then
                data = {
                    unit = unit,
                    next_action_time = 0,
                    last_action = "Ожидаю",
                }
            else
                data.unit = unit
            end

            data.last_seen = current_time
            next_tracked[handle] = data
        end
    end

    tracked_units = next_tracked
end

local function FindAnchor(unit)
    if my_hero and Entity.IsAlive(my_hero) then
        local hero_pos = Entity.GetAbsOrigin(my_hero)
        return my_hero, hero_pos
    end

    local unit_pos = Entity.GetAbsOrigin(unit)
    if not unit_pos or not my_hero then
        return nil, nil
    end

    local hero_team = Entity.GetTeamNum(my_hero)
    local best_ally = nil
    local best_distance = math.huge

    for _, hero in ipairs(Heroes.GetAll()) do
        if hero ~= my_hero and Entity.IsAlive(hero) and Entity.GetTeamNum(hero) == hero_team and not NPC.IsIllusion(hero) then
            local pos = Entity.GetAbsOrigin(hero)
            if pos then
                local distance = unit_pos:Distance(pos)
                if distance < best_distance then
                    best_distance = distance
                    best_ally = hero
                end
            end
        end
    end

    if best_ally then
        return best_ally, Entity.GetAbsOrigin(best_ally)
    end

    return nil, nil
end

local function AcquireAttackTarget(unit_pos, anchor_pos, hero_team, allow_creeps, attack_radius)
    local centers = { unit_pos }
    if anchor_pos then
        centers[#centers + 1] = anchor_pos
    end

    local function FindBest(team_type, predicate)
        local best_target = nil
        local best_distance = math.huge

        for _, center in ipairs(centers) do
            local units = NPCs.InRadius(center, attack_radius, hero_team, team_type) or {}
            for _, candidate in ipairs(units) do
                if Entity.IsAlive(candidate) and Entity.GetTeamNum(candidate) ~= hero_team and not NPC.IsCourier(candidate) and not NPC.IsIllusion(candidate) and predicate(candidate) then
                    local pos = Entity.GetAbsOrigin(candidate)
                    if pos then
                        local distance = center:Distance(pos)
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
        return NPC.IsCreep(enemy)
    end)

    if target then
        return target
    end

    if allow_creeps then
        target = FindBest(Enum.TeamType.TEAM_NEUTRAL, function(enemy)
            return NPC.IsCreep(enemy)
        end)
    end

    return target
end

local function IssueOrders()
    local follow_distance = GetFollowDistance()
    local attack_radius = GetAttackRadius()
    local auto_attack = ShouldAutoAttack()
    local allow_creeps = AllowCreepTargets()
    local current_time = GlobalVars.GetCurTime()

    for _, follower in pairs(tracked_units) do
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

        if type(NPC.IsChannellingAbility) == "function" and NPC.IsChannellingAbility(unit) then
            follower.last_action = "Канализирую способность"
            follower.next_action_time = current_time + ORDER_COOLDOWN
            goto continue
        end

        local anchor_unit, anchor_pos = FindAnchor(unit)
        local hero_team = my_hero and Entity.GetTeamNum(my_hero) or Entity.GetTeamNum(unit)
        local leash_target = anchor_pos
        local anchor_distance = nil

        if leash_target then
            anchor_distance = unit_pos:Distance(leash_target)
        end

        if leash_target and anchor_distance and anchor_distance > follow_distance then
            if local_player then
                Player.PrepareUnitOrders(
                    local_player,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    leash_target,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    unit
                )

                if anchor_unit then
                    follower.last_action = string.format("Следую к: %s", NPC.GetUnitName(anchor_unit) or "союзник")
                else
                    follower.last_action = "Двигаюсь к точке"
                end
                follower.next_action_time = current_time + ORDER_COOLDOWN
                goto continue
            end
        end

        local current_target = nil
        if auto_attack then
            current_target = AcquireAttackTarget(unit_pos, anchor_pos, hero_team, allow_creeps, attack_radius)
        end

        local context = {
            unit = unit,
            unit_pos = unit_pos,
            anchor_unit = anchor_unit,
            anchor_pos = anchor_pos,
            current_target = current_target,
            hero_team = hero_team,
            allow_creeps = allow_creeps,
        }

        if TryCastAbilities(follower, unit, context, current_time) then
            goto continue
        end

        if current_target and Entity.IsAlive(current_target) then
            if local_player then
                Player.PrepareUnitOrders(
                    local_player,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                    current_target,
                    nil,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    unit
                )

                follower.last_action = string.format("Атакую: %s", NPC.GetUnitName(current_target) or "цель")
                follower.next_action_time = current_time + ORDER_COOLDOWN
                goto continue
            end
        end

        if leash_target then
            if anchor_unit then
                follower.last_action = string.format("Рядом с: %s", NPC.GetUnitName(anchor_unit) or "союзник")
            else
                follower.last_action = "Удерживаю позицию"
            end
        else
            follower.last_action = "Ожидаю"
        end

        follower.next_action_time = current_time + ORDER_COOLDOWN

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
    IssueOrders()
end

function agent_script.OnDraw()
    if not my_hero then
        return
    end

    if agent_script.ui.debug and not agent_script.ui.debug:Get() then
        return
    end

    local font = EnsureFont()

    for _, follower in pairs(tracked_units) do
        local unit = follower.unit
        if unit and Entity.IsAlive(unit) and follower.last_action then
            local origin = Entity.GetAbsOrigin(unit)
            if origin then
                local offset = NPC.GetHealthBarOffset(unit) or 0
                local screen_pos, visible = Render.WorldToScreen(origin + Vector(0, 0, offset + 20))
                if visible then
                    Render.Text(font, 12, follower.last_action, screen_pos, Color(180, 220, 255, 255))
                end
            end
        end
    end
end

function agent_script.OnGameEnd()
    ResetState()
end

return agent_script
