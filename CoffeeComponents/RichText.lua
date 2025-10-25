--[[
	MIT License
	Copyright © 2025 Coffilhg
	This plugin is licensed under the MIT License. Users must include attribution to "Coffilhg" (Roblox UserId 517222346) in game credits.
	Full license: https://github.com/Coffilhg/Coffee-Components-Plugin/tree/main
	Plugin Version: 1.2.0
--]]
local module = {}

function module.new(
	createInstance : (string, Instance, {any}) -> Instance,
	parent : Instance,
	TextContent : string,
	LayoutOrder : number,
	TextSize : number,
	Width : UDim,
	TextColor : Color3,
	YPadding : number
) : TextLabel
	local InitialSize = UDim2.new(Width and Width.Scale or 0, Width and Width.Offset or 0, 0, 0)
	local Main = createInstance("TextLabel", parent, {
		Name = "TextLabel",
		Font = Enum.Font.Unknown,
		FontFace = Font.new("rbxassetid://12187365977", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		LineHeight = 1,
		MaxVisibleGraphemes = -1,
		OpenTypeFeatures = "",
		RichText = true,
		Text = TextContent,
		TextColor3 = TextColor or Color3.fromRGB(255, 255, 255),
		TextDirection = Enum.TextDirection.Auto,
		TextScaled = false,
		TextSize = TextSize or 42,
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		TextStrokeTransparency = 1,
		TextTransparency = 0,
		TextTruncate = Enum.TextTruncate.None,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Active = false,
		AnchorPoint = Vector2.new(0, 0),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderMode = Enum.BorderMode.Outline,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Interactable = true,
		LayoutOrder = LayoutOrder or 0,
		Position = UDim2.new(0, 0, 0, 0),
		Rotation = 0,
		Selectable = false,
		SelectionOrder = 0,
		Size = InitialSize,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Transparency = 1,
		Visible = true,
		ZIndex = 1,
		AutoLocalize = true,
		SelectionBehaviorDown = Enum.SelectionBehavior.Escape,
		SelectionBehaviorLeft = Enum.SelectionBehavior.Escape,
		SelectionBehaviorRight = Enum.SelectionBehavior.Escape,
		SelectionBehaviorUp = Enum.SelectionBehavior.Escape,
		SelectionGroup = false,
		Archivable = true,
		Sandboxed = false,
	}) :: TextLabel
	
	if not YPadding then
		YPadding = 0
	end
		
	local function updateSize()
		Main.Size = InitialSize + UDim2.new(0, 0, 0, Main.TextBounds.Y + YPadding*2)
	end
	updateSize()
	Main:GetPropertyChangedSignal("Text"):Connect(updateSize)
	
	local lastParentConnection = nil
	
	if parent:IsA("GuiObject") then
		lastParentConnection = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
	end
	
	Main:GetPropertyChangedSignal("Parent"):Connect(function(newParent)
		if lastParentConnection then
			lastParentConnection:Disconnect()
		end
		if not newParent then return end
		if newParent:IsA("GuiObject") then
			lastParentConnection = newParent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
		end
	end)
	
	return Main
end

return module