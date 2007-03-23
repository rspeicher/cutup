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
	- Bar starts when a proc is detected, not when it *lands*. This causes potential issues with resisted applications.
]]

local Gratuity = AceLibrary("Gratuity-2.0")
local surface = AceLibrary("Surface-1.0")

local frame = nil
local enchants = nil
local poisonData = nil

-------------------------------------------------------------------------------
-- Localization                                                              --
-------------------------------------------------------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Cutup_TickToxin")

L:RegisterTranslations("enUS", function() return {
	["Crippling Poison"] = true,
	["Deadly Poison"] = true,
	["Mind-Numbing Poison"] = true,
	["Wound Poison"] = true,
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
			--[[
			header = {
				type = "header",
				name = "TickToxin",
				order = 1,
			},
			]]
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
						min = 10, max = 40, step = 2,
						order = 3,
					},
					texture = {
						type = "text",
						name = "Texture",
						desc = "Change bar texture",
						validate = surface:List(),
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
						order = 8,
					},		
					test = {
						type = "execute",
						name = "Test",
						desc = "Display test bars",
						order = 7,
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

	enchants = { 
		mh = {
			enchant = nil,
			charges = 0,
		},
		oh = {
			enchant = nil,
			charges = 0
		} 
	}
	poisonData = {
		[L["Crippling Poison"]] = { 12, "Interface\\Icons\\Ability_PoisonSting" },
		[L["Deadly Poison"]] = { 12, "Interface\\Icons\\Ability_Rogue_DualWeild" }, -- Did they actually misspell Wield?
		[L["Mind-Numbing Poison"]] = { 14, "Interface\\Icons\\Spell_Nature_NullifyDisease" },
		[L["Wound Poison"]] = { 15, "Interface\\Icons\\INV_Misc_Herb_16" },
	}
end

function mod:OnEnable()
	self:CreateAnchor()

	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")

	self:RegisterEvent("Surface_SetGlobal", "UpdateActiveBars")
end

function mod:OnDisable()
	frame:Hide()
	frame = nil
end

-------------------------------------------------------------------------------
-- Addon Methods                                                             --
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
	name = name:gsub(" ", "")
	if not text then
		self:RegisterCandyBar(name, duration, name, icon, color)
	else
		self:RegisterCandyBar(name, duration, text, icon, color)
	end
	
	self:SetCandyBarTexture(name, surface:Fetch(self.db.profile.texture))
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
	--[[
	for i=1, #self.activebars, 1 do
		local value = self.activebars[i]
		self:SetCandyBarTexture(value, self.textures[self.db.profile.texture] or self.textures.default)
		self:SetCandyBarWidth(value, self.db.profile.width)
		self:SetCandyBarHeight(value, self.db.profile.height)
		self:SetCandyBarFontSize(value, self.db.profile.fontsize)
		self:SetCandyBarScale(value, self.db.profile.scale)
		self:UpdateCandyBarGroup("TickToxinBottom")
		self:UpdateCandyBarGroup("TickToxinTop")
	end
	]]
end

function mod:UpdateEnchants()
	local mhHasEnchant, _, mhCharges, ohHasEnchant, _, ohCharges = GetWeaponEnchantInfo()
	local mhEnchant, ohEnchant = nil, nil
	
	if mhHasEnchant then
		mhEnchant = self:GetEnchantName(GetInventorySlotInfo("MainHandSlot"))
		
		-- Our enchant is the same as before, but the charges are less. Start a tick!
		-- BUG: On the first application our enchant won't be the same as before, because it was nil
		if enchants.mh.enchant == mhEnchant and mhCharges < enchants.mh.charges then
			self:ToxinTick(mhEnchant)
		end
		
		enchants.mh.enchant = mhEnchant
		enchants.mh.charges = mhCharges
	end
	
	if ohHasEnchant then
		ohEnchant = self:GetEnchantName(GetInventorySlotInfo("SecondaryHandSlot"))
		
		if enchants.oh.enchant == ohEnchant and ohCharges < enchants.oh.charges then
			self:ToxinTick(ohEnchant)
		end
		
		enchants.oh.enchant = ohEnchant
		enchants.oh.charges = ohCharges
	end
end

-- Inspired by PoisonFu
function mod:GetEnchantName(id)
	Gratuity:SetInventoryItem("player", id)
	for i=1, Gratuity:NumLines() do
		-- BUG: Won't work with Crippling Poison because it doesn't have charges. But I'm not smart enough to fix it with a single regex.
		-- Then again, we're using charges to detect a new application of a poison, and because Crippling doesn't have charges,
		-- it won't work either way!
		local buffname = select(3, Gratuity:GetLine(i):find("^(.+) %(%d+ [^%)]+%) %(%d+ [^%)]+%)$"))
		if buffname then
			return buffname
		end
	end
end

function mod:ToxinTick(enchant)
	if enchant == nil then return end
	
	enchant = enchant:gsub(" .I*V*I*$", "") -- Remove Roman numerals from the name
	
	if poisonData[enchant] ~= nil then
		local data = poisonData[enchant]
		self:StartBar(enchant, data[1], data[2], "green")
	end
end

-------------------------------------------------------------------------------
-- Events                                                                    --
-------------------------------------------------------------------------------

function mod:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function mod:PLAYER_LEAVING_WORLD()
	-- Does this do anything? Dunno!
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function mod:UNIT_INVENTORY_CHANGED( arg1 )
	if arg1 == "player" then
		self:UpdateEnchants()
	end
end
