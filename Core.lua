local addonName, addon = ...
local secret, bool = addon.IsSecret, addon.ReadBoolean
local defaults = { enabled = true, debug = false, fontSize = 16, offsetX = 0, offsetY = 0 }
local ranges = { fontSize = { 8, 48 }, offsetX = { -150, 150 }, offsetY = { -100, 100 } }
local units, dirty, competitors = {}, {}, {}
local states = setmetatable({}, { __mode = "k" })
local events = CreateFrame("Frame")
local timer, inCombat, tank, ready
local Mark, MarkAll, Track
local levelKeys = { "LevelFrame", "levelFrame", "level", "PlayerLevelDiffFrame" }
local solo = false
local diagnostics, diagnosticOrder = {}, {}
local threatEvents, refreshes = 0, 0
addon.version = "1.0.1"

-- Bounded, local diagnostics. Store only our own reason codes and public tokens;
-- never stringify, compare or log a secret value or an API error payload.
local function Record(unit, reason, detail, reset)
    if not ready or not addon.db.debug then return end
    if not diagnostics[unit] then
        if #diagnosticOrder >= 40 then
            diagnostics[table.remove(diagnosticOrder, 1)] = nil
        end
        diagnosticOrder[#diagnosticOrder + 1] = unit
        diagnostics[unit] = {}
    end
    local record = diagnostics[unit]
    if reset then record.lastReason, record.lastDetail = nil, nil end
    record.reason, record.detail = reason, detail
    -- A death/filter event should not erase the reason that mattered in combat.
    if reason ~= "FILTERED" and reason ~= "WAITING" and reason ~= "FRAME" then
        record.lastReason, record.lastDetail = reason, detail
    end
end

local function Accessible(object)
    if secret(object) or not object then return false end
    if type(object) ~= "table" and type(object) ~= "userdata" then return false end
    return not object.IsForbidden or bool(object.IsForbidden, object) == false
end

local function PlateToken(unit)
    return not secret(unit) and type(unit) == "string" and unit:match("^nameplate%d+$") ~= nil
end

local function Clear(state)
    if state.text then
        state.text:Hide()
        state.text:SetText("")
    end
    state.value, state.green = nil, nil
end

local function Stop()
    if timer then timer:Cancel(); timer = nil end
    wipe(dirty)
    for _, state in pairs(units) do Clear(state) end
end

local function Active()
    return ready and inCombat and addon.db.enabled
end

local function RebuildRoster()
    wipe(competitors)
    competitors[#competitors + 1] = "pet"
    local raid = IsInRaid()
    local count = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
    solo = not raid and count == 0
    for i = 1, count do
        local unit = (raid and "raid" or "party") .. i
        competitors[#competitors + 1] = unit
        -- The player's raid pet is already represented by "pet".
        if bool(UnitIsUnit, unit, "player") ~= true then
            competitors[#competitors + 1] = (raid and "raidpet" or "partypet") .. i
        end
    end
end

local function UpdateRole()
    local role = addon.charDB.role
    if role == "auto" then
        local ok, assigned = pcall(UnitGroupRolesAssigned, "player")
        tank = ok and not secret(assigned) and assigned == "TANK" or false
    else
        tank = role == "tank"
    end
end

local function Position(state)
    local frame, text = state.frame, state.text
    local bar = frame.healthBar
    if not Accessible(bar) then return false end
    local shown = bool(bar.IsShown, bar)
    if shown ~= true then return false end
    -- Prefer exact readable geometry, but do not require it for rendering.
    -- Anchoring directly to a region does not need arithmetic on its coordinates.
    local ok, right = pcall(bar.GetRight, bar)
    local readable = ok and addon.IsNumber(right)
    local furthest = readable and right or 0
    local anchor = frame
    local levelAnchor
    local function Include(region)
        if Accessible(region) and bool(region.IsShown, region) == true then
            local edgeOK, edge = pcall(region.GetRight, region)
            if not edgeOK or not addon.IsNumber(edge) then readable = false
            elseif readable then furthest = math.max(furthest, edge) end
        end
    end
    for _, key in ipairs(levelKeys) do
        local region = frame[key]
        if Accessible(region) and bool(region.IsShown, region) == true then
            levelAnchor = region
            break
        end
    end
    Include(frame); Include(frame.LevelFrame); Include(frame.levelFrame)
    Include(frame.level); Include(frame.ClassificationFrame); Include(frame.PlayerLevelDiffFrame)
    local offset = 8 + addon.db.offsetX
    state.anchorFallback = not readable
    if readable then anchor, offset = bar, offset + furthest - right
    else anchor = levelAnchor or frame end
    text:ClearAllPoints()
    text:SetPoint("LEFT", anchor, "RIGHT", offset, addon.db.offsetY)
    text:SetFont(STANDARD_TEXT_FONT, addon.db.fontSize, "OUTLINE")
    return true
end

local function Refresh(state)
    if addon.db.debug then refreshes = refreshes + 1 end
    local unit = state.unit
    local currentPlate = unit and C_NamePlate.GetNamePlateForUnit(unit)
    if not Active() or not unit or not Accessible(state.frame)
        or not Accessible(state.plate) or bool(state.frame.IsShown, state.frame) ~= true
        or not Accessible(currentPlate) or currentPlate ~= state.plate
        or secret(state.frame.unit) or state.frame.unit ~= unit then
        Clear(state)
        if unit then Record(unit, "FRAME") end
        return
    end
    local delta, reason, detail = addon.CalculateDelta(unit, competitors, addon.db.debug and solo)
    local value, green = addon.FormatDelta(delta, tank)
    if not value then Clear(state); Record(unit, reason, detail); return end
    if reason == "SOLO" then value = value .. "*" end
    if not state.text then
        state.text = state.frame:CreateFontString(nil, "OVERLAY")
        state.text:SetJustifyH("LEFT")
        state.text:Hide()
    end
    if not Position(state) then Clear(state); Record(unit, "POSITION"); return end
    Record(unit, reason, state.anchorFallback and "ANCHOR_FALLBACK" or nil)
    if value ~= state.value then state.text:SetText(value); state.value = value end
    if green ~= state.green then
        state.text:SetTextColor(green and 0 or 1, green and 1 or 0, 0)
        state.green = green
    end
    state.text:Show()
end

local function Flush()
    timer = nil
    if not Active() then Stop(); return end
    for unit in pairs(dirty) do
        dirty[unit] = nil
        local state = units[unit]
        if state then Refresh(state) end
    end
end

Mark = function(unit)
    if not Active() or not units[unit] then return end
    dirty[unit] = true
    if not timer then timer = C_Timer.NewTimer(0.2, Flush) end
end

MarkAll = function()
    if not Active() then return end
    for unit in pairs(units) do Mark(unit) end
end

local function Detach(state)
    Clear(state)
    local unit = state.unit
    if unit and units[unit] == state then units[unit], dirty[unit] = nil, nil end
    state.unit = nil
end

Track = function(unit)
    if not PlateToken(unit) then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not Accessible(plate) or not Accessible(plate.UnitFrame) then Record(unit, "FRAME"); return end
    local frame = plate.UnitFrame
    if secret(frame.unit) or frame.unit ~= unit then Record(unit, "FRAME", "frame.unit"); return end
    local state = states[frame]
    if not state then
        state = { frame = frame, plate = plate }
        states[frame] = state
        frame:HookScript("OnHide", function() Clear(state) end)
        frame:HookScript("OnShow", function()
            if state.unit then Mark(state.unit) end
        end)
        frame:HookScript("OnSizeChanged", function()
            if state.unit then Mark(state.unit) end
        end)
    end
    local newUnit = state.unit ~= unit
    if newUnit then Detach(state) end
    if units[unit] and units[unit] ~= state then Detach(units[unit]) end
    state.unit, state.plate = unit, plate
    units[unit] = state
    if newUnit or not diagnostics[unit] then Record(unit, "WAITING", nil, newUnit) end
    Mark(unit)
end

local function Discover()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if Accessible(plate) and Accessible(plate.UnitFrame) then Track(plate.UnitFrame.unit) end
    end
end

function addon:SetOption(key, value)
    if key == "role" then
        if value ~= "auto" and value ~= "tank" and value ~= "nontank" then return end
        self.charDB.role = value
        UpdateRole()
    elseif key == "enabled" or key == "debug" then
        if type(value) ~= "boolean" then return end
        self.db[key] = value
        if key == "debug" then
            wipe(diagnostics); wipe(diagnosticOrder)
            threatEvents, refreshes = 0, 0
            self:Message(self.L[value and "DEBUG_ON" or "DEBUG_OFF"])
            if value then Discover() end
        end
    elseif ranges[key] then
        if not self.IsNumber(value) then return end
        self.db[key] = math.max(ranges[key][1], math.min(ranges[key][2], math.floor(value + 0.5)))
    else
        return
    end
    if not Active() then Stop() else MarkAll() end
end

function addon:Message(message)
    print("|cff70d5ffPlateThreatNumber|r: " .. message)
end

function addon:PrintStatus()
    -- Report recorded results; never initiate threat reads from a chat command.
    local visible, tracked = 0, 0
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _ in pairs(C_NamePlate.GetNamePlates()) do visible = visible + 1 end
    end
    for _ in pairs(units) do tracked = tracked + 1 end
    self:Message(string.format(self.L.DEBUG_STATUS, self.version, tostring(self.db.enabled),
        tostring(inCombat), tostring(self.db.debug), visible, tracked, threatEvents, refreshes))
    if not self.db.debug then self:Message(self.L.DEBUG_HELP); return end
    if #diagnosticOrder == 0 then self:Message(self.L.D_WAITING); return end
    for _, unit in ipairs(diagnosticOrder) do
        local record = diagnostics[unit]
        local line = unit .. ": " .. self.L["D_" .. record.reason]
            .. (record.detail and " [" .. record.detail .. "]" or "")
        if record.lastReason and record.lastReason ~= record.reason then
            line = line .. " | " .. self.L.DEBUG_LAST .. ": " .. self.L["D_" .. record.lastReason]
                .. (record.lastDetail and " [" .. record.lastDetail .. "]" or "")
        end
        self:Message(line)
    end
end

local function Initialize()
    if type(PlateThreatNumberDB) ~= "table" then PlateThreatNumberDB = {} end
    if type(PlateThreatNumberCharDB) ~= "table" then PlateThreatNumberCharDB = {} end
    addon.db, addon.charDB = PlateThreatNumberDB, PlateThreatNumberCharDB
    for key, value in pairs(defaults) do
        if type(addon.db[key]) ~= type(value) then addon.db[key] = value end
        if ranges[key] then
            if not addon.IsNumber(addon.db[key]) then addon.db[key] = value end
            addon.db[key] = math.max(ranges[key][1], math.min(ranges[key][2], math.floor(addon.db[key] + 0.5)))
        end
    end
    local role = addon.charDB.role
    if role ~= "auto" and role ~= "tank" and role ~= "nontank" then addon.charDB.role = "auto" end
    ready = true
    inCombat = bool(UnitAffectingCombat, "player") == true
    RebuildRoster()
    UpdateRole()
    -- Post-hook only: never replace Blizzard functions or write into their frames.
    if type(CompactUnitFrame_SetUnit) == "function" then
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame, unit)
            if not Accessible(frame) then return end
            local state = states[frame]
            if state then Detach(state) end
            if PlateToken(unit) then Track(unit) end
        end)
    end
    Discover()
    addon:CreateOptions()
end

local function ChangedUnit(unit)
    if secret(unit) or type(unit) ~= "string" then return end
    if units[unit] then Mark(unit); return end
    -- Threat events can name target/focus instead of the nameplate token.
    if unit == "target" or unit == "focus" or unit:match("^boss%d+$") then
        for plateUnit in pairs(units) do
            if bool(UnitIsUnit, unit, plateUnit) == true then Mark(plateUnit) end
        end
    elseif unit == "player" or unit == "pet" or unit:match("^party") or unit:match("^raid") then
        -- A member-level event does not identify the enemy; invalidate visible plates.
        MarkAll()
    end
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "ADDON_LOADED" then
        if unit == addonName then Initialize(); events:UnregisterEvent(event) end
        return
    end
    if not ready then return end
    if addon.db.debug and (event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE") then
        threatEvents = threatEvents + 1
    end
    if event == "NAME_PLATE_UNIT_ADDED" then Track(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if not secret(unit) and units[unit] then Detach(units[unit]) end
    elseif event == "PLAYER_REGEN_ENABLED" then inCombat = false; Stop()
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true; UpdateRole(); Discover(); MarkAll()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Stop()
        for _, state in pairs(states) do Detach(state) end
        inCombat = bool(UnitAffectingCombat, "player") == true
        RebuildRoster(); UpdateRole(); Discover()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "UNIT_PET" then
        RebuildRoster(); UpdateRole(); MarkAll()
    elseif event == "PLAYER_ROLES_ASSIGNED" or event == "ROLE_CHANGED_INFORM" then
        UpdateRole(); MarkAll()
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then MarkAll()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if Active() then Discover(); MarkAll() end
    elseif event == "UNIT_HEALTH" then
        -- Health changes are frequent. Only death invalidates threat here.
        if Active() and not secret(unit) and bool(UnitIsDeadOrGhost, unit) == true then ChangedUnit(unit) end
    elseif Active() then
        ChangedUnit(unit)
    end
end)

for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
    "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_THREAT_LIST_UPDATE",
    "UNIT_THREAT_SITUATION_UPDATE", "UNIT_FLAGS", "UNIT_FACTION", "UNIT_HEALTH",
    "UNIT_CONNECTION", "GROUP_ROSTER_UPDATE", "UNIT_PET", "PLAYER_ROLES_ASSIGNED",
    "ROLE_CHANGED_INFORM", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED",
    "PLAYER_TARGET_CHANGED",
}) do events:RegisterEvent(event) end
