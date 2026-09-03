local sourcePath = arg[1] or "LibPopupSlider-1.0.lua"

floor = math.floor
max = math.max
min = math.min

local library
local majorVersion
local minorVersion

LibStub = {
    NewLibrary = function(_, major, minor)
        majorVersion = major
        minorVersion = minor
        library = {}

        return library
    end,
}

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

function methods:SetBackdropBorderColor(...)
    self.borderColor = { ... }
end

UIParent = NewRegion()

local createdFrames = {}
function CreateFrame()
    local frame = NewRegion()
    createdFrames[#createdFrames + 1] = frame

    return frame
end

dofile(sourcePath)

assert(majorVersion == "LibPopupSlider-1.0", "unexpected LibStub major")
assert(minorVersion == 2, "unexpected LibStub minor")

local defaultPopup = library:Create(NewRegion(), {})
assert(defaultPopup.backdrop.edgeFile, "default popup border must remain enabled")
assert(defaultPopup.backdrop.edgeSize == 1, "default popup border size changed")
assert(rawget(defaultPopup, "borderColor"), "default popup border color was not applied")

local borderlessPopup = library:Create(NewRegion(), { showBorder = false })
assert(borderlessPopup.backdrop.bgFile, "borderless popup lost its background")
assert(not borderlessPopup.backdrop.edgeFile, "borderless popup still has an edge texture")
assert(not borderlessPopup.backdrop.edgeSize, "borderless popup still has an edge size")
assert(not rawget(borderlessPopup, "borderColor"), "borderless popup still applies a border color")

local ok, message = pcall(function()
    library:Create(NewRegion(), { showBorder = "false" })
end)
assert(not ok, "non-boolean showBorder value was accepted")
assert(message:find("showBorder must be a boolean", 1, true), "unexpected showBorder validation error")

print("LibPopupSlider tests: PASS")
