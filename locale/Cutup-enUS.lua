local L = AceLibrary("AceLocale-2.2"):new("Cutup")
L:RegisterTranslations("enUS", function() return {
	["Cutup"] = true,
	["A collection of Rogue modules."] = true,
	
	-- Module names
	["Julienne"] = true,
	["LightFingers"] = true,
	["Spam"] = true,
	["TickToxin"] = true,
	
	-- Shared
	["Enable"] = true,
	["Toggle anchor"] = true,
	["Width"] = true,
	["Height"] = true,
	["Scale"] = true,
	["Alpha"] = true,
	["Text size"] = true,
	["Texture"] = true,
	["Border"] = true,
	
		-- Module: Julienne
		["Slice and Dice timer"] = true,
		["Lock"] = true,
		["Toggle bar lock"] = true,
		["Background color"] = true,
		["Main color"] = true,
		["Color of the main countdown bar."] = true,
		["Show potential"] = true,
		["Show a second bar representing the length of the next potential timer."] = true,
		["Potential color"] = true,
		["Color of the secondary bar."] = true,
		["Show text"] = true,
		["Show countdown text."] = true,
		["Text position"] = true,
		["Text position"] = true,
		["Left"] = true,
		["Center"] = true,
		["Right"] = true,
		["Text color"] = true,
		["Text font"] = true,
	
		-- Module: LightFingers
		["Automatic Pick Pocket"] = true,
		
		-- Module: Spam
		["Block repeated Rogue-specific error messages"] = true,
		
		-- Module: TickToxin
		["Poison application timer"] = true,
		["Poison"] = true,
		["Grow up"] = true,
		["Add new bars above the anchor rather than below."] = true,
} end)