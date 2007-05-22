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
	["Spam"] = true,
	["Block spammed Rogue-specific messages in UIErrorsFrame."] = true,
	["Messages"] = true,
	["Messages to block"] = true,
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
		name = L["Spam"],
		desc = L["Block spammed Rogue-specific messages in UIErrorsFrame."],
		args = {
			Messages = {
				type = "group",
				name = L["Messages"],
				desc = L["Messages to block"],
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
						name = ERR_ABILITY_COOLDOWN,
						desc = ERR_ABILITY_COOLDOWN,
					},
					energy = {
						type = "toggle",
						name = ERR_OUT_OF_ENERGY,
						desc = ERR_OUT_OF_ENERGY,
					},
					notarget = {
						type = "toggle",
						name = ERR_NO_ATTACK_TARGET,
						desc = ERR_NO_ATTACK_TARGET,
					},
					combo = {
						type = "toggle",
						name = SPELL_FAILED_NO_COMBO_POINTS,
						desc = SPELL_FAILED_NO_COMBO_POINTS,
					},
					dead = {
						type = "toggle",
						name = SPELL_FAILED_TARGETS_DEAD,
						desc = SPELL_FAILED_TARGETS_DEAD,
					},
					inprogress = {
						type = "toggle",
						name = SPELL_FAILED_SPELL_IN_PROGRESS,
						desc = SPELL_FAILED_SPELL_IN_PROGRESS,
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

function mod:UIErrorsFrame_OnEvent(event, msg, ...)
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
