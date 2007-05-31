if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_Julienne
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that times Slice and Dice.
Inspired by: Disco Dice, SliceWatcher, Quartz (code)
]]

local Cutup = Cutup
if Cutup:HasModule('Julienne') then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cutup")
local BS = AceLibrary("Babble-Spell-2.2")
local SM = AceLibrary("SharedMedia-1.0")

local CutupJulienne = Cutup:NewModule('Julienne')
local self = CutupJulienne

-- Frames
local locked = true
local sndBar, sndBar2, sndTimeText, sndParent, db

-- Localized functions
local GetTime = GetTime

-- Settings/infos
local maxTime, combos = 0, 0
local improvedRank, improved = nil, { 0, 0.15, 0.30, 0.45 } -- Improved Slice and Dice modifiers
local netherbladeBonus = nil -- True if we have the two-piece Netherblade set bonus

local function OnUpdate()
	if self.running then
		-- Quartz sorcery
		local currentTime = GetTime()
		local startTime = self.startTime
		local endTime = self.endTime
	
		local remainingTime = endTime - currentTime
		remainingTime = ((remainingTime > 0) and remainingTime or 0) -- Hackity hack hack
	
		if remainingTime == 0 then
			self.running = false
		else
			local perc = remainingTime / maxTime
			sndBar:SetValue(perc)
			if remainingTime < 1 then
				sndTimeText:SetText('')
			else
				sndTimeText:SetText(("%d"):format(remainingTime))
			end
		end
	else
		if sndParent:IsVisible() then
			self:CheckVisibility(true)
		end
	end
end
CutupJulienne.OnUpdate = OnUpdate
local function OnShow()
	sndParent:SetScript('OnUpdate', OnUpdate)
end
local function OnHide()
	sndParent:SetScript('OnUpdate', nil)
end

function CutupJulienne:OnInitialize()
	db = Cutup:AcquireDBNamespace("Julienne")
	self.db = db
	Cutup:RegisterDefaults("Julienne", "profile", {
		y = 350,
		
		width   = 250,
		height  = 16,
		alpha   = 1,
		scale   = 1,
		texture = 'Cilo',
		
		border    = 'None',
		backColor = { 0, 0, 0, 1 },
		mainColor = { 0.38, 0.38, 1.0, 0.8 },
		
		potentialShow  = true,
		potentialColor = { 0.85, 0.80, 0, 1 },
		
		textShow     = true,
		textPosition = L["Center"],
		textColor    = { 1, 1, 1, 1 },
		textFont     = 'Friz Quadrata TT',
		textSize     = 14,
		
		-- sound = true, -- TODO: Optional sound
	})
end

function CutupJulienne:OnEnable()
	-- Slice and Dice / Combo Point detection
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("PLAYER_COMBO_POINTS")
	
	-- Netherblade bonus inventory scanning
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	
	-- Improved Slice and Dice scanning
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", 'ScanTalent')
	
	self.locked = locked
	self.startTime = 0
	self.endTime = 0
	self.running = false
	
	if not sndParent then
		sndParent = CreateFrame('Frame', nil, UIParent)
		sndParent:SetFrameStrata('LOW')
		sndParent:SetScript('OnShow', OnShow)
		sndParent:SetScript('OnHide', OnHide)
		sndParent:SetMovable(true)
		sndParent:RegisterForDrag('LeftButton')
		sndParent:SetClampedToScreen(true)
		
		sndBar = CreateFrame("StatusBar", nil, sndParent)
		sndBar:SetFrameStrata('MEDIUM')
		sndBar2 = CreateFrame("StatusBar", nil, sndParent)
		sndTimeText = sndBar:CreateFontString(nil, 'OVERLAY')
		
		sndParent:Hide()
	end
	self:ApplySettings()
end

function CutupJulienne:OnDisable()
	self.running = false
	self.locked = true
	sndParent:Hide()
end

-- ---------------------
-- Frame methods
-- ---------------------

function CutupJulienne:ApplySettings()
	if sndParent then
		local db = db.profile
		local back = {}
		
		-- sndParent, to which all our stuff is anchored
		sndParent:ClearAllPoints()
		if not db.x then
			db.x = (UIParent:GetWidth() / 2 - (db.width * db.scale) / 2) / db.scale
		end
		sndParent:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', db.x, db.y)
		
		if db.border == "None" then
			sndParent:SetWidth(db.width)
			sndParent:SetHeight(db.height)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.insets = { top = 0, right = 0, bottom = 0, left = 0 }
		else
			sndParent:SetWidth(db.width + 9)
			sndParent:SetHeight(db.height + 10)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.edgeFile = SM:Fetch('border', db.border)
			back.edgeSize = 16
			back.insets = { top = 4, right = 4, bottom = 4, left = 4 }
		end
		sndParent:SetBackdrop(back)
		sndParent:SetBackdropColor(unpack(db.backColor))
		
		sndParent:SetAlpha(db.alpha)
		sndParent:SetScale(db.scale)
		self:CheckVisibility(true)
		
		-- sndBar, the actual Slice and Dice timer
		sndBar:ClearAllPoints()
		sndBar:SetPoint('CENTER', sndParent, 'CENTER')
		sndBar:SetWidth(db.width)
		sndBar:SetHeight(db.height)
		sndBar:SetStatusBarTexture(SM:Fetch('statusbar', db.texture))
		sndBar:SetMinMaxValues(0, 1)
		sndBar:SetStatusBarColor(unpack(db.mainColor))
		sndBar:Show()
		
		-- sndBar2, the bar behind sndBar that shows what your timer would be if you cast SnD...right now!
		if db.potentialShow then
			sndBar2:ClearAllPoints()
			sndBar2:SetPoint('CENTER', sndParent, 'CENTER')
			sndBar2:SetWidth(db.width)
			sndBar2:SetHeight(db.height)
			sndBar2:SetStatusBarTexture(SM:Fetch('statusbar', db.texture))
			sndBar2:SetMinMaxValues(0, 1)
			sndBar2:SetStatusBarColor(unpack(db.potentialColor))
			
			sndBar2:Show()
		else
			sndBar2:Hide()
		end
		
		-- sndTimeText, countdown timer text
		if db.textShow then
			sndTimeText:ClearAllPoints()
			sndTimeText:SetWidth(db.width)
			sndTimeText:SetHeight(db.height)
			if db.textPosition == L["Left"] then
				sndTimeText:SetPoint('LEFT', sndParent, 'LEFT', 5)
				sndTimeText:SetJustifyH("LEFT")
			elseif db.textPosition == L["Center"] then
				sndTimeText:SetPoint('CENTER', sndParent, 'CENTER')
				sndTimeText:SetJustifyH("CENTER")
			elseif db.textPosition == L["Right"] then
				sndTimeText:SetPoint('RIGHT', sndParent, 'RIGHT', -5)
				sndTimeText:SetJustifyH("RIGHT")
			end
		
			sndTimeText:SetFont(SM:Fetch('font', db.textFont), db.textSize)
			sndTimeText:SetTextColor(unpack(db.textColor))
			sndTimeText:SetShadowColor(0, 0, 0, 1)
			sndTimeText:SetShadowOffset(0.8, -0.8)
			sndTimeText:SetNonSpaceWrap(false)
			
			sndTimeText:Show()
		else
			sndTimeText:Hide()
		end
		
		-- If we're not already running a timer, set some sane default values
		-- These are used when the user unlocks the bar, they can get an idea of
		-- what it'll look like. But we don't want to change these values when the
		-- bar's running!
		if not self.running and not self.locked then
			-- FIXME: If we unlock, then lock, then get a combo point on something, these values are shown.
			sndBar:SetValue(0.30)
			sndBar2:SetValue(0.80)
			sndTimeText:SetText(L["Julienne"])
		end
	end
end

-- Checks whether or not to show our parent frame based on various conditions
-- Args: perform - true to call Hide or Show on the frame based on results
-- returns true if the frame should be shown
function CutupJulienne:CheckVisibility(perform)
	local visible = false
	
	-- If we're running, we're visible. Simple as that.
	if self.running then
		visible = true
	else
		-- We're showing the potential bar and we have combos to show
		if db.profile.potentialShow and combos > 0 then
			visible = true
		-- We're unlocked and want to give the user something to drag/test settings with
		elseif not self.locked then
			visible = true
		end
	end
	
	if perform then
		if visible then
			sndParent:Show()
		else
			sndParent:Hide()
		end
	end
	
	return visible
end

-- ---------------------
-- Debugging
-- ---------------------

function CutupJulienne:TestBar()
	self.running = true

	self:Debug("Netherblade bonus:", netherbladeBonus)
	self:Debug("Talent rank:", improvedRank)
	
	sndBar:SetValue(0)
	sndBar2:SetValue(0)

	-- Pretend we've got a certain number of combo points
	combos = math.random(0, 5)
		
	sndParent:Show()

	-- We just "used" Slice and Dice. How much time did we get?!
	local duration = self:CurrentDuration(combos)
	self:Debug(combos, "combos,", duration, "seconds.")

	-- Stuff used by OnUpdate
	self.startTime = GetTime()
	self.endTime = self.startTime + duration

	-- Pretend we got Ruthlessness?
	combos = math.random(0, 1)
	sndBar2:SetValue(self:CurrentDuration(combos) / maxTime)
	self:Debug(combos, "point(s) from Ruthlessness")
end

-- ---------------------
-- Bonus scanning
-- ---------------------

function CutupJulienne:ScanNetherblade()
	netherbladeBonus = false
	
	local count = 0
	local set = { 29044, 29045, 29046, 29047, 29048 }
	
	local link
	for i=1,10 do
		link = GetInventoryItemLink('player', i)
		if link then
			for k,v in pairs(set) do
				if link:find(v) then
					count = count + 1
				end
			end
		end
	end
	
	if count >= 2 then
		netherbladeBonus = true
	end
	self:MaxDuration()
	
	return netherbladeBonus
end
function CutupJulienne:ScanTalent()
	improvedRank = 0
	
	local tab = 2
	local index = 4
	
	local talent, _, _, _, rank = GetTalentInfo(tab, index)
	improvedRank = rank
	self:MaxDuration()
	
	return improvedRank
end

-- ---------------------
-- Timer calculation
-- ---------------------

function CutupJulienne:CurrentDuration(combos)
	if not combos or combos == 0 then return 0 end
	
	if improvedRank == nil then
		self:ScanTalent()
	end
	if netherbladeBonus == nil then
		self:ScanNetherblade()
	end
	
	local value = 0
	local bonus = ((netherbladeBonus) and 3 or 0)
	
	-- Netherblade bonus is applied after Combo modifier, before Talent modifier
	value = (9 + (combos - 1) * 3) + bonus
	value = value + (value * improved[improvedRank + 1])
	
	return value
end
function CutupJulienne:MaxDuration()
	-- This is the maximum length of time that a Slice and Dice will run for,
	-- affected by gear and talents.
	maxTime = self:CurrentDuration(MAX_COMBO_POINTS)
	
	return maxTime
end

-- ---------------------
-- Events
-- ---------------------

function CutupJulienne:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end
function CutupJulienne:PLAYER_LEAVING_WORLD()
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end
function CutupJulienne:UNIT_INVENTORY_CHANGED(unit)
	if unit == 'player' then
		self:ScanNetherblade()
	end
end

function CutupJulienne:PLAYER_COMBO_POINTS()
	combos = GetComboPoints()	
	sndBar2:SetValue(self:CurrentDuration(combos) / maxTime)
	
	self:CheckVisibility(true)
end

function CutupJulienne:UNIT_SPELLCAST_SUCCEEDED(unit, spell, rank, target)
	if unit == 'player' and spell == BS["Slice and Dice"] then
		self.startTime = GetTime()
		self.endTime = self.startTime + self:CurrentDuration(combos)
		self.running = true
		sndParent:Show() -- Might not be shown if potentialShow is disabled
	end
end

do
	local function set(field, value)
		db.profile[field] = value
		self:ApplySettings()
	end
	local function get(field)
		return db.profile[field]
	end
	
	local function setcolor(field, ...)
		db.profile[field] = {...}
		self:ApplySettings()
	end
	local function getcolor(field)
		return unpack(db.profile[field])
	end
	
	local function dragstart()
		sndParent:StartMoving()
	end
	local function dragstop()
		db.profile.x = sndParent:GetLeft()
		db.profile.y = sndParent:GetBottom()
		sndParent:StopMovingOrSizing()
	end
	
	local function testbar()
		self:TestBar()
	end
	
	Cutup.options.args.Julienne = {
		type = 'group',
		name = L["Julienne"],
		desc = L["Slice and Dice timer"],
		args = {
			toggle = {
				type = 'toggle',
				name = L["Enable"],
				desc = L["Enable"],
				get = function()
					return Cutup:IsModuleActive('Julienne')
				end,
				set = function(v)
					Cutup:ToggleModuleActive('Julienne', v)
				end,
				order = 100,
			},
			lock = {
				type = 'toggle',
				name = L["Lock"],
				desc = L["Toggle bar lock"],
				get = function()
					return self.locked
				end,
				set = function(v)
					self.locked = v
					if v then
						sndParent:EnableMouse(false)
						sndParent:SetScript('OnDragStart', nil)
						sndParent:SetScript('OnDragStop', nil)
					else
						sndParent:Show()
						sndParent:EnableMouse(true)
						sndParent:SetScript('OnDragStart', dragstart)
						sndParent:SetScript('OnDragStop', dragstop)
						self:ApplySettings()
					end
				end,
				order = 101,
			},
			test = {
				type = 'execute',
				name = 'Test - DEBUGGING',
				desc = 'Test the bar without actually having Slice and Dice up.',
				func = testbar,
				order = 1,
				hidden = true,
			},
			
			header1 = {
				type = 'header',
				order = 200,
			},
			
			width = {
				type = 'range',
				name = L["Width"],
				desc = L["Width"],
				get = get, set = set, passValue = 'width',
				min = 10, max = 350, step = 5,
				order = 201,
			},
			height = {
				type = 'range',
				name = L["Height"],
				desc = L["Height"],
				get = get, set = set, passValue = 'height',
				min = 2, max = 30, step = 1,
				order = 202,
			},
			scale = {
				type = 'range',
				name = L["Scale"],
				desc = L["Scale"],
				get = get, set = set, passValue = 'scale',
				min = 0.2, max = 2, step = 0.1,
				order = 203,
			},
			alpha = {
				type = 'range',
				name = L["Alpha"],
				desc = L["Alpha"],
				get = get, set = set, passValue = 'alpha',
				min = 0, max = 1, step = 0.1,
				order = 204,
			},
			texture = {
				type = 'text',
				name = L["Texture"],
				desc = L["Texture"],
				get = get, set = set, passValue = 'texture',
				validate = SM:List('statusbar'),
				order = 205,
			},
			
			header2 = {
				type = 'header',
				order = 300,
			},
			
			border = {
				type = 'text',
				name = L["Border"],
				desc = L["Border"],
				get = get, set = set, passValue = 'border',
				validate = SM:List('border'),
				order = 301,
			},
			backColor = {
				type = 'color',
				name = L["Background color"],
				desc = L["Background color"],
				get = getcolor, set = setcolor, passValue = 'backColor',
				hasAlpha = true,
				order = 302,
			},
			mainColor = {
				type = 'color',
				name = L["Main color"],
				desc = L["Color of the main countdown bar."],
				get = getcolor, set = setcolor,	passValue = 'mainColor',
				hasAlpha = true,
				order = 303,
			},
			
			header3 = {
				type = 'header',
				order = 400,
			},
			
			potentialShow = {
				type = 'toggle',
				name = L["Show potential"],
				desc = L["Show a second bar representing the length of the next potential timer."],
				get = get, set = set, passValue = 'potentialShow',
				order = 401,
			},
			potentialColor = {
				type = 'color',
				name = L["Potential color"],
				desc = L["Color of the secondary bar."],
				get = getcolor,	set = setcolor,	passValue = 'potentialColor',
				hasAlpha = true,
				order = 402,
			},
			
			header4 = {
				type = 'header',
				order = 500,
			},
			
			textShow = {
				type = 'toggle',
				name = L["Show text"],
				desc = L["Show countdown text."],
				get = get, set = set, passValue = 'textShow',
				order = 501,
			},
			textPosition = {
				type = 'text',
				name = L["Text position"],
				desc = L["Text position"],
				get = get, set = set, passValue = 'textPosition',
				validate = { L["Left"], L["Right"], L["Center"] },
				order = 502,
			},
			textColor = {
				type = 'color',
				name = L["Text color"],
				desc = L["Text color"],
				get = getcolor,	set = setcolor, passValue = 'textColor',
				hasAlpha = true,
				order = 503,
			},
			textFont = {
				type = 'text',
				name = L["Text font"],
				desc = L["Text font"],
				get = get, set = set, passValue = 'textFont',
				validate = SM:List('font'),
				order = 504,
			},
			textSize = {
				type = 'range',
				name = L["Text size"],
				desc = L["Text size"],
				get = get, set = set, passValue = 'textSize',
				min = 8, max = 20, step = 0.5,
				order = 505,
			},
		},
	}
end