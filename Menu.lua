Menu = { sections = {} }
Menu.frame = nil

local function initUserData()
  if UserData == nil or UserData.sections == nil then
    UserData = {}
    UserData.sections = {}
  end
end

local function ReadUserData(sections)
  initUserData()
  for i = 1, table.getn(UserData.sections) do
    -- section
    for j = 1, table.getn(UserData.sections[i]) do
      -- spell
      local spellId = UserData.sections[i][j]
      local spellList = sections[i].selectedSpells.list
      spellList[j].spell = spellId
      spellList[j].texture:SetTexture(GetSpellTexture(spellId))
    end
  end
end

local function WriteUserData()
  initUserData()
  UserData.sections = {}
  for i = 1, table.getn(Menu.sections) do
    -- categories
    local sectionSpells = {}
    for j = 1, table.getn(Menu.sections[i].selectedSpells.list) do
      -- spells
      table.insert(sectionSpells, Menu.sections[i].selectedSpells.list[j].spell)
    end
    table.insert(UserData.sections, sectionSpells)
  end
end

local function onSelectSpell(sectionFrame)    
  local handleOnSelect = function (element)
    local totalElements = table.getn(sectionFrame.list)    
    for i = 1, totalElements do
      if (sectionFrame.list[i].spell == nil) then
        sectionFrame.list[i].spell = element.arg1
        sectionFrame.list[i].texture:SetTexture(GetSpellTexture(element.arg1))
        break
      end
    end
    WriteUserData()
  end
  return handleOnSelect
end

local function onDeleteSelectedSpell(self, btn)
  Utils.print("Clicked" .. " - " .. self.index)
  -- local section = Menu.frame[self.sectionId] or {}
  -- for i = 1, section.selectedSpells.list do
  --   local el = section.selectedSpells.list[i]
  --   if (el.spell == self.spell) then
      
  --   end
  -- end
  self.spell = nil
  self.texture:SetTexture(nil)
  WriteUserData()
end

local function initSelectedSpells (frame, sectionId)
  local numInRow = 10
  local iconWidth = 30
  frame.list = {}
  for i = 0, (numInRow - 1) do
    local posLeft = (i * iconWidth) * 1.2 + 10
    local spellIcon = Utils.createFrame(frame, "HLBSpellItemSelected" .. sectionId .. "-" .. i, nil, "TOPLEFT", "TOPLEFT", posLeft, -5, iconWidth, iconWidth)
    spellIcon.texture = spellIcon:CreateTexture(nil, "BACKGROUND")
    spellIcon.texture:SetSize(iconWidth, iconWidth)
    spellIcon.texture:SetPoint("CENTER", spellIcon, "CENTER")
    spellIcon.texture:SetTexture(nil)
    spellIcon.index = i
    spellIcon.sectionId = sectionId
    spellIcon.spell = nil
    spellIcon:SetScript("OnMouseDown", onDeleteSelectedSpell)
    table.insert(frame.list, spellIcon)
    spellIcon:Show()
  end
end

local function onClearSpells(frame)
  local onClearAllSpells = function ()
    for i = 1, table.getn(frame.list) do
      frame.list[i].texture:SetTexture(nil)
      frame.list[i].spell = nil
    end
    WriteUserData()
  end
  return onClearAllSpells
end

local function createMenuSection(name, title, posY)
  local section = Utils.createFrame(Menu.frame, name, "ThinBorderTemplate", "TOP", "TOP", 0, posY, 570, 120)
  section.title =  Utils.createFontString(section, title)
  
  section.selectedSpells = Utils.createFrame(
    section, (name .. "Spells"),
    "HorizontalBarTemplate", "TOP", "TOP", 0, -70, 500, 40
  )
  initSelectedSpells(section.selectedSpells, name)
  section.clearAllBtn = Utils.createButton(
    section, "TOPLEFT", "TOPLEFT", 30, -30, 90, 25,
    "Clear All", onClearSpells(section.selectedSpells)
  )
  -- section.searchInput = Utils.createEditBox(
  --   section, "TOP", "TOP", 200, -100, 90, 40
  -- )
  section.spellList = Utils.createDropdown(
    section, "SpellListDropdown",
    Utils.getAllSpells(), onSelectSpell(section.selectedSpells), "TOP", section, "TOP", 0, -30
  )
  return section
end

local function onGlobalEvents(self, event)
  if (event == "ADDON_LOADED") then
    ReadUserData(Menu.sections)
  end
end

function Menu_Init(self)  
  Menu.frame = Utils.createFrame(UIParent, "HealerTipsMenuFrame", "UIPanelDialogTemplate", "CENTER", "CENTER", 0, 50, 600, 600)
  Menu.frame.title = Utils.createFontString(Menu.frame, "Healer Tips - Menu")
  
  Menu.frame.aoeSection = createMenuSection("aoeSection", "AOE Healing Spells", -40)
  Menu.frame.tankSection = createMenuSection("tankSection", "`Tank in danger` Spells", -170)
  Menu.frame.regularSection = createMenuSection("regularSection", "`Moderate danger` Spells", -300)
  Menu.frame.noManaSection = createMenuSection("noManaSection", "`No mana` Spells", -450)
  Menu.sections = { Menu.frame.aoeSection, Menu.frame.tankSection, Menu.frame.regularSection, Menu.frame.noManaSection }

  self:RegisterEvent("ADDON_LOADED")
  self:SetScript("OnEvent", onGlobalEvents)
  Menu.frame:Hide()
end
