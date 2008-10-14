if (select(2, UnitClass("player"))) ~= "ROGUE" and (select(2, UnitClass("player"))) ~= "DRUID" then return end

--[[
Name: Cutup
Revision: $Revision: 82096 $
Author(s): tsigo (tsigo@eqdkp.com)
Description: A collection of Rogue modules.
Inspired By: Modular design of Quartz.
]]

local AceConfig = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")

Cutup = LibStub("AceAddon-3.0"):NewAddon("Cutup", "AceEvent-3.0", "AceConsole-3.0")
local self = Cutup

local options
local optFrame
function Cutup:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("CutupDB", nil, "Default")
	self.db:RegisterDefaults({
		profile = {
			modules = {},
		}
	})
	
	optFrame = AceConfig:AddToBlizOptions(L["Cutup"], L["Cutup"])
	-- FIXME: If we reset the profile, how do we make modules re-register their defaults table?
	--options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self.configOptions = options
	LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Cutup"], options)
	self:RegisterChatCommand("cutup", self.ShowConfig)
	
	self:UnregisterAllEvents()
end

function Cutup:OnEnable()
	local fmt = "|cffffffff%s - |r|cff33ff99%s|r"
	
	local name, module
	for name, module in self:IterateModules() do
		-- Create an option entry for this module to allow enable/disable
		options.args.modules.args[name] = {
			type = 'toggle',
			name = fmt:format(L[name], L[name .. "_Desc"]),
			desc = L["Toggle %s"]:format(L[name]),
			width = "full",
			get = function(info)
				return self.db.profile.modules[name] ~= false or false
			end,
			set = function(info, v)
				self.db.profile.modules[name] = v
				if v then
					self:EnableModule(name)
				else
					self:DisableModule(name)
				end
			end
		}
	
		if not module:IsEnabled() and self.db.profile.modules[name] ~= false then
			self:EnableModule(name)
		end
	end
end

function Cutup:OnDisable()
	local name, module
	for name, module in self:IterateModules() do
		self:DisableModule(name)
	end
end

function Cutup:ShowConfig()
	AceConfig:SetDefaultSize(L["Cutup"], 500, 550)
	AceConfig:Open(L["Cutup"], configFrame)
end

do
	options = {
		type = "group",
		name = L["Cutup"],
		desc = L["A collection of Rogue modules."],
		childGroups = "tab",
		args = {
			config = {
				type = "execute",
				name = L["Configure"],
				desc = L["Open the configuration dialog"],
				func = Cutup.ShowConfig,
				guiHidden = true
			},
			modules = {
				type = "group",
				name = L["Modules"],
				order = 0,
				args = {
				}
			},
		},
	}
	
	Cutup.options = options
end