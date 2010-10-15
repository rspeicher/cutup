if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_Bleeder
Revision: $Revision$
Author(s): ColdDoT (kevin@colddot.nl), tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that times Rupture.
Inspired by: Cutup_Julienne

We've got a bleeder!
]]

local mod = Cutup:NewModule("Bleeder", nil, "AceEvent-3.0", "AceConsole-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")
local self = mod
local db

local defaults = {
	profile = {
		bleeder = {
			y = 350,
			
			width   = 250,
			height  = 16,
			alpha   = 1,
			scale   = 100.0,
			texture = 'Smooth v2',
			
			border    = 'None',
			backColor = { 0, 0, 0, 1 },
			mainColor = { 1, 0, 0.1, 0.8 },
			
			potentialShow  = true,
			potentialColor = { 0.5, 0, 0.1, 1 },
			
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
local rupBar, rupBar2, rupTimeText, rupParent

-- Localized functions
local GetTime = _G.GetTime
local UnitGUID = _G.UnitGUID

-- Settings/infos
local minTime, maxTime, combos, rupCombos = 8, 16, 0, 0 
local resetValues = true -- Terrible hack to fix a display issue
local lastGUID = nil
local playerName = nil

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
				rupTimeText:SetText(("%.1f"):format(duration))
			end
		else
			local perc = remainingTime / maxTime
			rupBar:SetValue(perc)
			rupTimeText:SetText(("%.1f"):format(remainingTime))
		end
	else
		if rupParent:IsVisible() then
			self:CheckVisibility(true)
		end
	end
end
mod.OnUpdate = OnUpdate
local function OnShow()
	rupParent:SetScript('OnUpdate', OnUpdate)
end
local function OnHide()
	rupParent:SetScript('OnUpdate', nil)
end

function mod:OnInitialize()
	db = LibStub("AceDB-3.0"):New("CutupDB", nil, "Default")
	self.db = db
	
	self.db:RegisterDefaults(defaults)
	
	self:SetEnabledState(false)
end

function mod:OnEnable()
	-- Rupture / Combo Point detection
	self:RegisterEvent("UNIT_COMBO_POINTS")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	playerName = UnitName('player')
	self.locked = locked
	self.startTime = 0
	self.endTime = 0
	self.running = false
	
	if not rupParent then
		rupParent = CreateFrame('Frame', nil, UIParent)
		rupParent:SetFrameStrata('LOW')
		rupParent:SetScript('OnShow', OnShow)
		rupParent:SetScript('OnHide', OnHide)
		rupParent:SetMovable(true)
		rupParent:RegisterForDrag('LeftButton')
		rupParent:SetClampedToScreen(true)
		
		rupBar = CreateFrame("StatusBar", nil, rupParent)
		rupBar:SetFrameStrata('MEDIUM')
		rupBar2 = CreateFrame("StatusBar", nil, rupParent)
		rupTimeText = rupBar:CreateFontString(nil, 'OVERLAY')
		
		rupParent:Hide()
	end
	self:ApplySettings()
end

function mod:OnDisable()
	self.running = false
	self.locked = true
	rupParent:Hide()
	rupParent = nil
	
	self:UnregisterAllEvents()
end

-- ---------------------
-- Frame methods
-- ---------------------

function mod:ApplySettings()
	if not self:IsEnabled() then return end
	
	if rupParent then
		local db = db.profile.bleeder
		local back = {}
		
		-- rupParent, to which all our stuff is anchored
		rupParent:ClearAllPoints()
		if not db.x then
			db.x = (UIParent:GetWidth() / 2 - (db.width * (db.scale/100.0)) / 2) / (db.scale/100.0)
		end
		rupParent:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', db.x, db.y)
		
		if db.border == "None" then
			rupParent:SetWidth(db.width)
			rupParent:SetHeight(db.height)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.insets = { top = 0, right = 0, bottom = 0, left = 0 }
		else
			rupParent:SetWidth(db.width + 9)
			rupParent:SetHeight(db.height + 10)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.edgeFile = Media:Fetch('border', db.border)
			back.edgeSize = 16
			back.insets = { top = 4, right = 4, bottom = 4, left = 4 }
		end
		rupParent:SetBackdrop(back)
		rupParent:SetBackdropColor(unpack(db.backColor))
		
		rupParent:SetAlpha(db.alpha)
		rupParent:SetScale(db.scale / 100.0)
		
		-- rupBar, the actual Rupture timer
		rupBar:ClearAllPoints()
		rupBar:SetPoint('CENTER', rupParent, 'CENTER')
		rupBar:SetWidth(db.width)
		rupBar:SetHeight(db.height)
		rupBar:SetStatusBarTexture(Media:Fetch('statusbar', db.texture))
		rupBar:GetStatusBarTexture():SetHorizTile(false)
		rupBar:SetMinMaxValues(0, 1)
		rupBar:SetStatusBarColor(unpack(db.mainColor))
		rupBar:Show()
		
		-- rupBar2, the bar behind rupBar that shows what your timer would be if you cast Rupture...right now!
		rupBar2:ClearAllPoints()
		rupBar2:SetPoint('CENTER', rupParent, 'CENTER')
		rupBar2:SetWidth(db.width)
		rupBar2:SetHeight(db.height)
		rupBar2:SetStatusBarTexture(Media:Fetch('statusbar', db.texture))
		rupBar2:GetStatusBarTexture():SetHorizTile(false)
		rupBar2:SetMinMaxValues(0, 1)
		rupBar2:SetStatusBarColor(unpack(db.potentialColor))
		if db.potentialShow then
			rupBar2:Show()
		else
			rupBar2:Hide()
		end
		
		-- rupTimeText, countdown timer text
		rupTimeText:ClearAllPoints()
		if db.textPosition == 1 then -- LEFT
			rupTimeText:SetPoint('LEFT', rupParent, 'LEFT', 5, 0)
			rupTimeText:SetJustifyH("LEFT")
		elseif db.textPosition == 2 then -- CENTER
			rupTimeText:SetPoint('CENTER', rupParent, 'CENTER')
			rupTimeText:SetJustifyH("CENTER")
		elseif db.textPosition == 3 then -- RIGHT
			rupTimeText:SetPoint('RIGHT', rupParent, 'RIGHT', -5, 0)
			rupTimeText:SetJustifyH("RIGHT")
		end
		rupTimeText:SetFont(Media:Fetch('font', db.textFont), db.textSize)
		rupTimeText:SetTextColor(unpack(db.textColor))
		rupTimeText:SetShadowColor(0, 0, 0, 1)
		rupTimeText:SetShadowOffset(0.8, -0.8)
		rupTimeText:SetNonSpaceWrap(false)
		if db.textShow then
			rupTimeText:Show()
		else
			rupTimeText:Hide()
		end
		
		self:CheckVisibility(true)
		
		-- If we're not already running a timer, set some sane default values
		-- These are used when the user unlocks the bar, they can get an idea of
		-- what it'll look like. But we don't want to change these values when the
		-- bar's running!
		if not self.running and not self.locked then
			resetValues = true

			rupBar:SetValue(0.30)
			rupBar2:SetValue(0.80)
			rupTimeText:SetText(L["Bleeder"])
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
		if db.profile.bleeder.potentialShow and combos > 0 then
			visible = true
		-- We're unlocked and want to give the user something to drag/test settings with
		elseif not self.locked then
			visible = true
		end
	end
	
	if perform then
		if visible then
			rupParent:Show()
		else
			rupParent:Hide()
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

	rupBar:SetValue(0)
	rupBar2:SetValue(0)

	-- Pretend we've got a certain number of combo points
	combos = math.random(0, 5)
		
	rupParent:Show()

	-- We just "used" Rupture. How much time did we get?!
	local duration = self:CurrentDuration(combos)
	self:Print(combos, "combos,", duration, "seconds.")

	-- Stuff used by OnUpdate
	self.startTime = GetTime()
	self.endTime = self.startTime + duration

	-- Pretend we got Ruthlessness?
	combos = math.random(0, 1)
	rupBar2:SetValue(self:CurrentDuration(combos) / maxTime)
	self:Print(combos, "point(s) from Ruthlessness")
end

-- ---------------------
-- Bonus scanning
-- ---------------------

function mod:ScanGlyph()
	-- TODO for i = 1, NUM_GLYPH_SLOTS do
	for i = 1, 9 do
		local _, _, _, spellId = GetGlyphSocketInfo(i)
		if spellId == 56801 then
			minTime, maxTime = 12, 20
			return
		end
	end
	
	minTime, maxTime = 8, 16
	return
end

-- ---------------------
-- Timer calculation
-- ---------------------

function mod:CurrentDuration(combos)
	if not combos or combos == 0 then return 0 end
	
	return minTime + ((combos - 1) * 2)
end

-- ---------------------
-- Events
-- ---------------------
function mod:ACTIVE_TALENT_GROUP_CHANGED()
	self:ScanGlyph()
end

function mod:PLAYER_ENTERING_WORLD()
	self:ScanGlyph()
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
	
	if combos > 0 then
		rupCombos = combos
	end
	
	local duration = self:CurrentDuration(combos)
	rupBar2:SetValue(duration / maxTime)
	
	if not self.running then
		rupTimeText:SetText(("%.1f"):format(duration))
	end
	
	-- When the user unlocks a non-running bar, they get some default values
	-- to know what the bar looks like. If they lock and then get a combo point
	-- on something, those would still be shown, if not for this reset.
	if resetValues and not self.running then
		rupBar:SetValue(0)
		resetValues = nil
	end
	
	self:CheckVisibility(true)
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, _, eventType, _, srcName, _, destGUID, dstName, _, spellId, spellName, _, ...)
	-- Event wasn't from us or to us, or event isn't one we care about
	if srcName == playerName and spellId == 1943 then 
		if eventType == "SPELL_CAST_SUCCESS" then
			useableCombo = rupCombos
		end
		if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
			rupCombos = 0
			self.startTime = GetTime()
			self.endTime = self.startTime + self:CurrentDuration(useableCombo)
			self.running = true
			rupParent:Show()
		end
		if eventType == "SPELL_AURA_REMOVED" and destGUI == lastGUID then
			self.running = false
			rupParent:Hide()
		end
	end
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
		db.profile.bleeder[t[#t]] = value
		self:ApplySettings()
	end
	local function get(t)
		return db.profile.bleeder[t[#t]]
	end
	
	local function setcolor(t, ...)
		db.profile.bleeder[t[#t]] = {...}
		self:ApplySettings()
	end
	local function getcolor(t)
		return unpack(db.profile.bleeder[t[#t]])
	end
	
	local function dragstart()
		rupParent:StartMoving()
	end
	local function dragstop()
		db.profile.bleeder.x = rupParent:GetLeft()
		db.profile.bleeder.y = rupParent:GetBottom()
		rupParent:StopMovingOrSizing()
	end
	
	local function testbar()
		self:TestBar()
	end
	
	-- Select tables
	local textPosition = { L["Left"], L["Center"], L["Right"] }
	
	Cutup.options.args.Bleeder = {
		type = 'group',
		name = L["Bleeder"],
		desc = L["Bleeder_Desc"],
		icon = "Interface\\Icons\\Ability_Rogue_Rupture", -- FIXME: Does nothing?
		cmdHidden = true,
		disabled = function() return not self:IsEnabled() end,
		args = {
			desc = {
				type = 'description',
				name = "  " .. L["Bleeder_Desc"] .. "\n\n",
				order = 1,
				cmdHidden = true,
				image = "Interface\\Icons\\Ability_Rogue_Rupture",
				imageWidth = 16, imageHeight = 16,
			},
			test = {
				type = 'execute',
				name = 'Test - DEBUGGING',
				desc = 'Test the bar without actually having Rupture up.',
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
								rupParent:EnableMouse(false)
								rupParent:SetScript('OnDragStart', nil)
								rupParent:SetScript('OnDragStop', nil)
							else
								rupParent:Show()
								rupParent:EnableMouse(true)
								rupParent:SetScript('OnDragStart', dragstart)
								rupParent:SetScript('OnDragStop', dragstop)
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
						get = function(info) return tostring(db.profile.bleeder.x) end,
						set = function(info, v)
							db.profile.bleeder.x = tonumber(v)
							self:ApplySettings()
						end,
						order = 109,
					},
					posY = {
						type = 'input',
						name = L["Y Position"],
						get = function(info) return tostring(db.profile.bleeder.y) end,
						set = function(info, v)
							db.profile.bleeder.y = tonumber(v)
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
						get = function(info) return GetLSMIndex("border", db.profile.bleeder.border) end,
						set = function(info, v)
							db.profile.bleeder.border = Media:List("border")[v]
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
						get = function(info) return GetLSMIndex("statusbar", db.profile.bleeder.texture) end,
						set = function(info, v)
							db.profile.bleeder.texture = Media:List("statusbar")[v]
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
							db.profile.bleeder.textPosition = v
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
						get = function(info) return GetLSMIndex("font", db.profile.bleeder.textFont) end,
						set = function(info, v)
							db.profile.bleeder.textFont = Media:List("font")[v]
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