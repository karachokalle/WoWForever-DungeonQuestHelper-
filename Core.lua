local ADDON = ...
WFDQHDB = WFDQHDB or { hideTooHigh = false, hideCompleted = true, filter = "All" }
WFDQHDB.activeTab = WFDQHDB.activeTab or "quests"
WFDQH_UpdateRequested = WFDQH_UpdateRequested or false
if WFDQHDB.hideCompleted == nil then WFDQHDB.hideCompleted = true end

local frame, content, statusText, filterBox
local questWidgets = {}
local lootPanel, lootContent, lootStatus, lootDropdown, bossDropdown
local lootDungeonList = WFDQH_DUNGEON_LOOT or {}
local raidList = WFDQH_RAID_LOOT or {}
local raidPanel, raidContent, raidStatus, raidDropdown, raidBossDropdown
local lootLabels, raidLabels = {}, {}
local RefreshLoot, RefreshRaid
local tierPanel, tierContent, tierStatus, tierClassDropdown, tierSpecDropdown
local gearPanel, gearContent, gearStatus, gearClassDropdown, gearSpecDropdown, gearModeDropdown
local tierLabels, gearLabels = {}, {}
local RefreshTierSets, RefreshGearLists
local ROW_HEIGHT = 100
local Refresh

local function PlayerFaction()
    return (UnitFactionGroup and UnitFactionGroup("player")) or "Both"
end

local function PlayerLevel()
    return (UnitLevel and UnitLevel("player")) or 1
end

local completedCache = nil
local function IsCompleted(questID)
    if not questID then return false end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, result = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok and result then return true end
    end
    if IsQuestFlaggedCompleted then
        local ok, result = pcall(IsQuestFlaggedCompleted, questID)
        if ok and result then return true end
    end
    -- Some clients expose a completed-quest ID table instead of the direct query.
    if GetQuestsCompleted then
        if not completedCache then
            local ok, result = pcall(GetQuestsCompleted)
            if ok and type(result) == "table" then
                completedCache = {}
                for id, value in pairs(result) do
                    if type(id) == "number" and value then completedCache[id] = true end
                    if type(value) == "number" then completedCache[value] = true end
                end
            end
        end
        if completedCache and completedCache[questID] then return true end
    end
    return false
end

local function IsQuestCompleted(q)
    if q.questID and IsCompleted(q.questID) then return true end
    for _, questID in ipairs(q.questIDs or {}) do
        if IsCompleted(questID) then return true end
    end
    return false
end

local function HasQuestInLog(q)
    local ids = {}
    if q.questID then ids[q.questID] = true end
    for _, questID in ipairs(q.questIDs or {}) do ids[questID] = true end
    if q.questID and C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetNumQuestLogEntries then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and ids[info.questID] then return true end
        end
    end
    if GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, GetNumQuestLogEntries() do
            local title = GetQuestLogTitle(i)
            if title and q.title and title == q.title then return true end
        end
    end
    return false
end

local function GetStatus(q)
    if HasQuestInLog(q) then return "|cff55ddffIn Questlog|r" end
    if IsQuestCompleted(q) then return "|cffaaaaaaAbgeschlossen|r" end
    if PlayerLevel() < (q.minLevel or 1) then
        return "|cffff5555Mindestlevel " .. tostring(q.minLevel) .. " erforderlich|r"
    end
    local faction = PlayerFaction()
    if q.faction and q.faction ~= "Both" and q.faction ~= faction then
        return "|cffff5555Andere Fraktion|r"
    end
    if q.prerequisiteNames and #q.prerequisiteNames > 0 then
        return "|cffffff55Vorquests hinterlegt – Abschluss muss verifiziert werden|r"
    end
    return "|cffffff55Level passt – Questgeber prüfen|r"
end

local function ClearRows()
    if not content then return end
    for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
end

local function ClearLootRows(targetContent, labels)
    if not targetContent then return end
    for _, child in ipairs({targetContent:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    for i = #labels, 1, -1 do labels[i]:Hide(); labels[i] = nil end
end

local function MakeLootItem(parent, item, bossName, x, y)
    local itemID = tonumber(item.itemID)
    local itemName, itemLink, quality, _, _, _, _, _, _, texture
    if itemID and GetItemInfo then
        itemName, itemLink, quality, _, _, _, _, _, _, texture = GetItemInfo(itemID)
    end
    if itemID and not texture and C_Item and C_Item.GetItemIconByID then
        local ok, iconFileID = pcall(C_Item.GetItemIconByID, itemID)
        if ok then texture = iconFileID end
    end
    if itemID and not texture and GetItemIcon then texture = GetItemIcon(itemID) end
    if itemID and not texture then
        if C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, itemID)
        elseif GetItemInfo then
            pcall(GetItemInfo, itemID)
        end
    end
    texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(244, 54)
    card:SetPoint("TOPLEFT", x, y)
    card:EnableMouse(true)
    card:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    card:SetBackdropColor(0.06, 0.07, 0.09, 0.9)

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", card, "LEFT", 7, 0)
    icon:SetTexture(texture)

    local name = itemName or item.name or (itemID and ("Gegenstand #" .. itemID)) or "Unbekannter Gegenstand"
    if quality and GetItemQualityColor then
        local red, green, blue = GetItemQualityColor(quality)
        if red and green and blue then
            name = ("|cff%02x%02x%02x%s|r"):format(math.floor(red * 255 + 0.5), math.floor(green * 255 + 0.5), math.floor(blue * 255 + 0.5), name)
        end
    end
    local itemText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, -1)
    itemText:SetWidth(190)
    itemText:SetJustifyH("LEFT")
    itemText:SetText(name)

    local chanceText = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    chanceText:SetPoint("TOPLEFT", itemText, "BOTTOMLEFT", 0, -5)
    chanceText:SetWidth(190)
    chanceText:SetJustifyH("LEFT")
    chanceText:SetText(item.dropChance and ("Dropchance: %.2f%%"):format(tonumber(item.dropChance) or 0) or "Dropchance nicht hinterlegt")

    card:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if itemLink then GameTooltip:SetHyperlink(itemLink)
        elseif itemID then GameTooltip:SetHyperlink("item:" .. tostring(itemID))
        else GameTooltip:SetText(name) end
        GameTooltip:AddLine("Boss: " .. tostring(bossName), 0.8, 0.8, 0.8, true)
        if item.dropChance then
            GameTooltip:AddLine(("Beobachtete Dropchance: %.2f%%"):format(tonumber(item.dropChance) or 0), 0.4, 1, 0.4, true)
        else
            GameTooltip:AddLine("Für diesen Gegenstand ist keine Dropchance in der Datenquelle hinterlegt.", 1, 0.8, 0.3, true)
        end
        GameTooltip:AddLine("Shift + Linksklick: am Charakter anprobieren", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    card:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" or not IsShiftKeyDown() then return end
        local link = itemLink or (itemID and ("item:" .. tostring(itemID)))
        if link and DressUpItemLink then DressUpItemLink(link)
        elseif itemID and DressUpItem then DressUpItem(itemID) end
    end)
    card:Show()
end

local function RefreshLootView(dataList, instanceKey, bossKey, instanceDropdown, selectedBossDropdown, targetContent, targetStatus, labels, kind, refreshFunction)
    if not targetContent then return end
    ClearLootRows(targetContent, labels)
    if not dataList or #dataList == 0 then
        targetStatus:SetText("Für die Datenbank sind noch keine " .. kind .. "-Drops hinterlegt.")
        return
    end
    local selected = WFDQHDB[instanceKey] or dataList[1].name
    local instance
    for _, candidate in ipairs(dataList) do
        if candidate.name == selected then instance = candidate; break end
    end
    instance = instance or dataList[1]
    WFDQHDB[instanceKey] = instance.name
    if instanceDropdown and UIDropDownMenu_SetSelectedValue then
        UIDropDownMenu_SetSelectedValue(instanceDropdown, instance.name)
        UIDropDownMenu_SetText(instanceDropdown, instance.name)
    end

    local bosses = instance.bosses or {}
    local selectedBoss = WFDQHDB[bossKey] or "All"
    local bossExists = selectedBoss == "All"
    for _, boss in ipairs(bosses) do
        if (boss.name or boss.boss) == selectedBoss then bossExists = true; break end
    end
    if not bossExists then selectedBoss = "All"; WFDQHDB[bossKey] = "All" end
    if selectedBossDropdown then
        UIDropDownMenu_Initialize(selectedBossDropdown, function(_, level)
            local allInfo = UIDropDownMenu_CreateInfo()
            allInfo.text = "Alle Bosse"
            allInfo.value = "All"
            allInfo.func = function()
                WFDQHDB[bossKey] = "All"
                UIDropDownMenu_SetSelectedValue(selectedBossDropdown, "All")
                UIDropDownMenu_SetText(selectedBossDropdown, "Alle Bosse")
                refreshFunction()
            end
            UIDropDownMenu_AddButton(allInfo, level)
            for _, boss in ipairs(bosses) do
                local bossName = boss.name or boss.boss or "Unbekannter Boss"
                local info = UIDropDownMenu_CreateInfo()
                info.text = bossName
                info.value = bossName
                info.func = function()
                    WFDQHDB[bossKey] = bossName
                    UIDropDownMenu_SetSelectedValue(selectedBossDropdown, bossName)
                    UIDropDownMenu_SetText(selectedBossDropdown, bossName)
                    refreshFunction()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        local bossLabel = selectedBoss == "All" and "Alle Bosse" or selectedBoss
        UIDropDownMenu_SetSelectedValue(selectedBossDropdown, selectedBoss)
        UIDropDownMenu_SetText(selectedBossDropdown, bossLabel)
    end
    local totalItems, knownRates = 0, 0
    local shownBosses = 0
    local y = -4
    for _, boss in ipairs(bosses) do
        local bossName = boss.name or boss.boss or "Unbekannter Boss"
        if selectedBoss == "All" or bossName == selectedBoss then
            shownBosses = shownBosses + 1
            local header = targetContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            table.insert(labels, header)
            header:SetPoint("TOPLEFT", 4, y)
            header:SetWidth(500)
            header:SetText(bossName)
            y = y - 27
            local items = boss.loot or boss.items or {}
            for i, item in ipairs(items) do
                totalItems = totalItems + 1
                if tonumber(item.dropChance) then knownRates = knownRates + 1 end
                local column = (i - 1) % 2
                local row = math.floor((i - 1) / 2)
                MakeLootItem(targetContent, item, bossName, column * 250, y - row * 58)
            end
            y = y - math.ceil(#items / 2) * 62 - 8
        end
    end
    if totalItems == 0 then
        local empty = targetContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        table.insert(labels, empty)
        empty:SetPoint("TOPLEFT", 6, -8)
        empty:SetWidth(480)
        empty:SetJustifyH("LEFT")
        empty:SetText(selectedBoss == "All" and ("Für diesen " .. kind .. " sind in der verwendeten AtlasLoot-Datenquelle noch keine Boss-Drops hinterlegt.") or "Für diesen Boss sind in der verwendeten AtlasLoot-Datenquelle noch keine Drops hinterlegt.")
        y = -56
    end
    targetContent:SetHeight(math.max(1, -y))
    targetStatus:SetText(("%s · %d/%d Bosse · %d Gegenstände · Dropchance bei %d Gegenständen hinterlegt · Quelle: AtlasLoot Classic Forever"):format(instance.name, shownBosses, #bosses, totalItems, knownRates))
end

RefreshLoot = function()
    RefreshLootView(lootDungeonList, "lootDungeon", "lootBoss", lootDropdown, bossDropdown, lootContent, lootStatus, lootLabels, "Dungeon", RefreshLoot)
end

RefreshRaid = function()
    RefreshLootView(raidList, "raidInstance", "raidBoss", raidDropdown, raidBossDropdown, raidContent, raidStatus, raidLabels, "Raid", RefreshRaid)
end

local function GetGearClass(name)
    for _, classInfo in ipairs(WFDQH_GEAR_CLASSES or {}) do
        if classInfo.name == name then return classInfo end
    end
    return (WFDQH_GEAR_CLASSES or {})[1]
end

local function SetSimpleDropdown(dropdown, values, selected, onSelect, labelForValue)
    if not dropdown or not UIDropDownMenu_Initialize then return end
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, value in ipairs(values or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = labelForValue and labelForValue(value) or value
            info.value = value
            info.func = function()
                onSelect(value)
                UIDropDownMenu_SetSelectedValue(dropdown, value)
                UIDropDownMenu_SetText(dropdown, labelForValue and labelForValue(value) or value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, selected)
    UIDropDownMenu_SetText(dropdown, labelForValue and labelForValue(selected) or selected)
end

-- Character-window-style gear layout shared by the Tiersets and Pre-BiS/BiS tabs.
-- Item data can use the slot's English key (for example "Head", "Finger", or
-- "Main Hand") or its WoW inventory slot ID. Missing/unverified data stays empty.
local PAPERDOLL_SLOTS = {
    { key = "Head", label = "Kopf", token = "HeadSlot", column = 1, row = 1 },
    { key = "Hands", label = "Hände", token = "HandsSlot", column = 2, row = 1 },
    { key = "Neck", label = "Hals", token = "NeckSlot", column = 1, row = 2 },
    { key = "Waist", label = "Taille", token = "WaistSlot", column = 2, row = 2 },
    { key = "Shoulder", label = "Schultern", token = "ShoulderSlot", column = 1, row = 3 },
    { key = "Legs", label = "Beine", token = "LegsSlot", column = 2, row = 3 },
    { key = "Back", label = "Rücken", token = "BackSlot", column = 1, row = 4 },
    { key = "Feet", label = "Füße", token = "FeetSlot", column = 2, row = 4 },
    { key = "Chest", label = "Brust", token = "ChestSlot", column = 1, row = 5 },
    { key = "Finger1", label = "Ring 1", token = "Finger0Slot", column = 2, row = 5 },
    { key = "Shirt", label = "Hemd", token = "ShirtSlot", column = 1, row = 6 },
    { key = "Finger2", label = "Ring 2", token = "Finger1Slot", column = 2, row = 6 },
    { key = "Tabard", label = "Wappenrock", token = "TabardSlot", column = 1, row = 7 },
    { key = "Trinket1", label = "Schmuckstück 1", token = "Trinket0Slot", column = 2, row = 7 },
    { key = "Wrist", label = "Handgelenke", token = "WristSlot", column = 1, row = 8 },
    { key = "Trinket2", label = "Schmuckstück 2", token = "Trinket1Slot", column = 2, row = 8 },
    { key = "MainHand", label = "Waffenhand", token = "MainHandSlot", column = 1, row = 9 },
    { key = "OffHand", label = "Nebenhand", token = "SecondaryHandSlot", column = 2, row = 9 },
    { key = "Ranged", label = "Distanzwaffe", token = "RangedSlot", column = 1, row = 10 },
}

local GEAR_SLOT_ALIASES = {
    head = "Head", helm = "Head", neck = "Neck", necklace = "Neck",
    shoulder = "Shoulder", shoulders = "Shoulder", cloak = "Back", back = "Back",
    chest = "Chest", robe = "Chest", shirt = "Shirt", tabard = "Tabard",
    wrist = "Wrist", wrists = "Wrist", bracer = "Wrist", bracers = "Wrist",
    hands = "Hands", hand = "Hands", gloves = "Hands", glove = "Hands",
    waist = "Waist", belt = "Waist", legs = "Legs", leg = "Legs", pants = "Legs",
    feet = "Feet", boots = "Feet", boot = "Feet", finger = "Finger", ring = "Finger",
    trinket = "Trinket", mainhand = "MainHand", weapon = "MainHand", offhand = "OffHand",
    secondaryhand = "OffHand", ranged = "Ranged", rangedweapon = "Ranged",
}

local function NormalizeGearSlot(value)
    if type(value) ~= "string" then return nil end
    local key = value:lower():gsub("[%s%p_]", "")
    if key == "finger1" or key == "ring1" then return "Finger1" end
    if key == "finger2" or key == "ring2" then return "Finger2" end
    if key == "trinket1" then return "Trinket1" end
    if key == "trinket2" then return "Trinket2" end
    return GEAR_SLOT_ALIASES[key]
end

local function GetGearSlotIcon(slot)
    if GetInventorySlotInfo then
        local _, texture = GetInventorySlotInfo(slot.token)
        if texture then return texture end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function RenderGearPaperDoll(targetContent, labels, items, title, detailLines, footer)
    local equipped = {}
    local duplicateCounts = { Finger = 0, Trinket = 0 }
    for _, item in ipairs(items or {}) do
        local slot = NormalizeGearSlot(item.slot or item.equipSlot)
        if slot == "Finger" or slot == "Trinket" then
            duplicateCounts[slot] = duplicateCounts[slot] + 1
            slot = slot .. math.min(duplicateCounts[slot], 2)
        end
        if not slot and tonumber(item.slotID or item.inventorySlot or item.slot) then
            local numericSlot = tonumber(item.slotID or item.inventorySlot or item.slot)
            local numericMap = { [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest", [6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands", [11] = "Finger1", [12] = "Finger2", [13] = "Trinket1", [14] = "Trinket2", [15] = "Back", [16] = "MainHand", [17] = "OffHand", [18] = "Ranged", [19] = "Tabard" }
            slot = numericMap[numericSlot]
        end
        if slot and not equipped[slot] then equipped[slot] = item end
    end

    local heading = targetContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    labels[#labels + 1] = heading
    heading:SetPoint("TOPLEFT", 6, -4)
    heading:SetWidth(480)
    heading:SetText(title or "Ausrüstung")

    local subtitle = targetContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labels[#labels + 1] = subtitle
    subtitle:SetPoint("TOPLEFT", 6, -26)
    subtitle:SetWidth(480)
    subtitle:SetText("Ausrüstungsplätze · Gegenstand für Details überfahren")

    for _, slot in ipairs(PAPERDOLL_SLOTS) do
        local isWeaponRow = slot.row == 9 or slot.row == 10
        local x = isWeaponRow and (slot.column == 1 and 92 or 272) or (slot.column == 1 and 0 or 252)
        local y = isWeaponRow and -390 - (slot.row - 9) * 42 or -52 - (slot.row - 1) * 42
        local card = CreateFrame("Button", nil, targetContent, "BackdropTemplate")
        card:SetSize(isWeaponRow and 170 or 244, 38)
        card:SetPoint("TOPLEFT", x, y)
        card:EnableMouse(true)
        card:RegisterForClicks("LeftButtonUp")
        card:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        card:SetBackdropColor(0.06, 0.07, 0.09, 0.88)

        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT", card, "LEFT", 3, 0)
        local item = equipped[slot.key]
        local itemID = item and tonumber(item.itemID)
        local itemName, itemLink, quality, _, _, _, _, _, _, texture
        if itemID and GetItemInfo then
            itemName, itemLink, quality, _, _, _, _, _, _, texture = GetItemInfo(itemID)
        end
        if itemID and not texture and C_Item and C_Item.GetItemIconByID then
            local ok, iconFileID = pcall(C_Item.GetItemIconByID, itemID)
            if ok then texture = iconFileID end
        end
        icon:SetTexture(texture or (item and item.icon) or GetGearSlotIcon(slot))

        local slotText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slotText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, -2)
        slotText:SetWidth(card:GetWidth() - 44)
        slotText:SetJustifyH("LEFT")
        slotText:SetText(slot.label)

        local name = item and (itemName or item.name or (itemID and ("Gegenstand #" .. tostring(itemID))) or "Gegenstand nicht bestätigt") or "Keine Daten hinterlegt"
        if item and quality and GetItemQualityColor then
            local red, green, blue = GetItemQualityColor(quality)
            if red and green and blue then
                name = ("|cff%02x%02x%02x%s|r"):format(math.floor(red * 255 + 0.5), math.floor(green * 255 + 0.5), math.floor(blue * 255 + 0.5), name)
            end
        elseif not item then
            name = "|cff888888" .. name .. "|r"
        end
        local itemText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        itemText:SetPoint("TOPLEFT", slotText, "BOTTOMLEFT", 0, -2)
        itemText:SetWidth(card:GetWidth() - 44)
        itemText:SetJustifyH("LEFT")
        itemText:SetText(name)

        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if itemLink then GameTooltip:SetHyperlink(itemLink)
            elseif itemID then GameTooltip:SetHyperlink("item:" .. tostring(itemID))
            else GameTooltip:SetText(slot.label) end
            if item then
                if not itemLink and not itemID then GameTooltip:AddLine(item.name or "Gegenstand", 1, 1, 1, true) end
                if item.source then GameTooltip:AddLine("Quelle: " .. tostring(item.source), 0.75, 0.85, 1, true) end
                if item.stats then GameTooltip:AddLine(tostring(item.stats), 0.85, 0.85, 0.85, true) end
                GameTooltip:AddLine("Shift + Linksklick: am Charakter anprobieren", 0.7, 0.85, 1, true)
            else
                GameTooltip:AddLine("Für diesen Platz sind noch keine bestätigten Gegenstandsdaten hinterlegt.", 1, 0.8, 0.3, true)
            end
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function() GameTooltip:Hide() end)
        card:SetScript("OnClick", function(_, button)
            if button ~= "LeftButton" or not IsShiftKeyDown() or not item then return end
            local link = itemLink or (itemID and ("item:" .. tostring(itemID)))
            if link and DressUpItemLink then DressUpItemLink(link)
            elseif itemID and DressUpItem then DressUpItem(itemID) end
        end)
        card:Show()
    end

    local y = -478
    for _, lineText in ipairs(detailLines or {}) do
        local line = targetContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        labels[#labels + 1] = line
        line:SetPoint("TOPLEFT", 6, y)
        line:SetWidth(480)
        line:SetJustifyH("LEFT")
        line:SetText(lineText)
        y = y - 18
    end
    if footer then
        local note = targetContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        labels[#labels + 1] = note
        note:SetPoint("TOPLEFT", 6, y - 4)
        note:SetWidth(480)
        note:SetJustifyH("LEFT")
        note:SetText(footer)
        y = y - 38
    end
    targetContent:SetHeight(math.max(1, -y))
end

local function ClearGearRows(targetContent, labels)
    if not targetContent then return end
    for _, child in ipairs({targetContent:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    for i = #labels, 1, -1 do labels[i]:Hide(); labels[i] = nil end
end

RefreshTierSets = function()
    if not tierContent then return end
    ClearGearRows(tierContent, tierLabels)
    local classes = WFDQH_GEAR_CLASSES or {}
    if #classes == 0 then
        tierStatus:SetText("Für die Tiersets sind noch keine Klassendaten geladen.")
        return
    end
    local classInfo = GetGearClass(WFDQHDB.gearClass)
    local className = classInfo.name
    WFDQHDB.gearClass = className
    local selectedSpec = WFDQHDB.gearSpec
    local specExists = false
    for _, spec in ipairs(classInfo.specs or {}) do if spec == selectedSpec then specExists = true end end
    if not specExists then selectedSpec = (classInfo.specs or {})[1] end
    WFDQHDB.gearSpec = selectedSpec
    local classNames = {}
    for _, class in ipairs(classes) do classNames[#classNames + 1] = class.name end
    SetSimpleDropdown(tierClassDropdown, classNames, className, function(value)
        WFDQHDB.gearClass = value
        local newClass = GetGearClass(value)
        WFDQHDB.gearSpec = newClass and newClass.specs[1] or nil
        RefreshTierSets()
    end)
    SetSimpleDropdown(tierSpecDropdown, classInfo.specs or {}, selectedSpec, function(value)
        WFDQHDB.gearSpec = value
        RefreshTierSets()
    end)

    local shown = 0
    local selectedSet
    for _, setInfo in ipairs(WFDQH_TIER_SETS or {}) do
        if setInfo.class == className and setInfo.spec == selectedSpec then
            shown = shown + 1
            selectedSet = setInfo
            break
        end
    end
    local detailLines = {}
    for _, bonus in ipairs((selectedSet and selectedSet.bonuses) or {}) do
        detailLines[#detailLines + 1] = tostring(bonus.pieces) .. " Teile: " .. tostring(bonus.text)
    end
    local title = selectedSet and selectedSet.name or (className .. " · " .. selectedSpec .. " · kein bestätigtes Tierset")
    local footer = selectedSet
        and "Vorläufige Wowhead-Datamining-Daten; konkrete Gegenstandsteile und Bossquellen sind noch nicht bestätigt."
        or "Für diese Klasse/Spezialisierung liegt derzeit kein verifiziertes Forever-Tierset vor."
    RenderGearPaperDoll(tierContent, tierLabels, selectedSet and (selectedSet.items or selectedSet.gear) or {}, title, detailLines, footer)
    tierStatus:SetText(("Quelle: Wowhead · %s · Stand %s · Datamining, Änderungen möglich"):format(WFDQH_TIER_DATA_SOURCE or "Wowhead Forever", WFDQH_GEAR_DATA_VERSION or "unbekannt"))
end

RefreshGearLists = function()
    if not gearContent then return end
    ClearGearRows(gearContent, gearLabels)
    local classes = WFDQH_GEAR_CLASSES or {}
    if #classes == 0 then
        gearStatus:SetText("Für Pre-BiS/BiS sind noch keine Klassendaten geladen.")
        return
    end
    local classInfo = GetGearClass(WFDQHDB.gearClass)
    local className = classInfo.name
    WFDQHDB.gearClass = className
    local selectedSpec = WFDQHDB.gearSpec
    local specExists = false
    for _, spec in ipairs(classInfo.specs or {}) do if spec == selectedSpec then specExists = true end end
    if not specExists then selectedSpec = (classInfo.specs or {})[1] end
    WFDQHDB.gearSpec = selectedSpec
    local classNames = {}
    for _, class in ipairs(classes) do classNames[#classNames + 1] = class.name end
    SetSimpleDropdown(gearClassDropdown, classNames, className, function(value)
        WFDQHDB.gearClass = value
        local newClass = GetGearClass(value)
        WFDQHDB.gearSpec = newClass and newClass.specs[1] or nil
        RefreshGearLists()
    end)
    SetSimpleDropdown(gearSpecDropdown, classInfo.specs or {}, selectedSpec, function(value)
        WFDQHDB.gearSpec = value
        RefreshGearLists()
    end)
    local modes = { "Pre-BiS", "BiS" }
    local mode = WFDQHDB.gearMode or "Pre-BiS"
    if mode ~= "BiS" then mode = "Pre-BiS" end
    SetSimpleDropdown(gearModeDropdown, modes, mode, function(value)
        WFDQHDB.gearMode = value
        RefreshGearLists()
    end)
    local byClass = WFDQH_GEAR_LISTS and WFDQH_GEAR_LISTS[className]
    local bySpec = byClass and byClass[selectedSpec]
    local items = bySpec and bySpec[mode] or {}
    local footer = #items == 0
        and ((WFDQH_GEAR_DATA_STATUS or "Für diese Auswahl sind noch keine verifizierten Forever-Empfehlungen hinterlegt.") .. " Sobald belastbare Daten vorliegen, werden die bestätigten Gegenstände den Slots zugeordnet.")
        or "Slotdaten, Item-Tooltips und Quelle zeigen die verfügbaren Details. Shift + Linksklick probiert einen Gegenstand am Charakter an."
    RenderGearPaperDoll(gearContent, gearLabels, items, className .. " · " .. selectedSpec .. " · " .. mode, {}, footer)
    gearStatus:SetText(("%s · %s · %s · nur Forever-Empfehlungen"):format(className, selectedSpec, mode))
end

local activeWaypoint
local expandedQuestTitle
local mapPin
local arrowFrame
local waypointTicker
local nativeWaypointSet = false

local function ParseCoordinates(q)
    if not q or not q.coordinates then return nil end
    local x, y = tostring(q.coordinates):match('([%d%.]+)%s*,%s*([%d%.]+)')
    x, y = tonumber(x), tonumber(y)
    if not x or not y or x < 0 or y < 0 or x > 100 or y > 100 then return nil end
    return x / 100, y / 100
end

local function GetTargetZone(q)
    if q and q.location then
        local z = tostring(q.location):match('^([^,]+)') or tostring(q.location)
        z = z:gsub('^%s+', ''):gsub('%s+$', '')
        return z
    end
end

local function NormalizeMapName(name)
    return tostring(name or ""):lower():gsub("[%s%p]", "")
end

local function GetZoneAliases(zone)
    local aliases = {
        ["stormwind"] = {"Stormwind City", "Sturmwind"},
        ["ironforge"] = {"Ironforge City", "Ironforge", "Eisenschmiede"},
        ["badlands"] = {"Badlands", "Ödland"},
        ["thebarrens"] = {"The Barrens", "Barrens", "Brachland"},
        ["thousandneedles"] = {"Thousand Needles", "Tausend Nadeln"},
        ["hillsbradfoothills"] = {"Hillsbrad Foothills", "Hillsbrad", "Vorgebirge des Hügellands"},
        ["tarrenmill"] = {"Hillsbrad Foothills", "Vorgebirge des Hügellands"},
        ["brill"] = {"Tirisfal Glades", "Tirisfal"},
        ["silverpineforest"] = {"Silverpine Forest", "Silberwald"},
        ["wetlands"] = {"Wetlands", "Sumpfland"},
        ["darkshore"] = {"Darkshore", "Dunkelküste"},
        ["ashenvale"] = {"Ashenvale", "Eschental"},
        ["duskwood"] = {"Duskwood", "Dämmerwald"},
        ["redridgemountains"] = {"Redridge Mountains", "Rotkammgebirge"},
        ["burningsteppes"] = {"Burning Steppes", "Brennende Steppe"},
        ["westernplaguelands"] = {"Western Plaguelands", "Westliche Pestländer"},
        ["easternplaguelands"] = {"Eastern Plaguelands", "Östliche Pestländer"},
        ["winterspring"] = {"Winterspring", "Winterquell"},
        ["swampofsorrows"] = {"Swamp of Sorrows", "Sümpfe des Elends"},
        ["hinterlands"] = {"The Hinterlands", "Hinterland"},
        ["thehinterlands"] = {"The Hinterlands", "Hinterland"},
        ["thunderbluff"] = {"Thunder Bluff", "Donnerfels"},
        ["blackrockmountain"] = {"Blackrock Mountain", "Der Schwarzfels"},
    }
    local result = {zone}
    for _, alias in ipairs(aliases[NormalizeMapName(zone)] or {}) do
        table.insert(result, alias)
    end
    return result
end

local function FindMapIDForZone(zone)
    if not zone or not C_Map or not C_Map.GetFallbackWorldMapID or not C_Map.GetMapChildrenInfo then return nil end
    local root = C_Map.GetFallbackWorldMapID()
    if not root then return nil end

    local wanted = {}
    for _, name in ipairs(GetZoneAliases(zone)) do wanted[NormalizeMapName(name)] = true end
    local seen, stack = {}, {root}
    while #stack > 0 do
        local parentID = table.remove(stack)
        if not seen[parentID] then
            seen[parentID] = true
            local ok, children = pcall(C_Map.GetMapChildrenInfo, parentID, nil, false)
            if ok and type(children) == "table" then
                for _, child in ipairs(children) do
                    if child and child.mapID and child.name then
                        if wanted[NormalizeMapName(child.name)] then return child.mapID, child.name end
                        table.insert(stack, child.mapID)
                    end
                end
            end
        end
    end
end

local function SetNativeMapWaypoint(q, x, y)
    if not C_Map or not C_Map.SetUserWaypoint or not UiMapPoint or not UiMapPoint.CreateFromCoordinates then return false end
    local mapID = q.mapID
    local mapName
    if not mapID then mapID, mapName = FindMapIDForZone(GetTargetZone(q)) end
    if not mapID then
        print('|cffffcc00WFDQH:|r Kein Kartenbereich für „' .. tostring(GetTargetZone(q) or "unbekannt") .. '“ gefunden; der Questgeber-Pin konnte nicht gesetzt werden.')
        return false
    end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(mapID) then
        print('|cffffcc00WFDQH:|r Auf dieser Karte kann kein Ingame-Wegpunkt gesetzt werden.')
        return false
    end

    if WorldMapFrame and WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(mapID) end
    if WorldMapFrame and WorldMapFrame.Show then WorldMapFrame:Show() end
    local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
    local ok, wasSet = pcall(C_Map.SetUserWaypoint, point)
    if not ok or wasSet == false then
        print('|cffffcc00WFDQH:|r Der WoW-Client hat den Karten-Pin nicht angenommen.')
        return false
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
    nativeWaypointSet = true
    if mapPin then mapPin:Hide() end
    return true, mapName
end

local function ClearNativeWaypoint()
    if not nativeWaypointSet then return end
    if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, false)
    end
    nativeWaypointSet = false
end

local function SameZone(a, b)
    if not a or not b then return false end
    a, b = a:lower(), b:lower()
    if a == b or a:find(b, 1, true) or b:find(a, 1, true) then return true end
    local aliases = {
        ['the barrens']='barrens', ['barrens']='the barrens',
        ['thousand needles']='thousand needles', ['badlands']='badlands',
        ['hillsbrad foothills']='hillsbrad foothills', ['undercity']='undercity',
        ['ironforge']='ironforge', ['stormwind']='stormwind city', ['stormwind city']='stormwind',
        ['thunder bluff']='thunder bluff', ['orgrimmar']='orgrimmar',
        ['swamp of sorrows']='swamp of sorrows', ['tanaris']='tanaris', ['desolace']='desolace'
    }
    return aliases[a] ~= nil and aliases[a] == b or aliases[b] ~= nil and aliases[b] == a
end

local function RemoveMapPin()
    if mapPin then mapPin:Hide(); mapPin:SetParent(nil); mapPin = nil end
end

local function UpdateMapPin()
    if nativeWaypointSet then
        if mapPin then mapPin:Hide() end
        return
    end
    if not activeWaypoint or not WorldMapFrame or not WorldMapFrame:IsShown() then
        if mapPin then mapPin:Hide() end
        return
    end
    local tx, ty = ParseCoordinates(activeWaypoint)
    if not tx or not ty then
        if mapPin then mapPin:Hide() end
        return
    end

    -- Classic 1.12/1.60 map layouts render the visible map in WorldMapButton.
    -- WorldMapDetailFrame may be a texture layer with a different size/offset,
    -- which can place the marker outside the visible map.
    local parent = WorldMapButton or WorldMapDetailFrame or WorldMapFrame
    if not parent or not parent.GetWidth or parent:GetWidth() <= 0 or parent:GetHeight() <= 0 then
        return
    end

    if not mapPin then
        mapPin = CreateFrame('Frame', nil, parent)
        mapPin:SetFrameStrata('DIALOG')
        mapPin:SetSize(16, 16)
        local t = mapPin:CreateTexture(nil, 'OVERLAY')
        t:SetAllPoints(mapPin)
        t:SetTexture('Interface/TargetingFrame/UI-RaidTargetingIcon_8')
        mapPin.texture = t
    elseif mapPin:GetParent() ~= parent then
        mapPin:SetParent(parent)
    end

    mapPin:ClearAllPoints()
    -- Use the visible map button's normalized area coordinates.
    mapPin:SetPoint('CENTER', parent, 'TOPLEFT', tx * parent:GetWidth(), -ty * parent:GetHeight())
    mapPin:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 1) + 30)
    mapPin:Show()

    -- Keep a clear label visible even when the user has not navigated to the
    -- quest's zone yet; do not silently suppress the marker based on localized names.
end

local function CreateArrow()
    if arrowFrame then return end
    arrowFrame = CreateFrame('Frame', 'WFDQH_WaypointArrow', UIParent)
    arrowFrame:SetSize(100, 74)
    arrowFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, -120)
    arrowFrame:SetFrameStrata('HIGH')
    arrowFrame:EnableMouse(true)
    arrowFrame:SetMovable(true)
    arrowFrame:RegisterForDrag('LeftButton')
    arrowFrame:SetScript('OnDragStart', arrowFrame.StartMoving)
    arrowFrame:SetScript('OnDragStop', arrowFrame.StopMovingOrSizing)
    local bg = arrowFrame:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetTexture('Interface/Tooltips/UI-Tooltip-Background')
    bg:SetVertexColor(0, 0, 0, 0.72)
    local arrow = arrowFrame:CreateTexture(nil, 'ARTWORK')
    arrow:SetTexture('Interface/Minimap/MinimapArrow')
    arrow:SetSize(30, 30)
    arrow:SetPoint('TOP', 0, -4)
    arrowFrame.arrow = arrow
    local label = arrowFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    label:SetPoint('BOTTOM', 0, 5)
    label:SetWidth(94)
    label:SetJustifyH('CENTER')
    arrowFrame.label = label
    arrowFrame:Hide()
end

local function UpdateWaypointArrow()
    if not activeWaypoint then if arrowFrame then arrowFrame:Hide() end; return end
    CreateArrow()
    local tx, ty = ParseCoordinates(activeWaypoint)
    if not tx or not ty then arrowFrame.label:SetText('Keine Koordinaten'); arrowFrame:Show(); return end
    local zone = GetZoneText and GetZoneText() or ''
    local targetZone = GetTargetZone(activeWaypoint) or ''
    if not SameZone(zone, targetZone) then
        arrowFrame.label:SetText(targetZone .. '\nWegpunkt: ' .. math.floor(tx*100+0.5) .. ', ' .. math.floor(ty*100+0.5))
        arrowFrame.arrow:SetAlpha(0.45)
        arrowFrame:Show()
        return
    end
    local px, py
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local mapID = C_Map.GetBestMapForUnit('player')
        local position = mapID and C_Map.GetPlayerMapPosition(mapID, 'player')
        if position then
            if position.GetXY then px, py = position:GetXY()
            else px, py = position.x, position.y end
        end
    elseif GetPlayerMapPosition then
        px, py = GetPlayerMapPosition('player')
    end
    if not px or (px == 0 and py == 0) then
        arrowFrame.label:SetText(targetZone .. '\n' .. math.floor(tx*100+0.5) .. ', ' .. math.floor(ty*100+0.5))
        arrowFrame:Show(); return
    end
    local dx, dy = tx - px, py - ty
    local distance = math.sqrt(dx*dx + dy*dy)
    local bearing = math.atan2 and math.atan2(dx, dy) or math.atan(dx / (dy == 0 and 0.0001 or dy))
    arrowFrame.arrow:SetRotation(-bearing)
    arrowFrame.arrow:SetAlpha(1)
    arrowFrame.label:SetText(targetZone .. '\n' .. math.floor(tx*100+0.5) .. ', ' .. math.floor(ty*100+0.5) .. ' · ' .. math.floor(distance*1000) .. ' Z-Einheiten')
    arrowFrame:Show()
end

local function SetWaypoint(q)
    local x, y = ParseCoordinates(q)
    if not x or not y then
        print('|cffffcc00WFDQH:|r Für diesen Eintrag sind keine nutzbaren Zahlenkoordinaten hinterlegt (Dungeon-Orte sind derzeit nicht markierbar).')
        return
    end
    activeWaypoint = q
    UpdateWaypointArrow()
    local nativeSet = SetNativeMapWaypoint(q, x, y)
    if not nativeSet then
        -- On Forever, prefer a real user waypoint and don't draw a misleading
        -- overlay on whichever unrelated map happened to be open.
        if C_Map and C_Map.SetUserWaypoint then
            activeWaypoint = nil
            if arrowFrame then arrowFrame:Hide() end
            return
        end
        -- Keep the visible map marker as a fallback on clients without native waypoint APIs.
        nativeWaypointSet = false
        if q.mapIndex and SetMapZoom then pcall(SetMapZoom, q.mapIndex)
        elseif q.mapID and SetMapByID then pcall(SetMapByID, q.mapID) end
        if WorldMapFrame and WorldMapFrame.Show then WorldMapFrame:Show() end
        UpdateMapPin()
    end
    print('|cff33ff99WFDQH Ingame-Pin gesetzt:|r ' .. tostring(q.giver or q.title) .. ' – ' .. tostring(GetTargetZone(q)) .. ' (' .. math.floor(x*100+0.5) .. ', ' .. math.floor(y*100+0.5) .. '). /dqhelp clear zum Entfernen.')
end

local function GetQuestLogXP(q)
    if not GetQuestLogRewardXP then return nil end
    local ids = {}
    if q.questID then table.insert(ids, q.questID) end
    for _, questID in ipairs(q.questIDs or {}) do
        local duplicate = false
        for _, existingID in ipairs(ids) do
            if existingID == questID then duplicate = true; break end
        end
        if not duplicate then table.insert(ids, questID) end
    end
    for _, questID in ipairs(ids) do
        -- WoW Forever's 1.60.1 API accepts the quest ID directly and returns
        -- the character-specific total XP, including current quest bonuses.
        local ok, totalXP = pcall(GetQuestLogRewardXP, questID)
        if ok and tonumber(totalXP) and tonumber(totalXP) >= 0 then
            return tonumber(totalXP)
        end
    end
end

local function GetQuestXP(q)
    local xp = GetQuestLogXP(q)
    if xp then return xp, "Spiel-API" end
    xp = tonumber(q.xpReward)
    if xp and xp >= 0 then return xp, "Datenbank", tonumber(q.xpRewardLevel) or tonumber(q.questLevel) end
end

local function GetXPProgressText(q)
    local xp, source, xpLevel = GetQuestXP(q)
    if not xp then
        return "Erfahrung: Für diese Quest-ID hat der Client keinen XP-Wert geliefert."
    end
    local playerLevel = UnitLevel and tonumber(UnitLevel("player")) or nil
    if source == "Datenbank" and xpLevel and playerLevel and playerLevel ~= xpLevel then
        return ("Erfahrung: %d EP sind bei Queststufe %d dokumentiert; ein verlässlicher Prozentwert für Stufe %d liegt nicht vor."):format(xp, xpLevel, playerLevel)
    end
    local xpMax = UnitXPMax and tonumber(UnitXPMax("player")) or nil
    if not xpMax or xpMax <= 0 then
        return ("Erfahrung: %d EP · Quelle: %s"):format(xp, source)
    end
    local gainedPercent = xp / xpMax * 100
    local currentXP = UnitXP and tonumber(UnitXP("player")) or nil
    local text = ("Erfahrung: %d EP = %.1f%% dieses Levelbalkens"):format(xp, gainedPercent)
    if currentXP then
        local currentPercent = currentXP / xpMax * 100
        local remainingXP = math.max(0, xpMax - currentXP)
        text = text .. (xp >= remainingXP
            and (" · aktuell %.1f%%, reicht für den nächsten Levelaufstieg"):format(currentPercent)
            or (" · aktuell %.1f%%, danach %.1f%%"):format(currentPercent, (currentXP + xp) / xpMax * 100))
    end
    return text .. " · " .. source
end

local function MakeRow(q, index, offset)
    local rewards = q.rewards or {}
    local hasRewards = q.xpReward or q.moneyReward or #rewards > 0
    local summary
    if hasRewards then
        summary = (q.xpReward and (tostring(q.xpReward) .. " EP") or "") ..
            (q.moneyReward and (" · " .. tostring(q.moneyReward)) or "") ..
            (#rewards > 0 and (" · " .. (q.rewardChoices and "Auswahl aus " or "") .. #rewards .. " Gegenstand/Gegenständen") or "")
    elseif q.rewardDataVerified then
        summary = "Keine Geld-/Gegenstandsbelohnung dokumentiert"
    else
        summary = "Belohnungen nicht verifiziert"
    end
    local expanded = expandedQuestTitle == q.title
    -- The reward line sits below the prerequisite text; reserve enough room for
    -- it so it remains visible inside the scroll row after expanding.
    local rewardColumns = 2
    local rewardRows = math.ceil(#rewards / rewardColumns)
    local rowHeight = ROW_HEIGHT + (expanded and (68 + rewardRows * 26) or 0)
    local row = CreateFrame("Button", nil, content, "BackdropTemplate")
    row:SetSize(505, rowHeight)
    row:SetPoint("TOPLEFT", 0, -offset)
    row:EnableMouse(true)
    row:SetScript("OnClick", function()
        expandedQuestTitle = expanded and nil or q.title
        Refresh()
    end)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Belohnungen: " .. summary)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    row:SetBackdropColor(0.08, 0.08, 0.1, 0.88)

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -7)
    title:SetWidth(390)
    title:SetJustifyH("LEFT")
    title:SetText((q.title or "Unbekannte Quest") .. " |cffaaaaaa(" .. (q.dungeon or "?") .. ")|r")

    local details = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    details:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    details:SetWidth(480)
    details:SetJustifyH("LEFT")
    details:SetText("Mindestlevel: " .. tostring(q.minLevel or "?") .. " | Fraktion: " .. tostring(q.faction or "unbekannt") ..
        "\nQuestgeber: " .. tostring(q.giver or "unbekannt") .. "\nFundort: " .. tostring(q.location or "?") ..
        " (" .. tostring(q.coordinates or "keine Koordinaten") .. ")")

    local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("TOPLEFT", details, "BOTTOMLEFT", 0, -4)
    status:SetWidth(480)
    status:SetJustifyH("LEFT")
    status:SetText(GetStatus(q))

    local pre = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pre:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -3)
    pre:SetWidth(480)
    pre:SetJustifyH("LEFT")
    pre:SetText("Vorquests: " .. ((q.prerequisiteNames and #q.prerequisiteNames > 0) and table.concat(q.prerequisiteNames, " → ") or "keine hinterlegt"))

    local pin = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    pin:SetSize(72, 22)
    pin:SetPoint("TOPRIGHT", -8, -8)
    pin:SetText("Pin")
    pin:SetScript("OnClick", function() SetWaypoint(q) end)
    if expanded then
        local rewardHeading = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rewardHeading:SetPoint("TOPLEFT", pre, "BOTTOMLEFT", 0, -5)
        rewardHeading:SetWidth(480)
        local xpProgress = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        xpProgress:SetPoint("TOPLEFT", rewardHeading, "BOTTOMLEFT", 0, -4)
        xpProgress:SetWidth(480)
        xpProgress:SetJustifyH("LEFT")
        xpProgress:SetText(GetXPProgressText(q))
        if hasRewards then
            local heading = {}
            if q.rewardChoices then table.insert(heading, "Belohnungsauswahl – wähle einen Gegenstand")
            else table.insert(heading, "Questbelohnung") end
            if q.xpReward then table.insert(heading, "Erfahrung: " .. tostring(q.xpReward) .. " EP") end
            if q.moneyReward then table.insert(heading, "Geld: " .. tostring(q.moneyReward)) end
            rewardHeading:SetText(table.concat(heading, " · "))

            for rewardIndex, reward in ipairs(rewards) do
                local itemID = type(reward) == "table" and reward.itemID or nil
                local fallbackName = type(reward) == "table" and reward.name or tostring(reward)
                local itemName, itemLink, quality, itemLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, texture
                if itemID and GetItemInfo then
                    itemName, itemLink, quality, itemLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, texture = GetItemInfo(itemID)
                end
                local itemButton = CreateFrame("Button", nil, row)
                itemButton:SetSize(232, 24)
                local column = (rewardIndex - 1) % rewardColumns
                local itemRow = math.floor((rewardIndex - 1) / rewardColumns)
                itemButton:SetPoint("TOPLEFT", xpProgress, "BOTTOMLEFT", column * 240, -4 - itemRow * 26)
                itemButton:EnableMouse(true)
                local icon = itemButton:CreateTexture(nil, "ARTWORK")
                icon:SetSize(20, 20)
                icon:SetPoint("LEFT", itemButton, "LEFT", 0, 0)
                icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                local itemText = itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                itemText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
                itemText:SetWidth(204)
                itemText:SetJustifyH("LEFT")
                local displayName = itemName or fallbackName or (itemID and ("Gegenstand #" .. itemID)) or "Unbekannter Gegenstand"
                if quality and GetItemQualityColor then
                    local red, green, blue = GetItemQualityColor(quality)
                    if red and green and blue then
                        local hex = ("%02x%02x%02x"):format(math.floor(red * 255 + 0.5), math.floor(green * 255 + 0.5), math.floor(blue * 255 + 0.5))
                        displayName = "|c" .. hex .. displayName .. "|r"
                    end
                end
                itemText:SetText(displayName)
                itemButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    if itemLink then
                        GameTooltip:SetHyperlink(itemLink)
                    elseif itemID then
                        GameTooltip:SetHyperlink("item:" .. tostring(itemID))
                    else
                        GameTooltip:SetText(displayName)
                    end
                    if not itemLink and not itemName then
                        GameTooltip:AddLine("Gegenstandsdaten werden vom Spiel geladen.", 0.8, 0.8, 0.8, true)
                    end
                    GameTooltip:AddLine("Shift + Linksklick: am Charakter anprobieren", 0.7, 0.85, 1, true)
                    GameTooltip:Show()
                end)
                itemButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
                itemButton:SetScript("OnClick", function(_, button)
                    if button ~= "LeftButton" or not IsShiftKeyDown() then return end
                    local link = itemLink or (itemID and ("item:" .. tostring(itemID)))
                    if link and DressUpItemLink then
                        DressUpItemLink(link)
                    elseif itemID and DressUpItem then
                        DressUpItem(itemID)
                    else
                        print("|cffffcc00WFDQH:|r Anprobieren ist für diesen Gegenstand in diesem Client nicht verfügbar.")
                    end
                end)
                itemButton:Show()
            end
        elseif q.rewardDataVerified then
            rewardHeading:SetText("Keine Geld- oder Gegenstandsbelohnung dokumentiert; XP-Angaben fehlen in der Quelle.")
        else
            rewardHeading:SetText("Für diese Quest gibt es noch keine bestätigten Forever-Belohnungsdaten.")
        end
    end
    row:Show()
    return rowHeight
end

Refresh = function()
    if not content then return end
    ClearRows()
    local all = WFDQH_QUESTS or {}
    local shown = 0
    local search = (WFDQHDB.search or ""):lower()
    local filtered = {}
    for _, q in ipairs(all) do
        local factionOK = not q.faction or q.faction == "Both" or q.faction == PlayerFaction()
        local levelOK = not WFDQHDB.hideTooHigh or (q.minLevel or 1) <= PlayerLevel()
        local text = ((q.title or "") .. " " .. (q.dungeon or "") .. " " .. (q.giver or "") .. " " .. (q.location or "")):lower()
        local searchOK = search == "" or text:find(search, 1, true)
        local completedOK = not WFDQHDB.hideCompleted or not IsQuestCompleted(q)
        if factionOK and levelOK and searchOK and completedOK then
            table.insert(filtered, q)
        end
    end
    local sortBy = WFDQHDB.sortBy or {name = true, level = false, faction = false}
    table.sort(filtered, function(a, b)
        -- Dungeon is the primary grouping when enabled, so matching dungeons appear together.
        if sortBy.dungeon then
            local ad, bd = tostring(a.dungeon or "Unbekannter Dungeon"):lower(), tostring(b.dungeon or "Unbekannter Dungeon"):lower()
            if ad ~= bd then return ad < bd end
        end
        if sortBy.level then
            local al, bl = tonumber(a.minLevel) or 1, tonumber(b.minLevel) or 1
            if al ~= bl then return al < bl end
        end
        if sortBy.faction then
            local af, bf = tostring(a.faction or "Both"), tostring(b.faction or "Both")
            if af ~= bf then return af < bf end
        end
        if sortBy.name ~= false then
            local an, bn = tostring(a.title or ""):lower(), tostring(b.title or ""):lower()
            if an ~= bn then return an < bn end
        end
        return tostring(a.title or ""):lower() < tostring(b.title or ""):lower()
    end)
    local totalHeight = 0
    for _, q in ipairs(filtered) do
        shown = shown + 1
        totalHeight = totalHeight + MakeRow(q, shown, totalHeight)
    end
    content:SetHeight(math.max(1, totalHeight))
    local activeSort = {}
    if sortBy.dungeon then table.insert(activeSort, "Dungeon") end
    if sortBy.level then table.insert(activeSort, "Level") end
    if sortBy.faction then table.insert(activeSort, "Fraktion") end
    if sortBy.name ~= false then table.insert(activeSort, "Name") end
    statusText:SetText(("Sortierung: %s · Stufe %d · %d von %d Quests · Datenbank %s"):format(table.concat(activeSort, " + "), PlayerLevel(), shown, #all, WFDQH_DATABASE_VERSION or "unbekannt"))
end

local function CreateWindow()
    frame = CreateFrame("Frame", "WFDQH_MainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(570, 560)
    frame:SetPoint("CENTER")
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true); frame:Hide()
    frame.TitleText:SetText("WoW Forever – Quest & Gear Helper")

    local function TrackQuestWidget(widget)
        table.insert(questWidgets, widget)
        return widget
    end
    local function SetActiveTab(tab)
        WFDQHDB.activeTab = tab
        for _, widget in ipairs(questWidgets) do
            if tab == "quests" then widget:Show() else widget:Hide() end
        end
        if lootPanel then lootPanel:SetShown(tab == "loot") end
        if raidPanel then raidPanel:SetShown(tab == "raids") end
        if tierPanel then tierPanel:SetShown(tab == "tiersets") end
        if gearPanel then gearPanel:SetShown(tab == "gear") end
        if tab == "loot" then RefreshLoot()
        elseif tab == "raids" then RefreshRaid()
        elseif tab == "tiersets" then RefreshTierSets()
        elseif tab == "gear" then RefreshGearLists()
        else Refresh() end
    end
    local questsTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    questsTab:SetSize(76, 22); questsTab:SetPoint("TOPLEFT", 16, -30)
    questsTab:SetText("Quests")
    questsTab:SetScript("OnClick", function() SetActiveTab("quests") end)
    local lootTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    lootTab:SetSize(104, 22); lootTab:SetPoint("LEFT", questsTab, "RIGHT", 5, 0)
    lootTab:SetText("Dungeon Drops")
    lootTab:SetScript("OnClick", function() SetActiveTab("loot") end)
    local raidTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    raidTab:SetSize(54, 22); raidTab:SetPoint("LEFT", lootTab, "RIGHT", 5, 0)
    raidTab:SetText("Raids")
    raidTab:SetScript("OnClick", function() SetActiveTab("raids") end)
    local tierTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    tierTab:SetSize(72, 22); tierTab:SetPoint("LEFT", raidTab, "RIGHT", 5, 0)
    tierTab:SetText("Tiersets")
    tierTab:SetScript("OnClick", function() SetActiveTab("tiersets") end)
    local gearTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    gearTab:SetSize(100, 22); gearTab:SetPoint("LEFT", tierTab, "RIGHT", 5, 0)
    gearTab:SetText("Pre-BiS/BiS")
    gearTab:SetScript("OnClick", function() SetActiveTab("gear") end)

    local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", 16, -58); info:SetPoint("TOPRIGHT", -16, -58); info:SetJustifyH("LEFT")
    info:SetText("Wowhead-basierte Startdatenbank. Suche nach Quest, Dungeon, Questgeber oder Gebiet.")
    TrackQuestWidget(info)

    local search = CreateFrame("EditBox", "WFDQH_SearchBox", frame, "InputBoxTemplate")
    search:SetSize(240, 24); search:SetPoint("TOPLEFT", 18, -78); search:SetAutoFocus(false)
    TrackQuestWidget(search)
    search:SetText(WFDQHDB.search or "")
    search:SetScript("OnTextChanged", function(self)
        WFDQHDB.search = self:GetText() or ""
        if frame:IsShown() then Refresh() end
    end)

    local hide = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    hide:SetSize(160, 24); hide:SetPoint("LEFT", search, "RIGHT", 10, 0)
    TrackQuestWidget(hide)
    hide:SetText("Level-Filter umschalten")
    hide:SetScript("OnClick", function()
        WFDQHDB.hideTooHigh = not WFDQHDB.hideTooHigh
        Refresh()
    end)

    local updateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    updateButton:SetSize(126, 24)
    updateButton:SetPoint("TOPRIGHT", -16, -78)
    TrackQuestWidget(updateButton)
    updateButton:SetText("DB aktualisieren")
    updateButton:SetScript("OnClick", function()
        WFDQH_UpdateRequested = true
        print("|cff33ff99WFDQH:|r Update angefordert. Jetzt |cffffff00/reload|r eingeben. Das Begleitprogramm muss laufen und eine geprüfte HTTPS-Datenquelle konfiguriert haben.")
    end)
    local clearPinButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearPinButton:SetSize(126, 24)
    clearPinButton:SetPoint("TOPRIGHT", -16, -108)
    TrackQuestWidget(clearPinButton)
    clearPinButton:SetText("Pin löschen")
    clearPinButton:SetScript("OnClick", function()
        ClearNativeWaypoint()
        activeWaypoint = nil
        RemoveMapPin()
        if arrowFrame then arrowFrame:Hide() end
        print("|cff33ff99WFDQH:|r Wegpunkt entfernt.")
    end)

    WFDQHDB.sortBy = WFDQHDB.sortBy or {name = true, level = false, faction = false, dungeon = false}
    -- Backward-compatible with SavedVariables from versions before dungeon sorting.
    if WFDQHDB.sortBy.dungeon == nil then WFDQHDB.sortBy.dungeon = false end
    local sortLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortLabel:SetPoint("TOPLEFT", 18, -108)
    sortLabel:SetText("Sortieren nach:")
    TrackQuestWidget(sortLabel)
    local function MakeSortCheck(label, key, x)
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", x, -122)
        TrackQuestWidget(cb)
        cb:SetChecked(WFDQHDB.sortBy[key] and true or false)
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 0, 0)
        cb.text:SetText(label)
        cb:SetHitRectInsets(0, -62, 0, 0)
        cb:SetScript("OnClick", function(self)
            WFDQHDB.sortBy[key] = self:GetChecked() and true or false
            -- Keep at least one criterion active.
            if not WFDQHDB.sortBy.name and not WFDQHDB.sortBy.level and not WFDQHDB.sortBy.faction and not WFDQHDB.sortBy.dungeon then
                WFDQHDB.sortBy.name = true
                local nameCheck = WFDQH_SortNameCheck
                if nameCheck then nameCheck:SetChecked(true) end
            end
            Refresh()
        end)
        return cb
    end
    WFDQH_SortNameCheck = MakeSortCheck("Name", "name", 18)
    WFDQH_SortLevelCheck = MakeSortCheck("Level", "level", 120)
    WFDQH_SortFactionCheck = MakeSortCheck("Fraktion", "faction", 222)
    WFDQH_SortDungeonCheck = MakeSortCheck("Dungeon", "dungeon", 324)

    local completedCheck = CreateFrame("CheckButton", "WFDQH_HideCompletedCheck", frame, "UICheckButtonTemplate")
    completedCheck:SetSize(22, 22)
    completedCheck:SetPoint("TOPLEFT", 18, -143)
    TrackQuestWidget(completedCheck)
    completedCheck:SetChecked(WFDQHDB.hideCompleted and true or false)
    completedCheck.text = completedCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    completedCheck.text:SetPoint("LEFT", completedCheck, "RIGHT", 0, 0)
    completedCheck.text:SetText("Erledigte Quests ausblenden")
    completedCheck:SetHitRectInsets(0, -180, 0, 0)
    completedCheck:SetScript("OnClick", function(self)
        WFDQHDB.hideCompleted = self:GetChecked() and true or false
        Refresh()
    end)

    statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOMLEFT", 14, 12); statusText:SetPoint("BOTTOMRIGHT", -14, 12); statusText:SetJustifyH("LEFT")
    TrackQuestWidget(statusText)

    local scroll = CreateFrame("ScrollFrame", "WFDQH_ScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -176); scroll:SetPoint("BOTTOMRIGHT", -34, 38)
    content = CreateFrame("Frame", nil, scroll); content:SetSize(515, 1); scroll:SetScrollChild(content)
    TrackQuestWidget(scroll)

    lootPanel = CreateFrame("Frame", nil, frame)
    lootPanel:SetPoint("TOPLEFT", 12, -56); lootPanel:SetPoint("BOTTOMRIGHT", -28, 36)
    lootDropdown = CreateFrame("Frame", "WFDQH_LootDungeonDropdown", lootPanel, "UIDropDownMenuTemplate")
    lootDropdown:SetPoint("TOPLEFT", -12, 4)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(lootDropdown, 190) end
    UIDropDownMenu_Initialize(lootDropdown, function(_, level)
        for _, dungeon in ipairs(lootDungeonList or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = dungeon.name
            info.value = dungeon.name
            info.func = function()
                WFDQHDB.lootDungeon = dungeon.name
                WFDQHDB.lootBoss = "All"
                UIDropDownMenu_SetSelectedValue(lootDropdown, dungeon.name)
                UIDropDownMenu_SetText(lootDropdown, dungeon.name)
                RefreshLoot()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    bossDropdown = CreateFrame("Frame", "WFDQH_LootBossDropdown", lootPanel, "UIDropDownMenuTemplate")
    bossDropdown:SetPoint("LEFT", lootDropdown, "RIGHT", -18, 0)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(bossDropdown, 190) end
    local lootScroll = CreateFrame("ScrollFrame", "WFDQH_LootScrollFrame", lootPanel, "UIPanelScrollFrameTemplate")
    lootScroll:SetPoint("TOPLEFT", 8, -34); lootScroll:SetPoint("BOTTOMRIGHT", -22, 25)
    lootContent = CreateFrame("Frame", nil, lootScroll); lootContent:SetSize(500, 1); lootScroll:SetScrollChild(lootContent)
    lootStatus = lootPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lootStatus:SetPoint("BOTTOMLEFT", 6, 5); lootStatus:SetPoint("BOTTOMRIGHT", -6, 5); lootStatus:SetJustifyH("LEFT")
    lootPanel:Hide()
    raidPanel = CreateFrame("Frame", nil, frame)
    raidPanel:SetPoint("TOPLEFT", 12, -56); raidPanel:SetPoint("BOTTOMRIGHT", -28, 36)
    raidDropdown = CreateFrame("Frame", "WFDQH_RaidDropdown", raidPanel, "UIDropDownMenuTemplate")
    raidDropdown:SetPoint("TOPLEFT", -12, 4)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(raidDropdown, 190) end
    UIDropDownMenu_Initialize(raidDropdown, function(_, level)
        for _, raid in ipairs(raidList or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = raid.name
            info.value = raid.name
            info.func = function()
                WFDQHDB.raidInstance = raid.name
                WFDQHDB.raidBoss = "All"
                UIDropDownMenu_SetSelectedValue(raidDropdown, raid.name)
                UIDropDownMenu_SetText(raidDropdown, raid.name)
                RefreshRaid()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    raidBossDropdown = CreateFrame("Frame", "WFDQH_RaidBossDropdown", raidPanel, "UIDropDownMenuTemplate")
    raidBossDropdown:SetPoint("LEFT", raidDropdown, "RIGHT", -18, 0)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(raidBossDropdown, 190) end
    local raidScroll = CreateFrame("ScrollFrame", "WFDQH_RaidScrollFrame", raidPanel, "UIPanelScrollFrameTemplate")
    raidScroll:SetPoint("TOPLEFT", 8, -34); raidScroll:SetPoint("BOTTOMRIGHT", -22, 25)
    raidContent = CreateFrame("Frame", nil, raidScroll); raidContent:SetSize(500, 1); raidScroll:SetScrollChild(raidContent)
    raidStatus = raidPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raidStatus:SetPoint("BOTTOMLEFT", 6, 5); raidStatus:SetPoint("BOTTOMRIGHT", -6, 5); raidStatus:SetJustifyH("LEFT")
    raidPanel:Hide()
    tierPanel = CreateFrame("Frame", nil, frame)
    tierPanel:SetPoint("TOPLEFT", 12, -56); tierPanel:SetPoint("BOTTOMRIGHT", -28, 36)
    tierClassDropdown = CreateFrame("Frame", "WFDQH_TierClassDropdown", tierPanel, "UIDropDownMenuTemplate")
    tierClassDropdown:SetPoint("TOPLEFT", -12, 4)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(tierClassDropdown, 160) end
    tierSpecDropdown = CreateFrame("Frame", "WFDQH_TierSpecDropdown", tierPanel, "UIDropDownMenuTemplate")
    tierSpecDropdown:SetPoint("LEFT", tierClassDropdown, "RIGHT", -18, 0)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(tierSpecDropdown, 190) end
    local tierScroll = CreateFrame("ScrollFrame", "WFDQH_TierScrollFrame", tierPanel, "UIPanelScrollFrameTemplate")
    tierScroll:SetPoint("TOPLEFT", 8, -34); tierScroll:SetPoint("BOTTOMRIGHT", -22, 25)
    tierContent = CreateFrame("Frame", nil, tierScroll); tierContent:SetSize(500, 1); tierScroll:SetScrollChild(tierContent)
    tierStatus = tierPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tierStatus:SetPoint("BOTTOMLEFT", 6, 5); tierStatus:SetPoint("BOTTOMRIGHT", -6, 5); tierStatus:SetJustifyH("LEFT")
    tierPanel:Hide()
    gearPanel = CreateFrame("Frame", nil, frame)
    gearPanel:SetPoint("TOPLEFT", 12, -56); gearPanel:SetPoint("BOTTOMRIGHT", -28, 36)
    gearClassDropdown = CreateFrame("Frame", "WFDQH_GearClassDropdown", gearPanel, "UIDropDownMenuTemplate")
    gearClassDropdown:SetPoint("TOPLEFT", -12, 4)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(gearClassDropdown, 155) end
    gearSpecDropdown = CreateFrame("Frame", "WFDQH_GearSpecDropdown", gearPanel, "UIDropDownMenuTemplate")
    gearSpecDropdown:SetPoint("LEFT", gearClassDropdown, "RIGHT", -18, 0)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(gearSpecDropdown, 175) end
    gearModeDropdown = CreateFrame("Frame", "WFDQH_GearModeDropdown", gearPanel, "UIDropDownMenuTemplate")
    gearModeDropdown:SetPoint("LEFT", gearSpecDropdown, "RIGHT", -18, 0)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(gearModeDropdown, 110) end
    local gearScroll = CreateFrame("ScrollFrame", "WFDQH_GearScrollFrame", gearPanel, "UIPanelScrollFrameTemplate")
    gearScroll:SetPoint("TOPLEFT", 8, -34); gearScroll:SetPoint("BOTTOMRIGHT", -22, 25)
    gearContent = CreateFrame("Frame", nil, gearScroll); gearContent:SetSize(500, 1); gearScroll:SetScrollChild(gearContent)
    gearStatus = gearPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gearStatus:SetPoint("BOTTOMLEFT", 6, 5); gearStatus:SetPoint("BOTTOMRIGHT", -6, 5); gearStatus:SetJustifyH("LEFT")
    gearPanel:Hide()
    frame:SetScript("OnShow", function()
        if WFDQHDB.activeTab == "loot" then RefreshLoot()
        elseif WFDQHDB.activeTab == "raids" then RefreshRaid()
        elseif WFDQHDB.activeTab == "tiersets" then RefreshTierSets()
        elseif WFDQHDB.activeTab == "gear" then RefreshGearLists()
        else Refresh() end
    end)
    SetActiveTab(WFDQHDB.activeTab)
    if WorldMapFrame then WorldMapFrame:HookScript('OnShow', UpdateMapPin); WorldMapFrame:HookScript('OnHide', RemoveMapPin) end
end


-- Minimap launcher button: quest-style exclamation mark, enlarged and draggable around the minimap edge.
local function CreateMinimapButton()
    if WFDQH_MinimapButton or not Minimap then return end
    local b = CreateFrame("Button", "WFDQH_MinimapButton", Minimap)
    b:SetWidth(30); b:SetHeight(30)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 10)
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetClampedToScreen(true)

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    icon:SetWidth(24); icon:SetHeight(24)
    icon:SetPoint("CENTER", b, "CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.icon = icon
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local function PlaceAtAngle(angle)
        angle = tonumber(angle) or 225
        WFDQHDB = WFDQHDB or {}
        WFDQHDB.minimapAngle = angle
        local radius = math.max(Minimap:GetWidth(), Minimap:GetHeight()) * 0.5 + 2
        local rad = math.rad(angle)
        b:ClearAllPoints()
        b:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius)
    end
    b.PlaceAtAngle = PlaceAtAngle
    PlaceAtAngle((WFDQHDB and WFDQHDB.minimapAngle) or 225)

    b:SetScript("OnDragStart", function(self)
        self.isDragging = true
    end)
    b:SetScript("OnDragStop", function(self)
        self.isDragging = false
        local scale = UIParent:GetEffectiveScale() or 1
        local cx, cy = Minimap:GetCenter()
        local mx, my = GetCursorPosition()
        mx, my = mx / scale, my / scale
        local angle = math.deg(math.atan2(my - cy, mx - cx))
        PlaceAtAngle(angle)
    end)
    b:SetScript("OnClick", function(self, button)
        if self.isDragging then return end
        if not frame then CreateWindow() end
        if frame:IsShown() then frame:Hide() else frame:Show(); Refresh() end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Dungeon Quest Helper")
        GameTooltip:AddLine("Klicken: Questhelfer öffnen/schließen", 1, 1, 1)
        GameTooltip:AddLine("Ziehen: Symbol am Minimaprand verschieben", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Show()
end

SLASH_WFDQH1 = "/dqhelp"
SLASH_WFDQH2 = "/wfdqh"
SlashCmdList.WFDQH = function(msg)
    msg = (msg or ""):lower()
    if not frame then CreateWindow() end
    if msg == "refresh" then Refresh()
    elseif msg == "hidehigh" then WFDQHDB.hideTooHigh = not WFDQHDB.hideTooHigh; Refresh()
    elseif msg == "clear" then
        ClearNativeWaypoint(); activeWaypoint = nil; RemoveMapPin(); if arrowFrame then arrowFrame:Hide() end
        print("|cff33ff99WFDQH:|r Wegpunkt entfernt.")
    elseif msg == "dbversion" then
        print("|cff33ff99WFDQH Datenbank:|r Version " .. tostring(WFDQH_DATABASE_VERSION or "unbekannt") .. " · Quelle: " .. tostring(WFDQH_DATABASE_SOURCE or "unbekannt") .. " · Stand: " .. tostring(WFDQH_DATABASE_UPDATED or "?"))
    else
        if frame:IsShown() then frame:Hide() else frame:Show(); Refresh() end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("QUEST_LOG_UPDATE"); events:RegisterEvent("QUEST_TURNED_IN"); events:RegisterEvent("QUEST_COMPLETE"); events:RegisterEvent("PLAYER_LEVEL_UP"); events:RegisterEvent("ZONE_CHANGED"); events:RegisterEvent("ZONE_CHANGED_NEW_AREA"); events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event)
    completedCache = nil
    if event == "PLAYER_LOGIN" then
        print("|cff33ff99WFDQH geladen.|r Öffnen mit |cffffff00/dqhelp|r. Datenbank: " .. tostring(WFDQH_DATABASE_VERSION or "unbekannt") .. " (" .. tostring(WFDQH_DATABASE_UPDATED or "?") .. ").")
        if WFDQH_UpdateRequested then print("|cffffcc00WFDQH:|r Update-Anforderung gespeichert. Begleitprogramm sollte sie nach /reload erkennen.") end
    end
    if frame and frame:IsShown() then
        if WFDQHDB.activeTab == "loot" then RefreshLoot()
        elseif WFDQHDB.activeTab == "raids" then RefreshRaid()
        elseif WFDQHDB.activeTab == "tiersets" then RefreshTierSets()
        elseif WFDQHDB.activeTab == "gear" then RefreshGearLists()
        else Refresh() end
    end
    if activeWaypoint then UpdateWaypointArrow(); UpdateMapPin() end
end)

-- Item data (including the original icon and item link) may be filled by the
-- client asynchronously. Refresh an open list once the item cache updates.
local itemInfoEvents = CreateFrame("Frame")
local itemInfoEventRegistered = pcall(itemInfoEvents.RegisterEvent, itemInfoEvents, "GET_ITEM_INFO_RECEIVED")
if C_Item and C_Item.RequestLoadItemDataByID then
    local ok = pcall(itemInfoEvents.RegisterEvent, itemInfoEvents, "ITEM_DATA_LOAD_RESULT")
    itemInfoEventRegistered = itemInfoEventRegistered or ok
end
if itemInfoEventRegistered then
    itemInfoEvents:SetScript("OnEvent", function()
        if frame and frame:IsShown() then
            if WFDQHDB.activeTab == "loot" then RefreshLoot()
            elseif WFDQHDB.activeTab == "raids" then RefreshRaid()
            elseif WFDQHDB.activeTab == "tiersets" then RefreshTierSets()
            elseif WFDQHDB.activeTab == "gear" then RefreshGearLists()
            else Refresh() end
        end
    end)
end

local waypointUpdater = CreateFrame('Frame')
local elapsedSinceUpdate = 0
waypointUpdater:SetScript('OnUpdate', function(_, elapsed)
    if not activeWaypoint then return end
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate >= 0.5 then elapsedSinceUpdate = 0; UpdateWaypointArrow(); if WorldMapFrame and WorldMapFrame:IsShown() then UpdateMapPin() end end
end)


local WFDQH_MinimapInit = CreateFrame("Frame")
WFDQH_MinimapInit:RegisterEvent("PLAYER_LOGIN")
WFDQH_MinimapInit:SetScript("OnEvent", function()
    CreateMinimapButton()
end)



