if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_Spam
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Inspired By: RogueSpam by Allara (http://www.curse-gaming.com/en/wow/addons-924-1-roguespam.html)
Description: A module for Cutup that blocks spammed Rogue-specific messages in UIErrorsFrame.
]]

-------------------------------------------------------------------------------
-- Localization                                                              --
-------------------------------------------------------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Cutup_Spam")

L:RegisterTranslations("enUS", function() return {
	["Ability is not ready yet."]          = true,
	["Not enough energy"]                  = true,
	["There is nothing to attack."]        = true,
	["That ability requires combo points"] = true,
	["Your target is dead."]               = true,
	["Another action is in progress"]      = true,
} end)

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

local mod = Cutup:NewModule("Spam")

function mod:OnInitialize()
	self.db = Cutup:AcquireDBNamespace("Spam")
	
	Cutup:RegisterDefaults("Spam", "profile", {
		on = true,
		msg = {
			notready   = true,	-- Ability is not ready yet.
			energy     = true,	-- Not enough energy
			notarget   = true,	-- There is nothing to attack.
			combo      = true,	-- That ability requires combo points
			dead       = true,	-- Your target is dead.
			inprogress = true,	-- Another action is in progress
		},
	})
	
	Cutup.Options.args.Spam = {
		type = "group",
		name = "Spam",
		desc = "Block spammed Rogue-specific messages in UIErrorsFrame.",
		args = {
			Messages = {
				type = "group",
				name = "Messages",
				desc = "Messages to block",
				pass = true,
				get = function(key)
					return self.db.profile.msg[key]
				end,
				set = function(key, value)
					self.db.profile.msg[key] = value
				end,
				args = {
					notready = {
						type = "toggle",
						name = L["Ability is not ready yet."],
						desc = L["Ability is not ready yet."],
					},
					energy = {
						type = "toggle",
						name = L["Not enough energy"],
						desc = L["Not enough energy"],
					},
					notarget = {
						type = "toggle",
						name = L["There is nothing to attack."],
						desc = L["There is nothing to attack."],
					},
					combo = {
						type = "toggle",
						name = L["That ability requires combo points"],
						desc = L["That ability requires combo points"],
					},
					dead = {
						type = "toggle",
						name = L["Your target is dead."],
						desc = L["Your target is dead."],
					},
					inprogress = {
						type = "toggle",
						name = L["Another action is in progress"],
						desc = L["Another action is in progress"],
					},
				},
			},
			Toggle = {
				type = "toggle",
				name = "Toggle",
				desc = "Toggle the module on and off.",
				get = function() return self.db.profile.on end,
				set = function(v) self.db.profile.on = Cutup:ToggleModuleActive("Spam") end,
			},
		}
	}
end

function mod:OnEnable()
	self:Hook("UIErrorsFrame_OnEvent", true)
end

function mod:OnDisable()
	self:UnhookAll()
end

-------------------------------------------------------------------------------
-- Addon Methods                                                             --
-------------------------------------------------------------------------------

function mod:UIErrorsFrame_OnEvent( event, msg, ... )
	if self.db.profile.on then
		local opt = Cutup.Options.args.Spam.args.Messages
		for k, v in pairs(opt.args) do
			if opt.get(k) and msg == v.desc then
				return
			end
		end
	end
	
	self.hooks.UIErrorsFrame_OnEvent(event, msg, ...)
end
