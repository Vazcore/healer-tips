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
  spell.texture:SetTexture(GetSpellTexture(51505))

  spell:Show()
  Queue.spell = spell
end

function Init(self)
  self:SetPoint("TOP", UIParent, "TOP")
  initConsoleCommands(self)
  initSpellIcon(self, "spell", 0, -180)
  --initSpellIcon(self, "additional1", 50, -180)
end
