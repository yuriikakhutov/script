---@diagnostic disable: undefined-global, param-type-mismatch, inject-field
-- Armlet Abuse Plus [beta v3.8] - HEADLESS (no visuals)
-- Strict Umbrella API v2.0
-- Immortality core + Safe sorts + Projectiles/Particles + Anti-Burst/Summons

local ArmletPlus = {}

--==================== UI ====================--
local tab = Menu.Create("Miscellaneous", "In Game", "Armlet Abuse")
tab:Icon("\u{f135}")

local gMain   = tab:Create("Main"):Create("General")
local gThr    = tab:Create("Thresholds"):Create("General")
local gSafe   = tab:Create("Safety"):Create("General")
local gPred   = tab:Create("Prediction"):Create("General")
local gBurst  = tab:Create("Anti-Burst"):Create("General")
local gImm    = tab:Create("Immortality"):Create("General")
local gSumm   = tab:Create("Anti-Summons"):Create("General")
local gDbg    = tab:Create("Debug"):Create("Logs")

local ui = {}
ui.enable      = gMain:Switch("Enable Armlet Abuse", true)
ui.profile     = gMain:Combo("Profile", {"Safe", "Aggressive"}, 0)
ui.manual_allow= gMain:Switch("Allow manual Armlet control (do not force)", false)

ui.hp_thr      = gThr:Slider("Auto ON below HP%", 1, 40, 15, "%d")
ui.safe_hp     = gThr:Slider("Fail-safe HP (base)", 100, 1500, 480, "%d")
ui.enemy_rad   = gThr:Slider("Enemy check radius", 600, 2400, 1300, "%d")

ui.dot_block   = gSafe:Switch("Block OFF under DoT", true)
ui.tp_block    = gSafe:Switch("Force ON while TP/channel", true)
ui.rosh_threat = gSafe:Switch("Count Roshan as threat", true)
ui.creep_threat= gSafe:Switch("Count Creeps as threat", false)

ui.proj_predict= gPred:Switch("Projectile prediction (targeted/AoE)", true)
ui.part_predict= gPred:Switch("Particle hazards awareness", true)
ui.proj_grace  = gPred:Slider("Projectile grace after last (ms)", 0, 3000, 950, "%d")

ui.burst_enable= gBurst:Switch("Enable Anti-Burst Abuse", true)
ui.omni_radius = gBurst:Slider("Jugger Omnislash awareness", 400, 1800, 1000, "%d")

-- Immortality core
ui.imm_enable  = gImm:Switch("Immortality mode (hysteresis/memory)", true)
ui.hyst_ms     = gImm:Slider("Keep-ON hysteresis (ms)", 200, 3500, 1200, "%d")
ui.mem_ms      = gImm:Slider("Threat memory window (ms)", 300, 6000, 2000, "%d")
ui.safe_per_en = gImm:Slider("Safe buffer per enemy", 0, 300, 90, "%d")
ui.safe_proj   = gImm:Slider("Safe buffer: active projectiles", 0, 600, 240, "%d")
ui.huskar_bias = gImm:Switch("Huskar bias (extra ON hold)", true)

-- Anti-Summons
ui.summ_enable   = gSumm:Switch("Enable Anti-Summon hold", true)
ui.summ_radius   = gSumm:Slider("Summon radius", 300, 1600, 850, "%d")
ui.summ_min      = gSumm:Slider("Trigger at >= N summons", 1, 15, 3, "%d")
ui.summ_safe_add = gSumm:Slider("Safe buffer per summon", 0, 180, 45, "%d")

-- Debug
ui.debug_log     = gDbg:Switch("Print toggles to console", false)
ui.debug_particles= gDbg:Switch("Log particle hits", false)

--==================== Vars ====================--
local myHero, armlet = nil, nil
local last_toggle = 0

---@type table<integer,{expire:number,name:string,radius?:number,pos?:Vector}>
local active_projectiles, proj_id = {}, 0
local force_on_until, proj_grace_until = 0, 0
local threat_memory = {} -- [ent_index] = expire_ms

--==================== Databases ====================--
local danger_modifiers = {
  "modifier_venomancer_poison_nova","modifier_queenofpain_shadow_strike",
  "modifier_item_spirit_vessel","modifier_item_urn_damage",
  "modifier_viper_poison_attack","modifier_viper_viper_strike",
  "modifier_jakiro_dual_breath_burn","modifier_jakiro_liquid_fire_burn","modifier_jakiro_macropyre",
  "modifier_doom_bringer_doom","modifier_ogre_magi_ignite",
  "modifier_item_radiance","modifier_item_skadi_slow","modifier_huskar_burning_spear",
  "modifier_axe_battle_hunger","modifier_pudge_rot","modifier_silencer_curse_of_the_silent",
  "modifier_ancient_apparition_ice_blast","modifier_witch_doctor_maledict",
  "modifier_spectre_spectral_dagger_slow"
}

local control_modifiers = {
  "modifier_stunned","modifier_silence",
  "modifier_sheepstick_debuff","modifier_lion_voodoo","modifier_shadow_shaman_voodoo",
  "modifier_eul_cyclone"
}

local danger_burst = {
  "modifier_windrunner_focusfire","modifier_witch_doctor_death_ward_channel",
  "modifier_enigma_black_hole_pull","modifier_legion_commander_duel",
  "modifier_riki_tricks_of_the_trade_phase","modifier_ursa_overpower",
  "modifier_monkey_king_fur_army","modifier_monkey_king_fur_army_soldier",
  "modifier_faceless_void_chronosphere_freeze"
}

local post_death_effects = {
  "modifier_nevermore_requiem","modifier_phoenix_supernova_death",
  "modifier_techies_suicide","modifier_necronomicon_warrior_last_will",
  "modifier_pugna_nether_ward_death"
}

-- Dangerous AoE/projectile signatures (name substring → radius, ttl)
local danger_projectiles = {
  {name="snapfire_lizard",        radius=300, ttl=2600},
  {name="invoker_sun_strike",     radius=260, ttl=1400},
  {name="skywrath_mystic_flare",  radius=420, ttl=2400},
  {name="lich_chain_frost",       radius=260, ttl=5200},
  {name="techies_remote_mines",   radius=420, ttl=3200},
  {name="techies_suicide",        radius=320, ttl=1700},
  {name="nevermore_requiem",      radius=380, ttl=1800},
  {name="phoenix_supernova",      radius=450, ttl=1800},
  {name="spectre_dagger",         radius=180, ttl=2000},
  {name="spectral_dagger",        radius=180, ttl=2000},
}

-- Particle hazards (vpcf substring → radius, ttl)
local danger_particles = {
  {name="enigma_blackhole", radius=420, ttl=4000},
  {name="earthshaker_echo", radius=550, ttl=1200},
  {name="sandking_epicenter", radius=600, ttl=2500},
  {name="jakiro_macropyre", radius=520, ttl=3000},
  {name="zuus_thundergods_wrath", radius=300, ttl=1200}, -- conservative
  {name="skywrath_mage_ancient_seal", radius=400, ttl=1800},
  {name="techies_remote_mines", radius=420, ttl=3200},
  {name="pugna_nether_ward", radius=400, ttl=2200},
}

-- Items that imply burst intent on attacker
local danger_items = {
  "item_dagon","item_ethereal_blade","item_nullifier","item_orchid","item_bloodthorn",
  "item_diffusal_blade","item_maelstrom","item_mjollnir","item_radiance","item_shivas_guard"
}

-- Summons (Undying/Clinkz etc)
local summon_units = {
  "npc_dota_unit_undying_zombie",
  "npc_dota_unit_undying_zombie_torso",
  "npc_dota_clinkz_skeleton_archer",
  "npc_dota_clinkz_burning_skeleton",
  "npc_dota_clinkz_skeleton"
}

--==================== Safe sort helpers (fix invalid order function) ====================--
local function __toNumber(v, fallback)
  v = tonumber(v)
  if v == nil or v ~= v then return fallback end -- NaN guard
  return v
end

local function SafeSortByDistance(list, origin)
  if type(list) ~= "table" then return end
  origin = origin or (myHero and Entity.GetAbsOrigin(myHero)) or Vector()
  local i = 1
  while i <= #list do
    local e = list[i]
    local ent = e and (e.ent or e.entity or e) or nil
    local valid = ent and Entity.IsNPC(ent) and Entity.IsAlive(ent)
    if not valid then
      table.remove(list, i)
    else
      local p = Entity.GetAbsOrigin(ent)
      local d = (origin - p):Length()
      e.__dist = __toNumber(e.dist, d)
      e.__idx  = Entity.GetIndex(ent) or 0
      i = i + 1
    end
  end
  local function cmp(a, b)
    local da, db = __toNumber(a.__dist, math.huge), __toNumber(b.__dist, math.huge)
    if da ~= db then return da < db end
    return (__toNumber(a.__idx, 0)) < (__toNumber(b.__idx, 0))
  end
  pcall(function() table.sort(list, cmp) end)
end
--=============================================================================--

--==================== Utils ====================--
local function now() return os.clock()*1000 end
local function dbg(msg) if ui.debug_log:Get() then print("[ArmletAbuse] "..tostring(msg)) end end
local function dbgP(msg) if ui.debug_particles:Get() then print("[ArmletAbuse/Particles] "..tostring(msg)) end end

local function any_modifier(list)
  for _,m in ipairs(list) do
    if NPC.HasModifier(myHero, m) then return true end
  end
  return false
end

local function is_in_fountain(h) return NPC.GetHealthRegen(h) > 50 end

local function mark_hysteresis()
  if not ui.imm_enable:Get() then return end
  local t = now() + ui.hyst_ms:Get()
  if t > force_on_until then force_on_until = t end
end

local function mark_projectile_grace()
  if not ui.imm_enable:Get() then return end
  local t = now() + ui.proj_grace:Get()
  if t > proj_grace_until then proj_grace_until = t end
end

local function add_active_projectile(name, ttl_ms, radius, pos)
  proj_id = proj_id + 1
  active_projectiles[proj_id] = {expire = now()+ttl_ms, name = name or "", radius=radius, pos=pos}
  mark_hysteresis(); mark_projectile_grace()
end

local function cleanup_projectiles()
  local t = now()
  for id,info in pairs(active_projectiles) do
    if info.expire <= t then active_projectiles[id] = nil end
  end
end

local function count_summons(radius)
  if not ui.summ_enable:Get() then return 0 end
  local c, my = 0, Entity.GetAbsOrigin(myHero)
  for _, n in ipairs(NPCs.GetAll()) do
    if n and Entity.IsAlive(n) and not Entity.IsSameTeam(myHero,n) then
      local uname = Entity.GetUnitName(n) or ""
      for _, s in ipairs(summon_units) do
        if string.find(uname, s) then
          local d = (my - Entity.GetAbsOrigin(n)):Length()
          if d <= radius then c = c + 1 end
          break
        end
      end
    end
  end
  return c
end

local function enemy_nearby(hero, radius)
  for _, n in ipairs(NPCs.GetAll()) do
    if n and Entity.IsAlive(n) then
      local hostile = (NPC.IsIllusion(n) or Entity.IsHero(n)) and not Entity.IsSameTeam(hero,n)
      local rosh = ui.rosh_threat:Get() and Entity.GetUnitName(n)=="npc_dota_roshan"
      if hostile or rosh or (ui.creep_threat:Get() and not Entity.IsHero(n) and not Entity.IsSameTeam(hero,n)) then
        if (Entity.GetAbsOrigin(hero)-Entity.GetAbsOrigin(n)):Length() <= radius then return true end
      end
    end
  end
  return false
end

local function dyn_safe_hp(base)
  local safe = base
  -- nearby enemies
  local enemies = 0
  for _, n in ipairs(NPCs.GetAll()) do
    if n and Entity.IsAlive(n) and not Entity.IsSameTeam(myHero,n) and (Entity.IsHero(n) or NPC.IsIllusion(n) or (ui.creep_threat:Get() and not Entity.IsHero(n))) then
      if (Entity.GetAbsOrigin(myHero)-Entity.GetAbsOrigin(n)):Length() <= ui.enemy_rad:Get() then enemies = enemies + 1 end
    end
  end
  safe = safe + enemies * ui.safe_per_en:Get()
  -- active projectiles buffer
  if next(active_projectiles) ~= nil or now() < proj_grace_until then
    safe = safe + ui.safe_proj:Get()
  end
  -- summons
  local summ_c = count_summons(ui.summ_radius:Get())
  safe = safe + summ_c * ui.summ_safe_add:Get()
  -- huskar extra
  if ui.huskar_bias:Get() and Entity.GetUnitName(myHero)=="npc_dota_hero_huskar" then
    safe = safe + 150
  end
  return safe
end

local function is_omni_near()
  local rad = ui.omni_radius:Get()
  for _, n in ipairs(NPCs.GetAll()) do
    if n and Entity.IsAlive(n) and not Entity.IsSameTeam(myHero,n) and Entity.IsHero(n) then
      if Entity.GetUnitName(n)=="npc_dota_hero_juggernaut" then
        if NPC.HasModifier(n,"modifier_juggernaut_omnislash")
        or NPC.HasModifier(n,"modifier_juggernaut_swift_slash") then
          if (Entity.GetAbsOrigin(myHero)-Entity.GetAbsOrigin(n)):Length() <= rad then
            return true
          end
        end
      end
    end
  end
  return false
end

local function check_items(source)
  if not source or not Entity.IsNPC(source) then return false end
  for _, itemName in ipairs(danger_items) do
    if NPC.HasItem(source, itemName, false) then return true end
  end
  return false
end

local function can_toggle() return (now() - last_toggle) >= 250 end

local function toggle_armlet(state, forced, reason)
  if not armlet or not Entity.IsAbility(armlet) then return end
  if not can_toggle() then return end
  if ui.manual_allow:Get() and not forced then return end

  if state and not Ability.GetToggleState(armlet) then
    Ability.Toggle(armlet); last_toggle = now(); dbg("ON: "..(reason or ""))
  elseif (not state) and Ability.GetToggleState(armlet) then
    local hp = Entity.GetHealth(myHero)
    local SAFE = dyn_safe_hp(ui.safe_hp:Get())
    if hp <= SAFE then return end
    if ui.imm_enable:Get() then
      if any_modifier(danger_modifiers) or any_modifier(control_modifiers) then return end
      if now() < force_on_until then return end
      if next(active_projectiles) ~= nil or now() < proj_grace_until then return end
    end
    Ability.Toggle(armlet); last_toggle = now(); dbg("OFF")
  end
end

--==================== Core Logic ====================--
function ArmletPlus.OnUpdate()
  if not ui.enable:Get() then return end
  if not myHero then myHero = Heroes.GetLocal() end
  if not myHero or not Entity.IsAlive(myHero) then return end

  if not armlet then armlet = NPC.GetItem(myHero, "item_armlet", true); return end
  cleanup_projectiles()

  -- Pre-force: control / Omnislash close
  if any_modifier(control_modifiers) or is_omni_near() then
    mark_hysteresis(); toggle_armlet(true, true, "control/omni")
  end

  -- Strong scenarios
  if ui.burst_enable:Get() and any_modifier(danger_burst) then
    mark_hysteresis(); toggle_armlet(true, true, "burst"); return
  end
  if any_modifier(post_death_effects) then
    mark_hysteresis(); toggle_armlet(true, true, "post-death"); return
  end
  if ui.tp_block:Get() and NPC.IsChannellingAbility(myHero) then
    mark_hysteresis(); toggle_armlet(true, true, "channel"); return
  end
  if ui.dot_block:Get() and any_modifier(danger_modifiers) then
    mark_hysteresis(); toggle_armlet(true, true, "DoT"); return
  end

  -- Summons
  local sc = count_summons(ui.summ_radius:Get())
  if ui.summ_enable:Get() and sc >= ui.summ_min:Get() then
    mark_hysteresis(); toggle_armlet(true, true, "summons("..tostring(sc)..")")
  end

  -- Fountain: only turn OFF when absolutely clean
  if is_in_fountain(myHero)
    and not enemy_nearby(myHero, ui.enemy_rad:Get())
    and next(active_projectiles)==nil and now()>=proj_grace_until
    and now()>=force_on_until
    and not any_modifier(danger_modifiers)
    and not any_modifier(control_modifiers)
    and sc < ui.summ_min:Get()
  then
    toggle_armlet(false, true)
    return
  end

  -- Base logic
  local hp = Entity.GetHealth(myHero); local maxhp = Entity.GetMaxHealth(myHero)
  local hp_pct = (hp/maxhp)*100; local nearby = enemy_nearby(myHero, ui.enemy_rad:Get())
  local need_on = (hp_pct <= ui.hp_thr:Get())
  local proj_risk = (next(active_projectiles)~=nil or now()<proj_grace_until)

  if ui.profile:Get()==0 then -- Safe
    if (need_on and (nearby or proj_risk or sc>=ui.summ_min:Get())) then
      mark_hysteresis(); toggle_armlet(true, true, "safe-core")
    elseif not nearby and not proj_risk and now()>=force_on_until and sc<ui.summ_min:Get()
       and hp>dyn_safe_hp(ui.safe_hp:Get()) and not any_modifier(danger_modifiers) and not any_modifier(control_modifiers) then
      toggle_armlet(false, true)
    end
  else -- Aggressive
    if need_on or proj_risk or sc>=ui.summ_min:Get() then
      mark_hysteresis(); toggle_armlet(true, true, "agg-core")
    elseif now()>=force_on_until and hp>dyn_safe_hp(ui.safe_hp:Get())
       and not any_modifier(danger_modifiers) and not any_modifier(control_modifiers) then
      toggle_armlet(false, true)
    end
  end
end

--==================== Event Hooks ====================--
function ArmletPlus.OnEntityHurt(d)
  if not ui.enable:Get() then return end
  if not myHero or not Entity.IsAlive(myHero) then return end
  if d.target ~= myHero then return end

  if check_items(d.source) then mark_hysteresis(); toggle_armlet(true, true, "item-hit") end
  if (d.damage or 0) >= Entity.GetHealth(myHero) then mark_hysteresis(); toggle_armlet(true, true, "lethal") end

  if d.source then threat_memory[Entity.GetIndex(d.source)] = now() + ui.mem_ms:Get() end
end

-- Targeted projectiles (engine callback)
function ArmletPlus.OnProjectile(p)
  if not ui.enable:Get() or not ui.proj_predict:Get() then return end
  if not myHero or not Entity.IsAlive(myHero) then return end
  if p.target and p.target==myHero then
    add_active_projectile("targeted", 1800)
    if (p.damage or 0) >= Entity.GetHealth(myHero) then toggle_armlet(true, true, "proj-lethal") end
  end
end

-- AoE and location-based projectiles
function ArmletPlus.OnProjectileLoc(p)
  if not ui.enable:Get() or not ui.proj_predict:Get() then return end
  if not myHero or not Entity.IsAlive(myHero) then return end
  if not p.name or not p.position then return end
  local hero_pos = Entity.GetAbsOrigin(myHero)
  for _, data in ipairs(danger_projectiles) do
    if string.find(p.name, data.name) then
      if (p.position-hero_pos):Length() <= (data.radius or 300) then
        add_active_projectile(data.name, data.ttl or 1800, data.radius, p.position)
        toggle_armlet(true, true, "proj-aoe")
        break
      end
    end
  end
end

-- Particle awareness
function ArmletPlus.OnParticleCreate(particle)
  if not ui.enable:Get() or not ui.part_predict:Get() then return end
  if not myHero or not Entity.IsAlive(myHero) then return end
  if not particle or not particle.fullName then return end

  local fname = particle.fullName:lower()
  for _, sig in ipairs(danger_particles) do
    if string.find(fname, sig.name) then
      local pos = particle.position or (particle.entity and Entity.GetAbsOrigin(particle.entity)) or Entity.GetAbsOrigin(myHero)
      if pos then
        add_active_projectile("fx:"..sig.name, sig.ttl or 1500, sig.radius, pos)
        dbgP(("hit %s → r=%d"):format(sig.name, sig.radius or -1))
        toggle_armlet(true, true, "fx-hazard")
      end
      break
    end
  end
end

function ArmletPlus.OnParticleUpdate(particle)
  -- optional: could move AoE center as it updates; we only need the existence for armlet hold
end

function ArmletPlus.OnParticleDestroy(_)
  -- nothing: active_projectiles are cleaned by TTL
end

--==================== Housekeeping ====================--
function ArmletPlus.OnGameEnd()
  active_projectiles = {}; proj_id = 0
  force_on_until, proj_grace_until = 0, 0
  threat_memory = {}
  myHero, armlet = nil, nil
end

return ArmletPlus


