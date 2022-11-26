local BiggerHealthBar_QvantryEdit = {}

function Initialize()
	BiggerHealthBar_QvantryEdit.playerFrameHealthBar = GetHealthBarFrame()
	BiggerHealthBar_QvantryEdit.playerFrameManaBar = GetManaBarFrame()
	BiggerHealthBar_QvantryEdit.playerManaBarMask = GetManaBarMask()

	InitializeTables()
	CreateSeparator()
	RegisterEvents()
	TryUpdateHealthBarFromHealthBarColorAddon(PlayerFrameHealthBar)
	-- No need to call Run() here as OnPlayerFrame_ToPlayerArt gets called from a WoWClient event on Reload / Login which in turn calls Run.
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

function InitializeTables()
	ConstructFrames()
	ConstructMaskTextures()
	ConstructHealerSpecializations()
end

function ConstructFrames()
	local playerFrameHealthBar = BiggerHealthBar_QvantryEdit.playerFrameHealthBar
	BiggerHealthBar_QvantryEdit.frames = {
		playerFrameHealthBar:GetStatusBarTexture(),
		playerFrameHealthBar.MyHealPredictionBar,
		playerFrameHealthBar.OtherHealPredictionBar,
		playerFrameHealthBar.TotalAbsorbBar,
		playerFrameHealthBar.TotalAbsorbBarOverlay,
		playerFrameHealthBar.OverAbsorbGlow,
		playerFrameHealthBar.OverHealAbsorbGlow,
		playerFrameHealthBar.HealAbsorbBar,
		playerFrameHealthBar.HealAbsorbBarLeftShadow,
		playerFrameHealthBar.HealAbsorbBarRightShadow,
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.PlayerFrameHealthBarAnimatedLoss:GetStatusBarTexture()
	}
end

function ConstructMaskTextures()
	BiggerHealthBar_QvantryEdit.maskTextures = {}
	for index, frame in pairs(BiggerHealthBar_QvantryEdit.frames) do
		BiggerHealthBar_QvantryEdit.maskTextures[index] = frame:GetMaskTexture(1)
	end
end

function ConstructHealerSpecializations()
	BiggerHealthBar_QvantryEdit.healerSpecializations = {
		[2] = { 1 }, -- Paladin, Holy
		[5] = { 1, 2 }, -- Priest, Discipline + Holy
		[7] = { 3 }, -- Shaman, Restoration
		[10] = { 2 }, -- Monk, Mistweaver
		[11] = { 4 }, -- Druid, Restoration
		[13] = { 2 } -- Evoker, Preservation
	}
end

function CreateSeparator()
	local frame = CreateFrame("Frame", "BiggerHealthBar_QvantryEdit.separator", PlayerFrame)
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(124)
	frame:SetHeight(2)

	local texture = frame:CreateTexture("BiggerHealthBar_QvantryEdit.separatorTexture","BACKGROUND")
	texture:SetTexture("Interface\\AddOns\\BiggerHealthBar_QvantryEdit\\Separator.blp")
	texture:SetAllPoints(frame)
	frame.texture = texture

	frame:SetPoint("CENTER",31,-10)
	BiggerHealthBar_QvantryEdit.separator = frame;
end

function RegisterEvents()
	local BiggerHealthBar_QvantryEdit = CreateFrame("Frame", "BiggerHealthBar_QvantryEdit")
	BiggerHealthBar_QvantryEdit:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	BiggerHealthBar_QvantryEdit:SetScript("OnEvent", OnUnitChangedSpecialization)

	hooksecurefunc("PlayerFrame_ToPlayerArt", OnPlayerFrame_ToPlayerArt)
end

function OnUnitChangedSpecialization(...)
	local unit = select(3, ...)
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

function Run()
	BiggerHealthBar_QvantryEdit.shouldShowManaBar = IsHealer()
	if BiggerHealthBar_QvantryEdit.shouldShowManaBar then
		ShowManaBarAndShrinkHealthBar()
	else
		HideManaBarAndEnlargeHealthBar()
	end
end

function ShowManaBarAndShrinkHealthBar()
	ShowManaBar()
	BiggerHealthBar_QvantryEdit.separator:Show()
	IterateFramesAndInvokeAction(TryAddMaskTextureOnFrame)
	SetHealthBarHeight(22)
end

function HideManaBarAndEnlargeHealthBar()
	HideManaBar()
	BiggerHealthBar_QvantryEdit.separator:Hide()
	IterateFramesAndInvokeAction(TryRemoveMaskTextureOnFrame)
	SetHealthBarHeight(31)
end

function SetHealthBarHeight(height)
	BiggerHealthBar_QvantryEdit.playerFrameHealthBar:SetHeight(height)
end

function IterateFramesAndInvokeAction(functionAction)
	for i = 1, #BiggerHealthBar_QvantryEdit.frames do
		local frame = BiggerHealthBar_QvantryEdit.frames[i]
		local maskTexture = BiggerHealthBar_QvantryEdit.maskTextures[i]
		functionAction(frame, maskTexture)
	end
end

function IsHealer()
	local currentClassId = select(3, UnitClass("player"))

	if not IsHealerClass(currentClassId) then
		return false
	end

	if not IsHealerSpecialization(currentClassId) then
		return false
	end

	return true
end

function IsHealerClass(currentClassId)
	return BiggerHealthBar_QvantryEdit.healerSpecializations[currentClassId] ~= nil
end

function IsHealerSpecialization(currentClassId)
	local currentClass = BiggerHealthBar_QvantryEdit.healerSpecializations[currentClassId]
	local currentSpecialization = GetSpecialization()

	for i = 1, #currentClass do
		if currentClass[i] == currentSpecialization then
			return true
		end
	end
	
	return false
end

function HideManaBar()
	local manaBar = BiggerHealthBar_QvantryEdit.playerFrameManaBar
	manaBar:Hide()
	manaBar:HookScript("OnShow", function()
		if BiggerHealthBar_QvantryEdit.shouldShowManaBar then
			return
		end

		manaBar:Hide()
	end)

	BiggerHealthBar_QvantryEdit.playerManaBarMask:Hide()
end

function ShowManaBar()
	BiggerHealthBar_QvantryEdit.playerFrameManaBar:Show()
	BiggerHealthBar_QvantryEdit.playerManaBarMask:Show()
end

function TryUpdateHealthBarFromHealthBarColorAddon(PlayerFrameHealthBar)
	if not IsAddOnLoaded("HealthBarColor") then
		return
	end

	local healthBarColorTextures = HealthBarColor.db.profile.Textures
	local isUseCustomTextureOptionEnabled = healthBarColorTextures.custom
	if not isUseCustomTextureOptionEnabled then
		return
	end

	local media = LibStub("LibSharedMedia-3.0")
	BiggerHealthBar_QvantryEdit.playerFrameHealthBar:SetStatusBarTexture(media:Fetch("statusbar", healthBarColorTextures.statusbar))
	BiggerHealthBar_QvantryEdit.playerFrameHealthBar:GetStatusBarTexture():SetMask("Interface\\AddOns\\BiggerHealthBar_QvantryEdit\\UIUnitFramePlayerHealthMask")
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

function TryAddMaskTextureOnFrame(frame, maskTexture)
	if frame == nil or maskTexture == nil then
		return
	end

	if frame:GetMaskTexture(1) ~= nil then
		return
	end

	frame.mask = maskTexture
end

Initialize()
