--[[--
	MIT License
	Copyright © 2025 Coffilhg
	This plugin is licensed under the MIT License. Users must include attribution to "Coffilhg" (Roblox UserId 517222346) in game credits.
	Full license: https://github.com/Coffilhg/Coffee-Components-Plugin/blob/main/LICENSE
	Plugin Version: 2.1.0
--]]--

--- @Coffilhg | Coffee Components | [V2.1] ---
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

-- Manually load components to enable typization and autofills (straight access)
module.Main = require(script.Main)
module.TextButton = require(script.TextButton)
module.RichText = require(script.RichText)

-- late load components --
for _, component in ipairs(script:GetChildren()) do
	local componentName = component.Name
	assert(componentName ~= "new", `Never name a Component "new"; Consider Renaming all Components named "new".`)
	
	local componentModule = Components[componentName] or module[componentName]
	if not componentModule then
		componentModule = require(component)
	end
	
	module[componentName] = componentModule -- that's why never name a Component "new".
	Components[componentName] = componentModule
	
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

require(script.Attribute)

return module