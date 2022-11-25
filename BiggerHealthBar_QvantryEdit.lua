local frames = {}
local maskTextures = {}
local shouldShowManaBar = false

function Main()
	local PlayerFrameHealthBar = GetHealthBarFrame()

	InitializeTables(PlayerFrameHealthBar)
	RegisterEvents()
	TryUpdateHealthBarFromHealthBarColorAddon(PlayerFrameHealthBar)
	-- No need to call Run() here as OnPlayerFrame_ToPlayerArt gets called from a WoWClient event on Reload / Login which in turn calls Run.
end

function RegisterEvents()
	local BiggerHealthBar_QvantryEdit = CreateFrame("Frame", "BiggerHealthBar_QvantryEdit")
	BiggerHealthBar_QvantryEdit:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	BiggerHealthBar_QvantryEdit:SetScript("OnEvent", OnUnitChangedSpecialization)

	hooksecurefunc("PlayerFrame_ToPlayerArt", OnPlayerFrame_ToPlayerArt)
end

function InitializeTables(PlayerFrameHealthBar)
	frames = {
		PlayerFrameHealthBar:GetStatusBarTexture(),
		PlayerFrameHealthBar.MyHealPredictionBar,
		PlayerFrameHealthBar.OtherHealPredictionBar,
		PlayerFrameHealthBar.TotalAbsorbBar,
		PlayerFrameHealthBar.TotalAbsorbBarOverlay,
		PlayerFrameHealthBar.OverAbsorbGlow,
		PlayerFrameHealthBar.OverHealAbsorbGlow,
		PlayerFrameHealthBar.HealAbsorbBar,
		PlayerFrameHealthBar.HealAbsorbBarLeftShadow,
		PlayerFrameHealthBar.HealAbsorbBarRightShadow,
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.PlayerFrameHealthBarAnimatedLoss:GetStatusBarTexture()
	}

	for k,v in pairs(frames) do
		maskTextures[k] = v:GetMaskTexture(1)
	end
end

function OnUnitChangedSpecialization(self, event, ...)
	local unit = select(1, ...)
	if unit ~= "player" then
		return
	end

	OnPlayerChangedSpecialization()
end

function OnPlayerChangedSpecialization()
	Run()
end

function OnPlayerFrame_ToPlayerArt()
	Run()
end

function GetHealthBarFrame()
	return PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar
end

function GetManaBarFrame()
	return PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar
end

function GetManaBarMask()
	return PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.ManaBarMask
end

function Run()
	local healerSpecializations = {
		[2] = { 1 }, -- Paladin, Holy
		[5] = { 1, 2 }, -- Priest, Discipline + Holy
		[7] = { 3 }, -- Shaman, Restoration
		[10] = { 2 }, -- Monk, Mistweaver
		[11] = { 4 }, -- Druid, Restoration
		[13] = { 2 } -- Evoker, Preservation
	}

	shouldShowManaBar = IsHealer(healerSpecializations)
	if shouldShowManaBar then
		ShowManaBarAndShrinkHealthBar()
	else
		HideManaBarAndEnlargeHealthBar()
	end
end

function ShowManaBarAndShrinkHealthBar()
	ShowManaBar()

	for k, v in pairs(frames) do
		local frame = frames[k]
		local maskTexture = maskTextures[k]
		TryAddMaskTextureOnFrame(frame, maskTexture)
	end

	GetHealthBarFrame():SetHeight(20)
end

function HideManaBarAndEnlargeHealthBar()
	HideManaBar()

	for k, v in pairs(frames) do
		local frame = frames[k]
		local maskTexture = maskTextures[k]
		TryRemoveMaskTextureOnFrame(frame, maskTexture)
	end

	GetHealthBarFrame():SetHeight(31)
end

function IsHealer(healerSpecializations)
	local currentClassId = select(3, UnitClass("player"))

	if not IsHealerClass(healerSpecializations, currentClassId) then
		return false
	end

	if not IsHealerSpecialization(healerSpecializations, currentClassId) then
		return false
	end

	return true
end

function IsHealerClass(healerSpecializations, currentClassId)
	return healerSpecializations[currentClassId] ~= nil
end

function IsHealerSpecialization(healerSpecializations, currentClassId)
	currentClass = healerSpecializations[currentClassId]
	currentSpecialization = GetSpecialization()

	for k, v in pairs(currentClass) do
    if v == currentSpecialization then
			return true
		end
  end

	return false
end

function HideManaBar()
	local PlayerFrameManaBar = GetManaBarFrame()
	PlayerFrameManaBar:Hide()
	PlayerFrameManaBar:HookScript("OnShow", function()
		if shouldShowManaBar then
			return
		end

		PlayerFrameManaBar:Hide()
	end)

	GetManaBarMask():Hide()
end

function ShowManaBar()
	local PlayerFrameManaBar = GetManaBarFrame()
	PlayerFrameManaBar:Show()
	GetManaBarMask():Show()
end

function TryUpdateHealthBarFromHealthBarColorAddon(PlayerFrameHealthBar)
	if not IsAddOnLoaded("HealthBarColor") then
		return
	end

	healthBarColorTextures = HealthBarColor.db.profile.Textures
	isUseCustomTextureOptionEnabled = healthBarColorTextures.custom
	if not isUseCustomTextureOptionEnabled then
		return
	end

	local media = LibStub("LibSharedMedia-3.0")
	PlayerFrameHealthBar:SetStatusBarTexture(media:Fetch("statusbar", healthBarColorTextures.statusbar))
	PlayerFrameHealthBar:GetStatusBarTexture():SetMask("Interface\\AddOns\\BiggerHealthBar\\UIUnitFramePlayerHealthMask")
end

function TryRemoveMaskTextureOnFrame(frame)
	if frame == nil then
		return
	end

	local maskTexture = frame:GetMaskTexture(1)
	if maskTexture == nil then
		return
	end

	frame:RemoveMaskTexture(maskTexture)
end

function TryAddMaskTextureOnFrame(frame, masnkTexture)
	if frame == nil or maskTexture == nil then
		return
	end

	if frame:GetMaskTexture(1) ~= nil then
		return
	end

	frame.mask = maskTexture
end

Main()