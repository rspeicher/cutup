if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_LightFingers
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that switches to Auto Loot when Pick Pocket is cast.
]]

local Cutup = Cutup
if Cutup:HasModule('LightFingers') then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cutup")

local CutupLightFingers = Cutup:NewModule('LightFingers')
local self = CutupLightFingers

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

function CutupLightFingers:OnInitialize()
end

function CutupLightFingers:OnEnable()
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
end

function CutupLightFingers:OnDisable()
end

-------------------------------------------------------------------------------
-- Events                                                                    --
-------------------------------------------------------------------------------
do
	local current = nil
	local function restore()
		SetAutoLootDefault(current)
	end

	function CutupLightFingers:UNIT_SPELLCAST_SENT(p, spell, rank, target)
		if spell == L["Pick Pocket"] then
			current = GetAutoLootDefault()
			SetAutoLootDefault(1)
			self:ScheduleEvent(restore, 1)
		end
	end
end

do
	Cutup.options.args.LightFingers = {
		type = 'group',
		name = L["LightFingers"],
		desc = L["Automatic Pick Pocket"],
		args = {
			toggle = {
				type = 'toggle',
				name = L["Enable"],
				desc = L["Enable"],
				get = function()
					return Cutup:IsModuleActive('LightFingers')
				end,
				set = function(v)
					Cutup:ToggleModuleActive('LightFingers', v)
				end,
				order = 100,
			},
		},
	}
end