---@diagnostic disable: undefined-global, lowercase-global

local pudge_teleport_hook = {}

local HERO_NAME = "npc_dota_hero_pudge"
local HERO_ICON = "panorama/images/heroes/icons/" .. HERO_NAME .. "_png.vtex_c"
local HOOK_ABILITY_NAME = "pudge_meat_hook"
local ORDER_IDENTIFIER = "pudge_auto_teleport_hook"

local TELEPORT_START = "teleport_start"
local TELEPORT_END = "teleport_end"

local function safe_menu_create(...)
    local ok, menu = pcall(Menu.Create, ...)
    if ok then
        return menu
    end
    return nil
end

local function safe_icon(target, icon)
    if target and target.Icon then
        pcall(target.Icon, target, icon)
    end
end

local function create_group(parent, label, order)
    if not parent then
        return nil
    end

    if parent.Create then
        local ok, group
        if order ~= nil then
            ok, group = pcall(parent.Create, parent, label, order)
        else
            ok, group = pcall(parent.Create, parent, label)
        end

        if ok and group then
            return group
        end
    end

    return parent
end

local automation_tab = safe_menu_create("Heroes", "Hero List", "Pudge", "Auto Hook", "Teleport Sniper")
if not automation_tab then
    automation_tab = safe_menu_create("Heroes", "Hero List", "Pudge", "Auto Hook")
end
if not automation_tab then
    automation_tab = safe_menu_create("Heroes", "Hero List", "Pudge")
end
if not automation_tab then
    automation_tab = safe_menu_create("Heroes")
end
safe_icon(automation_tab, HERO_ICON)

local general_group = create_group(create_group(automation_tab, "General", 1), "Settings", 1) or automation_tab
local behavior_group = create_group(create_group(automation_tab, "Behavior", 2), "Options", 1) or automation_tab
local render_group = create_group(create_group(automation_tab, "Visuals", 3), "Status", 1) or automation_tab

local priority_tab = safe_menu_create("Heroes", "Hero List", "Pudge", "Auto Hook", "Manual Priority")
if not priority_tab then
    priority_tab = automation_tab
end
safe_icon(priority_tab, HERO_ICON)
local priority_group = create_group(create_group(priority_tab, "Enemy Targets", 4), "List", 1) or automation_tab or priority_tab

local ui = {}
ui.enabled = general_group:Switch("Enable teleport hook", true, HERO_ICON)
ui.idle_delay = general_group:Slider("Idle takeover delay", 0, 2000, 400, function(value)
    return string.format("%d ms", value)
end)
ui.cast_delay = general_group:Slider("Pre-hook delay", 0, 1500, 120, function(value)
    return string.format("%d ms", value)
end)
ui.window = general_group:Slider("Teleport window", 500, 4000, 2200, function(value)
    return string.format("%d ms", value)
end)
ui.range_buffer = general_group:Slider("Range buffer", 0, 400, 120, "%d")
ui.require_visible = general_group:Switch("Require vision", true, HERO_ICON)

ui.pause_moving = behavior_group:Switch("Pause while moving", true)
ui.pause_casting = behavior_group:Switch("Pause while casting", true)
ui.pause_attacking = behavior_group:Switch("Pause while attacking", true)
ui.pause_channeling = behavior_group:Switch("Pause while channeling", true)
ui.keep_best_only = behavior_group:Switch("Keep only best target", true)
ui.retry_failed = behavior_group:Switch("Retry if out of range", true)

ui.render_state = render_group:Switch("Render status text", false)
ui.render_queue = render_group:Switch("Render queue count", false)

ui.enabled:ToolTip("Automatically throw Meat Hook at teleport destinations of prioritised enemies.")
ui.idle_delay:ToolTip("Delay after the last manual order before automation takes over.")
ui.cast_delay:ToolTip("Time to wait after detecting a teleport before throwing the hook.")
ui.window:ToolTip("How long teleport information stays valid before expiring.")
ui.range_buffer:ToolTip("Additional distance allowed beyond the ability's cast range.")
ui.require_visible:ToolTip("Only hook enemies whose teleport end is currently visible.")
ui.pause_moving:ToolTip("Skip casting while Pudge is moving under player control.")
ui.pause_casting:ToolTip("Skip casting while Pudge is already casting another spell.")
ui.pause_attacking:ToolTip("Skip casting while Pudge is attacking a target.")
ui.pause_channeling:ToolTip("Skip casting while Pudge is channeling abilities or items.")
ui.keep_best_only:ToolTip("Keep only the highest priority teleport request in the queue.")
ui.retry_failed:ToolTip("Keep teleport info if the first hook attempt fails due to range.")
ui.render_state:ToolTip("Draw the automation status above Pudge.")
ui.render_queue:ToolTip("Show how many teleports are currently tracked.")

local enemy_controls = {}
local next_priority_seed = 1
local last_refresh_time = -1
local last_manual_order_time = -1000
local last_auto_cast_time = -1000
local status_font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_OUTLINE)

local teleport_events = {}
local pending_queue = {}

local function clamp(value, min_value, max_value)
    if value < min_value then return min_value end
    if value > max_value then return max_value end
    return value
end

local function get_display_name(unit_name)
    if not unit_name then
        return "Unknown"
    end
    local display_name = Engine.GetDisplayNameByUnitName and Engine.GetDisplayNameByUnitName(unit_name)
    if display_name and display_name ~= "" then
        return display_name
    end
    return unit_name
end

local function refresh_enemy_controls(local_hero, current_time)
    if not local_hero then
        return
    end

    if not priority_group or not priority_group.Switch or not priority_group.Slider then
        return
    end

    if last_refresh_time > 0 and current_time - last_refresh_time < 0.5 then
        return
    end
    last_refresh_time = current_time

    for _, entry in pairs(enemy_controls) do
        entry.hero = nil
    end

    local heroes = Heroes.GetAll()
    for i = 1, #heroes do
        local hero = heroes[i]
        if hero and hero ~= local_hero and Entity.IsHero(hero) and not Entity.IsSameTeam(hero, local_hero) then
            local unit_name = NPC.GetUnitName(hero)
            if unit_name then
                local controls = enemy_controls[unit_name]
                if not controls then
                    local display_name = get_display_name(unit_name)
                    local icon_path = "panorama/images/heroes/icons/" .. unit_name .. "_png.vtex_c"
                    local enable_switch = priority_group:Switch(display_name .. " enabled", true, icon_path)
                    enable_switch:ToolTip("Toggle auto-hook reactions for this enemy hero.")
                    local priority_slider = priority_group:Slider(display_name .. " priority", 1, 10, next_priority_seed, function(value)
                        return string.format("#%d", value)
                    end)
                    priority_slider:ToolTip("Lower numbers are handled first when several teleports appear.")
                    enable_switch:SetCallback(function()
                        priority_slider:Disabled(not enable_switch:Get())
                    end, true)
                    enemy_controls[unit_name] = {
                        hero = hero,
                        switch = enable_switch,
                        slider = priority_slider,
                        icon = icon_path,
                    }
                    next_priority_seed = clamp(next_priority_seed + 1, 1, 10)
                else
                    controls.hero = hero
                end
            end
        end
    end

    for _, controls in pairs(enemy_controls) do
        local visible = controls.hero ~= nil
        controls.switch:Visible(visible)
        controls.slider:Visible(visible)
        controls.slider:Disabled(not controls.switch:Get())
    end
end

local function is_pudge(hero)
    return hero and NPC.GetUnitName(hero) == HERO_NAME
end

local function is_ready_for_hook(hero)
    if not hero or not Entity.IsAlive(hero) then
        return false
    end

    local hook = NPC.GetAbility(hero, HOOK_ABILITY_NAME)
    if not hook then
        return false
    end

    if Ability.GetCooldown(hook) and Ability.GetCooldown(hook) > 0 then
        return false
    end

    local mana_cost = Ability.GetManaCost and Ability.GetManaCost(hook) or 0
    if mana_cost > NPC.GetMana(hero) then
        return false
    end

    if Ability.IsHidden and Ability.IsHidden(hook) then
        return false
    end

    if Ability.IsActivated and not Ability.IsActivated(hook) then
        return false
    end

    if Ability.IsInAbilityPhase and Ability.IsInAbilityPhase(hook) then
        return false
    end

    return true, hook
end

local function should_pause_for_player(hero)
    if ui.pause_moving:Get() and Entity.IsMoving and Entity.IsMoving(hero) then return true end
    if ui.pause_attacking:Get() and NPC.IsAttacking and NPC.IsAttacking(hero) then return true end
    if ui.pause_casting:Get() and NPC.IsCastingAbility and NPC.IsCastingAbility(hero) then return true end
    if ui.pause_channeling:Get() and NPC.IsChannellingAbility and NPC.IsChannellingAbility(hero) then return true end
    return false
end

local function passes_priority_filters(enemy)
    if not enemy or not Entity.IsHero(enemy) or not Entity.IsAlive(enemy) then
        return false
    end

    local unit_name = NPC.GetUnitName(enemy)
    if not unit_name then
        return false
    end

    local controls = enemy_controls[unit_name]
    if not controls then
        return false
    end

    if not controls.switch:Get() then
        return false
    end

    return true, controls.slider:Get()
end

local function queue_pending_hook(entity, position, end_time)
    if not entity or not position then
        return
    end

    local ok, priority = passes_priority_filters(entity)
    if not ok then
        return
    end

    local info = {
        entity = entity,
        position = Vector(position.x, position.y, 0),
        priority = priority,
        created = GameRules.GetGameTime(),
        trigger = GameRules.GetGameTime() + (ui.cast_delay:Get() / 1000.0),
        expire = GameRules.GetGameTime() + (ui.window:Get() / 1000.0),
        end_time = end_time,
    }

    if ui.keep_best_only:Get() then
        local best_index = nil
        for idx = 1, #pending_queue do
            local existing = pending_queue[idx]
            if existing.priority > info.priority or (existing.priority == info.priority and existing.created > info.created) then
                best_index = idx
                break
            end
        end
        if best_index then
            pending_queue[best_index] = info
            return
        end
        if #pending_queue == 0 then
            pending_queue[1] = info
            return
        end
        local best = pending_queue[1]
        if best.priority <= info.priority then
            return
        end
        pending_queue[1] = info
        return
    end

    pending_queue[#pending_queue + 1] = info
end

local function clean_pending_queue(current_time)
    for i = #pending_queue, 1, -1 do
        local entry = pending_queue[i]
        if not entry then
            table.remove(pending_queue, i)
        else
            if current_time > entry.expire then
                table.remove(pending_queue, i)
            end
        end
    end
end

local function select_next_entry()
    if #pending_queue == 0 then
        return nil
    end

    local best_index = 1
    local best_entry = pending_queue[1]

    for i = 2, #pending_queue do
        local entry = pending_queue[i]
        if entry.priority < best_entry.priority then
            best_index = i
            best_entry = entry
        elseif entry.priority == best_entry.priority and entry.created < best_entry.created then
            best_index = i
            best_entry = entry
        end
    end

    return best_entry, best_index
end

local function cast_hook(player, hero, hook, entry)
    if not player or not hero or not hook or not entry then
        return false
    end

    local hero_pos = Entity.GetAbsOrigin(hero)
    local distance = (entry.position - hero_pos):Length2D()

    local range = Ability.GetCastRange and Ability.GetCastRange(hook) or 1300
    range = range + ui.range_buffer:Get()

    if distance > range then
        if not ui.retry_failed:Get() then
            return false
        end
        entry.trigger = GameRules.GetGameTime() + 0.1
        return false
    end

    if ui.require_visible:Get() and not Entity.IsVisible(entry.entity) then
        return false
    end

    Player.PrepareUnitOrders(
        player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
        nil,
        entry.position,
        hook,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_CURRENT_UNIT_ONLY,
        hero,
        false,
        false,
        true,
        true,
        ORDER_IDENTIFIER,
        false
    )

    last_auto_cast_time = GameRules.GetGameTime()
    return true
end

function pudge_teleport_hook.OnParticleCreate(data)
    if not data then
        return
    end

    if data.name ~= TELEPORT_START and data.name ~= TELEPORT_END then
        return
    end

    teleport_events[data.index] = teleport_events[data.index] or {}
    teleport_events[data.index].name = data.name
    teleport_events[data.index].entity = data.entityForModifiers or teleport_events[data.index].entity
    teleport_events[data.index].created = GameRules.GetGameTime()
end

function pudge_teleport_hook.OnParticleUpdate(data)
    if not data then
        return
    end

    local event = teleport_events[data.index]
    if not event then
        return
    end

    event.position = data.position or event.position

    if event.name == TELEPORT_END and event.position then
        local entity = event.entity
        teleport_events[data.index] = nil
        if entity then
            queue_pending_hook(entity, event.position, event.created)
        end
    elseif event.name == TELEPORT_START then
        event.start_pos = data.position or event.start_pos
    end
end

function pudge_teleport_hook.OnParticleDestroy(data)
    if not data then
        return
    end
    teleport_events[data.index] = nil
end

function pudge_teleport_hook.OnPrepareUnitOrders(data)
    if not data then
        return true
    end

    if data.identifier == ORDER_IDENTIFIER then
        return true
    end

    local local_player = Players.GetLocal()
    if not local_player or data.player ~= local_player then
        return true
    end

    last_manual_order_time = GameRules.GetGameTime()
    return true
end

local function render_status(hero)
    if not ui.render_state:Get() or not hero then
        return
    end

    local text = "Hook idle"
    if #pending_queue > 0 then
        text = "Hook queued"
    end

    if GameRules.GetGameTime() - last_auto_cast_time < 1.0 then
        text = "Hook casting"
    end

    local origin = Entity.GetAbsOrigin(hero)
    local screen = Input.WorldToScreen(origin)
    if screen then
        Render.Text(status_font, 16, text, Vec2(screen.x - 40, screen.y - 60), Color(245, 245, 245, 255))
    end

    if ui.render_queue:Get() then
        local queue_text = string.format("Queue: %d", #pending_queue)
        Render.Text(status_font, 14, queue_text, Vec2(screen.x - 40, screen.y - 40), Color(180, 220, 255, 220))
    end
end

function pudge_teleport_hook.OnDraw()
    local hero = Heroes.GetLocal()
    if not is_pudge(hero) then
        return
    end
    render_status(hero)
end

function pudge_teleport_hook.OnUpdate()
    if not ui.enabled:Get() then
        return
    end

    local hero = Heroes.GetLocal()
    if not is_pudge(hero) then
        return
    end

    local player = Players.GetLocal()
    if not player then
        return
    end

    local current_time = GameRules.GetGameTime()
    refresh_enemy_controls(hero, current_time)
    clean_pending_queue(current_time)

    if #pending_queue == 0 then
        return
    end

    if should_pause_for_player(hero) then
        return
    end

    local idle_threshold = ui.idle_delay:Get() / 1000.0
    if current_time - last_manual_order_time < idle_threshold then
        return
    end

    local ready, hook = is_ready_for_hook(hero)
    if not ready then
        return
    end

    local entry, index = select_next_entry()
    if not entry then
        return
    end

    if current_time < entry.trigger then
        return
    end

    local ok = cast_hook(player, hero, hook, entry)
    if ok then
        table.remove(pending_queue, index)
    else
        if not ui.retry_failed:Get() then
            table.remove(pending_queue, index)
        end
    end
end

return pudge_teleport_hook
