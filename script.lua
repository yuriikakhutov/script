---@diagnostic disable: undefined-global

local agent_script = {}
agent_script.ui = {}

local DEFAULT_FOLLOW_DISTANCE = 300
local DEFAULT_ATTACK_RADIUS = 900
local ORDER_COOLDOWN = 0.3

local my_hero = nil
local local_player = nil
local local_player_id = nil
local player_handle = nil
local debug_font = nil
local menu_initialized = false

local followers = {}

local ABILITY_DATA = {
  mud_golem_hurl_boulder = {
    behavior = "target",
    target = "enemy",
    allow_creeps = true,
    allow_neutrals = true,
    range_buffer = 50,
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
    range_buffer = 75,
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
    always_cast = true,
    ignore_charge_count = true,
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
    fixed_range = 800,
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
    fixed_range = 750,
    message = "Огненный шар",
    aliases = {
      "black_dragon_fireball",
    },
  },
}

local function ExpandAbilityAliases()
  local alias_pairs = {}
  for ability_name, metadata in pairs(ABILITY_DATA) do
    if metadata.aliases then
      for _, alias in ipairs(metadata.aliases) do
        table.insert(alias_pairs, { alias, metadata })
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

local function ResetState()
  my_hero = nil
  local_player = nil
  local_player_id = nil
  player_handle = nil
  followers = {}
end

local function EnsureFont()
  if not debug_font and Render and Render.LoadFont then
    debug_font = Render.LoadFont("Arial", Enum.FontCreate and Enum.FontCreate.FONTFLAG_OUTLINE or 0, 12)
  end
  return debug_font
end

local function IsValidPlayerHandle(candidate)
  if not candidate then
    return false
  end

  local candidate_type = type(candidate)
  if candidate_type == "number" or candidate_type == "boolean" or candidate_type == "string" then
    return false
  end

  if candidate_type ~= "table" and candidate_type ~= "userdata" then
    return false
  end

  if candidate.IsNull then
    local ok, is_null = pcall(candidate.IsNull, candidate)
    if ok and is_null then
      return false
    end
  end

  return true
end

local function AcquirePlayerHandle()
  if not IsValidPlayerHandle(player_handle) then
    player_handle = nil
  end

  if player_handle then
    return player_handle
  end

  if Players and Players.GetLocal then
    local candidate = Players.GetLocal()
    if IsValidPlayerHandle(candidate) then
      player_handle = candidate
      return player_handle
    end
  end

  return player_handle
end

local function EnsureMenu()
  if menu_initialized then
    return
  end

  local tab = Menu.Create("Scripts", "Other", "Unit Followers", "Unit Followers", "Main")
  if not tab then
    return
  end

  if tab.Icon then
    tab:Icon("\u{f0c1}")
  end

  local main_group = tab.Create and tab:Create("Настройки") or tab
  if main_group and main_group.Create then
    main_group = main_group:Create("Поведение") or main_group
  end

  local function tooltip(control, text)
    if control and control.ToolTip then
      control:ToolTip(text)
    end
  end

  if main_group and main_group.Switch then
    agent_script.ui.enable = main_group:Switch("Включить", true, "\u{f205}")
    tooltip(agent_script.ui.enable, "Включает управление союзными юнитами.")

    agent_script.ui.auto_attack = main_group:Switch("Автоатака", true, "\u{f0e7}")
    tooltip(agent_script.ui.auto_attack, "Атаковать врагов поблизости.")

    agent_script.ui.auto_cast = main_group:Switch("Авто-умения", true, "\u{f0a4}")
    tooltip(agent_script.ui.auto_cast, "Использовать активные способности нейтралов.")

    agent_script.ui.cast_on_creeps = main_group:Switch("Способности на крипов", true, "\u{f06d}")
    tooltip(agent_script.ui.cast_on_creeps, "Позволять нацеливать умения на крипов и нейтралов.")

    agent_script.ui.debug = main_group:Switch("Отладка", true, "\u{f05a}")
    tooltip(agent_script.ui.debug, "Показывать состояние над юнитами.")
  end

  if main_group and main_group.Slider then
    agent_script.ui.follow_distance = main_group:Slider("Дистанция следования", 100, 800, DEFAULT_FOLLOW_DISTANCE, "%d")
    tooltip(agent_script.ui.follow_distance, "Минимальная дистанция до якоря.")

    agent_script.ui.attack_radius = main_group:Slider("Радиус атаки", 300, 1500, DEFAULT_ATTACK_RADIUS, "%d")
    tooltip(agent_script.ui.attack_radius, "Радиус поиска целей.")
  end

  menu_initialized = true
end

local function GetPlayerID()
  if my_hero and Hero and Hero.GetPlayerID then
    local id = Hero.GetPlayerID(my_hero)
    if id ~= nil and id >= 0 then
      return id
    end
  end

  if Player and Player.GetPlayerID then
    local handle = AcquirePlayerHandle()
    if IsValidPlayerHandle(handle) then
      local ok, id = pcall(Player.GetPlayerID, handle)
      if ok and id ~= nil and id >= 0 then
        return id
      end
    end
  end

  return local_player_id
end

local function ShouldAutoAttack()
  return agent_script.ui.auto_attack and agent_script.ui.auto_attack:Get()
end

local function ShouldAutoCast()
  return agent_script.ui.auto_cast and agent_script.ui.auto_cast:Get()
end

local function ShouldCastOnCreeps()
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

local function IsControlledUnit(unit)
  if not unit or not Entity.IsAlive(unit) then
    return false
  end

  if my_hero and unit == my_hero then
    return false
  end

  if NPC.IsCourier and NPC.IsCourier(unit) then
    return false
  end

  if local_player_id ~= nil and NPC.IsControllableByPlayer then
    if NPC.IsControllableByPlayer(unit, local_player_id) then
      return true
    end
  end

  if my_hero then
    if Entity.GetTeamNum(unit) ~= Entity.GetTeamNum(my_hero) then
      return false
    end

    if NPC.GetUnitOwner then
      local owner = NPC.GetUnitOwner(unit)
      if owner then
        if owner == my_hero then
          return true
        end

        if local_player_id ~= nil then
          local owner_id = Hero and Hero.GetPlayerID and Hero.GetPlayerID(owner)
          if owner_id == local_player_id then
            return true
          end
        end
      end
    end
  end

  if local_player_id == nil and NPC.IsControllableByPlayer then
    for id = 0, 23 do
      if NPC.IsControllableByPlayer(unit, id) then
        if my_hero and Entity.GetTeamNum(unit) == Entity.GetTeamNum(my_hero) then
          return true
        end
      end
    end
  end

  return false
end

local function UpdateFollowers()
  local next_followers = {}
  local now = GlobalVars and GlobalVars.GetCurTime and GlobalVars.GetCurTime() or 0

  for _, unit in ipairs(NPCs.GetAll()) do
    if IsControlledUnit(unit) then
      local handle = Entity.GetIndex(unit)
      local follower = followers[handle]
      if not follower then
        follower = {
          unit = unit,
          next_action_time = 0,
          last_action = "",
        }
      else
        follower.unit = unit
      end

      follower.last_seen = now
      next_followers[handle] = follower
    end
  end

  followers = next_followers
end

local function FindAllyAnchor(unit)
  if my_hero and Entity.IsAlive(my_hero) then
    return my_hero, Entity.GetAbsOrigin(my_hero)
  end

  if not my_hero then
    return nil, nil
  end

  local hero_team = Entity.GetTeamNum(my_hero)
  local unit_pos = Entity.GetAbsOrigin(unit)
  if not unit_pos then
    return nil, nil
  end

  local best_ally = nil
  local best_distance = math.huge

  for _, hero in ipairs(Heroes.GetAll()) do
    if hero ~= my_hero and Entity.IsAlive(hero) and Entity.GetTeamNum(hero) == hero_team and not NPC.IsIllusion(hero) then
      local hero_pos = Entity.GetAbsOrigin(hero)
      if hero_pos then
        local distance = unit_pos:Distance(hero_pos)
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

  for _, name in ipairs(readers) do
    local getter = Ability[name]
    if type(getter) == "function" then
      local ok, value = pcall(getter, ability)
      if ok and type(value) == "number" then
        return value
      end
    end
  end

  return nil
end

local function GetAbilityMetadata(name)
  return ABILITY_DATA[name]
end

local function CountEnemies(position, radius, metadata)
  if not my_hero or not position or radius <= 0 then
    return 0
  end

  local hero_team = Entity.GetTeamNum(my_hero)
  local count = 0

  local function accumulate(team_type)
    local enemies = NPCs.InRadius(position, radius, hero_team, team_type) or {}
    for _, enemy in ipairs(enemies) do
      if Entity.IsAlive(enemy) and Entity.GetTeamNum(enemy) ~= hero_team and not NPC.IsCourier(enemy) then
        if metadata and metadata.only_heroes and not NPC.IsHero(enemy) then
          goto continue
        end

        if NPC.IsCreep(enemy) then
          if not ShouldCastOnCreeps() then
            goto continue
          end

          if metadata and metadata.allow_creeps == false then
            goto continue
          end
        end

        count = count + 1
      end
      ::continue::
    end
  end

  accumulate(Enum.TeamType.TEAM_ENEMY)
  if metadata and metadata.allow_neutrals ~= false then
    accumulate(Enum.TeamType.TEAM_NEUTRAL)
  end

  return count
end

local function GetCastRange(ability, metadata)
  if metadata and metadata.fixed_range then
    return metadata.fixed_range
  end

  if Ability.GetCastRange then
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

local function AbilityIsReady(unit, ability, metadata)
  if not ability then
    return false
  end

  if Ability.GetLevel and Ability.GetLevel(ability) <= 0 then
    return false
  end

  if Ability.IsHidden and Ability.IsHidden(ability) then
    return false
  end

  local mana = NPC.GetMana and NPC.GetMana(unit) or 0

  if not (metadata and metadata.ignore_is_castable) then
    if Ability.IsReady and not Ability.IsReady(ability) then
      return false
    end

    if Ability.IsCastable and not Ability.IsCastable(ability, mana) then
      return false
    end
  end

  if metadata and metadata.requires_charges and not metadata.ignore_charge_count then
    local charges = GetAbilityCharges(ability)
    if charges == nil or charges <= 0 then
      return false
    end
  end

  if metadata and metadata.ignore_charge_count then
    local charges = GetAbilityCharges(ability)
    if charges and charges > 0 then
      return true
    end
  end

  if NPC.IsSilenced and NPC.IsSilenced(unit) then
    return false
  end

  return true
end

local function EnemyMatches(enemy, metadata)
  if not enemy or not Entity.IsAlive(enemy) then
    return false
  end

  if metadata and metadata.only_heroes and not NPC.IsHero(enemy) then
    return false
  end

  if metadata and metadata.allow_creeps == false and NPC.IsCreep(enemy) then
    return false
  end

  if NPC.IsCreep(enemy) and not ShouldCastOnCreeps() then
    return false
  end

  if metadata and metadata.allow_neutrals == false and Entity.GetTeamNum(enemy) == Enum.TeamNum.TEAM_NEUTRAL then
    return false
  end

  if metadata and metadata.min_mana_on_target and NPC.GetMana(enemy) < metadata.min_mana_on_target then
    return false
  end

  if metadata and metadata.avoid_modifier and NPC.HasModifier(enemy, metadata.avoid_modifier) then
    return false
  end

  return true
end

local function FindEnemyTarget(unit, metadata, cast_range, current_target)
  if current_target and EnemyMatches(current_target, metadata) then
    local unit_pos = Entity.GetAbsOrigin(unit)
    local target_pos = Entity.GetAbsOrigin(current_target)
    if unit_pos and target_pos then
      local distance = unit_pos:Distance(target_pos)
      if distance <= cast_range + (metadata and metadata.range_buffer or 0) then
        return current_target
      end
    end
  end

  local unit_pos = Entity.GetAbsOrigin(unit)
  if not unit_pos then
    return nil
  end

  local hero_team = my_hero and Entity.GetTeamNum(my_hero)
  local best_target = nil
  local best_score = -math.huge

  local function consider(list)
    for _, enemy in ipairs(list) do
      if EnemyMatches(enemy, metadata) then
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        if enemy_pos then
          local distance = unit_pos:Distance(enemy_pos)
          if distance <= cast_range + (metadata and metadata.range_buffer or 0) then
            local score = -distance
            if NPC.IsHero(enemy) then
              score = score + 200
            end
            if best_target == current_target then
              score = score + 100
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

  if hero_team then
    consider(NPCs.InRadius(unit_pos, cast_range, hero_team, Enum.TeamType.TEAM_ENEMY) or {})
    if metadata and metadata.allow_neutrals ~= false then
      consider(NPCs.InRadius(unit_pos, cast_range, hero_team, Enum.TeamType.TEAM_NEUTRAL) or {})
    end
  end

  return best_target
end

local function AllyMatches(ally, metadata)
  if not ally or not Entity.IsAlive(ally) then
    return false
  end

  if metadata and metadata.only_heroes and not NPC.IsHero(ally) then
    return false
  end

  if metadata and metadata.include_self == false and ally == my_hero then
    return false
  end

  if metadata and metadata.ally_max_health_pct then
    local hp = Entity.GetHealth(ally) or 0
    local max_hp = Entity.GetMaxHealth(ally) or 1
    if hp / max_hp > metadata.ally_max_health_pct then
      return false
    end
  end

  if metadata and metadata.avoid_modifier and NPC.HasModifier(ally, metadata.avoid_modifier) then
    return false
  end

  return true
end

local function FindAllyTarget(unit, metadata, cast_range)
  if metadata.prefer_anchor and my_hero and Entity.IsAlive(my_hero) and AllyMatches(my_hero, metadata) then
    local hero_pos = Entity.GetAbsOrigin(my_hero)
    local unit_pos = Entity.GetAbsOrigin(unit)
    if hero_pos and unit_pos and unit_pos:Distance(hero_pos) <= cast_range + (metadata.range_buffer or 0) then
      return my_hero
    end
  end

  local unit_pos = Entity.GetAbsOrigin(unit)
  if not unit_pos then
    return nil
  end

  local hero_team = my_hero and Entity.GetTeamNum(my_hero)
  if not hero_team then
    return nil
  end

  local best_target = nil
  local best_score = -math.huge

  local allies = NPCs.InRadius(unit_pos, cast_range, hero_team, Enum.TeamType.TEAM_FRIEND) or {}
  for _, ally in ipairs(allies) do
    if AllyMatches(ally, metadata) then
      local ally_pos = Entity.GetAbsOrigin(ally)
      if ally_pos then
        local distance = unit_pos:Distance(ally_pos)
        if distance <= cast_range + (metadata.range_buffer or 0) then
          local score = -distance
          if metadata.prefer_heroes and NPC.IsHero(ally) then
            score = score + 100
          end
          if score > best_score then
            best_score = score
            best_target = ally
          end
        end
      end
    end
  end

  if metadata.include_self and AllyMatches(unit, metadata) then
    return unit
  end

  return best_target
end

local function TryCastAbility(unit, ability, metadata, context)
  if not AbilityIsReady(unit, ability, metadata) then
    return false, nil
  end

  local cast_range = GetCastRange(ability, metadata)

  if metadata.behavior == "target" then
    if metadata.target == "ally" then
      local ally = FindAllyTarget(unit, metadata, cast_range)
      if ally then
        Ability.CastTarget(ability, ally)
        return true, metadata.message
      end
    else
      local enemy = FindEnemyTarget(unit, metadata, cast_range, context.current_target)
      if enemy then
        Ability.CastTarget(ability, enemy)
        return true, metadata.message
      end
    end
  elseif metadata.behavior == "point" then
    local target = context.current_target and EnemyMatches(context.current_target, metadata) and context.current_target or FindEnemyTarget(unit, metadata, cast_range, nil)
    local position = target and Entity.GetAbsOrigin(target) or nil
    if metadata.cast_self then
      position = Entity.GetAbsOrigin(unit)
    end

    if position then
      Ability.CastPosition(ability, position)
      return true, metadata.message
    end
  elseif metadata.behavior == "no_target" then
    local radius = metadata.radius or cast_range
    local enemies = CountEnemies(Entity.GetAbsOrigin(unit), radius, metadata)
    local required = metadata.min_enemies or (metadata.only_heroes and 1 or 0)
    if metadata.always_cast or enemies > required then
      Ability.CastNoTarget(ability)
      return true, metadata.message
    end
  elseif metadata.behavior == "toggle" then
    if Ability.GetToggleState and not Ability.GetToggleState(ability) then
      Ability.Toggle(ability)
      return true, metadata.message
    end
  end

  return false, nil
end

local function TryCastAbilities(follower, unit, context, current_time)
  if not ShouldAutoCast() then
    return false
  end

  if NPC.IsChannellingAbility and NPC.IsChannellingAbility(unit) then
    follower.last_action = "Канализирую"
    follower.next_action_time = current_time + 0.2
    return true
  end

  for slot = 0, 23 do
    local ability = NPC.GetAbilityByIndex(unit, slot)
    if ability then
      local name = Ability.GetName(ability)
      local metadata = GetAbilityMetadata(name)
      if metadata then
        local used, message = TryCastAbility(unit, ability, metadata, context)
        if used then
          follower.last_action = message or "Использую умение"
          follower.next_action_time = current_time + ORDER_COOLDOWN
          return true
        end
      end
    end
  end

  return false
end

local function AcquireAttackTarget(unit, leash_position)
  if not ShouldAutoAttack() or not my_hero then
    return nil
  end

  local hero_team = Entity.GetTeamNum(my_hero)
  local attack_radius = GetAttackRadius()
  local unit_pos = Entity.GetAbsOrigin(unit)
  if not unit_pos then
    return nil
  end

  local centers = { unit_pos }
  if leash_position then
    table.insert(centers, leash_position)
  end

  local include_creeps = ShouldCastOnCreeps()

  local function search(team_type, predicate)
    local best_target = nil
    local best_distance = math.huge
    for _, center in ipairs(centers) do
      local units = NPCs.InRadius(center, attack_radius, hero_team, team_type) or {}
      for _, candidate in ipairs(units) do
        if Entity.IsAlive(candidate) and Entity.GetTeamNum(candidate) ~= hero_team and not NPC.IsCourier(candidate) and predicate(candidate) then
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

  local target = search(Enum.TeamType.TEAM_ENEMY, function(enemy)
    return NPC.IsHero(enemy)
  end)

  if target then
    return target
  end

  target = search(Enum.TeamType.TEAM_ENEMY, function(enemy)
    return include_creeps and NPC.IsCreep(enemy)
  end)

  if target then
    return target
  end

  if include_creeps then
    target = search(Enum.TeamType.TEAM_NEUTRAL, function(enemy)
      return NPC.IsCreep(enemy)
    end)
  end

  return target
end

local function TryPrepareOrder(player, order, target, position, unit)
  if not Player or not Player.PrepareUnitOrders or not player or not unit then
    return false
  end

  local issuer = Enum.PlayerOrderIssuer and Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY or 0
  local ok = pcall(
    Player.PrepareUnitOrders,
    player,
    order,
    target,
    position,
    nil,
    issuer,
    unit,
    false,
    true,
    true,
    true
  )

  if not ok then
    Player.PrepareUnitOrders(player, order, target, position, nil, issuer, unit)
  end

  return true
end

local function IssueAttackOrder(player, unit, target)
  if not player or not unit or not target then
    return false
  end

  if Player and Player.AttackTarget then
    local ok = pcall(Player.AttackTarget, player, unit, target, false, true)
    if ok then
      return true
    end

    ok = pcall(Player.AttackTarget, player, unit, target)
    if ok then
      return true
    end
  end

  return TryPrepareOrder(player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET, target, nil, unit)
end

local function IssueMoveOrder(player, unit, position)
  if not player or not unit or not position then
    return false
  end

  if Player and Player.MoveToPosition then
    local ok = pcall(Player.MoveToPosition, player, unit, position, false, true, true)
    if ok then
      return true
    end
  end

  return TryPrepareOrder(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, position, unit)
end

local function IssueOrders()
  local current_time = GlobalVars and GlobalVars.GetCurTime and GlobalVars.GetCurTime() or 0
  local follow_distance = GetFollowDistance()
  local hero_pos = my_hero and Entity.GetAbsOrigin(my_hero) or nil

  local player = AcquirePlayerHandle()
  if not player then
    return
  end

  for handle, follower in pairs(followers) do
    local unit = follower.unit
    if not unit or not Entity.IsAlive(unit) then
      followers[handle] = nil
      goto continue
    end

    if follower.next_action_time and current_time < follower.next_action_time then
      goto continue
    end

    if NPC.IsChannellingAbility and NPC.IsChannellingAbility(unit) then
      follower.last_action = "Канализирую"
      follower.next_action_time = current_time + 0.2
      goto continue
    end

    local anchor_unit, anchor_pos = FindAllyAnchor(unit)
    local leash_pos = anchor_pos or hero_pos
    local unit_pos = Entity.GetAbsOrigin(unit)
    local anchor_distance = nil

    if leash_pos and unit_pos then
      anchor_distance = unit_pos:Distance(leash_pos)
    end

    local context = {
      current_target = nil,
    }

    if leash_pos then
      context.current_target = AcquireAttackTarget(unit, leash_pos)
    else
      context.current_target = AcquireAttackTarget(unit, unit_pos)
    end

    if TryCastAbilities(follower, unit, context, current_time) then
      goto continue
    end

    local target = context.current_target
    local leash_limit = follow_distance + 100
    if anchor_distance and anchor_distance > leash_limit then
      target = nil
    end

    if target and Entity.IsAlive(target) then
      IssueAttackOrder(player, unit, target)
      follower.last_action = string.format("Атакую: %s", NPC.GetUnitName(target) or "цель")
      follower.next_action_time = current_time + ORDER_COOLDOWN
    elseif leash_pos and anchor_distance and anchor_distance > follow_distance then
      IssueMoveOrder(player, unit, leash_pos)
      if anchor_unit and anchor_unit ~= my_hero then
        follower.last_action = string.format("Следую к %s", NPC.GetUnitName(anchor_unit) or "союзнику")
      else
        follower.last_action = "Следую к герою"
      end
      follower.next_action_time = current_time + ORDER_COOLDOWN
    else
      follower.last_action = "Ожидаю"
      follower.next_action_time = current_time + ORDER_COOLDOWN
    end

    ::continue::
  end
end

function agent_script.OnUpdate()
  EnsureMenu()

  if agent_script.ui.enable and not agent_script.ui.enable:Get() then
    return
  end

  if not Engine.IsInGame or not Engine.IsInGame() then
    ResetState()
    return
  end

  my_hero = Heroes.GetLocal() or my_hero

  local_player = AcquirePlayerHandle() or local_player
  local_player_id = GetPlayerID()

  if not my_hero then
    local candidate_id = local_player_id
    if candidate_id ~= nil then
      for _, hero in ipairs(Heroes.GetAll()) do
        if Hero and Hero.GetPlayerID and Hero.GetPlayerID(hero) == candidate_id then
          my_hero = hero
          break
        end
      end
    end
  end

  if not my_hero then
    return
  end

  UpdateFollowers()
  IssueOrders()
end

function agent_script.OnDraw()
  if not agent_script.ui.debug or not agent_script.ui.debug:Get() then
    return
  end

  local font = EnsureFont()
  for _, follower in pairs(followers) do
    local unit = follower.unit
    if unit and Entity.IsAlive(unit) and follower.last_action then
      local origin = Entity.GetAbsOrigin(unit)
      local offset = NPC.GetHealthBarOffset(unit) or 0
      local screen, visible = Render.WorldToScreen(origin + Vector(0, 0, offset + 20))
      if visible then
        Render.Text(font, 12, follower.last_action, screen, Color(180, 220, 255, 255))
      end
    end
  end
end

function agent_script.OnGameEnd()
  ResetState()
end

return agent_script
