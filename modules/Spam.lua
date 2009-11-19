if (select(2, UnitClass("player"))) ~= "ROGUE" and (select(2, UnitClass("player"))) ~= "DRUID" then return end

--[[
Name: Cutup_Spam
Revision: $Revision$
Author(s): ColdDoT (kevin@colddot.nl), tsigo (tsigo@eqdkp.com)
Inspired By: RogueSpam by Allara (http://www.curse-gaming.com/en/wow/addons-924-1-roguespam.html)
Description: A module for Cutup that blocks repeated Rogue-specific error messages.
]]

local mod = Cutup:NewModule("Spam", nil, "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")
local self = mod
local db

local defaults = {
	profile = {
		spam = {
			notready   = true,	-- Ability is not ready yet.
			energy     = true,	-- Not enough energy
			notarget   = true,	-- There is nothing to attack.
			combo      = true,	-- That ability requires combo points
			dead       = true,	-- Your target is dead.
			inprogress = true,	-- Another action is in progress
		}
	}
}
-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

function mod:OnInitialize()
	db = LibStub("AceDB-3.0"):New("CutupDB", nil, "Default")
	self.db = db
	
	self.db:RegisterDefaults(defaults)
	
	self:SetEnabledState(false)
end

function mod:OnEnable()
	self:RawHookScript(UIErrorsFrame, "OnEvent", "UIErrorsFrame_OnEvent", true)
end

function mod:OnDisable()
	self:UnhookAll()
end

-------------------------------------------------------------------------------
-- Addon Methods                                                             --
-------------------------------------------------------------------------------

function mod:UIErrorsFrame_OnEvent(frame, event, message, r, g, b)
	if event ~= "UI_ERROR_MESSAGE" then
		self.hooks[frame].OnEvent(frame, event, message, r, g, b)
		return
	end

	if self:IsEnabled() then
		local opt = Cutup.options.args.Spam.args
		for k, v in pairs(opt) do
			if k ~= 'desc' and db.profile.spam[k] and message == v.name then
				return
			end
		end
	end
	
	self.hooks[frame].OnEvent(frame, event, message, r, g, b)
end

do
	local function set(t, value)
		db.profile.spam[t[#t]] = value
	end
	local function get(t)
		return db.profile.spam[t[#t]]
	end
	Cutup.options.args.Spam = {
		type = 'group',
		name = L["Spam"],
		desc = L["Spam_Desc"],
		icon = "Interface\\Icons\\INV_Shield_04",
		cmdHidden = true,
		disabled = function() return not self:IsEnabled() end,
		args = {
			desc = {
				type = 'description',
				name = "  " .. L["Spam_Desc"] .. "\n\n",
				order = 1,
				cmdHidden = true,
				image = "Interface\\Icons\\INV_Shield_04",
				imageWidth = 16, imageHeight = 16,
			},
			notready = {
				type = 'toggle',
				name = ERR_ABILITY_COOLDOWN,
				get = get,
				set = set,
				order = 4,
				width = "full",
			},
			energy = {
				type = 'toggle',
				name = ERR_OUT_OF_ENERGY,
				get = get,
				set = set,
				order = 4,
				width = "full",
			},
			notarget = {
				type = 'toggle',
				name = ERR_NO_ATTACK_TARGET,
				get = get,
				set = set,
				order = 4,
				width = "full",
			},
			combo = {
				type = 'toggle',
				name = SPELL_FAILED_NO_COMBO_POINTS,
				get = get,
				set = set,
				order = 4,
				width = "full",
			},
			dead = {
				type = 'toggle',
				name = SPELL_FAILED_TARGETS_DEAD,
				get = get,
				set = set,
				order = 4,
				width = "full",
			},
			inprogress = {
				type = 'toggle',
				name = SPELL_FAILED_SPELL_IN_PROGRESS,
				get = get,
				set = set,
				order = 4,
				width = "full",
			},
		}
	}
end