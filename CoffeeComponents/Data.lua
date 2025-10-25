--[[
	MIT License
	Copyright © 2025 Coffilhg
	This plugin is licensed under the MIT License. Users must include attribution to "Coffilhg" (Roblox UserId 517222346) in game credits.
	Full license: https://github.com/Coffilhg/Coffee-Components-Plugin/tree/main
	Plugin Version: 1.2.0
--]]
local HttpService = game:GetService("HttpService")

local function fetch(url, decodeJson)
	local success, result = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		if decodeJson then
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(result)
			end)
			if ok then
				return decoded
			else
				return nil
			end
		else
			return result -- plain text
		end
	else
		return nil
	end
end


local module = {}

function module.requestData()
	return fetch("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json", true)
end

function module.requestVersion()
	return fetch("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/master/version.txt")
end


return module