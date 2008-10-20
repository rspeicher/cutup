local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Cutup", "enUS", true)
if not L then return end

L["Cutup"] = true
L["A collection of Rogue modules."] = true
L["Configure"] = true
L["Open the configuration dialog"] = true
L["Modules"] = true
L["Toggle %s"] = true

-- Module names and descriptions
L["Bleeder"] = true
L["Bleeder_Desc"] = "Rupture timer"
L["Glutton"] = true
L["Glutton_Desc"] = "Hunger For Blood timer"
L["Julienne"] = true
L["Julienne_Desc"] = "Slice and Dice timer"
L["LightFingers"] = true
L["LightFingers_Desc"] = "Automatic Pick Pocket"
L["Spam"] = true
L["Spam_Desc"] = "Block repeated Rogue-specific error messages"
L["TickToxin"] = true
L["TickToxin_Desc"] = "Poison application timer"

-- Shared
L["Enable"] = true
L["Lock"] = true
L["Width"] = true
L["Height"] = true
L["Scale"] = true
L["Alpha"] = true
L["Text size"] = true
L["Texture"] = true
L["Border"] = true
L["Frame"] = true
L["Bars"] = true
L["Text"] = true
L["X Position"] = true
L["Y Position"] = true

	-- Module: Julienne/Bleeder
	L["Toggle bar lock"] = true
	L["Background color"] = true
	L["Main color"] = true
	L["Color of the main countdown bar."] = true
	L["Show potential"] = true
	L["Show a second bar representing the length of the next potential timer."] = true
	L["Potential color"] = true
	L["Color of the secondary bar."] = true
	L["Show text"] = true
	L["Show countdown text."] = true
	L["Text position"] = true
	L["Text position"] = true
	L["Left"] = true
	L["Center"] = true
	L["Right"] = true
	L["Text color"] = true
	L["Text font"] = true
	
	-- Module: Glutton
	L["Stack Colors"] = true
	L["1 stack"] = true
	L["Color of the bar with 1 stack."] = true
	L["%d stacks"] = true
	L["Color of the bar with %d stacks."] = true

	-- Module: LightFingers
	
	-- Module: Spam
	
	-- Module: TickToxin
	L["Poison"] = true
	L["Poisons"] = true
	L["Grow Up"] = true
	L["Grow bars upwards"] = true
	L["Orientation"] = true
	L["Left to Right"] = true
	L["Right to Left"] = true
	L["Track"] = true
	L["Track %s"] = true
	L["Color"] = true