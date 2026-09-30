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
    if ok and not addon.IsSecret(value) and type(value) == "boolean" then
        return value
    end
end

-- Distinguish absence from restricted/invalid data. An unknown competitor must
-- not be silently excluded, as that could turn a deficit into a false lead.
function addon.ReadThreat(unit, enemy)
    local ok, _, status, _, _, value = pcall(UnitDetailedThreatSituation, unit, enemy)
    if not ok or addon.IsSecret(status) or addon.IsSecret(value) then
        return nil, "unknown"
    end
    if status == nil and value == nil then return nil, "absent" end
    if not addon.IsNumber(status) or not addon.IsNumber(value) or value < 0 then
        return nil, "unknown"
    end
    return value, "known"
end

function addon.CalculateDelta(enemy, competitors)
    if addon.ReadBoolean(UnitIsDeadOrGhost, "player") ~= false
        or addon.ReadBoolean(UnitExists, enemy) ~= true
        or addon.ReadBoolean(UnitIsPlayer, enemy) ~= false
        or addon.ReadBoolean(UnitCanAttack, "player", enemy) ~= true
        or addon.ReadBoolean(UnitIsDeadOrGhost, enemy) ~= false
        or addon.ReadBoolean(UnitAffectingCombat, enemy) ~= true then return end

    local own, state = addon.ReadThreat("player", enemy)
    if state ~= "known" then return end
    local highest
    for i = 1, #competitors do
        local unit = competitors[i]
        local exists = addon.ReadBoolean(UnitExists, unit)
        if exists == nil then return end
        if exists then
            local isSelf = addon.ReadBoolean(UnitIsUnit, unit, "player")
            if isSelf == nil then return end
            if not isSelf then
                local dead = addon.ReadBoolean(UnitIsDeadOrGhost, unit)
                local connected = addon.ReadBoolean(UnitIsConnected, unit)
                if dead == nil or connected == nil then return end
                if not dead and connected then
                    local value, otherState = addon.ReadThreat(unit, enemy)
                    if otherState == "unknown" then return end
                    if value and value > 0 and (not highest or value > highest) then
                        highest = value
                    end
                end
            end
        end
    end
    if highest then return own - highest end
end

function addon.FormatDelta(delta, tank)
    if not addon.IsNumber(delta) then return end
    local rounded = delta < 0 and -math.floor(-delta + 0.5) or math.floor(delta + 0.5)
    local text = rounded == 0 and "0" or string.format("%+.0f", rounded)
    local green = (tank and rounded > 0) or (not tank and rounded <= 0)
    return text, green
end
