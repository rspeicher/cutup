local L = AceLibrary("AceLocale-2.2"):new("Cutup")
L:RegisterTranslations("enUS", function() return {
	["Cutup"] = true,
	["A collection of Rogue modules."] = true,
	
	-- Module names
	["LightFingers"] = true,
	["Spam"] = true,
	["TickToxin"] = true,
	
	-- Shared
	["Enable"] = true,
	["Bar"] = true,
	["Bar settings"] = true,
	["Toggle anchor"] = true,
	["Width"] = true,
	["Height"] = true,
	["Scale"] = true,
	["Font size"] = true,
	["Texture"] = true,
	["Grow up"] = true,
	["Add new bars on top of existing bars rather than below."] = true,
	
		-- Module: LightFingers
		["Pick Pocket"] = true,
		["Automatic Pick Pocket"] = true,
		
		-- Module: Spam
		["Block repeated Rogue-specific error messages"] = true,
		["Messages"] = true,
		["Messages to block"] = true,
		
		-- Module: TickToxin
		["Poison application timer"] = true,
		["Poison"] = true,
} end)