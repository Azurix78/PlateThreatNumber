local passed = 0
local output = {}
local consolePrint = print
function print(message, ...)
    if type(message) == "string" and message:find("|cff70d5ffPlateThreatNumber|r:", 1, true) then
        output[#output + 1] = message
    else consolePrint(message, ...) end
end
local function reportContains(text)
    for _, line in ipairs(output) do if line:find(text, 1, true) then return true end end
    return false
end
local function eq(actual, expected, message)
    assert(actual == expected, (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function test(name, fn)
    fn()
    passed = passed + 1
    print("PASS " .. name)
end
local secretValue = setmetatable({}, { __tostring = function() return "<secret>" end })
function issecretvalue(v) return rawequal(v, secretValue) end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
local frames, timers, hooks, plates, data, threat, calls
local groupSize, raid, role, locale, addon, clock
local methods = {}
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:HookScript(event, fn)
    local prev = self.scripts[event]
    self.scripts[event] = function(...)
        if prev then prev(...) end
        fn(...)
    end
end
function methods:Show()
    local changed = not self.shown
    self.shown = true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    local changed = self.shown
    self.shown = false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:IsForbidden() return self.forbidden or false end
function methods:SetText(text) self.text = text end
function methods:SetTextColor(...) self.color = { ... } end
function methods:SetFont(...) self.font = { ... } end
function methods:SetJustifyH() end
function methods:ClearAllPoints() self.point = nil end
function methods:SetPoint(...) self.point = { ... } end
function methods:GetRight() return self.right or 100 end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width or 520 end
function methods:GetStringHeight() return math.ceil(#(self.text or "") / 60) * 16 end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetScrollChild(child) self.child = child end
function methods:SetMinMaxValues() end
function methods:SetValueStep() end
function methods:SetObeyStepOnDrag() end
function methods:SetChecked(v) self.checked = v end
function methods:GetChecked() return self.checked end
function methods:SetValue(v)
    self.value = v
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
end
function methods:CreateFontString()
    local font = CreateFrame("FontString", nil, self)
    self.fontStrings[#self.fontStrings + 1] = font
    return font
end
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, shown = true,
        scripts = {}, events = {}, fontStrings = {} }, { __index = methods })
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    if template == "UICheckButtonTemplate" then frame.Text = frame:CreateFontString() end
    if template == "OptionsSliderTemplate" then
        for _, suffix in ipairs({ "Low", "High", "Text" }) do _G[name .. suffix] = frame:CreateFontString() end
    end
    return frame
end
function hooksecurefunc(name, fn) hooks[name] = fn end
function CompactUnitFrame_SetUnit(frame, unit)
    frame.unit = unit
    if hooks.CompactUnitFrame_SetUnit then hooks.CompactUnitFrame_SetUnit(frame, unit) end
end
STANDARD_TEXT_FONT = "native-font"
function GetLocale() return locale end
function IsInRaid() return raid end
function GetNumGroupMembers() return groupSize end
function GetNumSubgroupMembers() return groupSize end
function UnitGroupRolesAssigned() return role end
local function property(unit, key, default)
    local entry = data[unit]
    if entry and entry[key] ~= nil then return entry[key] end
    return default
end
function UnitExists(unit) return property(unit, "exists", data[unit] ~= nil) end
function UnitIsPlayer(unit) return property(unit, "player", false) end
function UnitCanAttack(_, unit) return property(unit, "attackable", true) end
function UnitIsDeadOrGhost(unit) return property(unit, "dead", false) end
function UnitAffectingCombat(unit) return property(unit, "combat", false) end
function UnitIsConnected(unit) return property(unit, "connected", true) end
function UnitIsUnit(a, b)
    if property(a, "secretIdentity", false) then return secretValue end
    return a == b or (property(a, "id", a) == property(b, "id", b))
end
function UnitDetailedThreatSituation(unit, enemy)
    calls[#calls + 1] = { unit, enemy }
    local v = threat[enemy] and threat[enemy][unit]
    if v == "error" then error("unavailable") end
    if v == nil then return end
    if type(v) == "table" and not issecretvalue(v) then return false, v.status, 0, 0, v.value end
    return false, 0, 0, 0, v
end
C_Timer = {}
function C_Timer.NewTimer(delay, fn)
    local timer = { due = clock + delay, fn = fn }
    function timer:Cancel() self.cancelled = true end
    timers[#timers + 1] = timer
    return timer
end
C_NamePlate = {}
function C_NamePlate.GetNamePlateForUnit(unit) return plates[unit] end
function C_NamePlate.GetNamePlates()
    local result = {}
    for _, p in pairs(plates) do result[#result + 1] = p end
    return result
end
Settings = {}
function Settings.RegisterCanvasLayoutCategory(panel)
    Settings.panel = panel
    return { GetID = function() return 7 end }
end
function Settings.RegisterAddOnCategory() end
function Settings.OpenToCategory(id) Settings.opened = id end
local function event(name, unit)
    for _, frame in ipairs(frames) do
        if frame.events[name] then frame.scripts.OnEvent(frame, name, unit) end
    end
end
local function advance(seconds)
    clock = clock + seconds
    for _, t in ipairs(timers) do
        if not t.cancelled and not t.done and t.due <= clock then
            t.done = true; t.fn()
        end
    end
end
local function pending()
    local n = 0
    for _, t in ipairs(timers) do if not t.cancelled and not t.done then n = n + 1 end end
    return n
end
local function newPlate(unit)
    local p = CreateFrame("Frame")
    p.UnitFrame = CreateFrame("Frame", nil, p)
    p.UnitFrame.unit = unit
    p.UnitFrame.healthBar = CreateFrame("StatusBar", nil, p.UnitFrame)
    p.UnitFrame.LevelFrame = CreateFrame("Frame", nil, p.UnitFrame)
    p.UnitFrame.LevelFrame.right = 130
    plates[unit] = p
    data[unit] = { combat = true }
    event("NAME_PLATE_UNIT_ADDED", unit)
    return p.UnitFrame
end
local function textOf(frame) return frame.fontStrings[1] end
local function hidden(frame)
    local t = textOf(frame)
    assert(not t or not t.shown)
    if t then eq(t.text, "") end
end
local function reset(saved, charSaved)
    output = {}
    frames, timers, hooks, plates, data, threat, calls = {}, {}, {}, {}, {}, {}, {}
    groupSize, raid, role, locale, clock = 1, false, "NONE", "frFR", 0
    data.player, data.party1 = { id = "self", player = true }, { player = true }
    PlateThreatNumberDB, PlateThreatNumberCharDB = saved, charSaved
    SlashCmdList = {}
    addon = {}
    for _, file in ipairs({ "Locales.lua", "Threat.lua", "Core.lua", "Options.lua" }) do
        assert(loadfile(file))("PlateThreatNumber", addon)
    end
    event("ADDON_LOADED", "PlateThreatNumber")
end
local function combat()
    data.player.combat = true
    event("PLAYER_REGEN_DISABLED")
end
local function fixture()
    reset()
    local f = newPlate("nameplate1")
    threat.nameplate1 = { player = 1116, party1 = 1000 }
    combat(); advance(0.2)
    return f
end

test("first, second, last, maximum rival and player's pet", function()
    fixture()
    eq(addon.CalculateDelta("nameplate1", { "party1" }), 116)
    threat.nameplate1.player = 900
    eq(addon.CalculateDelta("nameplate1", { "party1" }), -100)
    data.party2, data.pet = {}, {}
    threat.nameplate1.party2, threat.nameplate1.pet = 1200, 1400
    eq(addon.CalculateDelta("nameplate1", { "party1", "party2", "pet" }), -500)
end)
test("rounding, signs, zero and role colors", function()
    reset()
    for _, row in ipairs({ {116,"+116",true}, {-245,"-245",false}, {0,"0",false},
        {0.49,"0",false}, {-0.49,"0",false}, {0.5,"+1",true}, {-0.5,"-1",false} }) do
        local t, green = addon.FormatDelta(row[1], true)
        eq(t, row[2]); eq(green, row[3])
        local _, inverse = addon.FormatDelta(row[1], false)
        eq(inverse, not row[3])
    end
end)
test("no competitor, zero threat and tied threat", function()
    local f = fixture()
    threat.nameplate1.party1 = nil
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2); hidden(f)
    threat.nameplate1.party1 = 0
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2); hidden(f)
    threat.nameplate1.party1 = 1116
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    eq(textOf(f).text, "0"); eq(textOf(f).color[2], 1)
end)
test("never reads threat outside combat, and exit cancels pending work", function()
    reset(); newPlate("nameplate1")
    for i = 1, 50 do event("UNIT_THREAT_LIST_UPDATE", "nameplate1") end
    advance(2); eq(#calls, 0); eq(pending(), 0)
    threat.nameplate1 = { player = 1116, party1 = 1000 }
    combat(); eq(pending(), 1)
    data.player.combat = false; event("PLAYER_REGEN_ENABLED")
    eq(pending(), 0); advance(2); eq(#calls, 0)
end)
test("coalesces events and only updates the dirty enemy", function()
    local f = fixture()
    newPlate("nameplate2"); threat.nameplate2 = { player = 100, party1 = 500 }
    advance(0.2); calls = {}
    for i = 1, 100 do event("UNIT_THREAT_LIST_UPDATE", "nameplate1") end
    eq(pending(), 1); advance(0.19); eq(#calls, 0)
    advance(0.02); eq(#calls, 2); eq(pending(), 0)
    for _, call in ipairs(calls) do eq(call[2], "nameplate1") end
    eq(textOf(f).text, "+116")
end)
test("rejects unrelated enemies before querying competitors", function()
    fixture(); calls = {}; threat.nameplate1.player = nil
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    eq(#calls, 1); eq(calls[1][1], "player")
    for _, field in ipairs({ "combat", "attackable", "exists" }) do
        calls = {}; data.nameplate1[field] = false
        event("UNIT_FLAGS", "nameplate1"); advance(0.2); eq(#calls, 0)
        data.nameplate1[field] = true
    end
    calls = {}; data.nameplate1.player = true
    event("UNIT_FLAGS", "nameplate1"); advance(0.2); eq(#calls, 0)
end)
test("secret, invalid, missing and failing values erase old numbers", function()
    local f = fixture()
    for _, value in ipairs({ secretValue, "error", -1, math.huge, 0/0,
        { status = 0 }, { status = secretValue }, { status = 0, value = "1000" } }) do
        threat.nameplate1.party1 = value
        event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2); hidden(f)
        threat.nameplate1.party1 = 1000
        event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2); eq(textOf(f).text, "+116")
    end
    threat.nameplate1.player = secretValue
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2); hidden(f)
    threat.nameplate1.player = 1116; data.nameplate1.combat = secretValue; calls = {}
    event("UNIT_FLAGS", "nameplate1"); advance(0.2); hidden(f); eq(#calls, 0)
end)

test("readable raw threat works even when aggro status is protected or absent", function()
    local f = fixture()
    threat.nameplate1.player = { status = secretValue, value = 1116 }
    threat.nameplate1.party1 = { status = secretValue, value = 1000 }
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    eq(textOf(f).text, "+116")
    threat.nameplate1.party1 = { value = 1200 }
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    eq(textOf(f).text, "-84")
end)

test("raw threat restrictions are identified precisely for player and competitors", function()
    fixture()
    threat.nameplate1.player = secretValue
    local delta, reason, detail = addon.CalculateDelta("nameplate1", { "party1" })
    eq(delta, nil); eq(reason, "SECRET"); eq(detail, "player/UnitDetailedThreatSituation.rawThreat")
    threat.nameplate1.player = { status = secretValue, value = 1116 }
    threat.nameplate1.party1 = { status = 0, value = secretValue }
    delta, reason, detail = addon.CalculateDelta("nameplate1", { "party1" })
    eq(delta, nil); eq(reason, "SECRET"); eq(detail, "party1/UnitDetailedThreatSituation.rawThreat")
    threat.nameplate1.party1 = { status = secretValue }
    delta, reason = addon.CalculateDelta("nameplate1", { "party1" }, true)
    eq(delta, nil); eq(reason, "INVALID") -- Missing data is not an absent rival.
end)
test("raid player alias is excluded and pets join the roster", function()
    reset(); raid = true; groupSize = 2
    data.raid1, data.raid2, data.raidpet2 = { id = "self" }, {}, {}
    local f = newPlate("nameplate1")
    threat.nameplate1 = { player = 1116, raid1 = 99999, raid2 = 1000, raidpet2 = 1300 }
    event("GROUP_ROSTER_UPDATE"); combat(); advance(0.2)
    eq(textOf(f).text, "-184")
    for _, call in ipairs(calls) do assert(call[1] ~= "raid1") end
    data.raidpet2 = nil; event("UNIT_PET", "raid2"); advance(0.2)
    eq(textOf(f).text, "+116")
    groupSize = 1; event("GROUP_ROSTER_UPDATE"); advance(0.2); hidden(f)
end)
test("pet-only solo combat works, pet removal hides the value", function()
    reset(); groupSize = 0; data.pet = {}
    event("GROUP_ROSTER_UPDATE")
    local f = newPlate("nameplate1")
    threat.nameplate1 = { player = 100, pet = 200 }
    combat(); advance(0.2); eq(textOf(f).text, "-100")
    data.pet = nil; event("UNIT_PET", "player"); advance(0.2); hidden(f)
end)
test("death, disconnection and resurrection update visibility", function()
    local f = fixture()
    data.party1.dead = true; event("UNIT_HEALTH", "party1"); advance(0.2); hidden(f)
    data.party1.dead = false; event("UNIT_FLAGS", "party1"); advance(0.2); eq(textOf(f).text, "+116")
    data.party1.connected = false; event("UNIT_CONNECTION", "party1"); advance(0.2); hidden(f)
    data.party1.connected = true; event("UNIT_CONNECTION", "party1"); advance(0.2)
    data.nameplate1.dead = true; calls = {}
    event("UNIT_HEALTH", "nameplate1"); advance(0.2); hidden(f); eq(#calls, 0)
    data.nameplate1.dead = false; data.player.dead = true
    event("UNIT_HEALTH", "player"); advance(0.2); hidden(f)
end)
test("ordinary health updates do not trigger threat scans", function()
    fixture(); calls = {}
    for i = 1, 100 do event("UNIT_HEALTH", "player"); event("UNIT_HEALTH", "nameplate1") end
    advance(1); eq(#calls, 0); eq(pending(), 0)
end)
test("frame reuse clears immediately and reuses one FontString", function()
    local f = fixture(); local text = textOf(f); local p = plates.nameplate1
    event("NAME_PLATE_UNIT_REMOVED", "nameplate1"); hidden(f)
    plates.nameplate1 = nil; plates.nameplate2 = p; data.nameplate2 = { combat = true }
    threat.nameplate2 = { player = 100, party1 = 200 }
    CompactUnitFrame_SetUnit(f, "nameplate2"); event("NAME_PLATE_UNIT_ADDED", "nameplate2")
    hidden(f); advance(0.2); eq(textOf(f), text); eq(text.text, "-100"); eq(#f.fontStrings, 1)
    CompactUnitFrame_SetUnit(f, nil); hidden(f)
end)
test("show, hide, forbidden frame and restricted positioning fallback", function()
    local f = fixture()
    f:Hide(); hidden(f); f:Show(); advance(0.2); eq(textOf(f).text, "+116")
    f.forbidden = true; event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2); hidden(f)
    f.forbidden = false; f.healthBar.right = secretValue
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    eq(textOf(f).text, "+116"); eq(textOf(f).point[2], f.LevelFrame)
    eq(textOf(f).point[4], 8)
end)
test("target alias updates the corresponding plate", function()
    local f = fixture(); data.target = { id = "nameplate1" }
    threat.nameplate1.player = 1200; calls = {}
    event("UNIT_THREAT_LIST_UPDATE", "target"); advance(0.2)
    eq(textOf(f).text, "+200"); eq(#calls, 2)
end)
test("role fallback, auto changes, override and disabling", function()
    local f = fixture(); eq(textOf(f).color[1], 1)
    role = "TANK"; event("PLAYER_ROLES_ASSIGNED"); advance(0.2); eq(textOf(f).color[2], 1)
    addon:SetOption("role", "nontank"); advance(0.2); eq(textOf(f).color[1], 1)
    role = "HEALER"; event("PLAYER_ROLES_ASSIGNED"); advance(0.2); eq(textOf(f).color[1], 1)
    addon:SetOption("role", "tank"); advance(0.2); eq(textOf(f).color[2], 1)
    addon:SetOption("enabled", false); hidden(f); calls = {}
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(1); eq(#calls, 0)
    addon:SetOption("enabled", true); advance(0.2); eq(textOf(f).text, "+116")
end)
test("layout after level badge, native font and option changes", function()
    local f = fixture(); local t = textOf(f)
    eq(t.point[4], 38); eq(t.point[5], 0); eq(t.font[1], STANDARD_TEXT_FONT); eq(t.font[2], 16)
    addon:SetOption("offsetX", 12); addon:SetOption("offsetY", -3); addon:SetOption("fontSize", 20)
    advance(0.2); eq(t.point[4], 50); eq(t.point[5], -3); eq(t.font[2], 20)
    SlashCmdList.PLATETHREATNUMBER(); eq(Settings.opened, 7)
end)
test("SavedVariables persist, invalid settings are repaired", function()
    reset(); addon:SetOption("role", "tank"); addon:SetOption("fontSize", 22); addon:SetOption("enabled", false)
    local db, char = PlateThreatNumberDB, PlateThreatNumberCharDB
    reset(db, char); eq(addon.charDB.role, "tank"); eq(addon.db.fontSize, 22); eq(addon.db.enabled, false)
    reset({ fontSize = 999, offsetX = 0/0, offsetY = -999, enabled = "yes" }, { role = "invalid" })
    eq(addon.db.fontSize, 48); eq(addon.db.offsetX, 0); eq(addon.db.offsetY, -100)
    eq(addon.db.enabled, true); eq(addon.charDB.role, "auto")
end)
test("world transition clears stale plates and handles reload in combat", function()
    local f = fixture(); plates = {}; event("PLAYER_ENTERING_WORLD"); hidden(f)
    local g = newPlate("nameplate2"); threat.nameplate2 = { player = 1116, party1 = 1000 }
    event("PLAYER_ENTERING_WORLD"); advance(0.2); eq(textOf(g).text, "+116")
end)
test("all locales contain every text, unknown locale falls back to English", function()
    reset()
    for _, code in ipairs({ "enUS", "enGB", "frFR", "deDE", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "unknown" }) do
        locale = code; local localized = {}; assert(loadfile("Locales.lua"))("PlateThreatNumber", localized)
        local count = 0
        for k, v in pairs(localized.L) do assert(type(v) == "string" and #v > 0, code .. ":" .. k); count = count + 1 end
        eq(count, 27)
        local status = string.format(localized.L.DEBUG_STATUS, "1.0.2", "true", "false", "true", 1, 2, 3, 4)
        assert(#status > 0)
        if code == "unknown" then assert(localized.L.DESCRIPTION:find("Shows your threat", 1, true)) end
    end
    -- Reject missing translated entries, even if runtime fallback would hide them.
    local file = assert(io.open("Locales.lua", "r")); local source = file:read("*a"); file:close()
    local instrumented = source .. "\nreturn locales, keys"
    local translations, keys = assert(loadstring(instrumented))("PlateThreatNumber", {})
    for code, values in pairs(translations) do eq(#values, #keys, code .. " key coverage") end
end)

test("solo debug is opt-in and marked; group calculations are unchanged", function()
    reset(); groupSize = 0; event("GROUP_ROSTER_UPDATE")
    local f = newPlate("nameplate1")
    threat.nameplate1 = { player = 116 }
    combat(); advance(0.2); hidden(f)
    SlashCmdList.PLATETHREATNUMBER("debug on"); advance(0.2)
    eq(textOf(f).text, "+116*"); eq(textOf(f).color[1], 1)
    addon:SetOption("role", "tank"); advance(0.2); eq(textOf(f).color[2], 1)
    SlashCmdList.PLATETHREATNUMBER("status"); assert(reportContains(addon.L.D_SOLO))
    groupSize = 1; event("GROUP_ROSTER_UPDATE"); advance(0.2); hidden(f)
    threat.nameplate1.party1 = 100
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    eq(textOf(f).text, "+16")
    groupSize = 0; event("GROUP_ROSTER_UPDATE"); advance(0.2)
    SlashCmdList.PLATETHREATNUMBER("debug off"); advance(0.2); hidden(f)
end)

test("debug preserves combat filters and never reads threat outside combat", function()
    reset(); groupSize = 0; event("GROUP_ROSTER_UPDATE")
    local f = newPlate("nameplate1"); threat.nameplate1 = { player = 116 }
    SlashCmdList.PLATETHREATNUMBER("debug"); advance(1); hidden(f); eq(#calls, 0)
    SlashCmdList.PLATETHREATNUMBER("status"); eq(#calls, 0)
    combat(); advance(0.2); eq(textOf(f).text, "+116*")
    data.nameplate1.combat = false
    event("UNIT_FLAGS", "nameplate1"); advance(0.2); hidden(f)
    SlashCmdList.PLATETHREATNUMBER("status"); assert(reportContains("UnitAffectingCombat"))
    data.player.combat = false; event("PLAYER_REGEN_ENABLED"); calls = {}
    SlashCmdList.PLATETHREATNUMBER("status"); advance(1); eq(#calls, 0); eq(pending(), 0)
end)

test("diagnostics identify missing player threat and no rivals", function()
    local f = fixture(); addon:SetOption("debug", true)
    threat.nameplate1.player = nil
    advance(0.2); hidden(f); SlashCmdList.PLATETHREATNUMBER("status")
    assert(reportContains(addon.L.D_NO_THREAT)); assert(reportContains("player/UnitDetailedThreatSituation"))
    threat.nameplate1.player = 1116; threat.nameplate1.party1 = nil; output = {}
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    SlashCmdList.PLATETHREATNUMBER("status"); assert(reportContains(addon.L.D_NO_RIVAL))
end)

test("diagnostics distinguish protected, invalid and failed API calls", function()
    local f = fixture(); addon:SetOption("debug", true)
    for _, row in ipairs({ { secretValue, "D_SECRET" }, { "error", "D_ERROR" }, { -1, "D_INVALID" } }) do
        threat.nameplate1.party1 = row[1]; output = {}
        event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2); hidden(f)
        eq(#output, 0) -- No automatic chat spam, even when events keep firing.
        SlashCmdList.PLATETHREATNUMBER("status")
        assert(reportContains(addon.L[row[2]])); assert(reportContains("party1/UnitDetailedThreatSituation"))
        assert(not reportContains("<secret>")); assert(not reportContains("unavailable"))
    end
    threat.nameplate1.party1 = 1000; data.nameplate1.combat = secretValue; output = {}
    event("UNIT_FLAGS", "nameplate1"); advance(0.2)
    SlashCmdList.PLATETHREATNUMBER("status")
    assert(reportContains(addon.L.D_SECRET)); assert(reportContains("UnitAffectingCombat"))
end)

test("debug does not turn secret threat into a solo value", function()
    reset(); groupSize = 0; event("GROUP_ROSTER_UPDATE")
    local f = newPlate("nameplate1"); threat.nameplate1 = { player = secretValue }
    addon:SetOption("debug", true); combat(); advance(0.2); hidden(f)
    SlashCmdList.PLATETHREATNUMBER("status"); assert(reportContains(addon.L.D_SECRET))
    threat.nameplate1.player = 116; data.pet = {}; threat.nameplate1.pet = secretValue
    event("UNIT_PET", "player"); advance(0.2); hidden(f)
end)

test("debug report survives combat exit and nameplate removal without stale text", function()
    local f = fixture(); addon:SetOption("debug", true); advance(0.2)
    event("NAME_PLATE_UNIT_REMOVED", "nameplate1"); plates.nameplate1 = nil; hidden(f)
    data.player.combat = false; event("PLAYER_REGEN_ENABLED"); calls = {}; output = {}
    SlashCmdList.PLATETHREATNUMBER("status")
    assert(reportContains(addon.L.D_SHOWN)); eq(#calls, 0); eq(pending(), 0)
    addon:SetOption("debug", false); output = {}; SlashCmdList.PLATETHREATNUMBER("status")
    assert(not reportContains(addon.L.D_SHOWN))
end)

test("enemy death preserves the useful combat diagnosis", function()
    local f = fixture(); addon:SetOption("debug", true)
    threat.nameplate1.party1 = secretValue
    advance(0.2); hidden(f)
    data.nameplate1.dead = true
    event("UNIT_HEALTH", "nameplate1"); advance(0.2)
    event("NAME_PLATE_UNIT_REMOVED", "nameplate1"); plates.nameplate1 = nil
    event("PLAYER_REGEN_ENABLED"); output = {}
    SlashCmdList.PLATETHREATNUMBER("status")
    assert(reportContains(addon.L.D_FILTERED)); assert(reportContains(addon.L.D_SECRET))
    assert(reportContains("party1/UnitDetailedThreatSituation"))
    -- Reusing the same token for a new enemy must discard the old diagnosis.
    newPlate("nameplate1"); output = {}; SlashCmdList.PLATETHREATNUMBER("status")
    assert(not reportContains(addon.L.D_SECRET))
end)

test("diagnostics are bounded and distinguish unreadable frames and hidden health bars", function()
    reset(); addon:SetOption("debug", true)
    for i = 1, 60 do
        local unit = "nameplate" .. i
        local f = newPlate(unit)
        f.unit = secretValue; event("NAME_PLATE_UNIT_ADDED", unit)
        event("NAME_PLATE_UNIT_REMOVED", unit); plates[unit] = nil
    end
    output = {}; SlashCmdList.PLATETHREATNUMBER("status")
    eq(#output, 41); assert(reportContains(addon.L.D_FRAME))
    assert(not reportContains("nameplate1:"))
    local f = newPlate("nameplate1"); threat.nameplate1 = { player = 1116, party1 = 1000 }
    f.healthBar:Hide(); combat(); advance(0.2); hidden(f)
    output = {}; SlashCmdList.PLATETHREATNUMBER("status"); assert(reportContains(addon.L.D_POSITION))
end)

test("nil optional geometry no longer suppresses the display", function()
    local f = fixture(); addon:SetOption("debug", true)
    f.ClassificationFrame = CreateFrame("Frame", nil, f)
    f.ClassificationFrame.GetRight = function() return nil end
    advance(0.2); eq(textOf(f).text, "+116")
    SlashCmdList.PLATETHREATNUMBER("status"); assert(reportContains("ANCHOR_FALLBACK"))
    f.LevelFrame:Hide(); f.level = 10 -- A scalar is not a region.
    event("UNIT_THREAT_LIST_UPDATE", "nameplate1"); advance(0.2)
    eq(textOf(f).point[2], f)
end)

test("early nameplate event recovers when Blizzard assigns its unit", function()
    reset(); addon:SetOption("debug", true)
    local p = CreateFrame("Frame"); local f = CreateFrame("Frame", nil, p)
    p.UnitFrame = f; f.healthBar = CreateFrame("StatusBar", nil, f)
    plates.nameplate1 = p; data.nameplate1 = { combat = true }
    threat.nameplate1 = { player = 1116, party1 = 1000 }
    combat(); event("NAME_PLATE_UNIT_ADDED", "nameplate1")
    CompactUnitFrame_SetUnit(f, "nameplate1"); advance(0.2)
    eq(textOf(f).text, "+116")
end)

print(string.format("\n%d tests passed (Lua %s).", passed, _VERSION))
