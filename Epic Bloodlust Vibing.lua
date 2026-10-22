local soundFolder = "Interface\\AddOns\\Epic Bloodlust Vibing\\sounds\\"

local defaults = {
    enabled = true,
    soundChannel = "Master",
}

if type(EpicBloodlustVibingDB) ~= "table" then
    EpicBloodlustVibingDB = {}
end
for key, value in pairs(defaults) do
    if EpicBloodlustVibingDB[key] == nil then
        EpicBloodlustVibingDB[key] = value
    end
end
local settings = EpicBloodlustVibingDB

local tracks = {
    "song1.ogg",
    "song2.ogg",
    "song3.ogg",
    "song4.ogg",
    "song5.ogg",
    "song6.ogg",
    "song7.ogg",
    "song8.ogg",
    "song9.ogg",
    "song10.ogg",
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
    if shouldLockout and not settings.enabled then
        return
    end

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

    local success = PlaySoundFile(soundFolder .. tracks[trackIndex], settings.soundChannel)
    if not success then
        print("|cffff5555Epic Bloodlust Vibing:|r Nepodařilo se přehrát " .. tracks[trackIndex] .. ". Zkontroluj složku sounds.")
    end
end

local soundChannels = {
    { value = "Master", label = "Master (Hlavní)" },
    { value = "Music", label = "Music (Hudba)" },
    { value = "Ambience", label = "Ambience (Prostředí)" },
    { value = "SFX", label = "SFX (Zvukové efekty)" },
    { value = "Dialog", label = "Dialog (Dialogy)" },
}

local soundChannelLabels = {}
for _, channel in ipairs(soundChannels) do
    soundChannelLabels[channel.value] = channel.label
end

local settingsFrame = CreateFrame("Frame", "EpicBloodlustVibingSettingsFrame", UIParent, "BackdropTemplate")
settingsFrame:SetSize(380, 175)
settingsFrame:SetPoint("CENTER")
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
settingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
settingsFrame:Hide()

local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("Epic Bloodlust Vibing")

local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function()
    settingsFrame:Hide()
end)

local enabledCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
enabledCheckbox:SetPoint("TOPLEFT", 24, -55)
local enabledLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
enabledLabel:SetPoint("LEFT", enabledCheckbox, "RIGHT", 4, 0)
enabledLabel:SetText("Přehrávat náhodné skladby při Bloodlustu")
enabledCheckbox:SetScript("OnClick", function(self)
    settings.enabled = self:GetChecked() and true or false
end)

local channelLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
channelLabel:SetPoint("TOPLEFT", 28, -94)
channelLabel:SetText("Zvukový kanál:")

local channelDropdown = CreateFrame("Frame", "EpicBloodlustVibingChannelDropdown", settingsFrame, "UIDropDownMenuTemplate")
channelDropdown:SetPoint("TOPLEFT", 15, -108)
UIDropDownMenu_SetWidth(channelDropdown, 230)

local function refreshSettingsFrame()
    enabledCheckbox:SetChecked(settings.enabled)
    UIDropDownMenu_SetText(channelDropdown, soundChannelLabels[settings.soundChannel])
end

UIDropDownMenu_Initialize(channelDropdown, function(_, level)
    for _, channel in ipairs(soundChannels) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = channel.label
        info.value = channel.value
        info.checked = settings.soundChannel == channel.value
        info.func = function(button)
            settings.soundChannel = button.value
            refreshSettingsFrame()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

local volumeHint = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
volumeHint:SetPoint("TOPLEFT", 28, -148)
volumeHint:SetText("Hlasitost nastavíš posuvníkem vybraného kanálu v nastavení zvuku WoW.")

local function toggleSettingsFrame()
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        refreshSettingsFrame()
        settingsFrame:Show()
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
SLASH_EPICBLOODLUSTVIBING2 = "/ebv"
SlashCmdList.EPICBLOODLUSTVIBING = function(message)
    local command = string.lower(message or "")
    if command == "test" then
        playRandomTrack(false)
    elseif command == "" or command == "settings" or command == "nastaveni" then
        toggleSettingsFrame()
    else
        print("|cff33ff99Epic Bloodlust Vibing|r: /epicbloodlustvibing otevře nastavení, /epicbloodlustvibing test otestuje přehrání skladby.")
    end
end

print("|cff33ff99Epic Bloodlust Vibing načten.|r Nastavení otevřeš příkazem /epicbloodlustvibing.")
