if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_TickToxin
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that times poison applications.
]]

local mod = Cutup:NewModule("TickToxin", nil, "AceEvent-3.0", "AceConsole-3.0", "LibBars-1.0")
local Media = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")
local self = mod
local db

local poisons = {
	3408,  -- Crippling
	2823,  -- Deadly
	5761,  -- Mind-numbing
	13219, -- Wound
}

local defaults = {
	profile = {
		ticktoxin = {
			locked      = false,
			scale       = 100.0,
			texture     = "Smooth v2",
			growUp      = false,
			clamped     = true,
			fontFace    = nil,
			fontSize    = 10,
			orientation = 1,
			alpha       = 100.0,
			
			width  = 150,
			height = 14,
			
			poisons = {
				[3408]  = { track = true, color = { 0, 0.35, 0, 1 } },
				[2823]  = { track = true, color = { 0, 0.35, 0, 1 } },
				[5761]  = { track = true, color = { 0, 0.35, 0, 1 } },
				[13219] = { track = true, color = { 0, 0.35, 0, 1 } },
			},
		}
	}
}

-- Frames
local barGroup = nil
local function sortFunc(a, b)
	if a.isTimer ~= b.isTimer then
		return a.isTimer
	end
	
	if a.value == b. value then
		return a.name > b.name
	else
		return a.value > b.value
	end
end

-- Localized functions

function mod:OnInitialize()
	db = LibStub("AceDB-3.0"):New("CutupDB", nil, "Default")
	self.db = db
	
	self.db:RegisterDefaults(defaults)
	
	self:SetEnabledState(false)
end

function mod:OnEnable()
	self:RegisterEvent("PLAYER_LOGIN")
	self:CreateFrame()
end

function mod:OnDisable()
	self:UnregisterAllEvents()
end

-- ---------------------
-- Bar methods
-- ---------------------

function mod:Test()
	mod:StartCooldown(L["TickToxin"] .. " 1", 27188, 45)
	mod:StartCooldown(L["TickToxin"] .. " 2", 27186, 30)
end

function mod:StartCooldown(sender, spellId, cooldown)
	local bar = barGroup:NewTimerBar((sender .. "_" .. spellId), sender, cooldown, cooldown, spellId)
	bar.caster  = sender
	bar.spellId = spellId

	local color = nil
	if type(color) == "table" then
		bar:SetColorAt(1.00, color.r, color.g, color.b, 1)
		bar:SetColorAt(0.00, color.r, color.g, color.b, 1)
	end
end

function mod:CreateFrame()
	barGroup = nil
	
	barGroup = self:NewBarGroup(L["TickToxin"], nil, self.db.profile.ticktoxin.width, self.db.profile.ticktoxin.height, "TickToxin_Anchor")
	--[[
	barGroup:SetColorAt(1.00, 1, 0, 0, 1)
	barGroup:SetColorAt(0.66, 1, 1, 0, 1)
	barGroup:SetColorAt(0.33, 0, 1, 1, 1)
	barGroup:SetColorAt(0.00, 0, 0, 1, 1)
	]]
	barGroup:SetFlashPeriod(0)
	barGroup:SetSortFunction(sortFunc)
	
	-- Callbacks
	barGroup.RegisterCallback(self, "AnchorClicked")
	barGroup.RegisterCallback(self, "AnchorMoved")
end

function mod:UpdateDisplay()
	if not barGroup then return end
	
	if self.db.profile.ticktoxin.locked then
		barGroup:Lock()
		barGroup:HideAnchor()
	else
		barGroup:Unlock()
		barGroup:ShowAnchor()
	end

	barGroup:SetOrientation(self.db.profile.ticktoxin.orientation)
	barGroup:SetClampedToScreen(self.db.profile.ticktoxin.clamped)
	barGroup:SetFont(Media:Fetch("font", self.db.profile.ticktoxin.fontFace), self.db.profile.ticktoxin.fontSize)
	barGroup:SetTexture(Media:Fetch("statusbar", self.db.profile.ticktoxin.texture))
	barGroup:SetScale(self.db.profile.ticktoxin.scale / 100.0)
	barGroup:ReverseGrowth(self.db.profile.ticktoxin.growUp)
	barGroup:SetAlpha(self.db.profile.ticktoxin.alpha / 100.0)
	barGroup:SetWidth(self.db.profile.ticktoxin.width)
	barGroup:SetHeight(self.db.profile.ticktoxin.height)
end

-- Omen rip
function mod:SetAnchors(useDB)
	local t = self.db.profile.ticktoxin.growUp
	local x, y
	if useDB then
		x, y = self.db.profile.ticktoxin.posX, self.db.profile.ticktoxin.posY
		if not x and not y then
			barGroup:ClearAllPoints()
			barGroup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			return
		end
	elseif t then
		x, y = barGroup:GetLeft(), barGroup:GetBottom()
	else
		x, y = barGroup:GetLeft(), barGroup:GetTop()
	end
	barGroup:ClearAllPoints()
	if t then
		barGroup:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	else
		barGroup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	end
	self.db.profile.ticktoxin.posX, self.db.profile.ticktoxin.posY = x, y
end

function mod:AnchorClicked(cbk, group, button)
	if button == "RightButton" then
		Cutup:ShowConfig()
	end
end

function mod:AnchorMoved(cbk, group, x, y)
	self:SetAnchors()
end

-- ---------------------
-- Events
-- ---------------------

function mod:PLAYER_LOGIN()
	self:SetAnchors(true)
	self:UpdateDisplay()
	self:UnregisterEvent("PLAYER_LOGIN")
end

-- ---------------------
-- Options
-- ---------------------

do
	local textures = Media:List("statusbar")
	local fonts = Media:List("font")

	local function GetLSMIndex(t, value)
		for k, v in pairs(Media:List(t)) do
			if v == value then
				return k
			end
		end
		return nil
	end

	local function set(t, value)
		db.profile.ticktoxin[t[#t]] = value
		self:UpdateDisplay()
	end
	local function get(t)
		return db.profile.ticktoxin[t[#t]]
	end
	
	local function setcolor(t, ...)
		db.profile.ticktoxin[t[#t]] = {...}
		self:UpdateDisplay()
	end
	local function getcolor(t)
		return unpack(db.profile.ticktoxin[t[#t]])
	end
	
	local function dragstart()
		sndParent:StartMoving()
	end
	local function dragstop()
		db.profile.ticktoxin.x = sndParent:GetLeft()
		db.profile.ticktoxin.y = sndParent:GetBottom()
		sndParent:StopMovingOrSizing()
	end
	
	local function testbar()
		self:TestBar()
	end
	
	-- Select tables
	local textPosition = { L["Left"], L["Center"], L["Right"] }
	
	Cutup.options.args.TickToxin = {
		type = 'group',
		name = L["TickToxin"],
		desc = L["TickToxin_Desc"],
		icon = "Interface\\Icons\\Ability_Rogue_DualWeild", -- FIXME: Does nothing?
		cmdHidden = true,
		disabled = function() return not self:IsEnabled() end,
		args = {
			desc = {
				type = 'description',
				name = "  " .. L["TickToxin_Desc"] .. "\n\n",
				order = 1,
				cmdHidden = true,
				image = "Interface\\Icons\\Ability_Rogue_DualWeild",
				imageWidth = 16, imageHeight = 16,
			},
			test = {
				type = "execute",
				name = L["Test"],
				desc = L["Test"],
				func = mod.Test,
				order = 2,
			},
			display = {
				type = "group",
				name = L["Frame"],
				cmdHidden = true,
				inline = true,
				args = {
					locked = {
						type = "toggle",
						name = L["Lock"],
						desc = L["Toggle bar lock"],
						get = get,
						set = set,
						order = 100,
					},
					growUp = {
						type = "toggle",
						name = L["Grow Up"],
						desc = L["Grow bars upwards"],
						get = get,
						set = set,
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
						min = 0, max = 100, step = 5, bigStep = 10,
						order = 107,
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
						get = function(info) return tostring(db.profile.ticktoxin.posX) end,
						set = function(info, v)
							db.profile.ticktoxin.posX = tonumber(v)
							mod:SetAnchors(true)
						end,
						order = 109,
					},
					posY = {
						type = 'input',
						name = L["Y Position"],
						get = function(info) return tostring(db.profile.ticktoxin.posY) end,
						set = function(info, v)
							db.profile.ticktoxin.posY = tonumber(v)
							mod:SetAnchors(true)
						end,
						order = 110,
					},
				},
			},
			bars = {
				type = "group",
				name = L["Bars"],
				order = 200,
				inline = true,
				args = {
					texture = {
						type = "select",
						name = L["Texture"],
						values = textures,
						get = function(info) return GetLSMIndex("statusbar", db.profile.ticktoxin.texture) end,
						set = function(info, v)
							db.profile.ticktoxin.texture = Media:List("statusbar")[v]
							mod:UpdateDisplay()
						end,
						order = 201,
					},
					orientation = {
						type = "select",
						name = L["Orientation"],
						values = { L["Right to Left"], L["Left to Right"] },
						-- "2" in LibBars is top to bottom, but we only have 2 choices, so this is a bit of a cheat
						get = function(info) return (db.profile.ticktoxin.orientation == 3) and 2 or 1 end,
						set = function(info, v)
							db.profile.ticktoxin.orientation = (v == 2) and 3 or 1
							mod:UpdateDisplay()
						end,
						order = 202,
					},
					blank1 = {
						type = 'description',
						name = '',
						order = 203,
						cmdHidden = true,
						width = "full",
					},
					fontFace = {
						type = "select",
						name = L["Text font"],
						values = fonts,
						get = function(info) return GetLSMIndex("font", db.profile.ticktoxin.fontFace) end,
						set = function(info, v)
							db.profile.ticktoxin.fontFace = Media:List("font")[v]
							mod:UpdateDisplay()
						end,
						order = 204,
					},
					fontSize = {
						type = "range",
						name = L["Text size"],
						min = 5, max = 30, step = 1, bigStep = 1,
						get = get,
						set = set,
						order = 205,
					},
				}
			},
			poisons = {
				type = "group",
				name = L["Poisons"],
				order = 300,
				inline = true,
				args = {
				},
			},
		}
	}
	
	local i = 301
	local args = Cutup.options.args.TickToxin.args.poisons.args
	for k, v in pairs(poisons) do
		local name, rank, icon = GetSpellInfo(v)
		local strid = tostring(v)
		
		-- Header
		args[strid .. "d"] = {
			type = "description",
			name = name,
			image = icon,
			imageWidth = 16, imageHeight = 16,
			order = i
		}
		-- Toggle
		args[strid .. "t"] = {
			type = "toggle",
			name = L["Track"],
			desc = L["Track %s"]:format(name),
			get = function(info) return db.profile.ticktoxin.poisons[v].track end,
			set = function(info, val)
				db.profile.ticktoxin.poisons[v].track = val
			end,
			order = i + 1,
			width = "half",
		}
		-- Color
		args[strid .. "c"] = {
			type = "color",
			name = L["Color"],
			get = function(info) return unpack(db.profile.ticktoxin.poisons[v].color) end,
			set = function(info, ...)
				db.profile.ticktoxin.poisons[v].color = {...}
			end,
			hasAlpha = true,
			order = i + 2,
			width = "half",
		}
		i = i + 3
	end
end