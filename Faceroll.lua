-- World of Warcraft Faceroll Logic

function FRDEBUG(text)
    -- print("Faceroll: " .. text)
end

-- Constants
local KEY_TOGGLE = hs.keycodes.map["F5"]
local KEY_Q = hs.keycodes.map["q"]
local KEY_E = hs.keycodes.map["e"]

-- Actions
local ACTIONS = {
    ["Q"] = {
        "7", "8", "9", "0", "-", "=", "pad7", "pad8", "pad9",          -- send keys
        0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
    },
    ["E"] = {
        "F7", "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
        0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
    }
}

-- Globals
local facerollActive = true
local facerollMode = nil
local facerollTick = 0

local wowApplication = nil
local function sendKeyToWow(keyName)
    -- if wowApplication == nil then
        wowApplication = hs.application.applicationsForBundleID('com.blizzard.worldofwarcraft')[1]
    -- end
    if wowApplication ~= nil then
        hs.eventtap.keyStroke({}, keyName, 20000, wowApplication)
    end
end

local wowTick = hs.timer.new(0.02, function()
    if facerollMode == nil then
        -- FRDEBUG("BAIL 1")
        return
    end

    local actions = ACTIONS[facerollMode]
    if actions == nil then
        -- FRDEBUG("BAIL 2")
        return
    end

    local actionCount = #actions

    local key = actions[facerollTick + 1]
    if key ~= 0 then
        -- FRDEBUG("FACEROLL KEY: " .. key)
        sendKeyToWow(key)
    end

    facerollTick = facerollTick + 1
    if facerollTick >= actionCount then
        facerollTick = 0
    end
end, true)

local function setFacerollActive(active)
    if facerollActive ~= active then
        facerollActive = active
        facerollMode = nil
    end
end

local wowTapKey = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    -- local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    -- FRDEBUG("lole key " .. keyCode)

    if keyCode == KEY_TOGGLE then
        facerollActive = not facerollActive
        if facerollActive then
            FRDEBUG("Faceroll: Active")
            sendKeyToWow("[")
        else
            FRDEBUG("Faceroll: Inactive")
            sendKeyToWow("]")
        end
    elseif facerollActive then
        if keyCode == KEY_Q then
            FRDEBUG("Faceroll: Q")
            if facerollMode ~= "Q" then
                facerollMode = "Q"
                facerollTick = 0
                wowTick:stop()
                wowTick:start()
            end
            return true
        elseif keyCode == KEY_E then
            FRDEBUG("Faceroll: E")
            if facerollMode ~= "E" then
                facerollMode = "E"
                facerollTick = 0
                wowTick:stop()
                wowTick:start()
            end
            return true
        end
    end
end)

local wowTapFlags = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    if facerollMode ~= nil then
        FRDEBUG("Faceroll: Reset")
        wowTick:stop()
        facerollMode = nil
    end
end)

local function enableFaceroll()
    FRDEBUG("enableFaceroll()")
    wowTapKey:start()
    wowTapFlags:start()
end
local function disableFaceroll()
    FRDEBUG("disableFaceroll()")
    wowTapKey:stop()
    wowTapFlags:stop()
end

local WoWFilter = hs.window.filter.new(true)--"Wow")
WoWFilter:subscribe(hs.window.filter.windowFocused, function(w)
    if w == nil then
        FRDEBUG("Focus: w is nil")
    else
        FRDEBUG("Focus: " .. w:title())
        if w:title() == "World of Warcraft" then
            enableFaceroll()
        end
    end
end)
WoWFilter:subscribe(hs.window.filter.windowUnfocused, function(w)
    if w ~= nil then
        FRDEBUG("Unfocus: " .. w:title())
        if w:title() == "World of Warcraft" then
            disableFaceroll()
        end
    end
end)

print("Faceroll loaded.")
