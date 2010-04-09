local barFrames = {}

local barOptions = { 
  ["height"]   = 100, 
  ["width"]    = 10, 
  ["distance"] = 100,
  ["spacing"]  = 2, 
  ["padding"]  = 1 }

local barCount = 0

function CreatePowerBar(unitId)
  return CreateBar("POWER", unitId)
end

function CreateHealthBar(unitId)
  return CreateBar("HEALTH", unitId)
end

function CreateBar(kind, unitId)
  local bar = CreateFrame("Frame", nil, UIParent)
  kind = ExplainKind(kind, unitId)
  InitializeBar(bar, kind)
  ResetBar(bar, kind, unitId)
  
  barCount = barCount + 1
  return bar
end

function Debug(s, arg1, arg2, arg3)
  DEFAULT_CHAT_FRAME:AddMessage(s:format(arg1, arg2, arg3))
end

function InitializeBar(bar, kind)
  local index, even = math.modf(barCount / 2)
  
  local offsetX = barOptions["distance"] + index * (barOptions["width"] + barOptions["spacing"])
  if even < 0.4 then
    offsetX = -offsetX
  end
  
  bar:SetFrameStrata("BACKGROUND")
  bar:SetWidth(barOptions["width"])
  bar:SetHeight(barOptions["height"])
  
  bar.texture = bar:CreateTexture()
  bar.texture:SetAllPoints(bar)
  bar.texture:SetTexture(0, 0, 0)
  bar:SetPoint("CENTER", offsetX, 0)
  
  local filler = CreateFrame("Frame", nil, bar)
  filler:SetFrameStrata("BACKGROUND")
  filler:SetWidth(barOptions["width"] - barOptions["padding"] * 2)
  filler:SetHeight(barOptions["height"] - barOptions["padding"] * 2)
  filler.texture = filler:CreateTexture()
  filler.texture:SetAllPoints(filler)
  SetFillerColor(filler, kind)
  filler:SetPoint("BOTTOMLEFT", barOptions["padding"], barOptions["padding"])
  
  bar.filler = filler
end

function SetFillerColor(bar, kind)
  local r = 0
  local g = 0
  local b = 0
  
  if kind == "HEALTH" then
    r, g, b = 32, 112, 1
  elseif kind == "MANA" then
    r, g, b = 23, 74, 137
  elseif kind == "RAGE" then
    r, g, b = 147, 9, 0
  elseif kind == "ENERGY" then
    r, g, b = 147, 144, 0
  elseif kind == "RUNIC_POWER" then
    r, g, b = 48, 149, 167
  elseif kind == "FOCUS" then
    r, g, b = 48, 149, 167
  elseif kind == "AMMOSLOT" then
    r, g, b = 48, 149, 167
  elseif kind == "FUEL" then
    r, g, b = 48, 149, 167
  end
  
  bar.texture:SetTexture(r / 255, g / 255, b / 255)
end

function BindBar(bar, kind, unitId)
  kind = ExplainKind(kind, unitId)
  local kindValueEvent = "UNIT_"..kind
  local kindMaxValueEvent = "UNIT_MAX"..kind
  
  bar:UnregisterAllEvents()
  
  bar:SetScript("OnEvent", function()
    if unitId == arg1 and (event == kindValueEvent or event == kindMaxValueEvent) then
      DEFAULT_CHAT_FRAME:AddMessage(msg)
      UpdateBar(bar, kind, unitId)
    end
  end)
  
  bar:RegisterEvent(kindValueEvent)
  bar:RegisterEvent(kindMaxValueEvent)
end

-- updates bar fillness/color/visibility
function UpdateBar(bar, kind, unitId)
  kind = ExplainKind(kind, unitId)
  local value, maxValue
  
  if kind == "HEALTH" then
    value = UnitHealth(unitId)
    maxValue = UnitHealthMax(unitId)
  else
    value = UnitPower(unitId)
    maxValue = UnitPowerMax(unitId)
  end
  
  bar.filler:SetHeight((barOptions["height"] - barOptions["padding"] * 2)*value/maxValue)
end

function ExplainKind(kind, unitId)
  if kind == "POWER" then
    local kindId, kindString = UnitPowerType(unitId)
    kind = kindString
  end
  return kind
end

-- used when target changed or power type changed
function ResetBar(bar, kind, unitId)
  if UnitExists(unitId) then
    kind = ExplainKind(kind, unitId)
    BindBar(bar, kind, unitId)
    SetFillerColor(bar.filler, kind)
    UpdateBar(bar, kind, unitId)
    bar:Show()
  else
    bar:UnregisterAllEvents()
    bar:Hide()
  end
end

function MainEventHandler()
  if event == "PLAYER_TARGET_CHANGED" then
    ResetBar(barFrames['targetHealthBar'], "HEALTH", "target")
    ResetBar(barFrames['targetPowerBar'], "POWER", "target")
  elseif event == "UNIT_DISPLAYPOWER" then -- display power changed here
    if arg1 == "player" or arg1 == "target" then
      ResetBar(barFrames[arg1..'PowerBar'], "POWER", "target")
    end
  else
    ResetBar(barFrames['playerHealthBar'], "HEALTH", "player")
    ResetBar(barFrames['playerPowerBar'], "POWER", "player")
    ResetBar(barFrames['targetHealthBar'], "HEALTH", "target")
    ResetBar(barFrames['targetPowerBar'], "POWER", "target")
  end
end

local overrideFrame = CreateFrame("Frame")
function sHUD_OnLoad()
  if arg1 == "sHUD" then
    barFrames['playerHealthBar'] = CreateHealthBar('player')
    barFrames['playerPowerBar']  = CreatePowerBar('player')
    barFrames['targetHealthBar'] = CreateHealthBar('target')
    barFrames['targetPowerBar']  = CreatePowerBar('target')

    overrideFrame:UnregisterAllEvents();
    overrideFrame:SetScript("OnEvent", MainEventHandler);
    overrideFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    overrideFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    overrideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    SetCVar("uiScale", 768/string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)"))
  end
end
overrideFrame:SetScript("OnEvent", sHUD_OnLoad);
overrideFrame:RegisterEvent("ADDON_LOADED");
