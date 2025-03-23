local debugOverlayEnabled = false

local background = nil
local debugOverlay = nil
local debugOverlayText = nil
local cells = {}
local buffs = {
    -- Elemental Shaman
    ["tempest"] = {
        ["id"]=0,
        ["name"]="Tempest",
    },

    -- Hunter
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
    ["lunarstorm"] = {
        ["id"]=0,
        ["name"]="Lunar Storm",
        ["harmful"]=true,
    },
    ["strikeitrich"] = {
        ["id"]=0,
        ["name"]="Strike it Rich",
    },
    ["tipofthespear"] = {
        ["id"]=0,
        ["name"]="Tip of the Spear",
    },

    -- Rogue
    ["adrenalinerush"] = {
        ["id"]=0,
        ["name"]="Adrenaline Rush",
    },
    ["bladeflurry"] = {
        ["id"]=0,
        ["name"]="Blade Flurry",
    },
    ["ruthlessprecision"] = {
        ["id"]=0,
        ["name"]="Ruthless Precision",
    },
    ["subterfuge"] = {
        ["id"]=0,
        ["name"]="Subterfuge",
    },
    ["stealth"] = {
        ["id"]=0,
        ["name"]="Stealth",
    },
    ["vanish"] = {
        ["id"]=0,
        ["name"]="Vanish",
    },
    ["opportunity"] = {
        ["id"]=0,
        ["name"]="Opportunity",
    },
    ["audacity"] = {
        ["id"]=0,
        ["name"]="Audacity",
    },

    -- Roll the bones buffs (the first 3 are "the good ones")
    ["rtb1"] = {
        ["id"]=0,
        ["name"]="Broadside",
        ["remain"]=false,
        ["cto"]=false,
    },
    ["rtb2"] = {
        ["id"]=0,
        ["name"]="True Bearing",
        ["remain"]=false,
        ["cto"]=false,
    },
    ["rtb3"] = {
        ["id"]=0,
        ["name"]="Ruthless Precision",
        ["remain"]=false,
        ["cto"]=false,
    },
    ["rtb4"] = {
        ["id"]=0,
        ["name"]="Skull and Crossbones",
        ["remain"]=false,
        ["cto"]=false,
    },
    ["rtb5"] = {
        ["id"]=0,
        ["name"]="Buried Treasure",
        ["remain"]=false,
        ["cto"]=false,
    },
    ["rtb6"] = {
        ["id"]=0,
        ["name"]="Grand Melee",
        ["remain"]=false,
        ["cto"]=false,
    },
}

local rtbStart = 0
local rtbEnd = 0
local rtbDelay = 0.1
local rtbNeedsAPressAfterKIR = false

local function setOverlayText(text)
    if debugOverlayEnabled and debugOverlayText ~= nil then
        debugOverlayText:SetText(text)
    end
end

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
    if UnitPower("player") < 30 then
        bits = bits + 0x200
    end
    return bits
end

local function calcBitsSurvival()
    local bits = 0
    if buffs.lunarstorm.id == 0 then
        bits = bits + 0x1
    end
    if buffs.strikeitrich.id ~= 0 then
        bits = bits + 0x2
    end
    if buffs.tipofthespear.id ~= 0 then
        bits = bits + 0x4
    end
    if C_Spell.GetSpellCharges("Wildfire Bomb").currentCharges >= 2 then
        bits = bits + 0x8
    end
    if C_Spell.GetSpellCharges("Wildfire Bomb").currentCharges >= 1 then
        bits = bits + 0x10
    end
    if C_Spell.GetSpellCooldown("Butchery").duration < 1.5 then
        bits = bits + 0x20
    end
    if C_Spell.GetSpellCooldown("Kill Command").duration < 1.5 then
        bits = bits + 0x40
    end
    if C_Spell.GetSpellCooldown("Explosive Shot").duration < 1.5 then
        bits = bits + 0x80
    end
    if C_Spell.IsSpellUsable("Kill Shot") and C_Spell.GetSpellCooldown("Kill Shot").duration < 1.5 then
        bits = bits + 0x100
    end
    if C_Spell.GetSpellCooldown("Fury of the Eagle").duration < 1.5 then
        bits = bits + 0x200
    end
    if UnitPower("player") > 85 then
        bits = bits + 0x400
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

local function calcBitsOutlaw()
    local bits = 0

    local kirCount = 0
    local goodRtbCount = 0
    local rtbCount = 0

    local rtbShortest = 1000
    for rtbIndex = 1,6 do
        local rtbName = "rtb" .. rtbIndex
        if buffs[rtbName].id ~= 0 then
            if rtbIndex <= 3 then
                goodRtbCount = goodRtbCount + 1
            end
            kirCount = kirCount + 1
            if not buffs[rtbName].cto then
                rtbCount = rtbCount + 1
            end
            local remaining = math.max(buffs[rtbName].expirationTime - GetTime(), 0)
            if rtbShortest > remaining then
                rtbShortest = remaining
            end
        end
    end

    -- print("rtbCount " .. rtbCount .. " goodRtbCount " .. goodRtbCount .. " kirCount " .. kirCount)

    local energy = UnitPower("player")
    local cp = GetComboPoints("player", "target")
    -- print("energy " .. energy .. " cp " .. cp)

    if kirCount >= 4 and rtbShortest < 2 then
        bits = bits + 0x1
    end
    if rtbCount <= 2 and goodRtbCount == 0 or rtbNeedsAPressAfterKIR then
        bits = bits + 0x2
    end

    if buffs.adrenalinerush.id ~= 0 then
        bits = bits + 0x4
    end
    if buffs.bladeflurry.id == 0 and C_Spell.GetSpellCooldown("Blade Flurry").duration < 1.5 then
        -- tracking "should I blade flurry"
        bits = bits + 0x8
    end
    if buffs.ruthlessprecision.id ~= 0 then
        bits = bits + 0x10
    end
    if buffs.subterfuge.id ~= 0 then
        bits = bits + 0x20
    end
    if buffs.stealth.id ~= 0 or buffs.vanish.id ~= 0 then
        bits = bits + 0x40
    end
    if buffs.opportunity.id ~= 0 then
        bits = bits + 0x80
    end
    if buffs.audacity.id ~= 0 then
        bits = bits + 0x100
    end

    if C_Spell.GetSpellCooldown("Keep It Rolling").duration < 1.5 then
        bits = bits + 0x200
    end
    if C_Spell.GetSpellCooldown("Adrenaline Rush").duration < 1.5 then
        bits = bits + 0x400
    end
    if C_Spell.GetSpellCooldown("Between the Eyes").duration < 1.5 then
        bits = bits + 0x800
    end
    if C_Spell.GetSpellCooldown("Vanish").duration < 1.5 then
        bits = bits + 0x1000
    end
    if C_Spell.GetSpellCooldown("Roll the Bones").duration < 1.5 then
        bits = bits + 0x2000
    end

    if cp >= 5 then
        bits = bits + 0x4000
    end
    if cp >= 6 then
        bits = bits + 0x8000
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    if debugOverlayEnabled then
        local rtbRem = math.max(rtbEnd - GetTime(), 0)
        local o = ""
        o = o .. "rtbStart: " .. rtbStart .. "\n"
        o = o .. "rtbEnd  : " .. rtbEnd .. "\n"
        o = o .. "rtbRem  : " .. rtbRem .. "\n"
        o = o .. "\n"
        o = o .. "rtbCount: " .. rtbCount .. "\n"
        o = o .. "kirCount: " .. kirCount .. "\n"
        o = o .. "rtbNeeds: " .. bt(rtbNeedsAPressAfterKIR) .. "\n"
        o = o .. "\n"
        o = o .. "rtbShort: " .. rtbShortest .. "\n"
        o = o .. "\n"
        o = o .. "rtb1: remain: " .. bt(buffs.rtb1.remain) .. " cto: " .. bt(buffs.rtb1.cto) .. "  [" .. buffs.rtb1.id .. "]\n"
        o = o .. "rtb2: remain: " .. bt(buffs.rtb2.remain) .. " cto: " .. bt(buffs.rtb2.cto) .. "  [" .. buffs.rtb2.id .. "]\n"
        o = o .. "rtb3: remain: " .. bt(buffs.rtb3.remain) .. " cto: " .. bt(buffs.rtb3.cto) .. "  [" .. buffs.rtb3.id .. "]\n"
        o = o .. "rtb4: remain: " .. bt(buffs.rtb4.remain) .. " cto: " .. bt(buffs.rtb4.cto) .. "  [" .. buffs.rtb4.id .. "]\n"
        o = o .. "rtb5: remain: " .. bt(buffs.rtb5.remain) .. " cto: " .. bt(buffs.rtb5.cto) .. "  [" .. buffs.rtb5.id .. "]\n"
        o = o .. "rtb6: remain: " .. bt(buffs.rtb6.remain) .. " cto: " .. bt(buffs.rtb6.cto) .. "  [" .. buffs.rtb6.id .. "]\n"
        setOverlayText(o)
    end

    return bits
end

local function showBits(bits)
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
end

local function hideBits()
    background:Hide()
    for bitIndex = 0,15 do
        cells[bitIndex]:Hide()
    end
end

local function resetEverything()
    print("WABits: resetEverything()")
    for _, buff in pairs(buffs) do
        buff.id = 0
        buff.remain = false
        buff.cto = false
        buff.expirationTime = 0
    end
end

local function updateBits()
    local _, playerClass = UnitClass("player")
    local spec = GetSpecialization()

    if (playerClass == "HUNTER") and (spec == 2) then
        showBits(calcBitsMarksmanship())
    elseif (playerClass == "HUNTER") and (spec == 3) then
        showBits(calcBitsSurvival())
    elseif (playerClass == "SHAMAN") and (spec == 1) then
        showBits(calcBitsElemental())
    elseif (playerClass == "ROGUE") and (spec == 2) then
        showBits(calcBitsOutlaw())
    else
        hideBits()
    end
end

local function onPlayerAura(info)
    if info.addedAuras then
        for _, aura in pairs(info.addedAuras) do
            for _, buff in pairs(buffs) do
                if aura.name == buff.name then
                    -- print("Detected: " .. buff.name)
                    if buff.harmful then
                        if aura.isHarmful then
                            buff.id = aura.auraInstanceID
                        end
                    else
                        buff.id = aura.auraInstanceID
                        buff.expirationTime = aura.expirationTime

                        local auraRemaining = aura.expirationTime - GetTime()
                        local rtbRemaining = math.max(rtbEnd - GetTime(), 0)
                        buff.remain = auraRemaining > rtbRemaining + rtbDelay
                        buff.cto = rtbRemaining > auraRemaining + rtbDelay
                    end
                end
            end
        end
    end

    -- RTB refresh checks
    if info.updatedAuraInstanceIDs then
		for _, v in pairs(info.updatedAuraInstanceIDs) do
			local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", v)
            if aura ~= nil then
                for _, buff in pairs(buffs) do
                    if aura.name == buff.name then
                        buff.id = aura.auraInstanceID
                        buff.expirationTime = aura.expirationTime

                        local auraRemaining = aura.expirationTime - GetTime()
                        local rtbRemaining = math.max(rtbEnd - GetTime(), 0)
                        buff.remain = auraRemaining > rtbRemaining + rtbDelay
                        buff.cto = rtbRemaining > auraRemaining + rtbDelay
                    end
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
                    buff.expirationTime = 0
                    buff.remain = false
                    buff.cto = false
                end
            end
        end
	end
end

local function init()
    if debugOverlayEnabled then
        debugOverlay = CreateFrame("Frame")
        debugOverlay:SetPoint("TOPLEFT", 0, 0)
        debugOverlay:SetHeight(300)
        debugOverlay:SetWidth(300)
        debugOverlay:SetFrameStrata("TOOLTIP")
        debugOverlay.texture = debugOverlay:CreateTexture()
        debugOverlay.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
        debugOverlay.texture:SetVertexColor(0.0, 0.0, 0.0, 0.9)
        debugOverlay.texture:SetAllPoints(debugOverlay)
        debugOverlayText = debugOverlay:CreateFontString(nil, "ARTWORK")
        debugOverlayText:SetFont("Interface\\Addons\\WeakAuras\\Media\\Fonts\\FiraMono-Medium.ttf", 13, "OUTLINE")
        debugOverlayText:SetPoint("TOPLEFT",0,0)
        debugOverlayText:SetJustifyH("LEFT")
        debugOverlayText:SetJustifyV("TOP")
        debugOverlayText:Show()
        debugOverlay:Show()
    end

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
        resetEverything()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        updateBits()
    elseif event == "UNIT_AURA" then
        if arg1 == "player" then
            onPlayerAura(arg2)
        end
        updateBits()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, sub_event, _, source, _, _, _, _, _, _, _, spell_id = CombatLogGetCurrentEventInfo()
        if source == UnitGUID("player") then
            if spell_id == 381989 then -- keep it rolling
                if sub_event == "SPELL_CAST_SUCCESS" then
                    -- print("Keep it rolling! - " .. sub_event)
                    rtbNeedsAPressAfterKIR = true
                end
            elseif spell_id == 315508 then -- roll the bones
                if sub_event == "SPELL_CAST_SUCCESS" then
                    -- print("Roll the bones! - " .. sub_event)
                    rtbNeedsAPressAfterKIR = false
                elseif sub_event == "SPELL_AURA_APPLIED" then
                    rtbStart = GetTime()
                    rtbEnd = rtbStart + 30
                elseif sub_event == "SPELL_AURA_REFRESH" then
                    rtbStart = GetTime()
                    rtbEnd = 30 + rtbStart + math.min(rtbEnd - rtbStart, 9)
                elseif sub_event == "SPELL_AURA_REMOVED" then
                    rtbStart = 0
                    rtbEnd = 0
                end
            end
        end
    end
end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", onevent)
