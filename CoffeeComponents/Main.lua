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
	colors : {Color3}
) : (ImageLabel, ScrollingFrame)
	local Main_1 = createInstance("ImageLabel", parent, {
		Name = "ImageLabel",
		Image = "",
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageContent = "Content",
		ImageRectOffset = Vector2.new(0, 0),
		ImageRectSize = Vector2.new(0, 0),
		ImageTransparency = 0,
		ResampleMode = Enum.ResamplerMode.Default,
		ScaleType = Enum.ScaleType.Stretch,
		SliceCenter = Rect.new(0, 0, 0, 0),
		SliceScale = 1,
		TileSize = UDim2.new(1, 0, 1, 0),
		Active = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundColor3 = colors[2],
		BackgroundTransparency = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderMode = Enum.BorderMode.Outline,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Interactable = true,
		LayoutOrder = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Rotation = 0,
		Selectable = false,
		SelectionOrder = 0,
		Size = UDim2.new(1, 0, 1, 0),
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
	})
	local Main_2 = createInstance("ScrollingFrame", parent, {
		Name = "ScrollingFrame",
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-bottom.png",
		BottomImageContent = "Content",
		CanvasPosition = Vector2.new(0, 0),
		CanvasSize = UDim2.new(0, 0, 2, 0),
		ElasticBehavior = Enum.ElasticBehavior.Always,
		HorizontalScrollBarInset = Enum.ScrollBarInset.Always,
		MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		MidImageContent = "Content",
		ScrollBarImageColor3 = colors[5],
		ScrollBarImageTransparency = 0,
		ScrollBarThickness = 12,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollingEnabled = true,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-top.png",
		TopImageContent = "Content",
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderMode = Enum.BorderMode.Outline,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Interactable = true,
		LayoutOrder = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Rotation = 0,
		Selectable = true,
		SelectionOrder = 0,
		Size = UDim2.new(1, 0, 1, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Transparency = 1,
		Visible = true,
		ZIndex = 1,
		AutoLocalize = true,
		SelectionBehaviorDown = Enum.SelectionBehavior.Escape,
		SelectionBehaviorLeft = Enum.SelectionBehavior.Escape,
		SelectionBehaviorRight = Enum.SelectionBehavior.Escape,
		SelectionBehaviorUp = Enum.SelectionBehavior.Escape,
		SelectionGroup = true,
		Archivable = true,
		Sandboxed = false,
	}) :: ScrollingFrame
	local Main_2_5 = createInstance("UIListLayout", Main_2, {
		Name = "UIListLayout",
		HorizontalFlex = Enum.UIFlexAlignment.None,
		ItemLineAlignment = Enum.ItemLineAlignment.Automatic,
		Padding = UDim.new(0, 12),
		VerticalFlex = Enum.UIFlexAlignment.None,
		Wraps = false,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Archivable = true,
		Parent = Main_2,
		Sandboxed = false,
	}) :: UIListLayout
	
	local function adjustSize()
		--print("!")
		Main_2.CanvasSize = UDim2.new(0, 0, 0, Main_2_5.AbsoluteContentSize.Y)
	end
	
	Main_2.DescendantAdded:Connect(function(descendant : Instance)
		if descendant:IsA("GuiObject") then
			descendant:GetPropertyChangedSignal("Size"):Connect(adjustSize)
		end
		adjustSize()
	end)
	
	return Main_1, Main_2
end

return module