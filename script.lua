---@diagnostic disable: undefined-global, lowercase-global

local script = {}

local LOW_HEALTH_THRESHOLD = 0.50
local RETRY_INTERVAL = 0.20

local last_cast_attempt = {
    item_ghost = -math.huge,
    item_glimmer_cape = -math.huge,
}

local function now()
    if GameRules and GameRules.GetGameTime then
        return GameRules.GetGameTime()
    end
    return os.clock()
end

local function is_valid_hero(hero)
    if not hero then
        return false
    end
    if not Entity.IsHero(hero) then
        return false
    end
    if NPC.IsIllusion(hero) then
        return false
    end
    return Entity.IsAlive(hero)
end

local function health_below_threshold(hero)
    local max_health = Entity.GetMaxHealth(hero)
    if not max_health or max_health <= 0 then
        return false
    end
    local current_health = Entity.GetHealth(hero) or 0
    return current_health > 0 and current_health <= (max_health * LOW_HEALTH_THRESHOLD)
end

local function can_cast_item(hero, item)
    if not item then
        return false
    end

    if Ability.IsHidden and Ability.IsHidden(item) then
        return false
    end

    if Ability.GetCooldown and Ability.GetCooldown(item) > 0 then
        return false
    end

    if Ability.IsReady and Ability.IsReady(item) then
        return true
    end

    local mana = NPC.GetMana(hero) or 0
    if Ability.IsCastable then
        return Ability.IsCastable(item, mana)
    end

    return true
end

local function cast_no_target_item(hero, item, name)
    if not hero or not item then
        return false
    end

    local current_time = now()
    if current_time - (last_cast_attempt[name] or -math.huge) < RETRY_INTERVAL then
        return false
    end

    last_cast_attempt[name] = current_time

    return Player.PrepareUnitOrders(
        Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET,
        nil,
        nil,
        item,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        hero
    )
end

local function try_use_item(hero, item_name)
    local item = NPC.GetItem(hero, item_name, true)
    if not can_cast_item(hero, item) then
        return false
    end

    if item_name == "item_ghost" then
        if NPC.HasModifier(hero, "modifier_item_ghost_scepter") then
            return false
        end
    elseif item_name == "item_glimmer_cape" then
        if NPC.HasModifier(hero, "modifier_item_glimmer_cape_fade") or NPC.HasModifier(hero, "modifier_item_glimmer_cape") then
            return false
        end
    end

    return cast_no_target_item(hero, item, item_name)
end

function script.OnUpdate()
    local hero = Heroes.GetLocal()
    if not is_valid_hero(hero) then
        return
    end

    if not health_below_threshold(hero) then
        return
    end

    try_use_item(hero, "item_ghost")
    try_use_item(hero, "item_glimmer_cape")
end

return script
