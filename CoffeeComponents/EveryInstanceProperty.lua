--[[
	MIT License
	Copyright © 2025 Coffilhg
	This plugin is licensed under the MIT License. Users must include attribution to "Coffilhg" (Roblox UserId 517222346) in game credits.
	Full license: https://github.com/Coffilhg/Coffee-Components-Plugin/tree/main
	Plugin Version: 2.0.0
--]]



local Players = game:GetService("Players")
local RunS = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local Selection = game:GetService("Selection") :: Selection

local PluginVersion = 2

if RunS:IsRunning() then 
	script.Enabled = false 
	return
end

-- Load Plugin Gui and Button --
local Toolbar = plugin:CreateToolbar("Coffee ☕ Components")
local Button = Toolbar:CreateButton("Coffee Components", `Toggle Coffee Components Tab (V{PluginVersion})`, "rbxassetid://98166713548081")
local WidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	false,
	false,
	270,
	150,
	90,
	90
)
local Widget = plugin:CreateDockWidgetPluginGui("Coffee ☕ Components", WidgetInfo) :: DockWidgetPluginGui
Widget.Title = "Coffee ☕ Components"
Widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Init --
Button.Click:Connect(function()
	Widget.Enabled = not Widget.Enabled
end)

-- Modules --
local API_DumpModule = require(script.Data)
local CopyInstance = require(script.CopyInstance)
local Component = require(script.CoffeeComponents)
-- Globals --
local Colors = {
	Color3.fromRGB(59, 47, 47),
	Color3.fromRGB(111, 78, 55),
	Color3.fromRGB(139, 94, 60),
	Color3.fromRGB(166, 123, 91),
	Color3.fromRGB(210, 180, 140),
}
local TweenInfo = TweenInfo.new(0.27, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)

function GetPathRecursively(instance, notIncludeSelf)
	if instance.Parent == game then
		return `game.{instance.Name}`
	end
	if notIncludeSelf then
		return `{GetPathRecursively(instance.Parent)}`
	else
		return `{GetPathRecursively(instance.Parent)}.{instance.Name}`
	end
end




local Temporary = Instance.new("Folder", Widget)

local Bg, ScrollingFrame = Component.new("Main", Widget, Colors)
local WelcomeTitle = Component.new("RichText", ScrollingFrame, "Loading...", 0, 21, UDim.new(0.96, -12), Colors[5], 18)

local DisplayPrintTextLabel = Component.new("RichText", ScrollingFrame, ``, 0, 15, UDim.new(0.96, -12), Colors[4], 3)
local function DisplayPrint(message)
	DisplayPrintTextLabel.Text = message
end
DisplayPrint("Loading...")

function GetMarkerText(value)
	if value == true then
		return `(Done ✅)`
	elseif value == false then
		return `(Undone ❌)`
	end
end

local UpdateSortedData = nil :: TextButton
local CreateBaseModule = nil :: TextButton


-- Main Code --




-- Load the Current API version in the background --
DisplayPrint("Getting API Version (Background)")
local APIVersion = API_DumpModule.requestVersion()
while not APIVersion do
	task.wait(3)
	APIVersion = API_DumpModule.requestVersion()
end
local LastRetrievedVersion = plugin:GetSetting("APIDumpVersion")
local APIDump = plugin:GetSetting("APIDumpData")
local LastSortedVersion = plugin:GetSetting("SortedAPIDumpVersion")
local SortedAPIDump = plugin:GetSetting("SortedAPIDumpData")
plugin:SetSetting("API_Dump_Version", nil)
plugin:SetSetting("API_Dump_Data", nil)
plugin:SetSetting("FilteredData", nil)


function EnsureAPIDump()
	if LastRetrievedVersion == APIVersion
		and APIDump then
		return
	end
	DisplayPrint("Getting New Dump Data (Background)")
	APIDump = API_DumpModule.requestData()
	while not APIDump do
		task.wait(3)
		APIDump = API_DumpModule.requestData()
	end
	LastRetrievedVersion = APIVersion
	plugin:SetSetting("APIDumpVersion", APIVersion)
	plugin:SetSetting("APIDumpData", APIDump)
end
EnsureAPIDump()



local PossibleFilters = {}
local PossibleFilterCategories = {}

local WhitelistedFilterCategories = {
	MemberType = true,
	Tags = true,
	Security = true,
}

for i, class in ipairs(APIDump.Classes) do
	for _, member in ipairs(class.Members or {}) do
		for possibleCategory, v in pairs(member) do
			if WhitelistedFilterCategories[possibleCategory] then
				PossibleFilterCategories[possibleCategory] = true
				if not PossibleFilters[possibleCategory] then
					PossibleFilters[possibleCategory] = {}
				end

				if typeof(v) == "table" then
					local isArray = false
					for _, vv in ipairs(v) do
						isArray = true
						PossibleFilters[possibleCategory][vv] = true
					end
					if isArray then continue end
					for k, vv in pairs(v) do
						if not PossibleFilters[possibleCategory][k] then
							PossibleFilters[possibleCategory][k] = {}
						end
						PossibleFilters[possibleCategory][k][vv] = true
					end
				else
					PossibleFilters[possibleCategory][v] = true
				end
			end
		end
	end
end

local DefaultSortingSettings = {
	MemberType = {
		Property = 1,
	},
	Security = {
		None = 1,
	},
	Tags = {
		Deprecated = 1,
	},
}
local SortingSettings = {
	MemberType = {
		Property = 1,
	},
	Security = {
		None = 1,
		PluginSecurity = 1,
	},
	Tags = {
		Deprecated = 1,
		ReadOnly = 1,
	},
}

function SortAPIDump()
	EnsureAPIDump()

	local completeSortedAPIDump = {}
	local other = {}
	local infos = {}
	local cachedMembers = {}
	local totalClasses = #APIDump.Classes

	local WhitelistedMemberTypes = {}
	local WhitelistedSecurityLevels = {}
	local BlacklistedTags = {}

	for name, v in pairs(SortingSettings["MemberType"]) do
		if v > 0 then
			WhitelistedMemberTypes[name] = true
		end
	end
	for name, v in pairs(SortingSettings["Security"]) do
		if v > 0 then
			WhitelistedSecurityLevels[name] = true
		end
	end
	for name, v in pairs(SortingSettings["Tags"]) do
		if v > 0 then
			BlacklistedTags[name] = true
		end
	end



	DisplayPrint(`Sorting API Dump with {totalClasses} classes`)



	local function GetMembers(className)
		if cachedMembers[className] then
			return cachedMembers[className]
		end

		local class = infos[className]
		if not class then return {} end

		local members = {}

		for _, member in ipairs(class.Members or {}) do

			if not WhitelistedMemberTypes[member["MemberType"]] then continue end

			local security = member["Security"]
			if not WhitelistedSecurityLevels[security["Read"]] then continue end
			if not WhitelistedSecurityLevels[security["Write"]] then continue end

			local tags = member["Tags"]
			if tags then
				local blacklistedTagsFound = false
				for i, tag in ipairs(tags) do
					if BlacklistedTags[tag] then
						blacklistedTagsFound = true
						break
					end
				end
				if blacklistedTagsFound then
					continue
				end
			end

			table.insert(members, member)
		end

		if class.Superclass and class.Superclass ~= "<<<ROOT>>>" then
			for _, parentMember in ipairs(GetMembers(class.Superclass)) do
				table.insert(members, parentMember)
			end
		end

		cachedMembers[className] = members
		return members
	end



	for i, class in ipairs(APIDump.Classes) do
		local className = class["Name"]
		infos[className] = class
	end

	for i, class in ipairs(APIDump.Classes) do
		DisplayPrint(`Filtering dump {i}/{totalClasses} ({math.round((i/totalClasses) * 10000) / 100}%)`)
		if i % 60 == 0 then task.wait(0.03) end


		local className = class["Name"]
		local completeClassData = {}
		for k, v in pairs(class) do
			if k == "Members" then continue end
			completeClassData[k] = v
		end
		completeClassData["Members"] = GetMembers(className)
		completeSortedAPIDump[className] = completeClassData
	end

	DisplayPrint("Complete Sorted API with Inheritance retrieved successfully!")
	
	LastSortedVersion = LastRetrievedVersion
	SortedAPIDump = completeSortedAPIDump

	plugin:SetSetting("SortedAPIDumpVersion", LastRetrievedVersion)
	plugin:SetSetting("SortedAPIDumpData", completeSortedAPIDump)
	
	if UpdateSortedData then
		UpdateSortedData.Text = `Sort API Dump {GetMarkerText(true)}`
	end
end

function IsSortedAPIDumpUpToDate() : boolean
	return (LastSortedVersion == LastRetrievedVersion and SortedAPIDump ~= nil)
end
function EnsureSortedAPIDump()
	if IsSortedAPIDumpUpToDate() then return end
	
	SortAPIDump()
end
SortAPIDump()
DisplayPrint("Up to date!")

local CoffeeComponents = nil
function CreateCoffeeComponentsBaseModule()
	DisplayPrint(`Working On It!`)
	local module = Instance.new("ModuleScript")
	module.Name = "Components"
	module:AddTag("CoffeeComponents")
	module.Parent = RS
	module.Source = `--- @Coffilhg | Coffee Components | [V{PluginVersion}] ---\n`..[[
function createInstance(className : string, parent : Instance, props : {[string]: (any)}?, tags : {[number]: string}?, attributes : {[string]: (any)}?) : Instance
	local newInstance = Instance.new(className, parent) :: Instance
	
	for propName, propVal in pairs(props) do
		newInstance[propName] = propVal
	end
	
	if tags then
		for _, tag in ipairs(tags) do
			newInstance:AddTag(tag)
		end
	end
	
	if attributes then
		for attributeName, attributeValue in pairs(attributes) do
			newInstance:SetAttribute(attributeName, attributeValue)
		end
	end
	
	return newInstance
end

-- Load components for use via .new; No typization/autofills will be shown.
local Components = {}



local module = {}

-- Manually load components to enable typization and autofills (straight access) e.g.:
-- module.COMPONENTNAME = require(script.COMPONENTNAME)

-- late load components --
for _, component in ipairs(script:GetChildren()) do
	local componentName = component.Name
	assert(componentName ~= "new", `Never name a Component "new"; Consider Renaming all Components named "new".`)
	
	local componentModule = Components[componentName] or module[componentName]
	if not componentModule then
		componentModule = require(component)
		Components[componentName] = componentModule
	end
	
	module[componentName] = componentModule -- that's why never name a Component "new".
	
	componentModule["CreateInstance"] = createInstance
	componentModule["Component"] = module
end

-- Calls the .new() for the given "<strong>componentName</strong>" Module
function module.new(componentName : string, parent : Instance, ...)
	local component = Components[componentName]
	if not component then
		error(`Component "{componentName}" Not Found!`)
		return nil
	end
	return component.new(parent, ...)
end

return module]]
	DisplayPrint(`Created Components Module!\n{GetPathRecursively(module)}`)
	
	return module
end
function SearchForCoffeeComponents()
	for _, instance : Instance in ipairs(CS:GetTagged("CoffeeComponents")) do
		if not instance:IsA("ModuleScript") then continue end
		if instance.Parent ~= RS then return end
		CoffeeComponents = instance
		break
	end
end
SearchForCoffeeComponents()
function EnsureCoffeeComponentsModule()
	if CoffeeComponents and CoffeeComponents.Parent ~= nil then
		return
	end
	SearchForCoffeeComponents()
	if not CoffeeComponents or not CoffeeComponents.Parent then
		CoffeeComponents = CreateCoffeeComponentsBaseModule()
	end
	if CreateBaseModule then
		CreateBaseModule.Text = `Get Components Module {GetMarkerText(not not CoffeeComponents)}`
	end
end

function CopySelection()
	EnsureSortedAPIDump()
	CopyInstance.SetSortedAPIDump(SortedAPIDump)
	local instancesToCopy = Selection:Get()
	local success, result = CopyInstance.GenerateCode(instancesToCopy, DisplayPrint)
	
	if not success then
		DisplayPrint(`Error: {result}`)
		return
	end
	
	EnsureCoffeeComponentsModule()
	local module = Instance.new("ModuleScript")
	module.Name = result.ModuleName
	module.Parent = CoffeeComponents
	module.Source = result.Result
	DisplayPrint(`Created Component Module!\n{GetPathRecursively(module)}`)

	return module
end























-- Load Gui --

WelcomeTitle.Text = `Welcome To Coffee Components!`
DisplayPrintTextLabel.Parent = ScrollingFrame
CopySelectionBtn = Component.new("TextButton", ScrollingFrame, Colors, `Selection To Component`, CopySelection)

local Credits = Component.new("RichText", ScrollingFrame, `Copyright © 2025 Coffilhg (Roblox UserId 517222346).\nAll rights reserved.\nThis project is licensed under the MIT License. Users must include attribution to "Coffilhg" in game credits.\n\nCurrent Roblox Username: @[Loading-Current-Username]\nPluginVersion: {PluginVersion}`, 999, 9, UDim.new(0.96, -12), Colors[4], 12)

local function getPlayerName(userId)

	while true do
		local success, playerName = pcall(Players.GetNameFromUserIdAsync, Players, userId)

		if success then
			return playerName
		else
			--warn("Attempt failed: " .. playerName) -- playerName contains the error message
			task.wait(3) -- Wait before retrying
		end
	end
end
task.spawn(function()
	local developersRobloxUsername = getPlayerName(517222346)
	Credits.Text = `Copyright © 2025 Coffilhg (Roblox UserId 517222346).\nAll rights reserved.\nThis project is licensed under the MIT License. Users must include attribution to "Coffilhg" in game credits.\n\nCurrent Roblox Username: @{developersRobloxUsername}\nPluginVersion: {PluginVersion}`
end)