local Bar = {
  bars    = {},
  count   = 0,
  options = {
    height   = 150, 
    width    = 14, 
    distance = 120,
    spacing  = 3, 
    padding  = 1,
    perfect  = 1 }
}

function Bar:new(o)
  if not o.kind then
    return nil
  end
  
  if not o.unitId then
    return nil
  end
  
  setmetatable(o, self)
  self.__index = self
  
  o:Initialize()
  o:Reset()
  
  Bar.bars[o.unitId..o.kind] = o
  Bar.count = Bar.count + 1
  
  return o
end

function Bar:Initialize()
  if self.kind == "POWER" then
    local powerId, powerString = UnitPowerType(self.unitId)
    self.power = powerString
  end
  
  local index, even = math.modf(Bar.count / 2)
  
  local offsetX = Bar.options.distance + index * (Bar.options.width + Bar.options.spacing)
  if even < 0.4 then
    offsetX = -offsetX
  end
  
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetFrameStrata("BACKGROUND")
  frame:SetWidth(Bar.options["width"])
  frame:SetHeight(Bar.options["height"])
  
  frame.texture = frame:CreateTexture()
  frame.texture:SetAllPoints(frame)
  frame.texture:SetTexture(0, 0, 0)
  frame:SetPoint("CENTER", offsetX, 0)
  
  self.frame = frame
  
  local filler = CreateFrame("Frame", nil, self.frame)
  filler:SetFrameStrata("BACKGROUND")
  filler:SetWidth(Bar.options.width - Bar.options.padding * 2)
  filler:SetHeight(Bar.options.height - Bar.options.padding * 2)
  filler.texture = filler:CreateTexture()
  filler.texture:SetAllPoints(filler)
  filler:SetPoint("BOTTOMLEFT", Bar.options.padding, Bar.options.padding)
  
  self.filler = filler
  self:UpdateFillerColor()
end

function Bar:UpdateFillerColor()
  local r = 0
  local g = 0
  local b = 0
  
  if self.kind == "HEALTH" then
    r, g, b = 32, 112, 1
  elseif self.power == "MANA" then
    r, g, b = 23, 74, 137
  elseif self.power == "RAGE" then
    r, g, b = 147, 9, 0
  elseif self.power == "ENERGY" then
    r, g, b = 147, 144, 0
  elseif self.power == "RUNIC_POWER" then
    r, g, b = 48, 149, 167
  elseif self.power == "FOCUS" then
    r, g, b = 48, 149, 167
  elseif self.power == "AMMOSLOT" then
    r, g, b = 48, 149, 167
  elseif self.power == "FUEL" then
    r, g, b = 48, 149, 167
  end
  
  self.filler.texture:SetTexture(r / 255, g / 255, b / 255)
end

function Bar:Reset()
  if UnitExists(self.unitId) then
    if self.kind == "POWER" then
      local powerId, powerString = UnitPowerType(self.unitId)
      self.power = powerString
    end
    self:BindFiller()
    self:UpdateFillerColor()
    self:UpdateFillerHeight()
    self.frame:Show()
  else
    self.filler:UnregisterAllEvents()
    self.frame:Hide()
  end
end

function Bar:BindFiller()
  local kind = self.power or self.kind
  local kindValueEvent = "UNIT_"..kind
  local kindMaxValueEvent = "UNIT_MAX"..kind
  
  self.filler:UnregisterAllEvents()
  
  self.filler:SetScript("OnEvent", function()
    if self.unitId == arg1 and (event == kindValueEvent or event == kindMaxValueEvent) then
      self:UpdateFillerHeight()
    end
  end)
  
  self.filler:RegisterEvent(kindValueEvent)
  self.filler:RegisterEvent(kindMaxValueEvent)
end

function Bar:UpdateFillerHeight()
  local value, maxValue
  
  if self.kind == "HEALTH" then
    value = UnitHealth(self.unitId)
    maxValue = UnitHealthMax(self.unitId)
  else
    value = UnitPower(self.unitId)
    maxValue = UnitPowerMax(self.unitId)
  end
  
  local newHeight = (Bar.options.height - Bar.options.padding * 2) * value / maxValue
  if newHeight < 1 then
    self.filler:Hide()
  else
    self.filler:SetHeight(newHeight)
    self.filler:Show()
  end
end

function MainEventHandler()
  if event == "PLAYER_TARGET_CHANGED" then
    Bar.bars['targetHEALTH']:Reset()
    Bar.bars['targetPOWER']:Reset()
  elseif event == "UNIT_DISPLAYPOWER" then
    if arg1 == "player" or arg1 == "target" then
      Bar.bars[arg1..'POWER']:Reset()
    end
  else -- PLAYER_ENTERING_WORLD
    Bar.bars['playerPOWER']:Reset()
    Bar.bars['playerHEALTH']:Reset()
    Bar.bars['targetPOWER']:Reset()
    Bar.bars['targetHEALTH']:Reset()
  end
end

function CreatePowerBar(unitId)
  return Bar:new{kind="POWER", unitId=unitId}
end

function CreateHealthBar(unitId)
  return Bar:new{kind="HEALTH", unitId=unitId}
end

local overrideFrame = CreateFrame("Frame")
function sHUD_OnLoad()
  if arg1 == "sHUD" then
    CreateHealthBar('player')
    CreatePowerBar('player')
    CreateHealthBar('target')
    CreatePowerBar('target')

    overrideFrame:UnregisterAllEvents();
    overrideFrame:SetScript("OnEvent", MainEventHandler);
    overrideFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    overrideFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    overrideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    if Bar.options.perfect then
      local uiScale = 768/string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)")
      RegisterCVar("useUiScale", 1)
      RegisterCVar("uiScale", uiScale)
      SetCVar("useUiScale", 1)
      SetCVar("uiScale", uiScale)
    end
  end
end
overrideFrame:SetScript("OnEvent", sHUD_OnLoad);
overrideFrame:RegisterEvent("ADDON_LOADED");

function Debug(s, arg1, arg2, arg3)
  DEFAULT_CHAT_FRAME:AddMessage(s:format(arg1, arg2, arg3))
end