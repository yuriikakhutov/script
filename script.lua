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
        message = "Бросаю валун",
        aliases = {
            "ancient_rock_golem_hurl_boulder",
        },
    },
    ogre_bruiser_ogre_smash = {
        behavior = "point",
        target = "enemy",
        require_attack_target = true,
        allow_creeps = true,
        allow_neutrals = true,
        radius = 300,
        message = "Размазываю врага",
        aliases = {
            "ogre_mauler_smash",
        },
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
        always_cast = true,
        ignore_is_castable = true,
        message = "Призываю скелетов",
        aliases = {
            "dark_troll_summoner_raise_dead",
        },
    },
    satyr_hellcaller_shockwave = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        min_enemies = 1,
        message = "Шоковая волна",
    },
    satyr_trickster_purge = {
        behavior = "target",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        message = "Пургую цель",
    },
    harpy_storm_chain_lightning = {
        behavior = "target",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        message = "Цепная молния",
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
    ancient_thunderhide_slam = {
        behavior = "no_target",
        radius = 315,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Грохочу копытом",
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
    ancient_black_dragon_fireball = {
        behavior = "point",
        target = "enemy",
        allow_creeps = true,
        allow_neutrals = true,
        min_enemies = 1,
        message = "Огненный шар",
        aliases = {
            "black_dragon_fireball",
        },
    },
    satyr_soulstealer_mana_burn = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Выжигаю ману",
    },
    crystal_maiden_crystal_nova = {
        behavior = "point",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Кристальная нова",
    },
    crystal_maiden_frostbite = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Замораживаю цель",
    },
    axe_berserkers_call = {
        behavior = "no_target",
        radius = 315,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Зов Берсерка",
    },
    axe_battle_hunger = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        allow_neutrals = false,
        avoid_modifier = "modifier_axe_battle_hunger",
        message = "Battle Hunger",
    },
    axe_culling_blade = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = false,
        logic = "axe_culling_blade",
        message = "Culling Blade",
    },
    centaur_hoof_stomp = {
        behavior = "no_target",
        radius = 315,
        min_enemies = 1,
        allow_creeps = true,
        allow_neutrals = true,
        message = "Hoof Stomp",
    },
    centaur_double_edge = {
        behavior = "target",
        target = "enemy",
        prefer_attack_target = true,
        allow_creeps = true,
        message = "Double Edge",
    },
    centaur_stampede = {
        behavior = "no_target",
        min_enemies = 1,
        global_range = 1200,
        message = "Stampede",
    },
    legion_commander_overwhelming_odds = {
        behavior = "point",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        min_enemies = 1,
        message = "Overwhelming Odds",
    },
    legion_commander_press_the_attack = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        include_self = true,
        ally_max_health_pct = 0.8,
        message = "Press the Attack",
    },
    legion_commander_duel = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = false,
        message = "Дуэль",
    },
    lich_frost_shield = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        include_self = true,
        avoid_modifier = "modifier_lich_frost_shield",
        message = "Frost Shield",
    },
    lich_sinister_gaze = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = false,
        message = "Sinister Gaze",
    },
    shadow_shaman_ether_shock = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Ether Shock",
    },
    shadow_shaman_shackles = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = false,
        message = "Shackles",
    },
    shadow_shaman_voodoo = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Hex",
    },
    witch_doctor_paralyzing_cask = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Paralyzing Cask",
    },
    witch_doctor_maledict = {
        behavior = "point",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        min_enemies = 1,
        message = "Maledict",
    },
    lion_impale = {
        behavior = "point",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Impale",
    },
    lion_voodoo = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Hex",
    },
    lion_mana_drain = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Mana Drain",
    },
    lion_finger_of_death = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = false,
        message = "Finger of Death",
    },
    ogre_magi_fireblast = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Fireblast",
    },
    ogre_magi_ignite = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Ignite",
    },
    beastmaster_wild_axes = {
        behavior = "point",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Wild Axes",
    },
    beastmaster_primal_roar = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = false,
        message = "Primal Roar",
    },
    chen_holy_persuasion = {
        behavior = "target",
        target = "enemy",
        allow_creeps = false,
        allow_neutrals = true,
        message = "Holy Persuasion",
    },
    chen_penitence = {
        behavior = "target",
        target = "enemy",
        prefer_heroes = true,
        allow_creeps = true,
        message = "Penitence",
    },
    chen_divine_favor = {
        behavior = "target",
        target = "ally",
        prefer_anchor = true,
        include_self = true,
        message = "Divine Favor",
    },
}

local function ExpandAbilityAliases()
    local alias_pairs = {}

    for ability_name, metadata in pairs(ABILITY_DATA) do
        local aliases = metadata and metadata.aliases
        if type(aliases) == "table" then
            for _, alias in ipairs(aliases) do
                if type(alias) == "string" then
                    alias_pairs[#alias_pairs + 1] = { alias, metadata }
                end
            end
        end
    end

    for _, pair in ipairs(alias_pairs) do
        local alias_name, metadata = pair[1], pair[2]
        if ABILITY_DATA[alias_name] == nil then
            ABILITY_DATA[alias_name] = metadata
        end
    end
end

ExpandAbilityAliases()

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

local function GetAbilityMetadata(name)
    if not name then
        return nil
    end

    return ABILITY_DATA[name]
end

local function GetAbilityCastRange(ability, metadata)
    if metadata and metadata.cast_range then
        return metadata.cast_range
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

local function GetAbilityCharges(ability)
    if type(Ability.GetCurrentAbilityCharges) == "function" then
        local charges = Ability.GetCurrentAbilityCharges(ability)
        if charges ~= nil then
            return charges
        end
    end

    if type(Ability.GetCurrentCharges) == "function" then
        local charges = Ability.GetCurrentCharges(ability)
        if charges ~= nil then
            return charges
        end
    end

    if type(Ability.GetRemainingCharges) == "function" then
        local charges = Ability.GetRemainingCharges(ability)
        if charges ~= nil then
            return charges
        end
    end

    return nil
end

local function GetUnitHealthPercent(unit)
    if not unit then
        return 0
    end

    local max_health = Entity.GetMaxHealth(unit)
    if not max_health or max_health <= 0 then
        return 0
    end

    local health = Entity.GetHealth(unit) or 0
    return health / max_health
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

    if metadata and metadata.ignore_is_castable then
        -- skip checks
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

    if metadata and metadata.requires_charges then
        local charges = GetAbilityCharges(ability)
        if charges ~= nil and charges <= 0 then
            return false
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

    if NPC.IsIllusion(enemy) or NPC.IsCourier(enemy) then
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

    if metadata.avoid_modifier and NPC.HasModifier(enemy, metadata.avoid_modifier) then
        return false
    end

    if metadata.min_health_pct and GetUnitHealthPercent(enemy) < metadata.min_health_pct then
        return false
    end

    if metadata.max_health_pct and GetUnitHealthPercent(enemy) > metadata.max_health_pct then
        return false
    end

    return true
end

local function ValidateAllyTarget(ally, metadata, context)
    if not ally or not Entity.IsAlive(ally) then
        return false
    end

    if NPC.IsIllusion(ally) and ally ~= my_hero then
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

    if (metadata.allow_neutrals or metadata.allow_creeps) and context.allow_creeps then
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
        local target_pos = Entity.GetAbsOrigin(attack_target)
        if target_pos and context.unit_pos:Distance(target_pos) <= cast_range + (metadata.range_buffer or 0) then
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
        for _, candidate in ipairs(enemies) do
            if ValidateEnemyTarget(candidate, metadata, context) then
                local candidate_pos = Entity.GetAbsOrigin(candidate)
                if candidate_pos then
                    local distance = context.unit_pos:Distance(candidate_pos)
                    if distance <= cast_range + (metadata.range_buffer or 0) then
                        local score = -distance
                        if metadata.prefer_heroes and NPC.IsHero(candidate) then
                            score = score + 100
                        end
                        if metadata.prefer_low_health then
                            score = score + (1 - GetUnitHealthPercent(candidate)) * 50
                        end
                        if score > best_score then
                            best_score = score
                            best_target = candidate
                        end
                    end
                end
            end
        end

        if metadata.allow_neutrals and context.allow_creeps then
            local neutrals = NPCs.InRadius(center, cast_range, context.hero_team, Enum.TeamType.TEAM_NEUTRAL) or {}
            for _, candidate in ipairs(neutrals) do
                if ValidateEnemyTarget(candidate, metadata, context) then
                    local candidate_pos = Entity.GetAbsOrigin(candidate)
                    if candidate_pos then
                        local distance = context.unit_pos:Distance(candidate_pos)
                        if distance <= cast_range + (metadata.range_buffer or 0) then
                            local score = -distance
                            if metadata.prefer_low_health then
                                score = score + (1 - GetUnitHealthPercent(candidate)) * 25
                            end
                            if score > best_score then
                                best_score = score
                                best_target = candidate
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
            if ValidateAllyTarget(ally, metadata, context) then
                local ally_pos = Entity.GetAbsOrigin(ally)
                if ally_pos then
                    local distance = context.unit_pos:Distance(ally_pos)
                    if distance <= cast_range + (metadata.range_buffer or 0) then
                        local score = -distance
                        if metadata.prefer_heroes and NPC.IsHero(ally) then
                            score = score + 50
                        end
                        if metadata.prefer_anchor and context.anchor_unit and ally == context.anchor_unit then
                            score = score + 25
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

local CUSTOM_LOGIC = {}

CUSTOM_LOGIC.axe_culling_blade = function(context, ability, metadata)
    local cast_range = GetAbilityCastRange(ability, metadata)
    local target = context.current_target
    if not target or not ValidateEnemyTarget(target, metadata, context) then
        target = FindBestEnemyTarget(metadata, context, cast_range)
    end

    if not target or not ValidateEnemyTarget(target, metadata, context) then
        return false
    end

    local target_pos = Entity.GetAbsOrigin(target)
    if not target_pos or context.unit_pos:Distance(target_pos) > cast_range + (metadata.range_buffer or 0) then
        return false
    end

    local threshold = nil
    if type(Ability.GetSpecialValueFor) == "function" then
        threshold = Ability.GetSpecialValueFor(ability, "kill_threshold")
            or Ability.GetSpecialValueFor(ability, "kill_threshold_tooltip")
    end

    if not threshold and type(Ability.GetLevelSpecialValueFor) == "function" then
        local level = Ability.GetLevel(ability) or 0
        if level > 0 then
            threshold = Ability.GetLevelSpecialValueFor(ability, "kill_threshold", level - 1)
        end
    end

    if not threshold and metadata.kill_threshold then
        threshold = metadata.kill_threshold
    end

    if not threshold then
        return false
    end

    if Entity.GetHealth(target) > threshold then
        return false
    end

    Ability.CastTarget(ability, target)
    return true, metadata.message or "Использую способность"
end

local function SelectCastPosition(metadata, context, cast_range)
    if metadata.position_source == "self" then
        return context.unit_pos
    end

    if metadata.position_source == "anchor" and context.anchor_pos then
        return context.anchor_pos
    end

    local target = context.current_target
    if metadata.prefer_attack_target and target then
        local target_pos = Entity.GetAbsOrigin(target)
        if target_pos and context.unit_pos:Distance(target_pos) <= cast_range + (metadata.range_buffer or 0) then
            return target_pos
        end
    end

    target = FindBestEnemyTarget(metadata, context, cast_range)
    if target then
        return Entity.GetAbsOrigin(target)
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
    if metadata.logic and CUSTOM_LOGIC[metadata.logic] then
        local success, message = CUSTOM_LOGIC[metadata.logic](context, ability, metadata)
        if success then
            return true, message
        end

        return false
    end

    local cast_range = GetAbilityCastRange(ability, metadata)

    if metadata.behavior == "target" then
        if metadata.target == "ally" then
            local ally = FindBestAllyTarget(metadata, context, cast_range)
            if ally then
                Ability.CastTarget(ability, ally)
                local message = metadata.message or "Поддержка союзника"
                return true, message
            end
        else
            local enemy = FindBestEnemyTarget(metadata, context, cast_range)
            if enemy then
                Ability.CastTarget(ability, enemy)
                local message = metadata.message or "Атакую способностью"
                return true, message
            end
        end
    elseif metadata.behavior == "point" then
        local cast_position = SelectCastPosition(metadata, context, cast_range)
        if cast_position then
            Ability.CastPosition(ability, cast_position)
            local message = metadata.message or "Кидаю способность"
            return true, message
        end
    elseif metadata.behavior == "no_target" then
        if ShouldCastNoTargetAbility(metadata, context, ability) then
            Ability.CastNoTarget(ability)
            local message = metadata.message or "Активирую способность"
            return true, message
        end
    elseif metadata.behavior == "toggle" then
        if type(Ability.GetToggleState) == "function" and not Ability.GetToggleState(ability) then
            Ability.Toggle(ability)
            local message = metadata.message or "Включаю способность"
            return true, message
        end
    end

    return false
end

local function TryCastAbilities(follower, unit, context, current_time)
    if not agent_script.ui.auto_cast or not agent_script.ui.auto_cast:Get() then
        return false
    end

    for slot = 0, 23 do
        local ability = NPC.GetAbilityByIndex(unit, slot)
        if ability then
            local ability_name = Ability.GetName(ability)
            local metadata = GetAbilityMetadata(ability_name)
            if metadata and IsAbilityReady(unit, ability, metadata) then
                local success, message = TryCastAbility(context, ability, metadata)
                if success then
                    follower.last_action = message
                    follower.next_action_time = current_time + (metadata.post_cast_delay or ORDER_COOLDOWN)
                    return true
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
    local allow_creep_targets = AllowCreepTargets()

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

        local need_target = auto_attack or (agent_script.ui.auto_cast and agent_script.ui.auto_cast:Get())
        local current_target = nil
        if need_target then
            current_target = AcquireAttackTarget(unit_pos, leash_target, attack_radius)
        end

        local context = {
            unit = unit,
            unit_pos = unit_pos,
            anchor_unit = anchor_unit,
            anchor_pos = anchor_pos,
            current_target = current_target,
            hero_team = Entity.GetTeamNum(my_hero),
            allow_creeps = allow_creep_targets,
        }

        if TryCastAbilities(follower, unit, context, current_time) then
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
