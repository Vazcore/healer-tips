Queue = {}
Queue.spell = nil
Queue.isRunning = false
Queue.queue = {}
Queue.intervalSeconds = 1
Queue.currentIntervalTime = 0
Queue.voiceintervalSeconds = 2
Queue.currentVoiceIntervalTime = 0
Queue.isRaid = false
Queue.isRaidOrGroup = false
Queue.numPlayers = 0
Queue.lastSpellId = 0
Queue.lastSpellIdAttempts = 0
Queue.lastSpellIdLimit = 2
Queue.config = { aoeHealth = 50, tankDangerousHealth = 40, lowMana = 70 }
Queue.spellIndications = { "spell", "additionalSpell1", "additionalSpell2" }

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
    playerModel.unitId = playersIds[i]
    table.insert(players, playerModel)
  end

  return players
end

local function getTanks(players)
  local tanks = {}
  for i = 1, table.getn(players) do
    if (players[i].role == ROLES.tank) then
      table.insert(tanks, players[i])
    end
  end
  return tanks
end

local function isTankInDanger(players)
  local numPlayers = table.getn(players)
  local tanks = getTanks(players)
  local isDanger = false

  for i = 1, table.getn(tanks) do
    if (tanks[i].health < Queue.config.tankDangerousHealth) then
      isDanger = true
    end
  end

  return isDanger
end

local function isBigAOEDamage(players)
  local numPlayers = table.getn(players)
  local healthPercentage = 0
  for i = 1, numPlayers do
    healthPercentage = healthPercentage + (players[i].health / players[i].maxHealth * 100)
  end
  return (healthPercentage / numPlayers) < Queue.config.aoeHealth
end

local function selfLowMana()
  local percentage = UnitPower("player", 0, false) /  UnitPowerMax("player", 0, false) * 100
  return percentage < Queue.config.lowMana
end

local function isSpellReadyToUse(spellId)
  local start = GetSpellCooldown(tonumber(spellId))
  return start == 0
end

local function getAvailableSpells(spells)
  local haveTotem, totemName, startTime, duration = GetTotemInfo(1)
  local activeTotemSpellId = nil
  if (totemName) then
    local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(totemName)
    activeTotemSpellId = spellID
  end

  Queue.queue = {}

  for i = 1, table.getn(spells) do
    if (spells[i].spell and isSpellReadyToUse(spells[i].spell) and activeTotemSpellId ~= spells[i].spell) then
      if (Queue.spellIndications[i]) then
        table.insert(Queue.queue, createQueueElement(spells[i].spell))
      else
        break
      end      
    end
  end
end

local function buffOnTanksControlRequired(players, spellList)
  local isBuffsMissing = true
  local buffsReport = {}

  for i = 1, table.getn(spellList) do
    local buffInfo = { spellId = spellList[i].spell, spell = spellList[i].spell, isActive = false }
    buffsReport[i] = buffInfo
  end  

  local tanks = getTanks(players)
  local numTanks = table.getn(tanks)
  for i = 1, table.getn(tanks) do
    AuraUtil.ForEachAura(tanks[i].unitId, "HELPFUL", nil, function(name, icon, _, _, _, _, _, _, _, spellId, ...)
      for i = 1, table.getn(spellList) do
        if (spellList[i].spell == spellId) then
          isBuffsMissing = false
          local report = Utils.findInArrayByPropertyValue(buffsReport, "spellId", spellId)
          if (report) then report.isActive = true end
        end
      end
    end)
  end

  if (numTanks > 0 and isBuffsMissing) then
    Utils.playSound("tanks_missing_buffs")
    local notActiveBuffs = Utils.findManyInArrayByPropertyValue(buffsReport, "isActive", false)
    getAvailableSpells(notActiveBuffs)
  end

  return numTanks > 0 and isBuffsMissing
end

local function notifyAboutMissingTankBuffs()
  
end

local function manageQueue()
  Queue.queue = {}
  -- check health
  local playersIds = getListOfPlayersTextIds()
  local players = getPlayers(playersIds)
  if (isTankInDanger(players)) then
    -- add spells to protect a tank
    getAvailableSpells(Menu.sections[Menu.sectionsOrder.tankInDanger].selectedSpells.list)
  elseif (isBigAOEDamage(players)) then
    -- add spells for AOE damage
    getAvailableSpells(Menu.sections[Menu.sectionsOrder.aoe].selectedSpells.list)
  elseif (selfLowMana()) then
    -- add spells for low mana
    getAvailableSpells(Menu.sections[Menu.sectionsOrder.noMana].selectedSpells.list)
  elseif (buffOnTanksControlRequired(players, Menu.sections[Menu.sectionsOrder.buffsOnTank].selectedSpells.list)) then
    notifyAboutMissingTankBuffs()
  else
    -- all other cases (regular danger)
    getAvailableSpells(Menu.sections[Menu.sectionsOrder.moderateDamage].selectedSpells.list)
  end
end

local function clearAllIndications()
  for i = 1, table.getn(Queue.spellIndications) do
    local spellIcon = Queue[Queue.spellIndications[i]]
    spellIcon.texture:SetTexture(nil)
  end
end

local function findSpellInIndications(spellId)
  local isFound = false
  for i = 1, table.getn(Queue.spellIndications) do
    local spellIcon = Queue[Queue.spellIndications[i]]
    if (spellIcon.spellId == spellId) then
      isFound = true
      break
    end
  end

  return isFound
end

local function executeQueue()
  if (Queue.isRunning == true) then
    return
  end
  Queue.isRunning = true
  
  clearAllIndications()

  for i = 1, table.getn(Queue.queue) do
    local spellIcon = Queue[Queue.spellIndications[i]]
    spellIcon.texture:SetTexture(GetSpellTexture(Queue.queue[i].spellId))
    spellIcon.spellId = Queue.queue[i].spellId
  end
  Queue.isRunning = false
end

local function executeVoiceMessages()
  local voiceElement = Queue.queue[1]
  if (voiceElement) then
    if (Queue.lastSpellId ~= voiceElement.spellId) then
      Utils.playSound(voiceElement.spellId)
    else
      -- reset voice attempts
      Queue.lastSpellIdAttempts = Queue.lastSpellIdAttempts + 1
      if Queue.lastSpellIdAttempts >= Queue.lastSpellIdLimit then
        Queue.lastSpellIdAttempts = 0
        Queue.lastSpellId = nil
      end
    end
    Queue.lastSpellId = voiceElement.spellId
  end
end

local function onUpdateTick(frame, elapsed)  
  Queue.currentIntervalTime = Queue.currentIntervalTime + elapsed
  Queue.currentVoiceIntervalTime = Queue.currentVoiceIntervalTime + elapsed
  if Queue.currentIntervalTime >= Queue.intervalSeconds --[[and Queue.isRaidOrGroup--]] then
    Queue.currentIntervalTime = 0
    -- execute methods
    manageQueue()
    executeQueue()
  end

  if ( Queue.currentVoiceIntervalTime >= Queue.voiceintervalSeconds) then
    Queue.currentVoiceIntervalTime = 0
    executeVoiceMessages()
  end
end

local function onPartyChange()
  Utils.print("Party size has been changed")

  local isRaid = false
  local numPlayersInGroupHome = GetNumGroupMembers(1)
  local numPlayersInGroupInstance = GetNumGroupMembers(2)
  local numPlayers = numPlayersInGroupHome
  if (numPlayersInGroupInstance > numPlayersInGroupHome) then
    numPlayers = numPlayersInGroupInstance
  end

  if (numPlayers > 5) then
    isRaid = true
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