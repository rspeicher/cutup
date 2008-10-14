if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_Julienne
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that times Slice and Dice.
Inspired by: Disco Dice, SliceWatcher, Quartz (code)

It slices, it dices, it makes julienne fries, whatever those are!
]]

local mod = Cutup:NewModule("Julienne", nil, "AceEvent-3.0", "AceConsole-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")
local self = mod
local db

local defaults = {
	profile = {
		julienne = {
			y = 350,
			
			width   = 250,
			height  = 16,
			alpha   = 1,
			scale   = 100.0,
			texture = 'Smooth v2',
			
			border    = 'None',
			backColor = { 0, 0, 0, 1 },
			mainColor = { 0.38, 0.38, 1.0, 0.8 },
			
			potentialShow  = true,
			potentialColor = { 0.85, 0.80, 0, 1 },
			
			textShow     = true,
			textPosition = 2,
			textColor    = { 1, 1, 1, 1 },
			textFont     = 'Friz Quadrata TT',
			textSize     = 14,
			
			-- sound = true, -- TODO: Optional sound
		}
	}
}

-- Frames
local locked = true
local sndBar, sndBar2, sndTimeText, sndParent, db

-- Localized functions
local GetTime = _G.GetTime
local UnitGUID = _G.UnitGUID

-- Settings/infos
local maxTime, combos = 0, 0
local improvedRank, improved = nil, { 0, 0.25, 0.50 } -- Improved Slice and Dice modifiers
local netherbladeBonus = nil -- True if we have the two-piece Netherblade set bonus
local netherbladeSet = { 29044, 29045, 29046, 29047, 29048 }
local resetValues = true -- Terrible hack to fix a display issue
local spellInfo = GetSpellInfo(6774) -- Slice and Dice (Rank 2)
local lastGUID = nil

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
			
			if combos > 0 then
				local duration = self:CurrentDuration(combos)
				sndTimeText:SetText(("%.1f"):format(duration))
			end
		else
			local perc = remainingTime / maxTime
			sndBar:SetValue(perc)
			sndTimeText:SetText(("%.1f"):format(remainingTime))
		end
	else
		if sndParent:IsVisible() then
			self:CheckVisibility(true)
		end
	end
end
mod.OnUpdate = OnUpdate
local function OnShow()
	sndParent:SetScript('OnUpdate', OnUpdate)
end
local function OnHide()
	sndParent:SetScript('OnUpdate', nil)
end

function mod:OnInitialize()
	db = LibStub("AceDB-3.0"):New("CutupDB", nil, "Default")
	self.db = db
	
	self.db:RegisterDefaults(defaults)
	
	self:SetEnabledState(false)
end

function mod:OnEnable()
	-- Slice and Dice / Combo Point detection
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_COMBO_POINTS")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	
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

function mod:OnDisable()
	self.running = false
	self.locked = true
	sndParent:Hide()
	sndParent = nil
	
	self:UnregisterAllEvents()
end

-- ---------------------
-- Frame methods
-- ---------------------

function mod:ApplySettings()
	if not self:IsEnabled() then return end
	
	if sndParent then
		local db = db.profile.julienne
		local back = {}
		
		-- sndParent, to which all our stuff is anchored
		sndParent:ClearAllPoints()
		if not db.x then
			db.x = (UIParent:GetWidth() / 2 - (db.width * (db.scale/100.0)) / 2) / (db.scale/100.0)
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
			back.edgeFile = Media:Fetch('border', db.border)
			back.edgeSize = 16
			back.insets = { top = 4, right = 4, bottom = 4, left = 4 }
		end
		sndParent:SetBackdrop(back)
		sndParent:SetBackdropColor(unpack(db.backColor))
		
		sndParent:SetAlpha(db.alpha)
		sndParent:SetScale(db.scale / 100.0)
		
		-- sndBar, the actual Slice and Dice timer
		sndBar:ClearAllPoints()
		sndBar:SetPoint('CENTER', sndParent, 'CENTER')
		sndBar:SetWidth(db.width)
		sndBar:SetHeight(db.height)
		sndBar:SetStatusBarTexture(Media:Fetch('statusbar', db.texture))
		sndBar:SetMinMaxValues(0, 1)
		sndBar:SetStatusBarColor(unpack(db.mainColor))
		sndBar:Show()
		
		-- sndBar2, the bar behind sndBar that shows what your timer would be if you cast SnD...right now!
		sndBar2:ClearAllPoints()
		sndBar2:SetPoint('CENTER', sndParent, 'CENTER')
		sndBar2:SetWidth(db.width)
		sndBar2:SetHeight(db.height)
		sndBar2:SetStatusBarTexture(Media:Fetch('statusbar', db.texture))
		sndBar2:SetMinMaxValues(0, 1)
		sndBar2:SetStatusBarColor(unpack(db.potentialColor))
		if db.potentialShow then
			sndBar2:Show()
		else
			sndBar2:Hide()
		end
		
		-- sndTimeText, countdown timer text
		sndTimeText:ClearAllPoints()
		if db.textPosition == 1 then -- LEFT
			sndTimeText:SetPoint('RIGHT', sndParent, 'LEFT')
			sndTimeText:SetJustifyH("LEFT")
		elseif db.textPosition == 2 then -- CENTER
			sndTimeText:SetPoint('CENTER', sndParent, 'CENTER')
			sndTimeText:SetJustifyH("CENTER")
		elseif db.textPosition == 3 then -- RIGHT
			sndTimeText:SetPoint('LEFT', sndParent, 'RIGHT')
			sndTimeText:SetJustifyH("RIGHT")
		end
		sndTimeText:SetFont(Media:Fetch('font', db.textFont), db.textSize)
		sndTimeText:SetTextColor(unpack(db.textColor))
		sndTimeText:SetShadowColor(0, 0, 0, 1)
		sndTimeText:SetShadowOffset(0.8, -0.8)
		sndTimeText:SetNonSpaceWrap(false)
		if db.textShow then
			sndTimeText:Show()
		else
			sndTimeText:Hide()
		end
		
		self:CheckVisibility(true)
		
		-- If we're not already running a timer, set some sane default values
		-- These are used when the user unlocks the bar, they can get an idea of
		-- what it'll look like. But we don't want to change these values when the
		-- bar's running!
		if not self.running and not self.locked then
			resetValues = true

			sndBar:SetValue(0.30)
			sndBar2:SetValue(0.80)
			sndTimeText:SetText(L["Julienne"])
		end
	end
end

-- Checks whether or not to show our parent frame based on various conditions
-- Args: perform - true to call Hide or Show on the frame based on results
-- returns true if the frame should be shown
function mod:CheckVisibility(perform)
	local visible = false
	
	-- If we're running, we're visible. Simple as that.
	if self.running then
		visible = true
	else
		-- We're showing the potential bar and we have combos to show
		if db.profile.julienne.potentialShow and combos > 0 then
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

function mod:TestBar()
	if not self:IsEnabled() then return end
	
	self.running = true

	self:Print("Netherblade bonus:", netherbladeBonus)
	self:Print("Talent rank:", improvedRank)
	
	sndBar:SetValue(0)
	sndBar2:SetValue(0)

	-- Pretend we've got a certain number of combo points
	combos = math.random(0, 5)
		
	sndParent:Show()

	-- We just "used" Slice and Dice. How much time did we get?!
	local duration = self:CurrentDuration(combos)
	self:Print(combos, "combos,", duration, "seconds.")

	-- Stuff used by OnUpdate
	self.startTime = GetTime()
	self.endTime = self.startTime + duration

	-- Pretend we got Ruthlessness?
	combos = math.random(0, 1)
	sndBar2:SetValue(self:CurrentDuration(combos) / maxTime)
	self:Print(combos, "point(s) from Ruthlessness")
end

-- ---------------------
-- Bonus scanning
-- ---------------------

function mod:ScanNetherblade()
	netherbladeBonus = false
	
	local count = 0
	
	local link
	for i=1,10 do
		link = GetInventoryItemLink('player', i)
		if link then
			for k,v in pairs(netherbladeSet) do
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
function mod:ScanTalent()
	improvedRank = 0
	
	local talent, _, _, _, rank = GetTalentInfo(2, 4)
	improvedRank = rank
	self:MaxDuration()
	
	return improvedRank
end

-- ---------------------
-- Timer calculation
-- ---------------------

function mod:CurrentDuration(combos)
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
function mod:MaxDuration()
	-- This is the maximum length of time that a Slice and Dice will run for,
	-- affected by gear and talents.
	maxTime = self:CurrentDuration(MAX_COMBO_POINTS)
	
	return maxTime
end

-- ---------------------
-- Events
-- ---------------------

function mod:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end
function mod:PLAYER_LEAVING_WORLD()
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end
function mod:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" then
		self:ScanNetherblade()
	end
	
	return
end

function mod:PLAYER_TARGET_CHANGED()
	local curGUID = UnitGUID("target")
	
	if curGUID ~= lastGUID then
		lastGUID = curGUID
		self:UNIT_COMBO_POINTS(nil, "player")
	end
	
	return
end

function mod:UNIT_COMBO_POINTS(event, unit)
	if unit ~= "player" then return end

	combos = GetComboPoints("player")
	local duration = self:CurrentDuration(combos)
	sndBar2:SetValue(duration / maxTime)
	
	if not self.running then
		sndTimeText:SetText(("%.1f"):format(duration))
	end
	
	-- When the user unlocks a non-running bar, they get some default values
	-- to know what the bar looks like. If they lock and then get a combo point
	-- on something, those would still be shown, if not for this reset.
	if resetValues and not self.running then
		sndBar:SetValue(0)
		resetValues = nil
	end
	
	self:CheckVisibility(true)
end

function mod:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell)
	if unit == 'player' and spell == spellInfo then
		self.startTime = GetTime()
		self.endTime = self.startTime + self:CurrentDuration(combos)
		self.running = true
		sndParent:Show() -- Might not be shown if potentialShow is disabled
	end
	
	return
end

do
	local function GetLSMIndex(t, value)
		for k, v in pairs(Media:List(t)) do
			if v == value then
				return k
			end
		end
		return nil
	end

	local function set(t, value)
		db.profile.julienne[t[#t]] = value
		self:ApplySettings()
	end
	local function get(t)
		return db.profile.julienne[t[#t]]
	end
	
	local function setcolor(t, ...)
		db.profile.julienne[t[#t]] = {...}
		self:ApplySettings()
	end
	local function getcolor(t)
		return unpack(db.profile.julienne[t[#t]])
	end
	
	local function dragstart()
		sndParent:StartMoving()
	end
	local function dragstop()
		db.profile.julienne.x = sndParent:GetLeft()
		db.profile.julienne.y = sndParent:GetBottom()
		sndParent:StopMovingOrSizing()
	end
	
	local function testbar()
		self:TestBar()
	end
	
	-- Select tables
	local textPosition = { L["Left"], L["Center"], L["Right"] }
	
	Cutup.options.args.Julienne = {
		type = 'group',
		name = L["Julienne"],
		desc = L["Julienne_Desc"],
		icon = "Interface\\Icons\\Ability_Rogue_SliceDice", -- FIXME: Does nothing?
		cmdHidden = true,
		disabled = function() return not self:IsEnabled() end,
		args = {
			desc = {
				type = 'description',
				name = "  " .. L["Julienne_Desc"] .. "\n\n",
				order = 1,
				cmdHidden = true,
				image = "Interface\\Icons\\Ability_Rogue_SliceDice",
				imageWidth = 16, imageHeight = 16,
			},
			test = {
				type = 'execute',
				name = 'Test - DEBUGGING',
				desc = 'Test the bar without actually having Slice and Dice up.',
				func = testbar,
				order = 4,
				hidden = true,
			},
			
			frame = {
				type = 'group',
				name = L["Frame"],
				desc = nil,
				order = 100,
				inline = true,
				args = {
					lock = {
						type = 'toggle',
						name = L["Lock"],
						desc = L["Toggle bar lock"],
						get = function(info)
							return self.locked
						end,
						set = function(info, v)
							self.locked = v
							if not self:IsEnabled() then return end
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
					blank1 = {
						type = 'description',
						name = '',
						order = 102,
						cmdHidden = true,
						width = "full",
					},
					width = {
						type = 'range',
						name = L["Width"],
						get = get, set = set,
						min = 10, max = 600, step = 1, bigStep = 5,
						order = 103,
					},
					height = {
						type = 'range',
						name = L["Height"],
						get = get, set = set,
						min = 2, max = 50, step = 1,
						order = 104,
					},
					blank2 = {
						type = 'description',
						name = '',
						order = 105,
						cmdHidden = true,
						width = "full",
					},
					scale = {
						type = 'range',
						name = L["Scale"],
						get = get, set = set,
						min = 1, max = 150, step = 1, bigStep = 1,
						order = 106,
					},
					alpha = {
						type = 'range',
						name = L["Alpha"],
						get = get, set = set,
						min = 0, max = 1, step = 0.1,
						order = 107,
						--width = "full",
					},
					blank3 = {
						type = 'description',
						name = '',
						order = 108,
						cmdHidden = true,
						width = "full",
					},
					posX = {
						type = 'input',
						name = L["X Position"],
						get = function(info) return tostring(db.profile.julienne.x) end,
						set = function(info, v)
							db.profile.julienne.x = tonumber(v)
							self:ApplySettings()
						end,
						order = 109,
					},
					posY = {
						type = 'input',
						name = L["Y Position"],
						get = function(info) return tostring(db.profile.julienne.y) end,
						set = function(info, v)
							db.profile.julienne.y = tonumber(v)
							self:ApplySettings()
						end,
						order = 110,
					},
					blank4 = {
						type = 'description',
						name = '',
						order = 111,
						cmdHidden = true,
						width = "full",
					},
					backColor = {
						type = 'color',
						name = L["Background color"],
						get = getcolor, set = setcolor,
						hasAlpha = true,
						order = 112,
						--width = "full",
					},
					border = {
						type = 'select',
						name = L["Border"],
						get = function(info) return GetLSMIndex("border", db.profile.julienne.border) end,
						set = function(info, v)
							db.profile.julienne.border = Media:List("border")[v]
							self:ApplySettings()
						end,
						values = Media:List('border'),
						order = 113,
						--width = nil,
					},
				}
			},
			
			bars = {
				type = 'group',
				name = L["Bars"],
				order = 200,
				inline = true,
				args = {
					potentialShow = {
						type = 'toggle',
						name = L["Show potential"],
						desc = L["Show a second bar representing the length of the next potential timer."],
						get = get, set = set,
						order = 201,
						width = "full",
					},
					mainColor = {
						type = 'color',
						name = L["Main color"],
						desc = L["Color of the main countdown bar."],
						get = getcolor, set = setcolor,
						hasAlpha = true,
						order = 202,
						--width = "full",
					},
					potentialColor = {
						type = 'color',
						name = L["Potential color"],
						desc = L["Color of the secondary bar."],
						get = getcolor,	set = setcolor,
						hasAlpha = true,
						order = 203
						--width = "full",
					},
					blank1 = {
						type = 'description',
						name = '',
						order = 204,
						cmdHidden = true,
						width = "full",
					},
					texture = {
						type = 'select',
						name = L["Texture"],
						get = function(info) return GetLSMIndex("statusbar", db.profile.julienne.texture) end,
						set = function(info, v)
							db.profile.julienne.texture = Media:List("statusbar")[v]
							self:ApplySettings()
						end,
						values = Media:List('statusbar'),
						order = 205,
					},
				}
			},
			
			text = {
				type = 'group',
				name = L["Text"],
				order = 300,
				inline = true,
				args = {
					textShow = {
						type = 'toggle',
						name = L["Show text"],
						desc = L["Show countdown text."],
						get = get, set = set,
						order = 301,
					},
					blank1 = {
						type = 'description',
						name = '',
						order = 302,
						cmdHidden = true,
						width = "full",
					},
					textColor = {
						type = 'color',
						name = L["Text color"],
						desc = L["Text color"],
						get = getcolor,	set = setcolor,
						hasAlpha = true,
						order = 303,
					},
					textPosition = {
						type = 'select',
						name = L["Text position"],
						desc = L["Text position"],
						get = get,
						set = function(info, v)
							db.profile.julienne.textPosition = v
							self:ApplySettings()
						end,
						values = textPosition,
						order = 304,
					},
					blank3 = {
						type = 'description',
						name = '',
						order = 305,
						cmdHidden = true,
						width = "full",
					},
					textSize = {
						type = 'range',
						name = L["Text size"],
						desc = L["Text size"],
						get = get, set = set,
						min = 6, max = 20, step = 1,
						order = 306,
					},
					textFont = {
						type = 'select',
						name = L["Text font"],
						desc = L["Text font"],
						get = function(info) return GetLSMIndex("font", db.profile.julienne.textFont) end,
						set = function(info, v)
							db.profile.julienne.textFont = Media:List("font")[v]
							self:ApplySettings()
						end,
						values = Media:List('font'),
						order = 307,
					},
				}
			},
		},
	}
end