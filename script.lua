---@diagnostic disable: undefined-global

local agent_script = {}

local local_player_id = nil
local player_handle = nil
local known_units = {}

local function ResetState()
  player_handle = nil
  known_units = {}
end

local function AcquirePlayerHandle()
  if local_player_id then
    local candidate = Players and Players.GetPlayer(local_player_id)
    if candidate then
      player_handle = candidate
      return player_handle
    end
  end

  if player_handle and player_handle:IsNull() then
    player_handle = nil
  end

  if not player_handle and Players and Players.GetLocal() then
    player_handle = Players.GetLocal()
  end

  return player_handle
end

local function IsControlledUnit(unit)
  if not unit or unit:IsNull() then
    return false
  end

  if local_player_id == nil then
    return unit:IsControllableByAnyPlayer()
  end

  if unit:IsControllableByPlayer(local_player_id, false) then
    return true
  end

  return false
end

function agent_script.OnUpdate()
  if GameRules and GameRules:IsGamePaused() then
    return
  end

  local_player_id = Players and Players.GetLocalPlayerID and Players.GetLocalPlayerID() or local_player_id

  local player = AcquirePlayerHandle()
  if not player then
    ResetState()
    return
  end

  for _, unit in pairs(known_units) do
    if unit and not unit:IsNull() and IsControlledUnit(unit) then
      -- placeholder for issuing orders to the unit
    end
  end
end

return agent_script
