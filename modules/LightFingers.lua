if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

--[[
Name: Cutup_LightFingers
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Description: A module for Cutup that switches to Auto Loot when Pick Pocket is cast.

You got light fingers, Everett. Gopher?
]]

local mod = Cutup:NewModule("LightFingers", nil, "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Cutup")
local self = mod

local spellInfo = GetSpellInfo(921) -- Pick Pocket

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

function mod:OnInitialize()
end

function mod:OnEnable()
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function mod:OnDisable()
	self:UnregisterAllEvents()
end

-------------------------------------------------------------------------------
-- Events                                                                    --
-------------------------------------------------------------------------------
do
	local current = nil
	local function restore()
		SetCVar("autoLootDefault", current)
		current = nil
	end

	function mod:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell)
		if unit == "player" and spell == spellInfo then
			if current == nil then
				current = GetCVar("autoLootDefault")
			end
			
			-- Already auto looting by default
			if current == '1' then
				current = nil
				return
			end
			
			SetCVar("autoLootDefault", '1') 
			self:ScheduleTimer(restore, 1)
		end
	end
end