--[[
	MIT License
	Copyright © 2025 Coffilhg
	This plugin is licensed under the MIT License. Users must include attribution to "Coffilhg" (Roblox UserId 517222346) in game credits.
	Full license: https://github.com/Coffilhg/Coffee-Components-Plugin/tree/main
	Plugin Version: 1.2.0
--]]
local module = {}

function module.new(
	C : (string, Instance, {any}) -> Instance, -- createInstance
	parent : Instance,
	colors : {Color3},
	TextContent : string,
	clickCallback : () -> any
) : TextButton
	local Main = C("TextButton", parent, {
		Name = "TextButton",
		Font = Enum.Font.Unknown,
		FontFace = Font.new("rbxassetid://12187365977", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		LineHeight = 1,
		MaxVisibleGraphemes = -1,
		OpenTypeFeatures = "",
		RichText = true,
		Text = TextContent,
		TextColor3 = colors[5],
		TextDirection = Enum.TextDirection.Auto,
		TextScaled = true,
		TextSize = 14,
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		TextStrokeTransparency = 1,
		TextTransparency = 0,
		TextTruncate = Enum.TextTruncate.None,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutoButtonColor = true,
		Modal = false,
		Selected = false,
		Style = Enum.ButtonStyle.Custom,
		Active = true,
		AnchorPoint = Vector2.new(0, 0),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundColor3 = colors[3],
		BackgroundTransparency = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderMode = Enum.BorderMode.Outline,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Interactable = true,
		LayoutOrder = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Rotation = 0,
		Selectable = true,
		SelectionOrder = 0,
		Size = UDim2.new(0.9, -3, 0, 24),
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Transparency = 0,
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
	}) :: TextButton
	local Main_1 = C("UIPadding", Main, {
		Name = "UIPadding",
		PaddingBottom = UDim.new(0.15, 0),
		PaddingLeft = UDim.new(0.05, 0),
		PaddingRight = UDim.new(0.05, 0),
		PaddingTop = UDim.new(0.05, 0),
		Archivable = true,
		Sandboxed = false,
	})
	local Main_2 = C("UICorner", Main, {
		Name = "UICorner",
		CornerRadius = UDim.new(0, 6),
		Archivable = true,
		Sandboxed = false,
	})
	local Main_3 = C("UIStroke", Main, {
		Name = "UIStroke",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderOffset = UDim.new(0, 0),
		BorderStrokePosition = Enum.BorderStrokePosition.Outer,
		Color = colors[1],
		Enabled = true,
		LineJoinMode = Enum.LineJoinMode.Round,
		StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
		Thickness = 1.2,
		Transparency = 0,
		ZIndex = 1,
		Archivable = true,
		Sandboxed = false,
	})
	
	if clickCallback then
		Main.MouseButton1Click:Connect(clickCallback)
	end
	
	return Main
end

return module