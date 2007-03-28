if (select(2, UnitClass("player"))) ~= "ROGUE" then return end

Cutup = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceEvent-2.0", "AceHook-2.1", "AceModuleCore-2.0", "AceDebug-2.0")
Cutup:RegisterDB("CutupDB")
Cutup:SetModuleMixins("AceConsole-2.0", "AceEvent-2.0", "AceHook-2.1", "AceDebug-2.0")
Cutup.Options = {
	type = "group",
	name = "Cutup",
	desc = "A framework for Rogue-specific modules.",
	args = {},
}

function Cutup:OnInitialize()
	self:RegisterChatCommand({"/cutup"}, self.Options, "CUTUP")
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

