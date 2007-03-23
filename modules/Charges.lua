--[[
Name: Cutup_Charges
Revision: $Revision$
Author(s): tsigo (tsigo@eqdkp.com)
Inspired By: ItemBuffCharges by tsigo
Description: A module for Cutup that displays the number of poison charges on the item buff icon.
]]

-------------------------------------------------------------------------------
-- Initialization                                                            --
-------------------------------------------------------------------------------

local mod = Cutup:NewModule("Charges")

function mod:OnInitialize()
	self.db = Cutup:AcquireDBNamespace("Charges")
	
	Cutup:RegisterDefaults("Charges", "profile", {
		on = true,
	})
	
	Cutup.Options.args.Charges = {
		type = "group",
		name = "Charges",
		desc = "Display poison charges on item buff icon.",
		args = {
			Toggle = {
				type = "toggle",
				name = "Toggle",
				desc = "Toggle the module on and off.",
				get = function() return self.db.profile.on end,
				set = function(v) self.db.profile.on = Cutup:ToggleModuleActive("Charges") end
			},
		}
	}
	
	-- Create FontStrings for both TempEnchant frames
	for i=1,2 do
		local parent = getglobal("TempEnchant" .. i)
		if parent then
			local str = parent:CreateFontString("TempEnchant" .. i .. "Charges", "OVERLAY")
			str:SetFontObject(GameFontHighlightSmallOutline)
			str:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 1, 1)
		end
	end
end

function mod:OnEnable()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:UpdateCharges()
end

function mod:OnDisable()
	self:SetCharges(1, 0)
	self:SetCharges(2, 0)
end

-------------------------------------------------------------------------------
-- Addon Methods                                                             --
-------------------------------------------------------------------------------

function mod:UpdateCharges()
	local mhHasEnchant, _, mhCharges, ohHasEnchant, _, ohCharges = GetWeaponEnchantInfo()
	
	if mhHasEnchant or ohHasEnchant then
		if mhHasEnchant and ohHasEnchant then
			self:SetCharges(2, mhCharges)
			self:SetCharges(1, ohCharges)
		elseif mhHasEnchant then
			self:SetCharges(1, mhCharges)
		elseif ohHasEnchant then
			self:SetCharges(1, ohCharges)
		end
	else
		self:SetCharges(2, 0)
		self:SetCharges(1, 0)
	end
end

function mod:SetCharges( index, charges )
	charges = ( charges == 0 ) and "" or charges

	local str = getglobal("TempEnchant" .. index .. "Charges")
	str:SetText(charges)
end

-------------------------------------------------------------------------------
-- Events                                                                    --
-------------------------------------------------------------------------------

function mod:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:UpdateCharges()
end

function mod:PLAYER_LEAVING_WORLD()
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function mod:UNIT_INVENTORY_CHANGED( arg1 )
	if arg1 == "player" then
		self:UpdateCharges()
	end
end