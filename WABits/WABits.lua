local background = nil
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

    -- Keep It Rolling buffs (any 4)
    ["kir1"] = {
        ["id"]=0,
        ["name"]="Broadside",
    },
    ["kir2"] = {
        ["id"]=0,
        ["name"]="Ruthless Precision",
    },
    ["kir3"] = {
        ["id"]=0,
        ["name"]="True Bearing",
    },
    ["kir4"] = {
        ["id"]=0,
        ["name"]="Grand Melee",
    },
    ["kir5"] = {
        ["id"]=0,
        ["name"]="Buried Treasure",
    },
    ["kir6"] = {
        ["id"]=0,
        ["name"]="Skull and Crossbones",
    },

    -- Roll the bones buffs (the first 3 are "the good ones")
    ["rtb1"] = {
        ["id"]=0,
        ["name"]="Broadside",
        ["rtb"]=true,
    },
    ["rtb2"] = {
        ["id"]=0,
        ["name"]="Ruthless Precision",
        ["rtb"]=true,
    },
    ["rtb3"] = {
        ["id"]=0,
        ["name"]="True Bearing",
        ["rtb"]=true,
    },
    ["rtb4"] = {
        ["id"]=0,
        ["name"]="Grand Melee",
        ["rtb"]=true,
    },
    ["rtb5"] = {
        ["id"]=0,
        ["name"]="Buried Treasure",
        ["rtb"]=true,
    },
    ["rtb6"] = {
        ["id"]=0,
        ["name"]="Skull and Crossbones",
        ["rtb"]=true,
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
    if buffs.kir1.id ~=0 then
        kirCount = kirCount + 1
    end
    if buffs.kir2.id ~=0 then
        kirCount = kirCount + 1
    end
    if buffs.kir3.id ~=0 then
        kirCount = kirCount + 1
    end
    if buffs.kir4.id ~=0 then
        kirCount = kirCount + 1
    end
    if buffs.kir5.id ~=0 then
        kirCount = kirCount + 1
    end
    if buffs.kir6.id ~=0 then
        kirCount = kirCount + 1
    end

    local goodRtbCount = 0
    local rtbCount = 0
    if buffs.rtb1.id ~= 0 then
        goodRtbCount = goodRtbCount + 1
        rtbCount = rtbCount + 1
    end
    if buffs.rtb2.id ~= 0 then
        goodRtbCount = goodRtbCount + 1
        rtbCount = rtbCount + 1
    end
    if buffs.rtb3.id ~= 0 then
        goodRtbCount = goodRtbCount + 1
        rtbCount = rtbCount + 1
    end
    if buffs.rtb4.id ~= 0 then
        rtbCount = rtbCount + 1
    end
    if buffs.rtb5.id ~= 0 then
        rtbCount = rtbCount + 1
    end
    if buffs.rtb6.id ~= 0 then
        rtbCount = rtbCount + 1
    end

    -- print("rtbCount " .. rtbCount .. " goodRtbCount " .. goodRtbCount .. " kirCount " .. kirCount)

    local energy = UnitPower("player")
    local cp = GetComboPoints("player", "target")
    -- print("energy " .. energy .. " cp " .. cp)

    if kirCount >= 4 then
        bits = bits + 0x1
    end
    if rtbCount <= 2 and goodRtbCount == 0 then
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
                        if not buff.rtb or aura.duration > 10 then
                            -- if we get a rtb buff that is super short,
                            -- we probs got it randomly and don't count it
                            buff.id = aura.auraInstanceID
                        end
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
                    if aura.name == buff.name and buff.rtb and aura.duration > 10 then
                        buff.id = aura.auraInstanceID
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
