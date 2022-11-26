local function initConsoleCommands(self)

  SLASH_HEALER_TIPS_CONSOLE1 = "/ht"
  SLASH_HEALER_TIPS_CONSOLE2 = "/healerTips"

  SlashCmdList["HEALER_TIPS_CONSOLE"] = function( msg )
    Utils.print("Open menu rules")
    Menu.frame:Show()
  end
end

local function initSpellIcon(self, name, posx, posy)
  local spell = CreateFrame("Frame", ("HLBSpellItem_" .. name), UIParent)
  spell:SetSize(50, 50)
  spell:SetPoint("CENTER", UIParent, "CENTER", posx, posy)
  spell.texture = spell:CreateTexture(nil, "BACKGROUND")
  spell.texture:SetSize(50,50)
  spell.texture:SetPoint("TOP", spell, "TOP")
  spell.texture:SetTexture(GetSpellTexture(nil))
  spell.spellId = nil

  spell:Show()
  Queue[name] = spell
end

function Init(self)
  self:SetPoint("TOP", UIParent, "TOP")
  initConsoleCommands(self)
  initSpellIcon(self, Queue.spellIndications[2], -50, -180)
  initSpellIcon(self, Queue.spellIndications[1], 10, -180)  
  initSpellIcon(self, Queue.spellIndications[3], 70, -180)
end
