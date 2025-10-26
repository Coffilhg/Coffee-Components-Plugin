--[[
	MIT License
	Copyright © 2025 Coffilhg
	This plugin is licensed under the MIT License. Users must include attribution to "Coffilhg" (Roblox UserId 517222346) in game credits.
	Full license: https://github.com/Coffilhg/Coffee-Components-Plugin/tree/main
	Plugin Version: 1.2.0
--]]

local debugEnabled = false

local usedWarnMessages = {}
function oneTimeWarn(message)
	if usedWarnMessages[message] then return end
	usedWarnMessages[message] = true
	warn(message)
end
function createInstance(className, parent, props)
	local newInstance = Instance.new(className, parent)
	for propName, propVal in pairs(props) do
		local success, err = pcall(function()
			newInstance[propName] = propVal
		end)
		if (not success) and debugEnabled then
			if string.match(err, "(lacking capability Plugin)") then
				oneTimeWarn(`Property Name: {propName}; Can Only Be Set Using Plugin In Studio!`)
				continue
			end
			warn(`Error: {err}; Name: {propName}; Value:`, propVal)
		end
	end
	return newInstance
end



local components = {}
-- late load components --
for _, component in ipairs(script:GetChildren()) do
	if components[component.Name] then
		continue
	end
	components[component.Name] = require(component)
end



local module = {}

function module.new(componentName : string, parent : Instance, ...)
	--print(componentName, ...)
	local component = components[componentName]
	if not component then
		error(`Component "{componentName}" Not Found!`)
		return nil
	end
	return component.new(createInstance, parent, ...)
end

return module