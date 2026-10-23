local currentPath = assert(arg[1], "current library path is required")
assert(arg[2], "at least one baseline library path is required")
local Harness = dofile("tests/harness.lua")

local function AssertPresentation(popup)
    assert(
        type(popup.GetVisualParts) == "function",
        "new popup lacks visual parts"
    )
    assert(
        type(popup.SetFontAppearance) == "function",
        "new popup lacks font appearance"
    )
    assert(
        type(popup.IsInteracting) == "function",
        "new popup lacks interaction state"
    )
    assert(not popup.backdrop.edgeFile, "new popup lost showBorder support")
    assert(popup:GetVisualParts().frame == popup)
end

for index = 2, #arg do
    local baselinePath = arg[index]
    local H = Harness.New()
    H:Load(baselinePath)
    local sharedLibrary, baselineMinor = H.env.LibStub("LibPopupSlider-1.0")
    assert(baselineMinor < 3, "baseline must predate the presentation API")
    local baselineCreate = sharedLibrary.Create
    local button = H.NewRegion()
    local existingPopup = sharedLibrary:Create(button, {
        minValue = 0,
        maxValue = 100,
        fontSize = 12,
    })
    local existingSetValue = existingPopup.SetValue
    existingPopup:SetValue(50, true)
    H.state.mouseDown = true
    button:RunScript("OnMouseDown", "LeftButton")

    H:Load(currentPath)
    local currentLibrary, currentMinor = H.env.LibStub("LibPopupSlider-1.0")
    assert(
        currentLibrary == sharedLibrary and currentMinor == 3,
        "upgrade replaced the persistent table"
    )
    assert(
        sharedLibrary.Create ~= baselineCreate,
        "new Create did not replace the baseline"
    )
    assert(
        existingPopup.SetValue == existingSetValue,
        "upgrade rewrote an existing popup"
    )
    H.state.cursorY = H.state.cursorY + 18
    existingPopup:RunScript("OnUpdate")
    assert(
        existingPopup:GetValue() == 60,
        "upgrade broke an active legacy drag"
    )
    H.state.mouseDown = false
    existingPopup:RunScript("OnUpdate")
    assert(
        not existingPopup:IsShown() and not existingPopup:GetScript("OnUpdate")
    )
    existingPopup:SetValue(70, true)
    assert(existingPopup:GetValue() == 70, "existing popup lost value API")
    assert(
        existingPopup.GetVisualParts == nil,
        "legacy popup was unexpectedly retrofitted"
    )
    AssertPresentation(
        sharedLibrary:Create(H.NewRegion(), { showBorder = false })
    )

    local currentCreate = sharedLibrary.Create
    H:Load(currentPath)
    assert(
        sharedLibrary.Create == currentCreate,
        "equal-MINOR copy replaced Create"
    )

    H = Harness.New()
    H:Load(currentPath)
    sharedLibrary = H.env.LibStub("LibPopupSlider-1.0")
    currentCreate = sharedLibrary.Create
    local newPopup = sharedLibrary:Create(H.NewRegion(), { showBorder = false })
    H:Load(baselinePath)
    currentLibrary, currentMinor = H.env.LibStub("LibPopupSlider-1.0")
    assert(currentLibrary == sharedLibrary and currentMinor == 3)
    assert(
        sharedLibrary.Create == currentCreate,
        "older copy replaced new Create"
    )
    AssertPresentation(newPopup)
    AssertPresentation(
        sharedLibrary:Create(H.NewRegion(), { showBorder = false })
    )
    print(
        "LibPopupSlider mixed MINOR "
            .. baselineMinor
            .. "/3 in both load orders: PASS"
    )
end
