local background = nil
local cells = {}
local buffs = {
    ["trickshots"] = {
        ["id"]=0,
        ["name"]="Trick Shots",
    },
    ["streamline"] = {
        ["id"]=0,
        ["name"]="Streamline",
    },
    ["preciseshots"] = {
        ["id"]=0,
        ["name"]="Precise Shots",
    },
    ["spottersmark"] = {
        ["id"]=0,
        ["name"]="Spotter's Mark",
    },
    ["movingtarget"] = {
        ["id"]=0,
        ["name"]="Moving Target",
    },
    ["tempest"] = {
        ["id"]=0,
        ["name"]="Tempest",
    },
}

local function calcBitsMarksmanship()
    local bits = 0
    if buffs.trickshots.id ~= 0 then
        bits = bits + 0x1
    end
    if buffs.streamline.id ~= 0 then
        bits = bits + 0x2
    end
    if buffs.preciseshots.id ~= 0 then
        bits = bits + 0x4
    end
    if buffs.spottersmark.id ~= 0 then
        bits = bits + 0x8
    end
    if buffs.movingtarget.id ~= 0 then
        bits = bits + 0x10
    end
    if C_Spell.GetSpellCooldown("Aimed Shot").duration < 1.5 then
        bits = bits + 0x20
    end
    if C_Spell.GetSpellCooldown("Rapid Fire").duration < 1.5 then
        bits = bits + 0x40
    end
    if C_Spell.GetSpellCooldown("Explosive Shot").duration < 1.5 then
        bits = bits + 0x80
    end
    if C_Spell.IsSpellUsable("Kill Shot") and C_Spell.GetSpellCooldown("Kill Shot").duration < 1.5 then
        bits = bits + 0x100
    end
    return bits
end

local function calcBitsElemental()
    local bits = 0
    if buffs.tempest.id ~= 0 then
        bits = bits + 0x1
    end
    if UnitPower("player") >= 55 then
        bits = bits + 0x2
    end
    local name, _, _, _, fullDuration, expirationTime = AuraUtil.FindAuraByName("Flame Shock", "target", "HARMFUL")
    if (name ~= nil) then
        local remainingDuration = expirationTime - GetTime()
        if remainingDuration > (fullDuration * 0.3) then
            bits = bits + 0x4
        end
    end
    if C_Spell.GetSpellCooldown("Stormkeeper").duration < 1.5 then
        bits = bits + 0x8
    end
    return bits
end

local function updateBits()
    local _, playerClass = UnitClass("player")
    local spec = GetSpecialization()

    if (playerClass == "HUNTER") and (spec == 2) then
        local bits = calcBitsMarksmanship()
        background:Show()

        local b = 1
        for bitIndex = 0,15 do
            if bit.band(bits, b)==0 then
                cells[bitIndex]:Hide()
            else
                cells[bitIndex]:Show()
            end
            b = b * 2
        end
    elseif (playerClass == "SHAMAN") and (spec == 1) then
        local bits = calcBitsElemental()
        background:Show()

        local b = 1
        for bitIndex = 0,15 do
            if bit.band(bits, b)==0 then
                cells[bitIndex]:Hide()
            else
                cells[bitIndex]:Show()
            end
            b = b * 2
        end
    else
        background:Hide()
        for bitIndex = 0,15 do
            cells[bitIndex]:Hide()
        end
    end
end

local function onPlayerAura(info)
    if info.addedAuras then
        for _, aura in pairs(info.addedAuras) do
            for _, buff in pairs(buffs) do
                if aura.name == buff.name then
                    -- print("Detected: " .. buff.name)
                    buff.id = aura.auraInstanceID
                end
            end
        end
    end

	if info.removedAuraInstanceIDs then
		for _, id in pairs(info.removedAuraInstanceIDs) do
            for _, buff in pairs(buffs) do
                if buff.id == id then
                    -- print("Lost: " .. buff.name)
                    buff.id = 0
                end
            end
        end
	end
end

local function init()
    -- loltest("init")

    background = CreateFrame("Frame")
    background:SetPoint("TOPRIGHT", -155, -5)
    background:SetHeight(32)
    background:SetWidth(32)
    background:SetFrameStrata("TOOLTIP")
    background.texture = background:CreateTexture()
    background.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
    background.texture:SetVertexColor(0.0, 0.0, 0.0, 1.0)
    background.texture:SetAllPoints(background)
    background:Show()

    for bitIndex = 0,15 do
        local bitX = bitIndex % 4
        local bitY = floor(bitIndex / 4)
        local bitName = "bit" .. bitIndex
        local cell = CreateFrame("Frame", bitName, background)
        cell:SetPoint("TOPLEFT", bitX * 8, bitY * -8)
        cell:SetHeight(8)
        cell:SetWidth(8)
        cell.texture = cell:CreateTexture()
        cell.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
        cell.texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        cell.texture:SetAllPoints(cell)
        cell:Hide()
        cells[bitIndex] = cell
    end

    updateBits()
    print("WABits: Initialized.")
end

local name, addon = ...
local f = CreateFrame("Frame")
local login = true
local function onevent(self, event, arg1, arg2, ...)
    if login and ((event == "ADDON_LOADED" and name == arg1) or (event == "PLAYER_LOGIN")) then
        login = nil
        f:UnregisterEvent("ADDON_LOADED")
        f:UnregisterEvent("PLAYER_LOGIN")
        init()
    elseif event == "PLAYER_ENTERING_WORLD" then
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        updateBits()
    elseif event == "UNIT_AURA" then
        if arg1 == "player" then
            onPlayerAura(arg2)
        end
        updateBits()
    end
end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:SetScript("OnEvent", onevent)

-- loltest("bottom")
