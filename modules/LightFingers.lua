if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_LightFingers
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that switches to Auto Loot when Pick Pocket is cast.
]]

-------------------------------------------------------------------------------
-- Localization                                                              --
-------------------------------------------------------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Cutup_LightFingers")

L:RegisterTranslations("enUS", function() return {
	["Pick Pocket"] = true,
} end)

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

local mod = Cutup:NewModule("LightFingers")

function mod:OnInitialize()
	self.db = Cutup:AcquireDBNamespace("LightFingers")
	
	Cutup:RegisterDefaults("LightFingers", "profile", {
		on = true,
	})
	
	Cutup.Options.args.LightFingers = {
		type = "group",
		name = "LightFingers",
		desc = "Auto Pick Pocket.",
		args = {
			toggle = {
				type = "toggle",
				name = "Toggle",
				desc = "Toggle the module on and off.",
				get = function() return self.db.profile.on end,
				set = function(v) self.db.profile.on = Cutup:ToggleModuleActive("LightFingers") end,
			},
		},
	}
end

function mod:OnEnable()
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
end

function mod:OnDisable()
end

-------------------------------------------------------------------------------
-- Events                                                                    --
-------------------------------------------------------------------------------
do
	local current = nil
	local function restore()
		SetAutoLootDefault(current)
	end

	function mod:UNIT_SPELLCAST_SENT(p, spell, rank, target)
		if spell == L["Pick Pocket"] then
			current = GetAutoLootDefault()
			SetAutoLootDefault(1)
			self:ScheduleEvent(restore, 1)
		end
	end
end

