local ADDON = ...
WFDQHDB = WFDQHDB or { hideTooHigh = false, hideCompleted = true, filter = "All" }
WFDQH_UpdateRequested = WFDQH_UpdateRequested or false
if WFDQHDB.hideCompleted == nil then WFDQHDB.hideCompleted = true end

local frame, content, statusText, filterBox
local ROW_HEIGHT = 100

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
    local rowHeight = ROW_HEIGHT + (expanded and 38 or 0)
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
        local rewardDetails = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rewardDetails:SetPoint("TOPLEFT", pre, "BOTTOMLEFT", 0, -4)
        rewardDetails:SetWidth(480)
        if hasRewards then
            local lines = {}
            if q.xpReward then table.insert(lines, "Erfahrung: " .. tostring(q.xpReward) .. " EP") end
            if q.moneyReward then table.insert(lines, "Geld: " .. tostring(q.moneyReward)) end
            for _, reward in ipairs(rewards) do
                local name = reward.name or reward
                if reward.itemID and GetItemInfo then name = GetItemInfo(reward.itemID) or name end
                table.insert(lines, "Gegenstand: " .. tostring(name))
            end
            if q.rewardChoices then table.insert(lines, 1, "Wähle einen Gegenstand") end
            rewardDetails:SetText("Belohnungen: " .. table.concat(lines, " · "))
        elseif q.rewardDataVerified then
            rewardDetails:SetText("Keine Geld- oder Gegenstandsbelohnung dokumentiert; XP-Angaben fehlen in der Quelle.")
        else
            rewardDetails:SetText("Für diese Quest gibt es noch keine bestätigten Forever-Belohnungsdaten.")
        end
    end
    row:Show()
    return rowHeight
end

local function Refresh()
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
    frame.TitleText:SetText("WoW Forever – Dungeon Quest Helper")

    local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", 16, -34); info:SetPoint("TOPRIGHT", -16, -34); info:SetJustifyH("LEFT")
    info:SetText("Wowhead-basierte Startdatenbank. Suche nach Quest, Dungeon, Questgeber oder Gebiet.")

    local search = CreateFrame("EditBox", "WFDQH_SearchBox", frame, "InputBoxTemplate")
    search:SetSize(240, 24); search:SetPoint("TOPLEFT", 18, -54); search:SetAutoFocus(false)
    search:SetText(WFDQHDB.search or "")
    search:SetScript("OnTextChanged", function(self)
        WFDQHDB.search = self:GetText() or ""
        if frame:IsShown() then Refresh() end
    end)

    local hide = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    hide:SetSize(160, 24); hide:SetPoint("LEFT", search, "RIGHT", 10, 0)
    hide:SetText("Level-Filter umschalten")
    hide:SetScript("OnClick", function()
        WFDQHDB.hideTooHigh = not WFDQHDB.hideTooHigh
        Refresh()
    end)

    local updateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    updateButton:SetSize(126, 24)
    updateButton:SetPoint("TOPRIGHT", -16, -84)
    updateButton:SetText("DB aktualisieren")
    updateButton:SetScript("OnClick", function()
        WFDQH_UpdateRequested = true
        print("|cff33ff99WFDQH:|r Update angefordert. Jetzt |cffffff00/reload|r eingeben. Das Begleitprogramm muss laufen und eine geprüfte HTTPS-Datenquelle konfiguriert haben.")
    end)
    local clearPinButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearPinButton:SetSize(126, 24)
    clearPinButton:SetPoint("TOPRIGHT", -16, -114)
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
    sortLabel:SetPoint("TOPLEFT", 18, -84)
    sortLabel:SetText("Sortieren nach:")
    local function MakeSortCheck(label, key, x)
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", x, -98)
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
    completedCheck:SetPoint("TOPLEFT", 18, -119)
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

    local scroll = CreateFrame("ScrollFrame", "WFDQH_ScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -158); scroll:SetPoint("BOTTOMRIGHT", -34, 38)
    content = CreateFrame("Frame", nil, scroll); content:SetSize(515, 1); scroll:SetScrollChild(content)
    frame:SetScript("OnShow", Refresh)
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
    if frame and frame:IsShown() then Refresh() end
    if activeWaypoint then UpdateWaypointArrow(); UpdateMapPin() end
end)

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



