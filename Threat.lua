local _, addon = ...

function addon.IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

function addon.IsNumber(value)
    return not addon.IsSecret(value) and type(value) == "number"
        and value == value and value > -math.huge and value < math.huge
end

-- Nil means that the client cannot establish the result. Never branch on secrets.
function addon.ReadBoolean(api, ...)
    local ok, value = pcall(api, ...)
    if not ok then return nil, "ERROR" end
    if addon.IsSecret(value) then return nil, "SECRET" end
    if type(value) ~= "boolean" then return nil, "INVALID" end
    return value
end

-- Distinguish absence from restricted/invalid data. An unknown competitor must
-- not be silently excluded, as that could turn a deficit into a false lead.
function addon.ReadThreat(unit, enemy)
    local ok, _, status, _, _, value = pcall(UnitDetailedThreatSituation, unit, enemy)
    if not ok then return nil, "unknown", "ERROR" end
    -- Only rawThreat participates in the calculation. A protected aggro status
    -- must not veto an otherwise readable number. Check secrecy before using it.
    if addon.IsSecret(value) then return nil, "unknown", "SECRET", "rawThreat" end
    if value == nil and not addon.IsSecret(status) and status == nil then
        return nil, "absent", "NO_THREAT", "rawThreat"
    end
    if not addon.IsNumber(value) or value < 0 then
        return nil, "unknown", "INVALID", "rawThreat"
    end
    return value, "known"
end

local function Check(api, expected, ...)
    local value, reason = addon.ReadBoolean(api, ...)
    if value ~= expected then return reason or "FILTERED" end
end

function addon.CalculateDelta(enemy, competitors, allowSolo)
    local reason = Check(UnitIsDeadOrGhost, false, "player")
    if reason then return nil, reason, "player/UnitIsDeadOrGhost" end
    reason = Check(UnitExists, true, enemy)
    if reason then return nil, reason, "UnitExists" end
    reason = Check(UnitIsPlayer, false, enemy)
    if reason then return nil, reason, "UnitIsPlayer" end
    reason = Check(UnitCanAttack, true, "player", enemy)
    if reason then return nil, reason, "UnitCanAttack" end
    reason = Check(UnitIsDeadOrGhost, false, enemy)
    if reason then return nil, reason, "UnitIsDeadOrGhost" end
    reason = Check(UnitAffectingCombat, true, enemy)
    if reason then return nil, reason, "UnitAffectingCombat" end

    local own, state, why, field = addon.ReadThreat("player", enemy)
    if state ~= "known" then
        return nil, why, "player/UnitDetailedThreatSituation" .. (field and "." .. field or "")
    end
    local highest
    for i = 1, #competitors do
        local unit = competitors[i]
        local exists, existsReason = addon.ReadBoolean(UnitExists, unit)
        if exists == nil then return nil, existsReason, unit .. "/UnitExists" end
        if exists then
            local isSelf, selfReason = addon.ReadBoolean(UnitIsUnit, unit, "player")
            if isSelf == nil then return nil, selfReason, unit .. "/UnitIsUnit" end
            if not isSelf then
                local dead, deadReason = addon.ReadBoolean(UnitIsDeadOrGhost, unit)
                local connected, connectedReason = addon.ReadBoolean(UnitIsConnected, unit)
                if dead == nil then return nil, deadReason, unit .. "/UnitIsDeadOrGhost" end
                if connected == nil then return nil, connectedReason, unit .. "/UnitIsConnected" end
                if not dead and connected then
                    local value, otherState, otherReason, otherField = addon.ReadThreat(unit, enemy)
                    if otherState == "unknown" then
                        return nil, otherReason, unit .. "/UnitDetailedThreatSituation"
                            .. (otherField and "." .. otherField or "")
                    end
                    if value and value > 0 and (not highest or value > highest) then
                        highest = value
                    end
                end
            end
        end
    end
    if highest then return own - highest, "SHOWN" end
    if allowSolo then return own, "SOLO" end
    return nil, "NO_RIVAL"
end

function addon.FormatDelta(delta, tank)
    if not addon.IsNumber(delta) then return end
    local rounded = delta < 0 and -math.floor(-delta + 0.5) or math.floor(delta + 0.5)
    local text = rounded == 0 and "0" or string.format("%+.0f", rounded)
    local green = (tank and rounded > 0) or (not tank and rounded <= 0)
    return text, green
end
