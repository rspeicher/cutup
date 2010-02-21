if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_Poisoner
Revision: $Revision$
Author(s): ColdDoT (kevin@colddot.nl)
Description: A module for Cutup that times Envenom buf
]]

local mod = Cutup:NewModule("Poisoner", nil, "AceEvent-3.0", "AceConsole-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")
local self = mod
local db

local defaults = {
	profile = {
		poisoner = {
			y = 350,
			
			width   = 250,
			height  = 16,
			alpha   = 1,
			scale   = 100.0,
			texture = 'Smooth v2',
			
			border    = 'None',
			backColor = { 0, 0, 0, 1 },
			mainColor = { 0.60, 0.90, 0, 1 },
			
			potentialShow  = true,
			potentialColor = { 1, 0.60, 0, 1 },
			
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
local eBar, eBar2, eTimeText, eParent

-- Localized functions
local GetTime = _G.GetTime
local UnitGUID = _G.UnitGUID

-- Settings/infos
local maxTime, combos = 6, 0 -- max duration for 5 combo poins is 1 + (1*5) = 6
local resetValues = true -- Terrible hack to fix a display issue
local spellInfo = GetSpellInfo(57993) -- Envenom (Rank 4)
local lastGUID = nil
local minDuration = 2 -- at 1 combo point

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
				eTimeText:SetText(("%.1f"):format(duration))
			end
		else
			local perc = remainingTime / maxTime
			eBar:SetValue(perc)
			eTimeText:SetText(("%.1f"):format(remainingTime))
		end
	else
		if eParent:IsVisible() then
			self:CheckVisibility(true)
		end
	end
end
mod.OnUpdate = OnUpdate
local function OnShow()
	eParent:SetScript('OnUpdate', OnUpdate)
end
local function OnHide()
	eParent:SetScript('OnUpdate', nil)
end

function mod:OnInitialize()
	db = LibStub("AceDB-3.0"):New("CutupDB", nil, "Default")
	self.db = db
	
	self.db:RegisterDefaults(defaults)
	
	self:SetEnabledState(false)
end

function mod:OnEnable()
	-- Slice and Dice / Combo Point detection
	self:RegisterEvent("UNIT_AURA") 
	self:RegisterEvent("UNIT_COMBO_POINTS")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	
	self.locked = locked
	self.startTime = 0
	self.endTime = 0
	self.running = false
	
	if not eParent then
		eParent = CreateFrame('Frame', nil, UIParent)
		eParent:SetFrameStrata('LOW')
		eParent:SetScript('OnShow', OnShow)
		eParent:SetScript('OnHide', OnHide)
		eParent:SetMovable(true)
		eParent:RegisterForDrag('LeftButton')
		eParent:SetClampedToScreen(true)
		
		eBar = CreateFrame("StatusBar", nil, eParent)
		eBar:SetFrameStrata('MEDIUM')
		eBar2 = CreateFrame("StatusBar", nil, eParent)
		eTimeText = eBar:CreateFontString(nil, 'OVERLAY')
		
		eParent:Hide()
	end
	self:ApplySettings()
end

function mod:OnDisable()
	self.running = false
	self.locked = true
	eParent:Hide()
	eParent = nil
	
	self:UnregisterAllEvents()
end

-- ---------------------
-- Frame methods
-- ---------------------

function mod:ApplySettings()
	if not self:IsEnabled() then return end
	
	if eParent then
		local db = db.profile.poisoner
		local back = {}
		
		-- eParent, to which all our stuff is anchored
		eParent:ClearAllPoints()
		if not db.x then
			db.x = (UIParent:GetWidth() / 2 - (db.width * (db.scale/100.0)) / 2) / (db.scale/100.0)
		end
		eParent:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', db.x, db.y)
		
		if db.border == "None" then
			eParent:SetWidth(db.width)
			eParent:SetHeight(db.height)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.insets = { top = 0, right = 0, bottom = 0, left = 0 }
		else
			eParent:SetWidth(db.width + 9)
			eParent:SetHeight(db.height + 10)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.edgeFile = Media:Fetch('border', db.border)
			back.edgeSize = 16
			back.insets = { top = 4, right = 4, bottom = 4, left = 4 }
		end
		eParent:SetBackdrop(back)
		eParent:SetBackdropColor(unpack(db.backColor))
		
		eParent:SetAlpha(db.alpha)
		eParent:SetScale(db.scale / 100.0)
		
		-- eBar, the actual Slice and Dice timer
		eBar:ClearAllPoints()
		eBar:SetPoint('CENTER', eParent, 'CENTER')
		eBar:SetWidth(db.width)
		eBar:SetHeight(db.height)
		eBar:SetStatusBarTexture(Media:Fetch('statusbar', db.texture))
		eBar:SetMinMaxValues(0, 1)
		eBar:SetStatusBarColor(unpack(db.mainColor))
		eBar:Show()
		
		-- eBar2, the bar behind eBar that shows what your timer would be if you cast e...right now!
		eBar2:ClearAllPoints()
		eBar2:SetPoint('CENTER', eParent, 'CENTER')
		eBar2:SetWidth(db.width)
		eBar2:SetHeight(db.height)
		eBar2:SetStatusBarTexture(Media:Fetch('statusbar', db.texture))
		eBar2:SetMinMaxValues(0, 1)
		eBar2:SetStatusBarColor(unpack(db.potentialColor))
		if db.potentialShow then
			eBar2:Show()
		else
			eBar2:Hide()
		end
		
		-- eTimeText, countdown timer text
		eTimeText:ClearAllPoints()
		if db.textPosition == 1 then -- LEFT
			eTimeText:SetPoint('LEFT', eParent, 'LEFT', 5, 0)
			eTimeText:SetJustifyH("LEFT")
		elseif db.textPosition == 2 then -- CENTER
			eTimeText:SetPoint('CENTER', eParent, 'CENTER')
			eTimeText:SetJustifyH("CENTER")
		elseif db.textPosition == 3 then -- RIGHT
			eTimeText:SetPoint('RIGHT', eParent, 'RIGHT', -5, 0)
			eTimeText:SetJustifyH("RIGHT")
		end
		eTimeText:SetFont(Media:Fetch('font', db.textFont), db.textSize)
		eTimeText:SetTextColor(unpack(db.textColor))
		eTimeText:SetShadowColor(0, 0, 0, 1)
		eTimeText:SetShadowOffset(0.8, -0.8)
		eTimeText:SetNonSpaceWrap(false)
		if db.textShow then
			eTimeText:Show()
		else
			eTimeText:Hide()
		end
		
		self:CheckVisibility(true)
		
		-- If we're not already running a timer, set some sane default values
		-- These are used when the user unlocks the bar, they can get an idea of
		-- what it'll look like. But we don't want to change these values when the
		-- bar's running!
		if not self.running and not self.locked then
			resetValues = true

			eBar:SetValue(0.30)
			eBar2:SetValue(0.80)
			eTimeText:SetText(L["Poisoner"])
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
		if db.profile.poisoner.potentialShow and combos > 0 then
			visible = true
		-- We're unlocked and want to give the user something to drag/test settings with
		elseif not self.locked then
			visible = true
		end
	end
	
	if perform then
		if visible then
			eParent:Show()
		else
			eParent:Hide()
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

	self:Print("Minimum duration: ", minDuration)
	
	eBar:SetValue(0)
	eBar2:SetValue(0)

	-- Pretend we've got a certain number of combo points
	combos = math.random(0, 5)
		
	eParent:Show()

	-- We just "used" Slice and Dice. How much time did we get?!
	local duration = self:CurrentDuration(combos)
	self:Print(combos, "combos,", duration, "seconds.")

	-- Stuff used by OnUpdate
	self.startTime = GetTime()
	self.endTime = self.startTime + duration

	-- Pretend we got Ruthlessness?
	combos = math.random(0, 1)
	eBar2:SetValue(self:CurrentDuration(combos) / maxTime)
	self:Print(combos, "point(s) from Ruthlessness")
end

-- ---------------------
-- Timer calculation
-- ---------------------

function mod:CurrentDuration(combos)
	if not combos or combos == 0 then return 0 end
		
	local value = 0

	value = (minDuration + (combos - 1)) 
	
	return value
end

-- ---------------------
-- Events
-- ---------------------
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
	eBar2:SetValue(duration / maxTime)
	
	if not self.running then
		eTimeText:SetText(("%.1f"):format(duration))
	end
	
	-- When the user unlocks a non-running bar, they get some default values
	-- to know what the bar looks like. If they lock and then get a combo point
	-- on something, those would still be shown, if not for this reset.
	if resetValues and not self.running then
		eBar:SetValue(0)
		resetValues = nil
	end
	
	self:CheckVisibility(true)
end

function mod:UNIT_AURA(event, unit)
	if unit ~= "player" then return	end
	
	local name, _, _, _, _, duration, endTime = UnitBuff(unit, spellInfo)
	if name then
		self.startTime = endTime - duration
		self.endTime = endTime
		self.running = true
		eParent:Show() -- Might not be shown if potentialShow is disabled
	else
		if self.running then -- When some one would lose the Envenom debuf before it would run out
			self.startTime = 0
			self.endTime  = 0
			eBar:SetValue(0)
			self:UNIT_COMBO_POINTS(nil, "player") -- force resetting of txt etc
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
		db.profile.poisoner[t[#t]] = value
		self:ApplySettings()
	end
	local function get(t)
		return db.profile.poisoner[t[#t]]
	end
	
	local function setcolor(t, ...)
		db.profile.poisoner[t[#t]] = {...}
		self:ApplySettings()
	end
	local function getcolor(t)
		return unpack(db.profile.poisoner[t[#t]])
	end
	
	local function dragstart()
		eParent:StartMoving()
	end
	local function dragstop()
		db.profile.poisoner.x = eParent:GetLeft()
		db.profile.poisoner.y = eParent:GetBottom()
		eParent:StopMovingOrSizing()
	end
	
	local function testbar()
		self:TestBar()
	end
	
	-- Select tables
	local textPosition = { L["Left"], L["Center"], L["Right"] }
	
	Cutup.options.args.poisoner = {
		type = 'group',
		name = L["Poisoner"],
		desc = L["Poisoner_Desc"],
		icon = "Interface\\Icons\\Ability_Rogue_Disembowel", -- FIXME: Does nothing?
		cmdHidden = true,
		disabled = function() return not self:IsEnabled() end,
		args = {
			desc = {
				type = 'description',
				name = "  " .. L["Poisoner_Desc"] .. "\n\n",
				order = 1,
				cmdHidden = true,
				image = "Interface\\Icons\\Ability_Rogue_Disembowel",
				imageWidth = 16, imageHeight = 16,
			},
			test = {
				type = 'execute',
				name = 'Test - DEBUGGING',
				desc = 'Test the bar without actually having Envenom buff up.',
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
								eParent:EnableMouse(false)
								eParent:SetScript('OnDragStart', nil)
								eParent:SetScript('OnDragStop', nil)
							else
								eParent:Show()
								eParent:EnableMouse(true)
								eParent:SetScript('OnDragStart', dragstart)
								eParent:SetScript('OnDragStop', dragstop)
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
						get = function(info) return tostring(db.profile.poisoner.x) end,
						set = function(info, v)
							db.profile.poisoner.x = tonumber(v)
							self:ApplySettings()
						end,
						order = 109,
					},
					posY = {
						type = 'input',
						name = L["Y Position"],
						get = function(info) return tostring(db.profile.poisoner.y) end,
						set = function(info, v)
							db.profile.poisoner.y = tonumber(v)
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
						get = function(info) return GetLSMIndex("border", db.profile.poisoner.border) end,
						set = function(info, v)
							db.profile.poisoner.border = Media:List("border")[v]
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
						get = function(info) return GetLSMIndex("statusbar", db.profile.poisoner.texture) end,
						set = function(info, v)
							db.profile.poisoner.texture = Media:List("statusbar")[v]
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
							db.profile.poisoner.textPosition = v
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
						get = function(info) return GetLSMIndex("font", db.profile.poisoner.textFont) end,
						set = function(info, v)
							db.profile.poisoner.textFont = Media:List("font")[v]
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