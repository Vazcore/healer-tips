Queue = {}
Queue.spell = nil
Queue.isRunning = false
Queue.queue = {}
Queue.intervalSeconds = 2
Queue.currentIntervalTime = 0
Queue.isRaid = false
Queue.isRaidOrGroup = false
Queue.numPlayers = 0
Queue.lastSpellId = 0

local ROLES = { tank = "TANK", healer = "HEALER", dps = "DAMAGER", none = "NONE" }

local function createQueueElement(spellId)
  local queueElement = {}
  queueElement.spellId = spellId
  queueElement.isRunning = false
  return queueElement
end

local function getListOfPlayersTextIds()
  local playersIds = {}
  local partyType = "party"
  local numPlayers = 4
  if (Queue.isRaid) then
    partyType = "raid"
    numPlayers = 40
  end

  local isOnline = false
  local health = 0
  local playerTextId = ""
  for i = 1, numPlayers do
    playerTextId = partyType .. i
    isOnline = UnitIsConnected(playerTextId)
    if (isOnline) then
      table.insert(playersIds, playerTextId)
    end
  end

  table.insert(playersIds, "player")

  return playersIds
end

local function getPlayers(playersIds)
  local guid = nil
  local player = nil
  local players = {}
  local playerModel = nil
  local role = nil  
  for i = 1, table.getn(playersIds) do
    guid = UnitGUID(playersIds[i])
    role = UnitGroupRolesAssigned(playersIds[i])
    local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
    playerModel = {}
    playerModel.health = UnitHealth(playersIds[i])
    playerModel.maxHealth = UnitHealthMax(playersIds[i])
    playerModel.guid = guid
    playerModel.name = name
    playerModel.role = role
    table.insert(players, playerModel)
  end

  return players
end

local function isTankInDanger(players)
end

local function isBigAOEDamage(players)
  local numPlayers = table.getn(players)
  local healthPercentage = 0
  for i = 1, numPlayers do
    healthPercentage = healthPercentage + (players[i].health / players[i].maxHealth * 100)
  end
  return (healthPercentage / numPlayers) < 90
end

local function selfLowMana()
  local percentage = UnitPower("player", 0, false) /  UnitPowerMax("player", 0, false) * 100
  return percentage < 95
end

local function isSpellReadyToUse(spellId)
  local start = GetSpellCooldown(tonumber(spellId))
  return start == 0
end

local function getAvailableSpells(spells)
  for i = 1, table.getn(spells) do
    if (spells[i].spell and isSpellReadyToUse(spells[i].spell)) then
      table.insert(Queue.queue, createQueueElement(spells[i].spell))
      break
    end
  end
end

local function manageQueue()
  Queue.queue = {}
  -- check health
  local playersIds = getListOfPlayersTextIds()
  local players = getPlayers(playersIds)
  if (isTankInDanger(players)) then
    -- add spells to protect a tank
    getAvailableSpells(Menu.frame.tankSection.selectedSpells.list)
  elseif (isBigAOEDamage(players)) then
    -- add spells for AOE damage
    getAvailableSpells(Menu.frame.aoeSection.selectedSpells.list)
  elseif (selfLowMana()) then
    -- add spells for low mana
    getAvailableSpells(Menu.frame.noManaSection.selectedSpells.list)
  else
    -- all other cases (regular danger)
    getAvailableSpells(Menu.frame.regularSection.selectedSpells.list)
  end
end

local function playSound(spellId)
  local fname = spellId .. ".ogg"
  PlaySoundFile("Interface\\AddOns\\HealerTips\\audio\\" .. fname, "Dialog")
end

local function executeQueue()
  if (Queue.isRunning == true) then
    return
  end
  Queue.isRunning = true
  local firstElement = Queue.queue[1]
  if (firstElement) then
    Queue.spell:Show()
    Queue.spell.texture:SetTexture(GetSpellTexture(firstElement.spellId))

    if (Queue.lastSpellId ~= firstElement.spellId) then
      playSound(firstElement.spellId)
    end
    
    Queue.lastSpellId = firstElement.spellId
  else
    Queue.spell:Hide()
    Queue.lastSpellId = 0
  end  
  Queue.isRunning = false
end

local function onUpdateTick(frame, elapsed)
  Queue.currentIntervalTime = Queue.currentIntervalTime + elapsed
  if Queue.currentIntervalTime >= Queue.intervalSeconds --[[and Queue.isRaidOrGroup--]] then
    Queue.currentIntervalTime = 0
    -- execute methods
    manageQueue()
    executeQueue()
  end
end

local function onPartyChange()
  Utils.print("Party size has been changed")

  local isRaid = false
  local numPlayersInGroup = GetNumGroupMembers()
  local numPlayersInRaid = GetNumRaidMembers()
  local numPlayers = 0
  if (numPlayersInGroup > 0) then
    isRaid = false
    numPlayers = numPlayersInGroup
  end

  if (numPlayersInRaid > 0) then
    isRaid = true
    numPlayers = numPlayersInRaid
  end

  Queue.isRaid = isRaid
  Queue.isRaidOrGroup = numPlayers > 0
  Queue.numPlayers = numPlayers
end

local function runQueue(self)
  local IntervalFrame = CreateFrame("Frame")
  IntervalFrame:SetScript("OnUpdate", onUpdateTick)
end

local function initRaidInfoDetection(self)
  local raidInfoFrame = CreateFrame("Frame")
  raidInfoFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  raidInfoFrame:SetScript(
    "OnEvent",
    function (self, event, ...)
      Utils.print(event)
      onPartyChange()
    end
  )
end

function QueueInit(self)
  -- Read Rules
  -- Execute queue management intervals
  initRaidInfoDetection(self)
  runQueue(self)
end