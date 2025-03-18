-- World of Warcraft Faceroll Logic

function FRDEBUG(text)
    -- print("Faceroll: " .. text)
end

-- Constants
local KEY_TOGGLE = hs.keycodes.map["F5"]
local KEY_Q = hs.keycodes.map["q"]
local KEY_E = hs.keycodes.map["e"]
local KEY_SLASH = hs.keycodes.map["/"]
local KEY_ENTER = hs.keycodes.map["return"]
local KEY_DELETE = hs.keycodes.map["delete"]

local AUTOMATIC_STOP_TIME = 0 -- 50 * 9

-- Actions
local ACTIONS = {
    ["Q"] = {0,0,0}, -- set by toggleBMAOE()
    ["E"] = {0,0,0}  -- set by toggleBMAOE()
}

-- Globals
local facerollActive = true
local facerollMode = nil
local facerollTick = 0
local facerollCountdown = 0
local facerollBM = true -- immediately disabled on load

local wowApplication = nil
local function sendKeyToWow(keyName)
    -- if wowApplication == nil then
        wowApplication = hs.application.applicationsForBundleID('com.blizzard.worldofwarcraft')[1]
    -- end
    if wowApplication ~= nil then
        hs.eventtap.keyStroke({}, keyName, 20000, wowApplication)
    end
end

local function updateActions()
    if not facerollActive then
        print("Faceroll: OFF")
    elseif facerollBM then
        print("Faceroll: BM (F7 pressed exclusively on occasion)")

        ACTIONS["Q"] = {
            "7", "8", "9", "0", "-", "=", "pad7", "pad8", "pad9",          -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            0,0,0,0,0,0,0,                                                 -- wait
        }

        ACTIONS["E"] = { -- BM AoE (presses F7 a bit every 6 seconds)
            "F7", "F7", "F7", "F7", "F7", "F7", "F7", "F7", "F7",
            "F7", "F7", "F7", "F7", "F7", "F7", "F7", "F7", "F7",
            "F7", "F7", "F7", "F7", "F7", "F7", "F7", "F7", "F7",
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            -- 0,0,0,0,0,0,0,                                                 -- wait

            "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            0,0,0,0,0,0,0,                                                 -- wait

            "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            0,0,0,0,0,0,0,                                                 -- wait

            "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            0,0,0,0,0,0,0,                                                 -- wait

            "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            0,0,0,0,0,0,0,                                                 -- wait

            "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            0,0,0,0,0,0,0,                                                 -- wait

            -- "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            -- 0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            -- "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            -- 0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
            -- "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            -- 0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
        }
    else
        print("Faceroll: ON (Regular AOE Active)")

        ACTIONS["Q"] = {
            "7", "8", "9", "0", "-", "=", "pad7", "pad8", "pad9",          -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
        }

        ACTIONS["E"] = { -- standard AoE
            "F7", "F8", "F9", "F10", "F11", "F12", "pad4", "pad5", "pad6", -- send keys
            0,0,0,0,0,0,0,0,0,0,0,0,0,                                     -- wait
        }
    end
end

local wowTick = hs.timer.new(0.02, function()
    if facerollMode == nil then
        -- FRDEBUG("BAIL 1")
        return
    end

    if facerollCountdown > 0 then
        facerollCountdown = facerollCountdown - 1
        if facerollCountdown <= 0 then
            FRDEBUG("Faceroll: Countdown Reset")
            facerollMode = nil
            return
        end
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

    if keyCode == KEY_SLASH or keyCode == KEY_ENTER or keyCode == KEY_DELETE then
        setFacerollActive(false)
    elseif keyCode == KEY_TOGGLE then

        facerollTick = 0
        if facerollActive then
            if facerollBM then
                facerollActive = false
                facerollBM = false
            else
                facerollActive = true
                facerollBM = true
            end
        else
            facerollActive = true
        end

        updateActions()

        if facerollActive and facerollBM then
            sendKeyToWow("6")
        elseif facerollActive then
            sendKeyToWow("[")
        else
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
            facerollCountdown = AUTOMATIC_STOP_TIME
            return true
        elseif keyCode == KEY_E then
            FRDEBUG("Faceroll: E")
            if facerollMode ~= "E" then
                facerollMode = "E"
                facerollTick = 0
                wowTick:stop()
                wowTick:start()
            end
            facerollCountdown = 0
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
updateActions()
