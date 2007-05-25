if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_TickToxin
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that times poison applications.
Inspired By: A lot of the CandyBar-related code was ripped from HotMan.

TODO:
	- Bars don't disappear when your target dies. Should they? Can they?
	- Bars don't account for different targets. Rogues don't often poison multiple targets anyway.
	- Deadly Poison bar will continue to tick even if your DP was removed via Envenom. I doubt there's an easy way around this.
]]

local Cutup = Cutup
if Cutup:HasModule('TickToxin') then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cutup")
local Gratuity = AceLibrary("Gratuity-2.0")
local SM = AceLibrary("SharedMedia-1.0")

local CutupTickToxin = Cutup:NewModule('TickToxin', 'CandyBar-2.0')
local self = CutupTickToxin

local frame, db
local activebars = {}

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

function CutupTickToxin:OnInitialize()
	db = Cutup:AcquireDBNamespace("TickToxin")
	self.db = db
	
	Cutup:RegisterDefaults("TickToxin", "profile", {
		width = 200,
		height = 16,
		scale = 1,
		
		fontsize = 10,
		
		texture = 'Cilo',
		growup = false,
	})
end

function CutupTickToxin:OnEnable()
	self:CreateAnchor()

	self:RegisterBucketEvent("UNIT_AURA", 0.2)
end

function CutupTickToxin:OnDisable()
	frame:Hide()
	frame = nil
end

-------------------------------------------------------------------------------
-- Bar/Anchor Methods                                                        --
-------------------------------------------------------------------------------

-- creates the statusbar anchor and registers candybar group
-- Ripped from HotMan
function CutupTickToxin:CreateAnchor()
	if frame then return end
	frame = CreateFrame("Button", "TickToxinFrame", UIParent)
	frame:SetHeight(16)
	frame:SetWidth(200)
	frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true, tileSize = 16,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	frame:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:RegisterForClicks("RightButtonUp")
	frame:SetScript("OnDragStart", function() this:StartMoving() end)
	frame:SetScript("OnDragStop", function() 
		this:StopMovingOrSizing()
		local a,b,c,d,e = this:GetPoint()
		if a == "TOPLEFT" and c == "TOPLEFT" then
			self.db.profile.x = floor(d + 0.5)
			self.db.profile.y = floor(e + 0.5)
		end
	end)
	frame:SetClampedToScreen(true)
	
	frame:Hide()
	
	frame.text = frame:CreateFontString("TickToxinFrameText", "OVERLAY")
	frame.text:SetFont(GameFontHighlightSmall:GetFont())
	frame.text:SetText("TickToxin")
	frame.text:ClearAllPoints()
	frame.text:SetAllPoints(frame)
	
	if not self.db.profile.x then
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
	else
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.profile.x, self.db.profile.y)
	end
	
	self:RegisterCandyBarGroup("TickToxinBottom")
	self:SetCandyBarGroupPoint("TickToxinBottom", "TOPLEFT", frame, "TOPLEFT", 0, -15)
	
	self:RegisterCandyBarGroup("TickToxinTop")
	self:SetCandyBarGroupPoint("TickToxinTop", "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 15)
	self:SetCandyBarGroupGrowth("TickToxinTop", true)
end

-- Ripped from HotMan
function CutupTickToxin:StartBar(name, duration, text, icon)
	self:Debug("StartBar", name)
	if not text then text = name end
	self:RegisterCandyBar(name, duration, text, icon, "green")
	self:StoreActiveBar(name)
	
	self:SetCandyBarTexture(name, SM:Fetch("statusbar", self.db.profile.texture))
	self:SetCandyBarWidth(name, self.db.profile.width)
	self:SetCandyBarHeight(name, self.db.profile.height)
	self:SetCandyBarFontSize(name, self.db.profile.fontsize)
	self:SetCandyBarScale(name, self.db.profile.scale)
	self:SetCandyBarBackgroundColor(name, "Grey", 0.6)
	
	if self.db.profile.growup then
		self:RegisterCandyBarWithGroup(name, "TickToxinTop")
	else
		self:RegisterCandyBarWithGroup(name, "TickToxinBottom")
	end
	
	self:StartCandyBar(name, true)
end

function CutupTickToxin:UpdateActiveBars()
	for i=1, #activebars do
		local value = activebars[i]
		self:SetCandyBarTexture(value, SM:Fetch("statusbar", self.db.profile.texture))
		self:SetCandyBarWidth(value, self.db.profile.width)
		self:SetCandyBarHeight(value, self.db.profile.height)
		self:SetCandyBarFontSize(value, self.db.profile.fontsize)
		self:SetCandyBarScale(value, self.db.profile.scale)
		self:UpdateCandyBarGroup("TickToxinBottom")
		self:UpdateCandyBarGroup("TickToxinTop")
	end
end

function CutupTickToxin:StoreActiveBar(barName)
	for i=1, #activebars do
		if activebars[i] == barName then
			return
		end
	end

	table.insert(activebars, barName)
end

-------------------------------------------------------------------------------
-- Addon Methods                                                             --
-------------------------------------------------------------------------------

function CutupTickToxin:UpdateTargetAuras()
	local name, rank, icon, count, debuffType, duration, timeLeft
	local text
	
	for i=1, MAX_TARGET_DEBUFFS do
		name, rank, icon, count, debuffType, duration, timeLeft = UnitDebuff("target", i)
		
		if timeLeft and debuffType == "Poison" and name:find("^.*" .. L["Poison"] .. ".*$") then
			text = ((count ~= 0) and string.format("%s (%s)", name, count) or name)
			self:ToxinTick(name, icon, duration, timeLeft, text)
		end
	end
end

function CutupTickToxin:ToxinTick(enchant, icon, duration, timeLeft, text)
	if enchant == nil then return end
	enchant = self:RemoveNumerals(enchant)
	
	local barName = enchant:gsub(" ", "")
	local barDuration = 0
	local barReg, barTime, barElapsed, _ = self:CandyBarStatus(barName)
	
	if not barReg then
		self:StartBar(barName, duration, text, icon)
	else
		self:SetCandyBarTime(barName, duration)
		self:SetCandyBarTimeLeft(barName, timeLeft)
		self:SetCandyBarText(barName, text)
	end
end

function CutupTickToxin:RemoveNumerals(enchant)
	if enchant == nil then return end
	
	return enchant:gsub(" .I*V*I*$", "")
end

-------------------------------------------------------------------------------
-- Events                                                                    --
-------------------------------------------------------------------------------

function CutupTickToxin:UNIT_AURA(units)
	for unit in pairs(units) do
		if unit == "target" then self:UpdateTargetAuras() end
	end
end

do
	local function toggleanchor()
		if frame:IsVisible() then
			frame:Hide()
			
			self:UnregisterCandyBar('Test1', 'Test2')
		else
			frame:Show()
			
			self:StartBar('Test1', 45, 'Main Hand', "Interface\\Icons\\Ability_ThunderBolt")
			self:StartBar('Test2', 75, 'Off Hand', "Interface\\Icons\\Ability_ThunderBolt")
		end
	end
	local function set(field, value)
		db.profile[field] = value
		self:UpdateActiveBars()
	end
	local function get(field)
		return db.profile[field]
	end
	Cutup.options.args.TickToxin = {
		type = "group",
		name = L["TickToxin"],
		desc = L["Poison application timer"],
		args = {
			toggle = {
				type = 'toggle',
				name = L["Enable"],
				desc = L["Enable"],
				get = function()
					return Cutup:IsModuleActive('TickToxin')
				end,
				set = function(v)
					Cutup:ToggleModuleActive('TickToxin', v)
				end,
				order = 100,
			},
			anchor = {
				type = 'execute',
				name = L["Toggle anchor"],
				desc = L["Toggle anchor"],
				func = toggleanchor,
				order = 101,
			},
			
			header1 = {
				type = 'header',
				order = 200,
			},
			
			width = {
				type = 'range',
				name = L["Width"],
				desc = L["Width"],
				get = get,
				set = set,
				passValue = 'width',
				min = 25, max = 500, step = 5,
				order = 201,
			},
			height = {
				type = 'range',
				name = L["Height"],
				desc = L["Height"],
				get = get,
				set = set,
				passValue = 'height',
				min = 8, max = 40, step = 1,
				order = 202,
			},
			scale = {
				type = 'range',
				name = L["Scale"],
				desc = L["Scale"],
				get = get,
				set = set,
				passValue = 'scale',
				min = 0.5, max = 2, step = 0.1,
				order = 203,
			},

			header2 = {
				type = 'header',
				order = 204,
			},
			
			fontsize = {
				type = 'range',
				name = L["Font size"],
				desc = L["Font size"],
				get = get,
				set = set,
				passValue = 'fontsize',
				min = 8, max = 20, step = 0.2,
				order = 205,
			},
			
			header3 = {
				type = 'header',
				order = 206,
			},
			
			texture = {
				type = 'text',
				name = L["Texture"],
				desc = L["Texture"],
				get = get,
				set = set,
				passValue = 'texture',
				validate = SM:List('statusbar'),
				order = 207,
			},
			growup = {
				type = 'toggle',
				name = L["Grow up"],
				desc = L["Add new bars on top of existing bars rather than below."],
				get = get,
				set = set,
				passValue = 'growup',
				order = 208,
			},
		},
	}
end