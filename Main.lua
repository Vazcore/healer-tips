local function initConsoleCommands(self)

  SLASH_HEALER_TIPS_CONSOLE1 = "/ht"
  SLASH_HEALER_TIPS_CONSOLE2 = "/healerTips"

  SlashCmdList["HEALER_TIPS_CONSOLE"] = function( msg )
    Utils.print("Open menu rules")
    Menu.frame:Show()
  end
end

local function initSpellIcon(self)
  local spell = CreateFrame("Frame", "HLBSpellItem", UIParent)
  spell:SetSize(50, 50)
  spell:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
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
  initSpellIcon(self)
end
