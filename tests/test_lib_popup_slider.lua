local sourcePath = arg[1] or "LibPopupSlider-1.0.lua"
local H = dofile("tests/harness.lua").New()
H:Load(sourcePath)
local library, minor = H.env.LibStub("LibPopupSlider-1.0")
assert(minor == 4, "unexpected LibStub minor")

local defaultPopup = library:Create(H.NewRegion(), {})
assert(
    defaultPopup.backdrop.edgeFile,
    "default popup border must remain enabled"
)
assert(defaultPopup.backdrop.edgeSize == 1, "default popup border size changed")
assert(defaultPopup.borderColor, "default popup border color was not applied")

local borderlessPopup = library:Create(H.NewRegion(), { showBorder = false })
assert(borderlessPopup.backdrop.bgFile, "borderless popup lost its background")
assert(
    not borderlessPopup.backdrop.edgeFile,
    "borderless popup still has an edge texture"
)
assert(
    not borderlessPopup.backdrop.edgeSize,
    "borderless popup still has an edge size"
)
assert(
    not borderlessPopup.borderColor,
    "borderless popup still applies a border color"
)

local function ExpectError(message, callback)
    local ok, actual = pcall(callback)
    assert(
        not ok and actual:find(message, 1, true),
        "expected error: " .. message
    )
end

ExpectError("showBorder must be a boolean", function()
    library:Create(H.NewRegion(), { showBorder = "false" })
end)

local button = H.NewRegion()
local existingMouseDowns = 0
button:SetScript("OnMouseDown", function()
    existingMouseDowns = existingMouseDowns + 1
end)
local callbacks = {}
local popup = library:Create(button, {
    minValue = 50,
    maxValue = 150,
    step = 5,
    label = "Scale",
    showBorder = false,
    showEndMarkers = false,
    showMiddleMarker = false,
    formatValue = function(value)
        return value .. "%"
    end,
    onValueChanged = function(value)
        callbacks[#callbacks + 1] = value
    end,
})
local parts = popup:GetVisualParts()
assert(parts == popup:GetVisualParts(), "visual mapping must be stable")
assert(
    parts.frame == popup
        and parts.slider == popup.slider
        and parts.track == popup.track
)
assert(parts.label == popup.label and parts.value == popup.value)
assert(parts.thumb == popup.slider.SetThumbTextureArgs[1])
assert(
    parts.markers[1] == popup.diamondTop
        and parts.markers[2] == popup.diamondCenter
        and parts.markers[3] == popup.diamondBottom
)
assert(
    parts.backgroundColor
        and parts.trackColor
        and parts.markerColor
        and parts.thumbColor
)
assert(not popup:IsInteracting() and not popup:IsShown())
assert(not popup.diamondTop:IsShown() and not popup.diamondCenter:IsShown())

popup:SetValue(102, true)
assert(
    popup:GetValue() == 100 and #callbacks == 0 and popup.value.text == "100%"
)
popup:SetValue(110)
assert(popup:GetValue() == 110 and #callbacks == 1 and callbacks[1] == 110)
popup:SetValue(110)
assert(#callbacks == 1, "unchanged value fired callback")
popup:SetValue(500, true)
assert(popup:GetValue() == 150 and #callbacks == 1)
popup:SetValue(100, true)

local sliderScript = popup.slider:GetScript("OnValueChanged")
popup:SetFontAppearance("Fonts\\Test.ttf", "")
assert(parts.font == "Fonts\\Test.ttf" and parts.fontFlags == "")
assert(popup:GetValue() == 100 and #callbacks == 1 and not popup:IsShown())
assert(popup:GetHeight() == nil, "hidden popup fitted before opening")
local fontWrites = H.state.fontWrites
popup:SetFontAppearance(parts.font, parts.fontFlags)
assert(H.state.fontWrites == fontWrites, "same font should be a no-op")
ExpectError("requires a font path and flags string", function()
    popup:SetFontAppearance("", "")
end)
ExpectError("requires a font path and flags string", function()
    popup:SetFontAppearance(1, "")
end)
ExpectError("requires a font path and flags string", function()
    popup:SetFontAppearance(parts.font, nil)
end)

button:RunScript("OnMouseDown", "RightButton")
assert(not popup:IsInteracting() and not popup:IsShown())
H.state.mouseDown = true
button:RunScript("OnMouseDown", "LeftButton")
assert(existingMouseDowns == 2, "existing owner script was replaced")
assert(popup:IsInteracting() and popup:IsShown() and popup:GetHeight() > 180)
assert(popup.label.font[1] == parts.font and popup.label.font[3] == "")
popup:SetFontAppearance(parts.font, parts.fontFlags)
ExpectError("Finish the active drag", function()
    popup:SetFontAppearance("Fonts\\Other.ttf", "OUTLINE")
end)
H.state.cursorY = H.state.cursorY + 18
popup:RunScript("OnUpdate")
assert(
    popup:GetValue() == 110 and callbacks[2] == 110,
    "drag/value behavior changed"
)
local fittedValueSize = popup.value.font[2]
H.state.cursorY = H.state.cursorY + 18
popup:RunScript("OnUpdate")
assert(
    popup.value.font[2] == fittedValueSize,
    "value font refitted while dragging"
)
H.state.mouseDown = false
popup:RunScript("OnUpdate")
assert(
    not popup:IsInteracting()
        and not popup:IsShown()
        and not popup:GetScript("OnUpdate")
)

local savedValue, savedCallbacks = popup:GetValue(), #callbacks
popup:Show()
popup:SetFontAppearance("Fonts\\Other.ttf", "OUTLINE")
assert(
    popup.label.font[1] == "Fonts\\Other.ttf"
        and popup.value.font[1] == "Fonts\\Other.ttf"
)
assert(popup:GetValue() == savedValue and #callbacks == savedCallbacks)
assert(popup.slider:GetScript("OnValueChanged") == sliderScript)
assert(not popup.diamondTop:IsShown() and not popup.diamondCenter:IsShown())
popup:Hide()
H.state.mouseDown = true
button:RunScript("OnMouseDown", "LeftButton")
button:Hide()
assert(
    not popup:IsInteracting()
        and not popup:IsShown()
        and not popup:GetScript("OnUpdate")
)

print(
    "LibPopupSlider public API, border, font fitting, and interaction tests: PASS"
)
