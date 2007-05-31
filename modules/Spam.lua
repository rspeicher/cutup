if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_Spam
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Inspired By: RogueSpam by Allara (http://www.curse-gaming.com/en/wow/addons-924-1-roguespam.html)
Description: A module for Cutup that blocks repeated Rogue-specific error messages.
]]

local Cutup = Cutup
if Cutup:HasModule('Spam') then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cutup")

local CutupSpam = Cutup:NewModule('Spam')
local self = CutupSpam

local db

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

function CutupSpam:OnInitialize()
	db = Cutup:AcquireDBNamespace('Spam')
	self.db = db
	
	Cutup:RegisterDefaults('Spam', 'profile', {
		notready   = true,	-- Ability is not ready yet.
		energy     = true,	-- Not enough energy
		notarget   = true,	-- There is nothing to attack.
		combo      = true,	-- That ability requires combo points
		dead       = true,	-- Your target is dead.
		inprogress = true,	-- Another action is in progress
	})	
end

function CutupSpam:OnEnable()
	self:Hook("UIErrorsFrame_OnEvent", true)
end

function CutupSpam:OnDisable()
	self:UnhookAll()
end

-------------------------------------------------------------------------------
-- Addon Methods                                                             --
-------------------------------------------------------------------------------

function CutupSpam:UIErrorsFrame_OnEvent(event, msg, ...)
	if Cutup:IsModuleActive('Spam') then
		local opt = Cutup.options.args.Spam
		for k, v in pairs(opt.args) do
			if k ~= 'toggle' and self.db.profile[k] and msg == v.desc then
				return
			end
		end
	end
	
	self.hooks.UIErrorsFrame_OnEvent(event, msg, ...)
end

do
	local function set(field, value)
		db.profile[field] = value
	end
	local function get(field)
		return db.profile[field]
	end
	Cutup.options.args.Spam = {
		type = 'group',
		name = L["Spam"],
		desc = L["Block repeated Rogue-specific error messages"],
		args = {
			toggle = {
				type = 'toggle',
				name = L["Enable"],
				desc = L["Enable"],
				get = function()
					return Cutup:IsModuleActive('Spam')
				end,
				set = function(v)
					Cutup:ToggleModuleActive('Spam', v)
				end,
				order = 100,
			},
			notready = {
				type = 'toggle',
				name = ERR_ABILITY_COOLDOWN,
				desc = ERR_ABILITY_COOLDOWN,
				get = get,
				set = set,
				passValue = 'notready',
				order = 101,
			},
			energy = {
				type = 'toggle',
				name = ERR_OUT_OF_ENERGY,
				desc = ERR_OUT_OF_ENERGY,
				get = get,
				set = set,
				passValue = 'energy',
				order = 101,
			},
			notarget = {
				type = 'toggle',
				name = ERR_NO_ATTACK_TARGET,
				desc = ERR_NO_ATTACK_TARGET,
				get = get,
				set = set,
				passValue = 'notarget',
				order = 101,
			},
			combo = {
				type = 'toggle',
				name = SPELL_FAILED_NO_COMBO_POINTS,
				desc = SPELL_FAILED_NO_COMBO_POINTS,
				get = get,
				set = set,
				passValue = 'combo',
				order = 101,
			},
			dead = {
				type = 'toggle',
				name = SPELL_FAILED_TARGETS_DEAD,
				desc = SPELL_FAILED_TARGETS_DEAD,
				get = get,
				set = set,
				passValue = 'dead',
				order = 101,
			},
			inprogress = {
				type = 'toggle',
				name = SPELL_FAILED_SPELL_IN_PROGRESS,
				desc = SPELL_FAILED_SPELL_IN_PROGRESS,
				get = get,
				set = set,
				passValue = 'inprogress',
				order = 101,
			},
		}
	}
end