if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A collection of Rogue modules.
Inspired By: Modular design of Quartz.
]]

local L = AceLibrary("AceLocale-2.2"):new("Cutup")

Cutup = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceEvent-2.0", "AceHook-2.1", "AceModuleCore-2.0", "AceDebug-2.0")
Cutup:SetModuleMixins("AceEvent-2.0", "AceHook-2.1", "AceDebug-2.0")
Cutup:RegisterDB("CutupDB")
local self = Cutup

local options

function Cutup:OnInitialize()
	-- Quartz goodness
	if AceLibrary:HasInstance("Waterfall-1.0") then
		AceLibrary("Waterfall-1.0"):Register('Cutup',
			'aceOptions', options,
			'title', L["Cutup"],
			'treeLevels', 2,
			'colorR', 0.2, 'colorG', 0.8, 'colorB', 0.2
		)
		self:RegisterChatCommand({"/cutup"}, function()
			AceLibrary("Waterfall-1.0"):Open('Cutup')
		end)
		if AceLibrary:HasInstance("Dewdrop-2.0") then
			self:RegisterChatCommand({"/cutupdd"}, function()
				AceLibrary("Dewdrop-2.0"):Open('Cutup', 'children', function()
					AceLibrary("Dewdrop-2.0"):FeedAceOptionsTable(options)
				end)
			end)
		end
		self:RegisterChatCommand({"/cutupcl"}, options)
	elseif AceLibrary:HasInstance("Dewdrop-2.0") then
		self:RegisterChatCommand({"/cutup"}, function()
			AceLibrary("Dewdrop-2.0"):Open('Cutup', 'children', function()
				AceLibrary("Dewdrop-2.0"):FeedAceOptionsTable(options)
			end)
		end)
	else
		self:RegisterChatCommand({"/cutup"}, options)
	end
	
	self:RegisterDefaults("profile", {
	})
end

function Cutup:OnDisable()
	for name, module in self:IterateModules() do
		self:ToggleModuleActive(module, false)
	end
end

function Cutup:OnDebugEnable()
	self:Debug("Debug enabled.")
	
	for name, mod in self:IterateModules() do
		mod:SetDebugging(true)
	end
end

function Cutup:OnDebugDisable()
	self:Debug("Debug disabled.")
	
	for name, mod in self:IterateModules() do
		mod:SetDebugging(false)
	end
end

do
	options = {
		type = "group",
		name = L["Cutup"],
		desc = L["A collection of Rogue modules."],
		args = { },
	}
	
	Cutup.options = options
end