local currentPath = assert(arg[1], "current library path is required")
local baselinePath = assert(arg[2], "baseline library path is required")

floor = math.floor
max = math.max
min = math.min

local methods = {}
local regionMeta = {
    __index = function(_, key)
        return methods[key] or function()
        end
    end,
}

local function NewRegion()
    return setmetatable({}, regionMeta)
end

function methods:CreateTexture()
    return NewRegion()
end

function methods:CreateFontString()
    return NewRegion()
end

function methods:SetBackdrop(backdrop)
    self.backdrop = backdrop
end

UIParent = NewRegion()

function CreateFrame()
    return NewRegion()
end

local function NewLibStub()
    local currentMinor = 0
    local sharedLibrary = {}
    local stub = {}

    function stub:NewLibrary(_, minor)
        if minor <= currentMinor then
            return nil
        end

        currentMinor = minor

        return sharedLibrary
    end

    function stub:GetMinor()
        return currentMinor
    end

    function stub:GetLibrary()
        return sharedLibrary
    end

    return stub
end

LibStub = NewLibStub()
dofile(baselinePath)

local sharedLibrary = LibStub:GetLibrary()
local baselineCreate = sharedLibrary.Create
local existingPopup = sharedLibrary:Create(NewRegion(), {})
assert(LibStub:GetMinor() == 1, "baseline copy did not register as minor 1")

dofile(currentPath)
assert(LibStub:GetMinor() == 2, "current copy did not upgrade the shared library to minor 2")
assert(sharedLibrary.Create ~= baselineCreate, "current Create implementation did not replace the baseline")

existingPopup:SetValue(50, true)
local upgradedPopup = sharedLibrary:Create(NewRegion(), { showBorder = false })
assert(not upgradedPopup.backdrop.edgeFile, "upgraded library ignored showBorder after an old-first load")

LibStub = NewLibStub()
dofile(currentPath)

sharedLibrary = LibStub:GetLibrary()
local currentCreate = sharedLibrary.Create
dofile(baselinePath)

assert(LibStub:GetMinor() == 2, "baseline copy replaced a newer implementation")
assert(sharedLibrary.Create == currentCreate, "baseline copy changed Create after a new-first load")

print("LibPopupSlider mixed-version tests: PASS")
