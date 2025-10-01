--[[
	Anti-Mage Counterspell Auto-Cast
	Автоматически использует Counterspell против Orchid и Hex
]]

local ui = {}
do
	if NEW_UI_LIB then
		ui.root = NEW_UI_LIB.create_tab(false, Menu.Find("Miscellaneous"), "In Game", "AM Counterspell")
		ui.root.ref:Image("panorama/images/spellicons/antimage_counterspell_png.vtex_c")
		ui.group = ui.root:create(""):create("General")

		ui.enable_bind = ui.group:bind("Enable", nil, nil)
		if ui.enable_bind and ui.enable_bind.Properties then
			ui.enable_bind:Properties(nil, nil, true)
		end
	end
end

if not Heroes.GetLocal() then return {} end

local hero_lib = LIB_HEROES_DATA
local my_data, _, helpers, _, variables = hero_lib.get()
hero_lib.add_func_to_reload_variables(function() my_data, _, helpers, _, variables = hero_lib.get() end)

-- Способности которые нужно блокировать
local block_abilities = {
	["item_orchid"] = true,
	["item_bloodthorn"] = true,
	["item_sheepstick"] = true,
	["shadow_shaman_voodoo"] = true,
	["lion_voodoo"] = true,
	["rhasta_hex"] = true,
	["item_abyssal_blade"] = true,
	-- Дагон всех уровней
	["item_dagon"] = true,          -- Dagon 1
	["item_dagon_2"] = true,        -- Dagon 2
	["item_dagon_3"] = true,        -- Dagon 3
	["item_dagon_4"] = true,        -- Dagon 4
	["item_dagon_5"] = true,        -- Dagon 5
       -- Еулы
        ["item_cyclone"] = true,
        ["item_wind_waker"] = true,
        ["item_heavens_halberd"] = true,
        ["item_diffusal_blade"] = true,
        ["item_disperser"] = true,
}

local counterspell_img = nil
local enabled_state = true

local function now()
	return GameRules.GetGameTime()
end

local function net_delay()
	local inc = NetChannel.GetAvgLatency and NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING) or 0.0
	local out = NetChannel.GetAvgLatency and NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) or 0.0
	inc = inc or 0.0
	out = out or 0.0
	local d = inc + out
	if d < 0.0 then d = 0.0 end
	if d > 0.25 then d = 0.25 end
	return d
end

local function face_delay(caster)
	if not caster then return 0.0 end
	local ttf = NPC.GetTimeToFace and NPC.GetTimeToFace(caster, my_data.ref) or 0.0
	if not ttf or ttf < 0 then ttf = 0.0 end
	if ttf > 0.45 then ttf = 0.45 end
	return ttf
end

local function is_enabled()
	return enabled_state
end

local function handle_toggle()
	if not ui.enable_bind then return end
	if ui.enable_bind.IsPressed and ui.enable_bind:IsPressed() then
		enabled_state = not enabled_state
	elseif ui.enable_bind.IsDown and ui.enable_bind:IsDown() then
		if not variables.check_timer("cs_toggle_cd") then
			enabled_state = not enabled_state
			variables.set_timer("cs_toggle_cd", 0.25)
		end
	elseif ui.enable_bind.down and ui.enable_bind:down() then
		if not variables.check_timer("cs_toggle_cd") then
			enabled_state = not enabled_state
			variables.set_timer("cs_toggle_cd", 0.25)
		end
	end
end

local function get_counterspell()
	local cs = NPC.GetAbility(my_data.ref, "antimage_counterspell")
	if not cs then
		cs = NPC.GetAbility(my_data.ref, "antimage_counterspell_ally")
	end
	return cs
end

local function is_counterspell_ready()
	local cs = get_counterspell()
	if not cs then return false end
	if not Ability.IsCastable(cs, NPC.GetMana(my_data.ref)) then return false end
	local cd = Ability.GetCooldown(cs) or 0.0
	if cd > 0.0 then return false end
	return true
end

local function cast_counterspell()
	local cs = get_counterspell()
	if not cs then return false end
	
	if variables.check_timer("counterspell_cast_cd") then return false end
	
	Ability.CastNoTarget(cs)
	variables.set_timer("counterspell_cast_cd", 0.1)
	return true
end

local function is_item_ability(ability)
	if not ability then return false end
	local name = Ability.GetName(ability)
	return name and name:find("item_") == 1
end

local function is_targeted_ability(ability)
	if not ability then return false end
	local beh = Ability.GetBehavior(ability)
	if not beh then return false end
	local mask_unit = Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	local mask_opt_unit = Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET
	return (beh & mask_unit) ~= 0 or (beh & mask_opt_unit) ~= 0
end

local function get_cast_range(caster, ability)
	if not ability then return 0 end
	local base = Ability.GetCastRange(ability) or 0
	if base < 0 then base = 0 end
	local bonus = (caster and NPC.GetCastRangeBonus and NPC.GetCastRangeBonus(caster)) or 0
	if not bonus or bonus < 0 then bonus = 0 end
	return base + bonus
end

local function compute_time_to_hit(proj)
	local speed = proj.original_move_speed or proj.moveSpeed or 900.0
	if speed <= 0 then speed = 900.0 end
	local start_pos = proj.source and Entity.GetAbsOrigin(proj.source) or proj.sourceLoc or my_data.pos
	local target_pos = my_data.pos
	local dist = 0.0
	if start_pos and target_pos then
		dist = start_pos:Distance(target_pos)
	end
	local t = (dist / speed) + 0.06
	if t < 0.06 then t = 0.06 end
	if t > 1.2 then t = 1.2 end
	return t
end

local function should_counterspell_for(proj)
	if not is_enabled() then return false end
	if not proj then return false end
	if proj.isAttack then return false end
	if not proj.ability then return false end
	local source = proj.source
	if source and Entity.IsSameTeam(source, my_data.ref) then return false end

	if proj.target and proj.target ~= my_data.ref then return false end
	local name = Ability.GetName(proj.ability)
	if not name or name == "" then return false end

	if not block_abilities[name] then return false end

	return true
end

return {

	OnDraw = function()
		if not my_data or not my_data.ref or not Entity.IsAlive(my_data.ref) then return end
		local cs = get_counterspell()
		if not cs then return end
		
		if not counterspell_img then
			counterspell_img = Render.LoadImage("panorama/images/spellicons/antimage_counterspell_png.vtex_c")
		end
		
		local z = NPC.GetHealthBarOffset(my_data.ref, true) or 0
		local hb_world = my_data.pos + Vector(0, -135, z)
		local screen_pos, visible = Render.WorldToScreen(hb_world)
		if not visible then return end
		
		local size = 20
		local rounding = 4.0
		local pos = Vec2(screen_pos.x - size / 2, screen_pos.y - size / 2)
		local end_pos = Vec2(pos.x + size, pos.y + size)
		local enabled = is_enabled()
		local ready = is_counterspell_ready()
		
		local img_color
		local outline_color
		
		if not enabled then
			img_color = Color(140, 140, 140, 220)
			outline_color = Color(220, 40, 40, 255)
		elseif ready then
			img_color = Color(255, 255, 255, 255)
			outline_color = Color(0, 220, 0, 255)
		else
			img_color = Color(255, 200, 100, 200)
			outline_color = Color(255, 165, 0, 255)
		end
		
		Render.Image(counterspell_img, pos, Vec2(size + 3, size), img_color, rounding, Enum.DrawFlags.None, nil, nil, enabled and 0.0 or 0.85)
		Render.Rect(pos, Vec2(end_pos.x + 3, end_pos.y), outline_color, rounding, Enum.DrawFlags.None, 1.0)
	end,

	OnPreHumanizer = function()
		if not my_data or not my_data.ref or not Entity.IsAlive(my_data.ref) then return end
		handle_toggle()
	end,

	OnPrepareUnitOrders = function(data)
		if not my_data or not my_data.ref or not Entity.IsAlive(my_data.ref) then return true end
		if not is_enabled() then return true end
		if not data then return true end
		if data.order ~= Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET then return true end
		if not data.ability then return true end

		if not is_targeted_ability(data.ability) then return true end
		if not data.target or data.target ~= my_data.ref then return true end
		local caster = data.npc
		if caster and Entity.IsSameTeam(caster, my_data.ref) then return true end
		local name = Ability.GetName(data.ability)
		if not name or not block_abilities[name] then return true end
		
		if caster then
			local eff_range = get_cast_range(caster, data.ability)
			if eff_range < 0 then eff_range = 0 end
			if not NPC.IsEntityInRange(caster, my_data.ref, eff_range + 50) then
				return true
			end
		end
		
		if not is_counterspell_ready() then return true end

		local cp = Ability.GetCastPoint(data.ability, true) or 0.0
		local nd = net_delay()
		local fd = face_delay(data.npc)
		
		-- Используем Counterspell с учетом времени каста
		local delay = cp + nd + fd - 0.1 -- Немного раньше чтобы успеть
		if delay <= 0 then
			cast_counterspell()
		else
			-- Запланировать каст через delay секунд (можно добавить систему планировщика)
			variables.set_timer("counterspell_scheduled", delay)
		end
		
		return true
	end,

	OnUnitAnimation = function(data)
		if not my_data or not my_data.ref or not Entity.IsAlive(my_data.ref) then return end
		if not is_enabled() then return end
		if not data or not data.unit or Entity.IsSameTeam(data.unit, my_data.ref) then return end

		local ability = NPC.GetAbilityByActivity(data.unit, data.activity)
		if not ability then return end
		local name = Ability.GetName(ability)
		if not name or not block_abilities[name] then return end

		if not is_targeted_ability(ability) then return end

		local range = get_cast_range(data.unit, ability)
		if range <= 0 then range = 0 end
		local in_range = NPC.IsEntityInRange(data.unit, my_data.ref, range + 50)
		if not in_range then return end

		-- Проверяем направление каста
		local src_pos = Entity.GetAbsOrigin(data.unit)
		local face_ok = true
		if src_pos then
			local forward_pos = Entity.GetForwardPosition(data.unit, 100)
			local to_me = my_data.pos - src_pos
			local dir = forward_pos - src_pos
			if to_me and dir then
				local dot = to_me:Dot(dir)
				face_ok = dot > 0
			end
		end
		if not face_ok then return end

		if not is_counterspell_ready() then return end
		
		local cp = Ability.GetCastPoint(ability, true) or 0.0
		local nd = net_delay()
		local fd = face_delay(data.unit)
		
		-- Используем Counterspell с учетом анимации
		local delay = cp + nd + fd - 0.1
		if delay <= 0 then
			cast_counterspell()
		end
	end,

	OnProjectile = function(data)
		if not my_data or not my_data.ref or not Entity.IsAlive(my_data.ref) then return end
		if not data then return end
		if not should_counterspell_for(data) then return end
		if not is_counterspell_ready() then return end

		-- Для проджектайлов используем немедленно
		cast_counterspell()
	end,

	OnUpdate = function()
		if not my_data or not my_data.ref or not Entity.IsAlive(my_data.ref) then return end
		
		-- Проверяем запланированный каст
		if variables.check_timer("counterspell_scheduled") then
			if is_counterspell_ready() then
				cast_counterspell()
			end
		end
	end,

	OnGameEnd = function()
		-- Очистка при завершении игры
	end,
}

