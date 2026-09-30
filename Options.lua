local _, addon = ...
local L = addon.L

function addon:CreateOptions()
    local panel = CreateFrame("Frame")
    panel:Hide()
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(520, 1)
    scroll:SetScrollChild(content)
    local rows, checks, sliders = {}, {}, {}

    local function Label(text, font)
        local label = content:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        label:SetText(text)
        label:SetJustifyH("LEFT")
        rows[#rows + 1] = { kind = "label", widget = label }
    end
    local function Check(text, choice)
        local button = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        local label = button.Text or button.text
        label:SetText(text)
        label:SetJustifyH("LEFT")
        label:ClearAllPoints()
        label:SetPoint("LEFT", button, "RIGHT", 2, 0)
        button:SetScript("OnClick", function()
            if choice then addon:SetOption("role", choice)
            else addon:SetOption("enabled", not not button:GetChecked()) end
            panel:Sync()
        end)
        local row = { kind = "check", widget = button, label = label, choice = choice }
        checks[#checks + 1] = row
        rows[#rows + 1] = row
    end
    local function Slider(key, title, low, high)
        local name = "PlateThreatNumber_" .. key
        local slider = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
        slider:SetMinMaxValues(low, high)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)
        _G[name .. "Low"]:SetText(tostring(low))
        _G[name .. "High"]:SetText(tostring(high))
        _G[name .. "Text"]:SetText("")
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetJustifyH("LEFT")
        slider:SetScript("OnValueChanged", function(_, value)
            if panel.syncing then return end
            addon:SetOption(key, value)
            panel:Sync()
        end)
        local row = { kind = "slider", widget = slider, label = label, key = key, title = title }
        sliders[#sliders + 1] = row
        rows[#rows + 1] = row
    end

    Label("PlateThreatNumber", "GameFontNormalLarge")
    Label(L.DESCRIPTION)
    Check(L.ENABLED)
    Label(L.ROLE, "GameFontNormal")
    Check(L.AUTO, "auto")
    Check(L.TANK, "tank")
    Check(L.NONTANK, "nontank")
    Slider("fontSize", L.FONT_SIZE, 8, 48)
    Slider("offsetX", L.OFFSET_X, -150, 150)
    Slider("offsetY", L.OFFSET_Y, -100, 100)
    Label(L.HELP)

    function panel:Layout()
        local width = math.max(180, scroll:GetWidth())
        content:SetWidth(width)
        local y = 12
        for _, row in ipairs(rows) do
            local widget = row.widget
            widget:ClearAllPoints()
            if row.kind == "label" then
                widget:SetPoint("TOPLEFT", 16, -y)
                widget:SetWidth(width - 32)
                y = y + widget:GetStringHeight() + 16
            elseif row.kind == "check" then
                row.label:SetWidth(width - 76)
                local height = math.max(32, row.label:GetStringHeight() + 8)
                widget:SetPoint("TOPLEFT", 16, -y - (height - 32) / 2)
                y = y + height + 4
            else
                row.label:ClearAllPoints()
                row.label:SetPoint("TOPLEFT", 16, -y)
                row.label:SetWidth(width - 32)
                y = y + row.label:GetStringHeight() + 12
                widget:SetPoint("TOPLEFT", 20, -y)
                widget:SetSize(math.min(400, width - 48), 16)
                y = y + 48
            end
        end
        content:SetHeight(y + 12)
    end
    function panel:Sync()
        self.syncing = true
        for _, row in ipairs(checks) do
            local checked
            if row.choice then checked = addon.charDB.role == row.choice
            else checked = addon.db.enabled end
            row.widget:SetChecked(checked)
        end
        for _, row in ipairs(sliders) do
            row.widget:SetValue(addon.db[row.key])
            row.label:SetText(row.title .. ": " .. addon.db[row.key])
        end
        self.syncing = false
        self:Layout()
    end
    panel:SetScript("OnShow", panel.Sync)
    scroll:SetScript("OnSizeChanged", function() panel:Layout() end)
    panel:Sync()
    self.category = Settings.RegisterCanvasLayoutCategory(panel, "PlateThreatNumber")
    Settings.RegisterAddOnCategory(self.category)
    SLASH_PLATETHREATNUMBER1 = "/ptn"
    SlashCmdList.PLATETHREATNUMBER = function()
        Settings.OpenToCategory(addon.category:GetID())
    end
end
