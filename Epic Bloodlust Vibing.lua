local soundFolder = "Interface\\AddOns\\Epic Bloodlust Vibing\\sounds\\"

local tracks = {
    "song1.ogg",
}

local bloodlustSpells = {
    [2825] = true,   -- Bloodlust
    [32182] = true,  -- Heroism
    [80353] = true,  -- Time Warp
    [90355] = true,  -- Ancient Hysteria
    [160452] = true, -- Netherwinds
    [264667] = true, -- Primal Rage
    [390386] = true, -- Fury of the Aspects
    [146555] = true, -- Drums of Rage
    [178207] = true, -- Drums of Fury
    [230935] = true, -- Drums of the Mountain
    [256740] = true, -- Drums of the Maelstrom
    [309658] = true, -- Drums of Deathly Ferocity
    [466904] = true, -- Harrier's Cry
    [1243972] = true, -- Void-Touched Drums
}

local lastTrackIndex
local nextAllowedTime = 0
local lockoutSeconds = 40

local function playRandomTrack(shouldLockout)
    if shouldLockout then
        local now = GetTime()
        if now < nextAllowedTime then
            return
        end
        nextAllowedTime = now + lockoutSeconds
    end

    local trackIndex
    if #tracks > 1 and lastTrackIndex then
        trackIndex = math.random(#tracks - 1)
        if trackIndex >= lastTrackIndex then
            trackIndex = trackIndex + 1
        end
    else
        trackIndex = math.random(#tracks)
    end
    lastTrackIndex = trackIndex

    local success = PlaySoundFile(soundFolder .. tracks[trackIndex], "Master")
    if not success then
        print("|cffff5555Epic Bloodlust Vibing:|r Nepodařilo se přehrát " .. tracks[trackIndex] .. ". Zkontroluj složku sounds.")
    end
end

-- Debuffs applied to everyone who receives a lust effect
local lustDebuffs = {
    57723,  -- Exhaustion
    57724,  -- Sated
    80354,  -- Temporal Displacement
    95809,  -- Insanity
    160455, -- Fatigued
    264689, -- Fatigued
    390435, -- Exhaustion (Fury of the Aspects)
}

local function hasPlayerAura(spellId)
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
    return ok and aura ~= nil
end

local function playerHasLust()
    for spellId in pairs(bloodlustSpells) do
        if hasPlayerAura(spellId) then
            return true
        end
    end
    for _, spellId in ipairs(lustDebuffs) do
        if hasPlayerAura(spellId) then
            return true
        end
    end
    return false
end

local hadLust = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
pcall(frame.RegisterEvent, frame, "COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        if unit ~= "player" then
            return
        end
        local hasLust = playerHasLust()
        if hasLust and not hadLust then
            playRandomTrack(true)
        end
        hadLust = hasLust
        return
    end

    local ok, _, subEvent, _, _, _, _, _, _, _, _, _, spellId = pcall(CombatLogGetCurrentEventInfo)
    if ok and (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_AURA_APPLIED")
        and bloodlustSpells[spellId] then
        playRandomTrack(true)
    end
end)

SLASH_EPICBLOODLUSTVIBING1 = "/epicbloodlustvibing"
SlashCmdList.EPICBLOODLUSTVIBING = function(message)
    local command = string.lower(message or "")
    if command == "test" then
        playRandomTrack(false)
    else
        print("|cff33ff99Epic Bloodlust Vibing|r: /epicbloodlustvibing test – otestuje přehrání náhodné skladby.")
    end
end

print("|cff33ff99Epic Bloodlust Vibing načten.|r Pro test použij /epicbloodlustvibing test.")
