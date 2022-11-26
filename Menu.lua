Menu = { sections = {} }
Menu.sectionsOrder = { aoe = 1, tankInDanger = 2, moderateDamage = 3, noMana = 4, buffsOnTank = 5 }
Menu.frame = nil
Menu.tabs = { dangerLevel = "dangerLevel", buffControl = "buffControl" }
Menu.activeTab = Menu.tabs.dangerLevel

Menu.fonts = { normal = CreateFont("normalBtnFont"), activeTabFont = CreateFont("activeTabFont")}
Menu.fonts.normal:SetTextColor(1, 1, 1)
Menu.fonts.activeTabFont:SetTextColor(0.1, 0.7, 0.15)

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
    Utils.print(i)
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

local function createMenuSection(name, title, posY, parent)
  local section = Utils.createFrame(parent, name, "ThinBorderTemplate", "TOP", "TOP", 0, posY, 570, 120)
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

local function changeTabBtnStyle(btn, font)
  btn:SetNormalFontObject(font)
end

local function onChangeTab(tabName)
  return function ()
    Menu.frame.tabsContent[Menu.activeTab]:Hide()
    changeTabBtnStyle(Menu.frame.tabs[Menu.activeTab], Menu.fonts.normal)
    changeTabBtnStyle(Menu.frame.tabs[tabName], Menu.fonts.activeTabFont)
    Menu.activeTab = tabName
    Menu.frame.tabsContent[Menu.activeTab]:Show()
  end
end

local function CreateTabs(parent)
  parent.tabs = {}
  parent.tabs[Menu.tabs.dangerLevel] = Utils.createButton(
    parent, "TOPLEFT", "TOPLEFT", 10, -30, 90, 25,
    "Danger Level", onChangeTab(Menu.tabs.dangerLevel)
  )
  parent.tabs[Menu.tabs.buffControl] = Utils.createButton(
    parent, "TOPLEFT", "TOPLEFT", 105, -30, 90, 25,
    "Buff Control", onChangeTab(Menu.tabs.buffControl)
  )

  changeTabBtnStyle(parent.tabs[Menu.tabs.dangerLevel], Menu.fonts.activeTabFont)

  return parent.tabs
end

local function createDangerLevelFrameContent(parent)
  local contentFrame = Utils.createFrame(parent, nil, nil, "CENTER", "CENTER", 3, 5, 580, 580)
  contentFrame.aoeSection = createMenuSection("aoeSection", "AOE Healing Spells", -60, contentFrame)
  contentFrame.tankSection = createMenuSection("tankSection", "`Tank in danger` Spells", -190, contentFrame)
  contentFrame.regularSection = createMenuSection("regularSection", "`Moderate danger` Spells", -320, contentFrame)
  contentFrame.noManaSection = createMenuSection("noManaSection", "`No mana` Spells", -450, contentFrame)
  table.insert(Menu.sections, contentFrame.aoeSection)
  table.insert(Menu.sections, contentFrame.tankSection)
  table.insert(Menu.sections, contentFrame.regularSection)
  table.insert(Menu.sections, contentFrame.noManaSection)
  return contentFrame
end

local function createBuffControlFrameContent(parent)
  local contentFrame = Utils.createFrame(parent, nil, nil, "CENTER", "CENTER", 3, 5, 580, 580)
  contentFrame.buffsOnTank = createMenuSection("buffsOnTank", "Buffs on Tank", -60, contentFrame)
  table.insert(Menu.sections, contentFrame.buffsOnTank)
  contentFrame:Hide()
  return contentFrame
end

function Menu_Init(self)  
  Menu.frame = Utils.createFrame(UIParent, "HealerTipsMenuFrame", "UIPanelDialogTemplate", "CENTER", "CENTER", 0, 50, 600, 600)
  Menu.frame.title = Utils.createFontString(Menu.frame, "Healer Tips - Menu")
  Menu.frame.tabs = CreateTabs(Menu.frame)

  Menu.frame.tabsContent = {}
  Menu.frame.tabsContent[Menu.tabs.dangerLevel] = createDangerLevelFrameContent(Menu.frame)
  Menu.frame.tabsContent[Menu.tabs.buffControl] = createBuffControlFrameContent(Menu.frame)

  self:RegisterEvent("ADDON_LOADED")
  self:SetScript("OnEvent", onGlobalEvents)
  Menu.frame:Hide()
end
