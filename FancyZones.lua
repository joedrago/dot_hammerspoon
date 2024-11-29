-- My very own FancyZones/RectanglePro/Divvy implementation

function FZDEBUG(text)
    -- print("FancyZones: " .. text)
end

function addFancyZone(key, x, y, w, h)
    hs.hotkey.bind({"cmd", "alt"}, key, function()
        local win = hs.window.focusedWindow()
        local f = win:frame()

        FZDEBUG("Before: (" .. f.x .. "," .. f.y .. ") " .. f.w .. "x" .. f.h .. "")

        local screens = hs.screen.allScreens()
        for i = #screens, 1, -1 do
            local screen = screens[i]
            local frame = screen:fullFrame()
            local dx = x + frame.x
            local dy = y + frame.y
            local matches = (dx == f.x) and (dy == f.y) and (w == f.w) and (h == f.h)
            if not matches then
                f.x = dx
                f.y = dy
                f.w = w
                f.h = h

                local axApp = hs.axuielement.applicationElement(win:application())
                local wasEnhanced = axApp.AXEnhancedUserInterface
                if wasEnhanced then
                    axApp.AXEnhancedUserInterface = false
                end
                win:setFrame(f)
                if wasEnhanced then
                    axApp.AXEnhancedUserInterface = true
                end
                return
            end
        end
    end)
end

hs.window.animationDuration = 0

addFancyZone("Left", 0, 0, 1280, 810)
addFancyZone("Right", 1280, 0, 1280, 1440)
addFancyZone("Down", 0, 810, 1280, 630)

print("FancyZones loaded.")
