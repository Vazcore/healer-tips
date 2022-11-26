Utils = {}

Utils.debug = true

Utils.print = function (message)
  if (Utils.debug) then
    print(message)
  end
end

Utils.createFrame = function ( ... )
  local parent, name, template, pos1, pos2, ox, oy, w, h, type  = ...
  local frame = CreateFrame(type ~= nil and type or "Frame", name, parent, template)
  frame:SetSize(w, h)
  frame:SetPoint(pos1, parent, pos2, ox, oy)

  return frame
end

Utils.createEditBox = function ( ... )  
  local parent, pos1, pos2, ox, oy, w, h  = ...
  local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetSize(150, 50)
  scrollFrame:SetPoint("CENTER")
  local frame = CreateFrame("EditBox", nil, parent)
  frame:SetWidth(w)
  frame:SetFontObject(ChatFontNormal)
  frame:SetPoint(pos1, parent, pos2, ox, oy)
  scrollFrame:SetScrollChild(frame)
  return scrollFrame
end

Utils.createFontString = function (frame, text)
  local font = frame:CreateFontString(nil, "OVERLAY")
  font:SetFontObject("GameFontHighlight")
  font:SetPoint("TOP", frame, "TOP", 5, -10)
  font:SetText(text)
end

Utils.createDropdownMenu = function (options, onClick, dropDown)
  local groupNum = 20
  local totalElements = table.getn(options)
  local groups = ceil(totalElements / groupNum)    

  local onCreateMenu = function (frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.func = onClick

    if level == 1 then
      for g = 1, groups do
        info.text, info.hasArrow, info.menuList = ("Group " .. g), true, g
        UIDropDownMenu_AddButton(info)
      end
    elseif menuList and menuList > 0 then
      local from = (menuList - 1) * groupNum + 1
      local to = from + groupNum - 1
      if (to > totalElements) then
        to = totalElements
      end
      for k = from, to do
        info.text, info.arg1 = options[k].label, options[k].value
        UIDropDownMenu_AddButton(info, level)
      end
    end
  end

  return onCreateMenu
 end

Utils.createDropdown = function (frame, name, options, onClick, position, parent, pos2, ox, oy)
  local dropDown = CreateFrame("Frame", name, frame, "UIDropDownMenuTemplate")
  dropDown:SetPoint(position, parent, pos2, ox, oy)
  UIDropDownMenu_SetWidth(dropDown, 200)
  UIDropDownMenu_Initialize(dropDown, Utils.createDropdownMenu(options, onClick, dropDown))
  return dropdown
end

Utils.getAllSpells = function ()
  local spells = {}
  for i = 1, 150 do
    local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(i, "spell")
    if name ~= nil then
      local spell = { label = name, value = spellID, name = name, icon = icon, spellId = spellID }
      table.insert(spells, spell)
    end
  end
  return spells
end

Utils.createButton = function( ... )
  local parent, pos1, pos2, ox, oy, w, h, text, onClick = ...
  local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  button:SetPoint(pos1, parent, pos2, ox, oy)
  button:SetSize(w, h)
  button:SetText(text)

  if onClick then
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", onClick)
  end
  
  return button
end