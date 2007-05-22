if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_TickToxin
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that times poison applications.
Inspired By: A lot of the CandyBar-related code was ripped from HotMan.
]]

--[[
TODO:
	- Bars don't disappear when your target dies. Should they? Can they?
	- Bars don't account for different targets. Rogues don't often poison multiple targets anyway.
	- Deadly Poison bar will continue to tick even if your DP was removed via Envenom. I doubt there's an easy way around this.
]]

local Gratuity = AceLibrary("Gratuity-2.0")
local SM = AceLibrary("SharedMedia-1.0")

local frame = nil
local activebars = {}

-------------------------------------------------------------------------------
-- Localization                                                              --
-------------------------------------------------------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Cutup_TickToxin")

L:RegisterTranslations("enUS", function() return {
	["Poison"] = true,
} end)

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

local mod = Cutup:NewModule("TickToxin", "CandyBar-2.0")

function mod:OnInitialize()
	self.db = Cutup:AcquireDBNamespace("TickToxin")
	
	Cutup:RegisterDefaults("TickToxin", "profile", {
		on = true,
		
		texture = "Smooth",
		fontsize = 10,
		width = 200,
		height = 16,
		scale = 1,
		growup = false,
	})
	
	Cutup.Options.args.TickToxin = {
		type = "group",
		name = "TickToxin",
		desc = "Poison application timer.",
		args = {
			anchor = {
				type = "execute",
				name = "Show/Hide Anchor",
				desc = "Show/Hide the bar anchor",
				func = function() 
					if TickToxinFrame:IsVisible() then 
						TickToxinFrame:Hide()
					else 
						TickToxinFrame:Show()
					end 
				end,
				order = 2,
			},
			bars = {
				type = "group",
				name = "Bar",
				desc = "Bar options",
				order = 5,
				pass = true,
				get = function(key)
					return self.db.profile[key]
				end,
				set = function(key, value)
					self.db.profile[key] = value
					self:UpdateActiveBars()
				end,
				func = function() -- Only used by test.
					self:StartBar("Main Hand", 30, "Interface\\Icons\\Ability_ThunderBolt", "lightgrey")
					self:StartBar("Off Hand", 45, "Interface\\Icons\\Ability_ThunderBolt", "lightgrey")
				end,
				args = {
					scale = {
						type = "range",
						name = "Scale",
						desc = "Change bar scale",
						min = 0.5, max = 2, step = 0.1,
						order = 1,
					},
					width = {
						type = "range",
						name = "Width",
						desc = "Change bar width",
						min = 50, max = 300, step = 5,
						order = 2,
					},
					height = {
						type = "range",
						name = "Height",
						desc = "Change bar height",
						min = 10, max = 40, step = 1,
						order = 3,
					},
					texture = {
						type = "text",
						name = "Texture",
						desc = "Change bar texture",
						validate = SM:List("statusbar"),
						order = 4,
					},
					fontsize = {
						type = "range",
						name = "Font size",
						desc = "Change bar text font size",
						min = 8, max = 20, step = 0.2,
						order = 5,
					},
					growup = {
						type = "toggle",
						name = "Grow bar group upwards",
						desc = "Grows bar group upwards (i.e. new bars will be added at the top)",
						order = 7,
					},		
					test = {
						type = "execute",
						name = "Test",
						desc = "Display test bars",
						order = 8,
					},
				},
			},
			toggle = {
				type = "toggle",
				name = "Toggle",
				desc = "Toggle the module on and off.",
				get = function() return self.db.profile.on end,
				set = function(v) self.db.profile.on = Cutup:ToggleModuleActive("TickToxin") end,
			},
		},
	}
end

function mod:OnEnable()
	self:CreateAnchor()

	self:RegisterBucketEvent("UNIT_AURA", 0.2)
end

function mod:OnDisable()
	frame:Hide()
	frame = nil
end

-------------------------------------------------------------------------------
-- Bar/Anchor Methods                                                        --
-------------------------------------------------------------------------------

-- creates the statusbar anchor and registers candybar group
-- Ripped from HotMan
function mod:CreateAnchor()
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
function mod:StartBar(name, duration, icon, color, text)
	if not text then text = name end
	self:RegisterCandyBar(name, duration, text, icon, color)
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

function mod:UpdateActiveBars()
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

function mod:StoreActiveBar(barName)
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

function mod:UpdateTargetAuras()
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

function mod:ToxinTick(enchant, icon, duration, timeLeft, text)
	if enchant == nil then return end
	enchant = self:RemoveNumerals(enchant)
	
	local barName = enchant:gsub(" ", "")
	local barDuration = 0
	local barReg, barTime, barElapsed, _ = self:CandyBarStatus(barName)
	
	if not barReg then
		self:StartBar(barName, duration, icon, "green", text)
	else
		self:SetCandyBarTime(barName, duration)
		self:SetCandyBarTimeLeft(barName, timeLeft)
		self:SetCandyBarText(barName, text)
	end
end

function mod:RemoveNumerals(enchant)
	if enchant == nil then return end
	
	return enchant:gsub(" .I*V*I*$", "")
end

-------------------------------------------------------------------------------
-- Events                                                                    --
-------------------------------------------------------------------------------

function mod:UNIT_AURA(units)
	for unit in pairs(units) do
		if unit == "target" then self:UpdateTargetAuras() end
	end
end