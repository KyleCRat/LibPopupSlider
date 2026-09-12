local Harness = {}

function Harness.New()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.floor, env.max, env.min = math.floor, math.max, math.min
    env.strmatch = string.match
    setfenv(assert(loadfile("tests/fixtures/LibStub.lua")), env)()

    local state = { mouseDown = false, cursorX = 500, cursorY = 400, fontWrites = 0 }
    local methods = {}
    local function NewRegion(parent)
        return setmetatable({ parent = parent, scripts = {}, hooks = {}, shown = true }, { __index = methods })
    end

    function methods:CreateTexture() return NewRegion(self) end
    function methods:CreateFontString() return NewRegion(self) end
    function methods:SetBackdrop(value) self.backdrop = value end
    function methods:SetBackdropBorderColor(...) self.borderColor = { ... } end
    function methods:SetBackdropColor(...) self.backgroundColor = { ... } end
    function methods:SetSize(width, height) self.width, self.height = width, height end
    function methods:SetWidth(value) self.width = value end
    function methods:SetHeight(value) self.height = value end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetEffectiveScale() return self.scale or 1 end
    function methods:ClearAllPoints() self.point = nil end
    function methods:SetPoint(...) self.point = { ... } end
    function methods:SetText(text) self.text = text end
    function methods:SetFont(...) self.font = { ... }; state.fontWrites = state.fontWrites + 1 end
    function methods:GetStringWidth() return #(self.text or "") * self.font[2] * 0.5 end
    function methods:GetUnboundedStringWidth() return self:GetStringWidth() end
    function methods:GetStringHeight() return self.font[2] end
    function methods:SetScript(event, callback) self.scripts[event] = callback end
    function methods:GetScript(event) return self.scripts[event] end
    function methods:HookScript(event, callback)
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], callback)
    end
    function methods:RunScript(event, ...)
        if self.scripts[event] then self.scripts[event](self, ...) end
        for _, callback in ipairs(self.hooks[event] or {}) do callback(self, ...) end
    end
    function methods:IsShown() return self.shown end
    function methods:Show()
        if not self.shown then self.shown = true; self:RunScript("OnShow") end
    end
    function methods:Hide()
        if self.shown then self.shown = false; self:RunScript("OnHide") end
    end
    function methods:SetMinMaxValues(low, high) self.low, self.high, self.sliderValue = low, high, low end
    function methods:GetValue() return self.sliderValue end
    function methods:SetValue(value)
        if self.sliderValue == value then return end
        self.sliderValue = value
        self:RunScript("OnValueChanged", value)
    end

    local setters = {
        "SetFrameStrata", "SetOrientation", "SetValueStep", "SetObeyStepOnDrag",
        "EnableMouse", "SetThumbTexture", "SetColorTexture", "SetVertexColor",
        "SetAtlas", "SetRotation", "SetTextColor", "SetWordWrap", "SetNonSpaceWrap",
        "SetMaxLines", "SetJustifyH",
    }
    for _, name in ipairs(setters) do
        local key = name
        methods[key] = function(self, ...) self[key .. "Args"] = { ... } end
    end

    env.UIParent = NewRegion()
    env.UIParent:SetSize(1920, 1080)
    env.CreateFrame = function(_, _, parent) return NewRegion(parent) end
    env.GetCursorPosition = function() return state.cursorX, state.cursorY end
    env.IsMouseButtonDown = function() return state.mouseDown end

    return {
        env = env, state = state, NewRegion = NewRegion,
        Load = function(_, path) setfenv(assert(loadfile(path)), env)() end,
    }
end

return Harness
