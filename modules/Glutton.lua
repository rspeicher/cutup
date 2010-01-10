if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_Glutton
Revision: $Revision$
Author(s): ColdDoT (kevin@colddot.nl), tsigo (tsigo@eqdkp.com), Neloter (op157@hotmail.com)
Description: A module for Cutup that times Hunger for Blood.
Inspired by: Cutup_Julienne

I want to suck you blood!
]]

local mod = Cutup:NewModule("Glutton", nil, "AceEvent-3.0", "AceConsole-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")
local self = mod
local db

local defaults = {
	profile = {
		glutton = {
			y = 350,
			
			width   = 250,
			height  = 16,
			alpha   = 1,
			scale   = 100.0,
			texture = 'Smooth v2',
			
			border    = 'None',
			backColor = { 0, 0, 0, 1 },
			barColor = { 34/255, 250/255, 42/255, 0.8 },
			
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
local maxTime = 60
local hunBar, hunTimeText, hunParent
local hunRank = nil

-- Localized functions
local GetTime = _G.GetTime
local UnitGUID = _G.UnitGUID
local playerName = nil

-- Settings/infos
local resetValues = true -- Terrible hack to fix a display issue

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
			hunBar:SetValue(perc)
			hunTimeText:SetText(("%.1f"):format(remainingTime))
		end
	else
		if hunParent:IsVisible() then
			self:CheckVisibility(true)
		end
	end
end
mod.OnUpdate = OnUpdate
local function OnShow()
	hunParent:SetScript('OnUpdate', OnUpdate)
end
local function OnHide()
	hunParent:SetScript('OnUpdate', nil)
end

function mod:OnInitialize()
	db = LibStub("AceDB-3.0"):New("CutupDB", nil, "Default")
	self.db = db
	
	self.db:RegisterDefaults(defaults)
	
	self:SetEnabledState(false)
end

function mod:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")--, 'ScanTalent')
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	
	playerName = UnitName('player')
	
	self.locked = locked
	self.startTime = 0
	self.endTime = 0
	self.running = false
	
	if not hunParent then
		hunParent = CreateFrame('Frame', nil, UIParent)
		hunParent:SetFrameStrata('LOW')
		hunParent:SetScript('OnShow', OnShow)
		hunParent:SetScript('OnHide', OnHide)
		hunParent:SetMovable(true)
		hunParent:RegisterForDrag('LeftButton')
		hunParent:SetClampedToScreen(true)
		
		hunBar = CreateFrame("StatusBar", nil, hunParent)
		hunBar:SetFrameStrata('MEDIUM')
		hunTimeText = hunBar:CreateFontString(nil, 'OVERLAY')
		
		hunParent:Hide()
	end
	self:ApplySettings()
end

function mod:OnDisable()
	self.running = false
	self.locked = true
	hunParent:Hide()
	hunParent = nil
	
	self:UnregisterAllEvents()
end

-- ---------------------
-- Frame methods
-- ---------------------

function mod:ApplySettings()
	if not self:IsEnabled() then return end

	if hunParent then
		local db = db.profile.glutton
		local back = {}
		
		-- hunParent, to which all our stuff is anchored
		hunParent:ClearAllPoints()
		if not db.x then
			db.x = (UIParent:GetWidth() / 2 - (db.width * (db.scale/100.0)) / 2) / (db.scale/100.0)
		end
		hunParent:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', db.x, db.y)
		
		if db.border == "None" then
			hunParent:SetWidth(db.width)
			hunParent:SetHeight(db.height)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.insets = { top = 0, right = 0, bottom = 0, left = 0 }
		else
			hunParent:SetWidth(db.width + 9)
			hunParent:SetHeight(db.height + 10)
			
			back.bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
			back.tile = true
			back.tileSize = 16
			back.edgeFile = Media:Fetch('border', db.border)
			back.edgeSize = 16
			back.insets = { top = 4, right = 4, bottom = 4, left = 4 }
		end
		hunParent:SetBackdrop(back)
		hunParent:SetBackdropColor(unpack(db.backColor))
		
		hunParent:SetAlpha(db.alpha)
		hunParent:SetScale(db.scale / 100.0)
		
		-- hunBar, the actual timer bar
		hunBar:ClearAllPoints()
		hunBar:SetPoint('CENTER', hunParent, 'CENTER')
		hunBar:SetWidth(db.width)
		hunBar:SetHeight(db.height)
		hunBar:SetStatusBarTexture(Media:Fetch('statusbar', db.texture))
		hunBar:SetMinMaxValues(0, 1)
		hunBar:SetStatusBarColor(unpack(db.barColor))
		hunBar:Show()
		
		-- hunTimeText, countdown timer text
		hunTimeText:ClearAllPoints()
		if db.textPosition == 1 then -- LEFT
			hunTimeText:SetPoint('LEFT', hunParent, 'LEFT', 5, 0)
			hunTimeText:SetJustifyH("LEFT")
		elseif db.textPosition == 2 then -- CENTER
			hunTimeText:SetPoint('CENTER', hunParent, 'CENTER')
			hunTimeText:SetJustifyH("CENTER")
		elseif db.textPosition == 3 then -- RIGHT
			hunTimeText:SetPoint('RIGHT', hunParent, 'RIGHT', -5, 0)
			hunTimeText:SetJustifyH("RIGHT")
		end
		hunTimeText:SetFont(Media:Fetch('font', db.textFont), db.textSize)
		hunTimeText:SetTextColor(unpack(db.textColor))
		hunTimeText:SetShadowColor(0, 0, 0, 1)
		hunTimeText:SetShadowOffset(0.8, -0.8)
		hunTimeText:SetNonSpaceWrap(false)
		if db.textShow then
			hunTimeText:Show()
		else
			hunTimeText:Hide()
		end
		
		self:CheckVisibility(true)
		
		-- If we're not already running a timer, set some sane default values
		-- These are used when the user unlocks the bar, they can get an idea of
		-- what it'll look like. But we don't want to change these values when the
		-- bar's running!
		if not self.running and not self.locked then
			resetValues = true

			hunBar:SetValue(0.30)
			hunTimeText:SetText(L["Glutton"])
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
		-- We're unlocked and want to give the user something to drag/test settings with
		if not self.locked then
			visible = true
		end
	end
	
	if perform then
		if visible then
			hunParent:Show()
		else
			hunParent:Hide()
		end
	end
	
	return visible
end

function mod:StartBar()
	self.startTime = GetTime()
	self.endTime = self.startTime + maxTime
	self.running = true

	hunBar:SetValue(1)
	hunParent:Show() -- Might not be shown if potentialShow is disabled
end

-- ---------------------
-- Debugging
-- ---------------------

function mod:TestBar()
	if not self:IsEnabled() then return end
	
	hunBar:SetValue(0)
	self:StartBar()
end

-- ---------------------
-- Bonus scanning
-- ---------------------

function mod:ScanTalent()
	local talent, _, _, _, rank = GetTalentInfo(1, 27)

	if rank == 0 then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	
	hunRank = rank
end

-- ---------------------
-- Events
-- ---------------------

function mod:ACTIVE_TALENT_GROUP_CHANGED()
	self:ScanTalent()
end

function mod:PLAYER_TALENT_UPDATE()
	self:ScanTalent()
end

function mod:CHARACTER_POINTS_CHANGED()
	self:ScanTalent()
end

function mod:PLAYER_ALIVE()
	-- player logged in or alive after logging in talents ready to be read
	self:UnregisterEvent("PLAYER_ALIVE")
	self:ScanTalent()
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, _, eventType, _, srcName, _, _, dstName, _, spellId, spellName, _, ...)
	-- Event wasn't from us
	if srcName ~= playerName or spellId ~= 63848 then
		return
	end

	if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
		self.startTime = GetTime()
		self.endTime = self.startTime + maxTime
		self.running = true
		hunBar:SetValue(1)
		hunParent:Show() 
	end
	if eventType == "SPELL_AURA_REMOVED" then
		self.running = false
		hunParent:Hide()
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
		db.profile.glutton[t[#t]] = value
		self:ApplySettings()
	end
	local function get(t)
		return db.profile.glutton[t[#t]]
	end
	
	local function setcolor(t, ...)
		db.profile.glutton[t[#t]] = {...}
		self:ApplySettings()
	end
	local function getcolor(t)
		return unpack(db.profile.glutton[t[#t]])
	end
	
	local function dragstart()
		hunParent:StartMoving()
	end
	local function dragstop()
		db.profile.glutton.x = hunParent:GetLeft()
		db.profile.glutton.y = hunParent:GetBottom()
		hunParent:StopMovingOrSizing()
	end
	
	local function testbar()
		self:TestBar()
	end
	
	-- Select tables
	local textPosition = { L["Left"], L["Center"], L["Right"] }
	
	Cutup.options.args.Glutton = {
		type = 'group',
		name = L["Glutton"],
		desc = L["Glutton_Desc"],
		icon = "Interface\\Icons\\Ability_Rogue_HungerforBlood", -- FIXME: Does nothing?
		cmdHidden = true,
		disabled = function() return not self:IsEnabled() end,
		args = {
			desc = {
				type = 'description',
				name = "  " .. L["Glutton_Desc"] .. "\n\n",
				order = 1,
				cmdHidden = true,
				image = "Interface\\Icons\\Ability_Rogue_HungerforBlood",
				imageWidth = 16, imageHeight = 16,
			},
			test = {
				type = 'execute',
				name = 'Test - DEBUGGING',
				desc = 'Test the bar without actually having Hunger For Blood up.',
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
								hunParent:EnableMouse(false)
								hunParent:SetScript('OnDragStart', nil)
								hunParent:SetScript('OnDragStop', nil)
							else
								hunParent:Show()
								hunParent:EnableMouse(true)
								hunParent:SetScript('OnDragStart', dragstart)
								hunParent:SetScript('OnDragStop', dragstop)
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
						get = function(info) return tostring(db.profile.glutton.x) end,
						set = function(info, v)
							db.profile.glutton.x = tonumber(v)
							self:ApplySettings()
						end,
						order = 109,
					},
					posY = {
						type = 'input',
						name = L["Y Position"],
						get = function(info) return tostring(db.profile.glutton.y) end,
						set = function(info, v)
							db.profile.glutton.y = tonumber(v)
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
						get = function(info) return GetLSMIndex("border", db.profile.glutton.border) end,
						set = function(info, v)
							db.profile.glutton.border = Media:List("border")[v]
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
					barColor = {
						type = 'color',
						name = L["Main color"],
						desc = L["Color of the HfB bar."],
						get = getcolor, set = setcolor,
						hasAlpha = true,
						order = 201,
						width = 'half',
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
						get = function(info) return GetLSMIndex("statusbar", db.profile.glutton.texture) end,
						set = function(info, v)
							db.profile.glutton.texture = Media:List("statusbar")[v]
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
							db.profile.glutton.textPosition = v
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
						get = function(info) return GetLSMIndex("font", db.profile.glutton.textFont) end,
						set = function(info, v)
							db.profile.glutton.textFont = Media:List("font")[v]
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