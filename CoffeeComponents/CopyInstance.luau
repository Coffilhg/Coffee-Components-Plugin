--[[
	MIT License
	Copyright © 2025 Coffilhg
	This plugin is licensed under the MIT License. Users must include attribution to "Coffilhg" (Roblox UserId 517222346) in game credits.
	Full license: https://github.com/Coffilhg/Coffee-Components-Plugin/blob/main/LICENSE
	Plugin Version: 2.1.0
--]]
local Players = game:GetService("Players")



--- Dev Only ---
local doDebug = false
local doSecondaryDebug = true
--- Active ---
local mainParentString = nil --"Main" :: string ir nil
local stringLimit = 200000 :: number
local ignorePlayersAndPlayerCharacters = true
local ignoreAllNPCs = false
local addTypization = true
local prettyProperties = true
local writeAsLocalVariables = true
local removeSpaces = false
local useHexForColor3 = false
local maxInstancesPerSecond = 300
local rateLimitingWaitInterval = 0.03 -- min = 0.03, max = 1
--- Deprecated ---
local leaveInstacesUndefined = false




--- Setting Based ---
local codegenStarted = false
local spaceCharacter = removeSpaces and "" or " "
local rateLimit = math.clamp(rateLimitingWaitInterval, 0.03, 1)/1*maxInstancesPerSecond
local useNames = mainParentString == nil



--- Other Don't Modify ---
local whitelistedCategories = {
	DataType = true,
	Primitive = true,
	Enum = true,
	Class = true,
}
local blacklistedClassNames = {
	"Terrain",
}
local blacklistedPropNames = {
	-- written explicitly at the top of instance
	Parent = true,
	-- replaced as 2 in 1 with CFrame
	CFrame = true,
	--Position = true,
	--Rotation = true,
	-- Content Duplicates
	--ImageContent = true,
	--TextureContent = true,
}
local blacklistedPropTypes = {
	CFrame = true,
}






----- Parser -----
local precision = 3
local seenParsedProperties = {}

local propertyPrefix = prettyProperties and "\n\t" or ""
local propertyTableWrap = prettyProperties and "\n" or ""

--local parsedPropertiesVariables = {}

-- Luau reserved keywords (https://luau-lang.org/syntax#reserved-keywords)
local reservedKeywords = {
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
	["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
	["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
	["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
	["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true, ["continue"] = true,
	["C"] = true, -- Create Instance function
	["Component"] = true, -- Link to the Loader module
	["T"] = true, -- Dictionary for Tags
	["A"] = true, -- Dictionary for Attributes
	["Secret"] = true,
}

local charDictionary = {
	--"_", -- Start with underscore
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
	"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
}
type CustomDictionary = {
	["_currentIndex"]: number,
	["_letterCount"]: number,
	["_currentCombo"]: {number},
	["Variables"]: {
		[string]: string, -- Value = VariableName
	},
	["CreateVariable"]: (self: CustomDictionary, string) -> string,
	["GetVariableName"]: (self: CustomDictionary, string, boolean?) -> string,
}

local CustomDictionaryMetatable = {}
CustomDictionaryMetatable.__index = CustomDictionaryMetatable

function CustomDictionaryMetatable:CreateVariable(variableValue: string) : string
	local variableName

	-- Generate variable name and check against reserved keywords
	repeat
		local chars = {}
		for i = 1, self._letterCount do
			chars[i] = charDictionary[self._currentCombo[i] or 1]
		end
		variableName = table.concat(chars)

		-- Update for next variable name
		local i = self._letterCount
		while i > 0 do
			self._currentCombo[i] = (self._currentCombo[i] or 1) + 1
			if self._currentCombo[i] <= #charDictionary then
				break
			end
			self._currentCombo[i] = 1
			i = i - 1
			if i == 0 then
				self._letterCount = self._letterCount + 1
				self._currentCombo = {}
				for j = 1, self._letterCount do
					self._currentCombo[j] = 1
				end
			end
		end
	until not reservedKeywords[variableName]

	-- Store the parsed property string
	self.Variables[variableValue] = variableName

	return variableName
end

function CustomDictionaryMetatable:GetVariableName(variableValue: string, unreliable : boolean?) : string
	local variableName = self.Variables[variableValue]
	if variableName or unreliable then
		return variableName
	end

	return self:CreateVariable(variableValue)
end



local VariableDictionaries = {} :: {[string]: CustomDictionary}

function newVariableDictionary(dictName : string) : CustomDictionary
	local dict = setmetatable({}, CustomDictionaryMetatable)
	dict._currentIndex = 1 -- Tracks position in charDictionary
	dict._letterCount = 1 -- Number of characters in the variable name
	dict._currentCombo = {1} -- Tracks the current combination of indices
	dict.Variables = {}

	VariableDictionaries[dictName] = dict
	return dict
end



--- Parser Main ---
local function round(v)
	local stringR = string.format("%."..precision.."f", v)
	for i = 0, precision-1 do
		local number = math.round(v*10^i)/10^i
		if number == tonumber(stringR) then
			return tostring(number)
		end
	end

	return stringR
	--return tonumber(string.format("%."..precision.."f", v))
end
local function returnColor3(v : Color3)
	if useHexForColor3 then
		return `Color3.fromHex("{v:ToHex()}")`
	end
	return `Color3.fromRGB({math.round(v.R*255)},{spaceCharacter}{math.round(v.G*255)},{spaceCharacter}{math.round(v.B*255)})`
end
local function returnUDim2(Value)
	return `UDim2.new({round(Value.X.Scale)},{spaceCharacter}{math.round(Value.X.Offset)},{spaceCharacter}{round(Value.Y.Scale)},{spaceCharacter}{math.round(Value.Y.Offset)})`
end



local function wrapString(s)
	-- check newlines directly
	if string.find(s, "[\r\n]") then
		return "[[" .. s .. "]]"
	end

	local hasQuote = string.find(s, '"', 1, true) ~= nil
	local hasApos  = string.find(s, "'", 1, true) ~= nil

	if hasQuote and hasApos then
		return "[[" .. s .. "]]"
	elseif hasQuote then
		return "'" .. s .. "'"
	else
		return '"' .. s .. '"'
	end
end
local function returnEnumOrPrimitive(Value)
	if tostring(Value) == "inf" then
		return "math.huge"
	end
	if typeof(Value) == "string" then
		return wrapString(Value)--`"{Value}"`
	else
		if typeof(Value) == "number" then
			return `{round(Value)}`
		end
		return `{Value}`
	end
end
function returnEnum(Value)
	return `{Value}`
end
function tostringVector3OrAlikes(v)
	return `Vector3.new({round(v.X)},{spaceCharacter}{round(v.Y)},{spaceCharacter}{round(v.Z)})`
end
function tostringVector2(v)
	return `Vector2.new({round(v.X)},{spaceCharacter}{round(v.Y)})`
end
propTypeCallbacks = {
	Axes = function(v)
		return `Axes.new({v})`
	end,
	BrickColor = function(v)
		return `BrickColor.new("{v}")`
	end,
	CFrame = function(v)
		local pos = v.Position
		local right = v.RightVector
		local up = v.UpVector
		local look = v.LookVector
		return `CFrame.fromMatrix({tostringVector3OrAlikes(pos)},{spaceCharacter}{tostringVector3OrAlikes(right)},{spaceCharacter}{tostringVector3OrAlikes(up)})`
	end,
	Color3 = returnColor3,
	ColorSequence = function(v : ColorSequence)
		local result = "ColorSequence.new({"
		if typeof(v) == "Color3" then
			result = result .. returnColor3(v)
		else
			local splits = v.Keypoints
			result = result .. propertyTableWrap
			for i, split : ColorSequenceKeypoint in ipairs(splits) do
				local splitColor = Color3.new(split.Value.R, split.Value.G, split.Value.B)
				result = result .. `{i==1 and "\t\t\t" or ""}ColorSequenceKeypoint.new({round(split.Time)},{spaceCharacter}{returnColor3(splitColor)}){i == #splits and "" or `,{propertyPrefix}\t`}` --Color3.new({split.Value.R}, {split.Value.G}, {split.Value.B})
			end
		end
		result = result .. propertyTableWrap .."\t\t})"
		return result
	end,
	-- Content will be updated later, apperently those are different, so leave two different callbacks as a placeholder for now
	Content = function(v : Content)
		if v.SourceType == Enum.ContentSourceType.Uri then
			return `Content.fromUri("{v.Uri}")`
		elseif v.SourceType == Enum.ContentSourceType.Object then
			return `Content.fromObject({v.Object})`
		elseif v.SourceType == Enum.ContentSourceType.None then
			return `Content.none`
		end
		return "Exception_NotFound"
	end,
	ContentId = function(v)
		return `"{v}"`
	end,
	Faces = function(v)
		return `Faces.new({v})`
	end,
	Font = function(v)
		return `Font.new("{v.Family}",{spaceCharacter}{v.Weight},{spaceCharacter}{v.Style})`
	end,
	NumberRange = function(v)
		if typeof(v) == "number" then
			return `NumberRange.new({round(v)})`
		else
			return `NumberRange.new({round(v.Min)},{spaceCharacter}{round(v.Max)})`
		end
	end,
	NumberSequence = function(v : NumberSequence)
		local result = "NumberSequence.new({"
		if typeof(v) == "number" then
			result = result .. `{v}`
		else
			local splits = v.Keypoints
			result = result .. propertyTableWrap
			for i, split : NumberSequenceKeypoint in ipairs(splits) do
				result = result .. `{i==1 and "\t\t\t" or ""}NumberSequenceKeypoint.new({round(split.Time)},{spaceCharacter}{round(split.Value)},{spaceCharacter}{round(split.Envelope)}){i == #splits and "" or `,{propertyPrefix}\t`}`
			end
		end
		result = result .. propertyTableWrap .. "\t\t})"
		return result
	end,
	Ray = function(v)
		local origin, direction = v.Origin, v.Direction
		return `Ray.new({tostringVector3OrAlikes(origin)},{spaceCharacter}{tostringVector3OrAlikes(direction)})`
	end,
	Rect = function(v)
		local min, max = v.Min, v.Max
		return `Rect.new({math.round(min.X)},{spaceCharacter}{math.round(min.Y)},{spaceCharacter}{math.round(max.X)},{spaceCharacter}{math.round(max.Y)})`
	end,
	UDim = function(v)
		return `UDim.new({round(v.Scale)},{spaceCharacter}{math.round(v.Offset)})`
	end,
	UDim2 = returnUDim2,
	Vector2 = tostringVector2,
	Vector3 = tostringVector3OrAlikes,
}

function try(propType, v)
	if tostring(v) == "inf" then
		return "math.huge"
	end

	local cb = propTypeCallbacks[propType] -- O(1)
	if not cb then return "Exception_NotFound" end
	return cb(v)
end




--- Helpers ---
local function toPascalCase(str)
	-- trim spaces on sides
	str = str:match("^%s*(.-)%s*$") 

	-- remove non-alphanumeric except spaces
	str = str:gsub("[^%w%s]", "") 

	-- capitalize words but preserve existing PascalCase
	str = str:gsub("(%S+)", function(word)
		-- if word is ALL CAPS (like "SS"), keep it
		if word:match("^%u+$") then
			return word
		end
		-- if word is already PascalCase (starts with uppercase, followed by mixed case), keep it
		if word:match("^%u%l") then
			return word
		end
		-- else PascalCase the word
		return word:sub(1,1):upper() .. word:sub(2):lower()
	end)

	-- remove spaces
	str = str:gsub("%s+", "")

	-- if starts with digit, prefix with "_"
	if str:match("^[0-9]") then
		str = "_" .. str
	end

	return str
end
function getPathRecursively(instance, notIncludeSelf)
	if instance == game then return "game" end
	if instance.Parent == game then
		return `game.{instance.Name}`
	end
	if notIncludeSelf then
		return `{getPathRecursively(instance.Parent)}`
	else
		return `{getPathRecursively(instance.Parent)}.{instance.Name}`
	end
end
local usedWarnMessages = {}
function oneTimeWarn(message)
	if usedWarnMessages[message] then return end
	usedWarnMessages[message] = true
	print(message)
end
local ignoredCharacterModels = {}
function canCountInstance(instance)
	if ignoreAllNPCs then
		if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoredCharacterModels, instance)
			return false
		end
		for _, ignoredCharacterModel in ipairs(ignoredCharacterModels) do
			if instance:IsDescendantOf(ignoredCharacterModel) then
				return false
			end
		end
	end
	if ignorePlayersAndPlayerCharacters then
		return not (instance:IsA("Player") or Players:GetPlayerFromCharacter(instance))
	else
		return true
	end
end
local takenVariableNames = {}
function createVariableName(child, lastPathString, i)
	if useNames then
		local base = toPascalCase(child.Name)
		local attempts = takenVariableNames[base]
		if attempts then
			takenVariableNames[base] = attempts+1
			local result = `{base}{attempts}`
			takenVariableNames[result] = 1
			return result
		end
		takenVariableNames[base] = 1
		return base
	else
		return `{lastPathString}{i ~= nil and `_{i}` or ""}`
	end
end



local SortedAPIDump = nil





local module = {}

function module.SetSortedAPIDump(NewSortedAPIDump)
	SortedAPIDump = NewSortedAPIDump
end

-- returns success and errorMessage (string) or result (dictionary)
function module.GenerateCode(
	mainParents : {Instance},
	displayPrint : (string) -> any
) : (
	boolean,
	string | {
		["Result"]: string,
		["ModuleName"]: string,
	}
	)
	if not SortedAPIDump then
		return false, "No SortedAPIDump Set!"
	end
	if codegenStarted then
		return false, "Already Generating, Please Wait"
	end
	if typeof(mainParents) ~= "table" then
		return false, "Array of Instances required"
	end
	if #mainParents <= 0 then
		return false, "mainParents: Non-Empty Array expected, got Dictionary"
	end

	codegenStarted = true

	local parsedPropertiesVariables = newVariableDictionary("Variables")
	local TagVariables = newVariableDictionary("T")
	local AttributeVariables = newVariableDictionary("A")

	--- Reset ---
	seenParsedProperties = {}
	--parsedPropertiesVariables = {}
	spaceCharacter = removeSpaces and "" or " "
	useNames = mainParentString == nil

	--currentIndex = 1 -- Tracks position in charDictionary
	--letterCount = 1 -- Number of characters in the variable name
	--currentCombo = {1} -- Tracks the current combination of indices

	usedWarnMessages = {}
	ignoredCharacterModels = {}
	takenVariableNames = {}

	rateLimit = math.clamp(rateLimitingWaitInterval, 0.03, 1)/1*maxInstancesPerSecond
	--- /E Reset ---
	--- Local Globals ---
	local instancesToVariables = {}

	propertyPrefix = prettyProperties and "\n\t\t" or ""
	propertyTableWrap = prettyProperties and "\n" or ""
	local variablePrefix = writeAsLocalVariables and "local " or ""

	local totalInstances = 0
	local totalCopied = 0
	local resultShards = {}

	local function progressCallback(progress)
		displayPrint(`{math.round(progress*10000)/100}%`)
	end

	local function count(instance)
		totalInstances += 1
		for _, child in ipairs(instance:GetChildren()) do
			count(child)
		end
	end

	--- Core ---
	local function copyInstance(instanceToCopy : Instance, parentVariable, variableName, canBeUndefined, propertiesOnly)
		local instanceClassName = instanceToCopy.ClassName
		if blacklistedClassNames[instanceClassName] then
			oneTimeWarn(`Not Copying ClassName [{instanceClassName}]; Blacklisted!`)
			return
		end

		local parts = {}  -- Collect string parts in a table
		local classInfo = SortedAPIDump[instanceClassName]

		if not classInfo then
			oneTimeWarn(`No Data For ClassName [{instanceClassName}]`)
		end
		if not propertiesOnly then
			if not canBeUndefined then
				table.insert(parts, {v = `\t{variablePrefix}{variableName}{spaceCharacter}={spaceCharacter}`})
			end
			table.insert(parts, {v = `{canBeUndefined and "\t" or ""}C("{instanceClassName}",{spaceCharacter}{parentVariable},{spaceCharacter}`})
			table.insert(parts, {v = '{' .. propertyPrefix .. 'Name="' .. instanceToCopy.Name .. '",'})
		end

		local parsedProperties = { Name = true }

		local function isAlreadyParsed(propName, secondParse)
			if doDebug and parsedProperties[propName] and secondParse then 
				warn(`{propName} already parsed.`)
			end
			return parsedProperties[propName]
		end

		local function writeProperty(propName, parsedPropValue)
			if seenParsedProperties[parsedPropValue] then
				local variable = parsedPropertiesVariables:GetVariableName(parsedPropValue)
				table.insert(parts, {v = `{propertiesOnly and "" or "\t" .. propertyPrefix}{propName}={variable}{propertiesOnly and "" or ","}`})
			else
				table.insert(parts, {t = true, v = {propName, parsedPropValue}})
			end
			parsedProperties[propName] = true
			seenParsedProperties[parsedPropValue] = true
		end

		local function parseProperty(propName, propType, propValue)
			if isAlreadyParsed(propName, true) then return end

			local parsedPropValue = try(propType, propValue)

			if parsedPropValue ~= "Exception_NotFound" then
				writeProperty(propName, parsedPropValue)
			elseif doDebug then
				warn(`{propName} parse error. Skipped. {propType} {propValue}`)
			end
		end

		for _, member in ipairs(classInfo.Members) do
			local propName = member["Name"]

			if blacklistedPropNames[propName] then
				continue
			end

			--- EXCEPTION (for Text Gui Objects) ---
			if propName == "Transparency" then
				if string.find(instanceClassName, "Text") then
					propName = "TextTransparency"
				end
			end

			local valueType = member["ValueType"]
			local category = valueType["Category"]

			if not whitelistedCategories[category] then 
				print(`Category [{category}] is not Whitelisted; PropName: [{propName}]`) 
				continue 
			end
			local propType = valueType["Name"]
			if blacklistedPropTypes[propType] then
				continue
			end 

			if isAlreadyParsed(propName) then continue end

			local success, propValue = pcall(function()
				return instanceToCopy[propName]
			end)
			if success then
				if not instanceToCopy:IsPropertyModified(propName) then
					continue
				end

				local callbacks = {
					Class = function()
						local instanceVariable = instancesToVariables[propValue]
						if instanceVariable then
							--writeProperty(propName, instanceVariable)
							table.insert(parts, {v = `\t{propertyPrefix}{propName}={instanceVariable},`})
						end
					end,
					DataType = parseProperty,
					Enum = function()
						writeProperty(propName, returnEnum(propValue))
					end,
					Primitive = function()
						local parsedValue = returnEnumOrPrimitive(propValue)
						writeProperty(propName, parsedValue)
					end,
				}
				local cb = callbacks[category]
				if cb then cb(propName, propType, propValue) end
			end
		end

		if not propertiesOnly then
			--- Close the properties table
			table.insert(parts, {v = propertyTableWrap})
			------ Parse Tags and Attributes ------			
			local instanceTags = instanceToCopy:GetTags()
			local instanceAttributes = instanceToCopy:GetAttributes()

			local instanceAttributesNum = 0
			local attributesParts = {}

			for attributeName, attributeValue in pairs(instanceAttributes) do
				instanceAttributesNum += 1
				local attributeNameVariable = AttributeVariables:GetVariableName(attributeName)
				local parsedAttributeValue = try(typeof(attributeValue), attributeValue)

				if parsedAttributeValue == "Exception_NotFound" then
					warn("{\n\tCouldn't copy attribute:", attributeName, "\n\tfor instance:", instanceToCopy, "\n}")
					continue
				end

				if seenParsedProperties[parsedAttributeValue] then
					local variable = parsedPropertiesVariables:GetVariableName(parsedAttributeValue)
					table.insert(attributesParts, {v = `\t{propertyPrefix}[A.{attributeNameVariable}]={variable},`})
				else
					table.insert(attributesParts, {t = true, a = true, v = {attributeNameVariable, parsedAttributeValue}})
				end
				seenParsedProperties[parsedAttributeValue] = true
			end

			if #instanceTags < 1 and instanceAttributesNum < 1 then
				table.insert(parts, {v = "\t})"}) -- close the default properties
			else
				table.insert(parts, {v = "\t}," .. propertyTableWrap .. "\t{"})
				for i, tag : string in ipairs(instanceTags) do
					local tagVariableName = TagVariables:GetVariableName(tag)
					table.insert(parts, {v = `\t{propertyPrefix}T.{tagVariableName},`})
				end
				table.insert(parts, {v = propertyTableWrap .. "\t}"})


				if instanceAttributesNum > 0 then
					table.insert(parts, {v = "," .. propertyTableWrap .. "\t{"})
					for _, part in ipairs(attributesParts) do
						table.insert(parts, part)
					end
					table.insert(parts, {v = propertyTableWrap .. "\t}"})
				end



				table.insert(parts, {v = ")"})
			end



			if addTypization then
				table.insert(parts, {v = " :: " .. instanceClassName})
			end
		end

		totalCopied += 1
		if totalCopied % rateLimit == 0 then
			task.wait(rateLimitingWaitInterval)
		end
		progressCallback(totalCopied / totalInstances)

		return parts
		--return table.concat(parts)  -- Concat once at the end
	end
	--- /E Local Globals ---
	local variableTree = {This = mainParents, Children = {}}

	--- Core ---
	local function addToResult(parent, destination, lastPathString, children)
		if destination then
			destination[lastPathString] = {This = parent, Children = {}}
		end

		for i, child in ipairs(children) do
			if not canCountInstance(child) then continue end

			local thisChildren = child:GetChildren()
			local canRemainUndefined = leaveInstacesUndefined and #thisChildren < 1
			local variableName = ""
			if not canRemainUndefined then
				variableName = createVariableName(child, lastPathString, i)
				instancesToVariables[child] = variableName
			end
			local copiedInstance = copyInstance(child, lastPathString, variableName, canRemainUndefined)
			if copiedInstance == nil then continue end
			table.insert(resultShards, copiedInstance)
			addToResult(child, destination == nil and variableTree.Children or destination[lastPathString].Children, variableName, thisChildren)
		end
	end
	--- /E Core ---



	local resultParts = {} -- Main result builder table
	local serviceResultShards = {}



	local mainType = ""
	local mainTypes = {}
	local mainVariables = {}
	local sortedMainParents = {}
	for _, mainParent in ipairs(mainParents) do

		if typeof(mainParent) ~= "Instance" then continue end
		if not canCountInstance(mainParent) then continue end

		local instanceClassName = mainParent.ClassName
		if blacklistedClassNames[instanceClassName] then
			oneTimeWarn(`Not Copying ClassName [{instanceClassName}]; Blacklisted!`)
			continue
		end

		count(mainParent)
		table.insert(mainTypes, instanceClassName)



		local mainParentVariable = createVariableName(mainParent, mainParentString, nil) -- mainParentString or toPascalCase(mainParents.Name)
		if mainParent.Parent == game then
			table.insert(resultParts, `{mainParentVariable} = game:GetService("{mainParent.ClassName}"){addTypization and ` :: {mainParent.ClassName}` or ""}`)
			local parts = {}
			local originalParts = copyInstance(mainParent, nil, mainParentVariable, false, true)
			for _, part in ipairs(originalParts) do
				local newPart = {}
				if part["t"] then
					newPart["t"] = true
					newPart["v"] = {
						`{mainParentVariable}.{part["v"][1]}`,
						part["v"][2],
					}
				else
					newPart["v"] = `{mainParentVariable}.{part["v"]}`
				end
				table.insert(parts, newPart)
			end
			table.insert(serviceResultShards, parts)
		else
			table.insert(resultShards, copyInstance(mainParent, `parent`, mainParentVariable))
		end

		table.insert(mainVariables, mainParentVariable)
		sortedMainParents[mainParentVariable] = mainParent
	end
	if #mainTypes > 1 then
		mainType = "(" .. table.concat(mainTypes, ", ") .. ")"
	else
		mainType = mainTypes[1]
	end

	displayPrint("Analyzing Properties For "..tostring(totalInstances).." Instances")

	for mainParentVariable, mainParent in pairs(sortedMainParents) do
		addToResult(mainParent, nil, mainParentVariable, mainParent:GetChildren())
	end




	--- Assemble the final string ---
	displayPrint("Generating Output String")



	local header = [[local module = {}

local C : (className : string, parent : Instance, props : {[string]: (any)}?, tags : {[number]: string}?, attributes : {[string]: (any)}?) -> Instance, Component : {
	[string] : ModuleScript,
	["new"]: (componentName : string, parent : Instance, any) -> any,
}

function module.new(
	parent : Instance 
) : ]] .. mainType .. [[
	
	if not C then
		repeat task.wait() C = module["CreateInstance"] until C
	end
	if not Component then
		repeat task.wait() Component = module["Component"] until Component
	end]]



	local totalOperationCount = #resultShards + 3
	local operationsDone = 0
	local function operationDone(delta)
		--print(operationsDone, totalOperationCount)
		operationsDone += (delta or 1)
		progressCallback(operationsDone/totalOperationCount)
	end



	--- Build Tags Variables Part
	local TagShards = {"T = {"}
	for tag, variable in pairs(TagVariables.Variables) do
		table.insert(TagShards, `\t{variable}="{tag}",`)
	end
	table.insert(TagShards, "}")
	if #TagShards > 2 then
		table.insert(resultParts, table.concat(TagShards, "\n"))
	end

	--- Build Attributes Variables Part
	local AttributeShards = {"A = {"}
	for attributeName, variable in pairs(AttributeVariables.Variables) do
		table.insert(AttributeShards, `\t{variable}="{attributeName}",`)
	end
	table.insert(AttributeShards, "}")
	if #AttributeShards > 2 then
		table.insert(resultParts, table.concat(AttributeShards, "\n"))
	end

	--- Build variables result Part
	local variableShards = {}
	for value, variable in pairs(parsedPropertiesVariables.Variables) do
		table.insert(variableShards, `{variable}={value}`)
		totalOperationCount+=1
		operationDone()
	end
	if #variableShards > 0 then
		table.insert(resultParts, table.concat(variableShards, "\n"))
		operationDone()
	end



	table.insert(resultParts, header)



	if #serviceResultShards > 0 then
		local stringResultShards = {}
		for _, copiedInstanceParts in ipairs(serviceResultShards) do
			local parts = {}
			for _, part in ipairs(copiedInstanceParts) do
				if part["t"] then
					local propName, parsedPropValue = table.unpack(part.v)
					local variable = parsedPropertiesVariables:GetVariableName(parsedPropValue, true) --parsedPropertiesVariables[parsedPropValue]
					table.insert(parts, `\t{propName}={variable or parsedPropValue}`)
					continue
				end
				table.insert(parts, `\n\t{part.v}`)
			end
			table.insert(stringResultShards, table.concat(parts, "\n"))
			operationDone()
		end

		table.insert(resultParts, table.concat(stringResultShards, "\n"))
		operationDone()
	end



	--print(resultShards)
	--- Build resultPiece efficiently
	if #resultShards > 0 then
		local stringResultShards = {}
		for _, copiedInstanceParts in ipairs(resultShards) do
			local parts = {}
			for _, part in ipairs(copiedInstanceParts) do

				if part["t"] then
					local propName, parsedPropValue = table.unpack(part.v)
					local isAttribute = part["a"]
					local usedVariableDictionary = isAttribute and AttributeVariables or parsedPropertiesVariables

					local variable = usedVariableDictionary:GetVariableName(parsedPropValue, true) --parsedPropertiesVariables[parsedPropValue]

					if isAttribute then
						table.insert(parts, `\t{propertyPrefix}[A.{propName}]={variable or parsedPropValue},`)
					else -- regular property
						table.insert(parts, `\t{propertyPrefix}{propName}={variable or parsedPropValue},`)
					end

					continue
				end
				table.insert(parts, part.v)
			end
			--print(copiedInstanceParts, parts)
			table.insert(stringResultShards, table.concat(parts))
			operationDone()
		end

		table.insert(resultParts, table.concat(stringResultShards, "\n"))
		operationDone()
	end

	table.insert(resultParts, `\treturn {table.concat(mainVariables, ", ")}\nend\n\nreturn module`)

	local result = table.concat(resultParts, "\n\n")
	displayPrint(`Output length {#result}`)

	operationDone()
	progressCallback(1)
	codegenStarted = false

	if #result <= stringLimit then
		return true, {
			Result = result,
			ModuleName = table.concat(mainVariables, "_"),
		}
	end
	return false, "Component Is Too Big For One Module; Consider Decomposing It"
end

return module