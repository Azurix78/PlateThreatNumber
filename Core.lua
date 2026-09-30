local addonName, addon = ...
local secret, bool = addon.IsSecret, addon.ReadBoolean
local defaults = { enabled = true, fontSize = 16, offsetX = 0, offsetY = 0 }
local ranges = { fontSize = { 8, 48 }, offsetX = { -150, 150 }, offsetY = { -100, 100 } }
local units, dirty, competitors = {}, {}, {}
local states = setmetatable({}, { __mode = "k" })
local events = CreateFrame("Frame")
local timer, inCombat, tank, ready
local Mark, MarkAll, Track

local function Accessible(object)
    if secret(object) or not object then return false end
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
    -- Use readable geometry only. The health bar is the vertical reference;
    -- the outermost visible level/classification region is the horizontal one.
    local right = bar:GetRight()
    if not addon.IsNumber(right) then return false end
    local furthest = right
    local function Include(region)
        if Accessible(region) and bool(region.IsShown, region) == true then
            local edge = region:GetRight()
            if not addon.IsNumber(edge) then return false end
            furthest = math.max(furthest, edge)
        end
        return true
    end
    if not Include(frame) or not Include(frame.LevelFrame)
        or not Include(frame.levelFrame) or not Include(frame.level)
        or not Include(frame.ClassificationFrame)
        or not Include(frame.PlayerLevelDiffFrame) then return false end
    text:ClearAllPoints()
    text:SetPoint("LEFT", bar, "RIGHT", furthest - right + 8 + addon.db.offsetX, addon.db.offsetY)
    text:SetFont(STANDARD_TEXT_FONT, addon.db.fontSize, "OUTLINE")
    return true
end

local function Refresh(state)
    local unit = state.unit
    local currentPlate = unit and C_NamePlate.GetNamePlateForUnit(unit)
    if not Active() or not unit or not Accessible(state.frame)
        or not Accessible(state.plate) or bool(state.frame.IsShown, state.frame) ~= true
        or not Accessible(currentPlate) or currentPlate ~= state.plate
        or secret(state.frame.unit) or state.frame.unit ~= unit then
        Clear(state)
        return
    end
    local delta = addon.CalculateDelta(unit, competitors)
    local value, green = addon.FormatDelta(delta, tank)
    if not value then Clear(state); return end
    if not state.text then
        state.text = state.frame:CreateFontString(nil, "OVERLAY")
        state.text:SetJustifyH("LEFT")
        state.text:Hide()
    end
    if not Position(state) then Clear(state); return end
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
    if not Accessible(plate) or not Accessible(plate.UnitFrame) then return end
    local frame = plate.UnitFrame
    if secret(frame.unit) or frame.unit ~= unit then return end
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
    if state.unit ~= unit then Detach(state) end
    if units[unit] and units[unit] ~= state then Detach(units[unit]) end
    state.unit, state.plate = unit, plate
    units[unit] = state
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
    elseif key == "enabled" then
        if type(value) ~= "boolean" then return end
        self.db.enabled = value
    elseif ranges[key] then
        if not self.IsNumber(value) then return end
        self.db[key] = math.max(ranges[key][1], math.min(ranges[key][2], math.floor(value + 0.5)))
    else
        return
    end
    if not Active() then Stop() else MarkAll() end
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
            if state then
                Detach(state)
                if PlateToken(unit) then Track(unit) end
            end
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
}) do events:RegisterEvent(event) end
