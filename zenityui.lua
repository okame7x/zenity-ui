-- Zenity UI: Check-UI design system (solid slate canvas, GothamBlack + black outline, 3D beveled buttons,
-- 2-tier header divider, fading checkerboard, center-anchored micro-interactions, responsive UIScale) in the
-- purple "Rebirth" palette. Drop-in for the hub's previous library: same CreateWindow / CreateTab / AddSection /
-- Add* / Notify / CreateStatus / CreateStealPanel API and the same handle fields the hub reaches into.

-- Services.
local playersService = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local httpService = game:GetService("HttpService")

local localPlayer = playersService.LocalPlayer

local Library = { ReducedMotion = false, Screens = {}, Touch = userInputService.TouchEnabled and not userInputService.KeyboardEnabled }

-- Check-UI palette (canvas, cards, strokes) with the purple header archetype as the accent.
Library.Theme = {
	Canvas = Color3.fromRGB(59, 88, 102),
	Border = Color3.fromRGB(24, 30, 34),
	Card = Color3.fromRGB(26, 44, 52),
	CardHighlight = Color3.fromRGB(75, 125, 145),
	Recess = Color3.fromRGB(20, 34, 42),
	RecessBorder = Color3.fromRGB(85, 140, 160),
	Trough = Color3.fromRGB(20, 30, 36),
	Ink = Color3.fromRGB(17, 23, 26),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(196, 214, 228),
	Accent = Color3.fromRGB(204, 140, 255),
	Accent2 = Color3.fromRGB(160, 0, 255),
	Warning = Color3.fromRGB(255, 196, 64),
	Success = Color3.fromRGB(150, 240, 60),
	Error = Color3.fromRGB(255, 92, 120),
	Stroke = Color3.fromRGB(12, 20, 26),
}

-- Gradient / bevel / rim / checker colour sets for every 3D surface.
Library.Palettes = {
	Purple = { Gradient = { Color3.fromRGB(160, 0, 255), Color3.fromRGB(96, 0, 200) }, Bevel = Color3.fromRGB(60, 0, 110), Rim = Color3.fromRGB(224, 160, 255), Damier = Color3.fromRGB(96, 0, 144), Dark = Color3.fromRGB(80, 0, 120) },
	Lime = { Gradient = { Color3.fromRGB(180, 255, 25), Color3.fromRGB(105, 225, 0) }, Bevel = Color3.fromRGB(15, 120, 15), Rim = Color3.fromRGB(235, 255, 130), Damier = Color3.fromRGB(40, 160, 20) },
	Silver = { Gradient = { Color3.fromRGB(216, 222, 228), Color3.fromRGB(148, 160, 176) }, Bevel = Color3.fromRGB(72, 82, 96), Rim = Color3.fromRGB(255, 255, 255), Damier = Color3.fromRGB(96, 104, 112) },
	Red = { Gradient = { Color3.fromRGB(255, 32, 80), Color3.fromRGB(208, 0, 32) }, Bevel = Color3.fromRGB(112, 0, 16), Rim = Color3.fromRGB(255, 176, 200), Damier = Color3.fromRGB(144, 0, 24) },
	Amber = { Gradient = { Color3.fromRGB(255, 208, 0), Color3.fromRGB(255, 140, 0) }, Bevel = Color3.fromRGB(153, 76, 0), Rim = Color3.fromRGB(255, 240, 160), Damier = Color3.fromRGB(176, 96, 0) },
	Cyan = { Gradient = { Color3.fromRGB(0, 205, 255), Color3.fromRGB(0, 130, 245) }, Bevel = Color3.fromRGB(0, 50, 110), Rim = Color3.fromRGB(180, 240, 255), Damier = Color3.fromRGB(0, 75, 150) },
	Close = { Gradient = { Color3.fromRGB(255, 125, 175), Color3.fromRGB(255, 20, 40) }, Bevel = Color3.fromRGB(115, 0, 16), Rim = Color3.fromRGB(255, 210, 235), Damier = Color3.fromRGB(150, 0, 20) },
}

-- HUD colour pairs and state words, the same keys the hub feeds the Status / Steal HUDs with.
Library.Hud = {
	StateColors = {
		active = { Color3.fromRGB(150, 255, 40), Color3.fromRGB(60, 190, 0) },
		waiting = { Color3.fromRGB(255, 214, 40), Color3.fromRGB(255, 140, 0) },
		idle = { Color3.fromRGB(200, 208, 218), Color3.fromRGB(120, 132, 150) },
	},
	StateWords = { active = "WORKING", waiting = "WAITING", idle = "IDLE" },
	Red = { Color3.fromRGB(255, 80, 110), Color3.fromRGB(200, 0, 40) },
	Green = { Color3.fromRGB(150, 255, 40), Color3.fromRGB(40, 180, 0) },
	Grey = { Color3.fromRGB(200, 208, 218), Color3.fromRGB(120, 132, 150) },
	Bloom = { Color3.fromRGB(214, 120, 255), Color3.fromRGB(130, 0, 220) },
	Sky = { Color3.fromRGB(0, 205, 255), Color3.fromRGB(0, 120, 240) },
	Lilac = { Color3.fromRGB(190, 140, 255), Color3.fromRGB(120, 60, 220) },
	Gold = { Color3.fromRGB(255, 214, 40), Color3.fromRGB(255, 130, 0) },
}

Library.Assets = {
	Damier = "rbxassetid://385956923",
	Sunburst = "rbxassetid://130563114903838",
	Logo = "rbxassetid://74314729534917",
	OpenLogo = "rbxassetid://123727588877909",
	Shadow = "rbxassetid://6014261993",
}

-- Constants.
local LUCIDE_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
local FONT = Enum.Font.GothamBlack
local HEADER_HEIGHT = 60
local SIDEBAR_WIDTH = 154
local ROW_HEIGHT = 46
local OPTION_HEIGHT = 32
local BASE_VIEWPORT = Vector2.new(1050, 620)

local Theme, Palettes, Hud, Assets = Library.Theme, Library.Palettes, Library.Hud, Library.Assets

-- Small builders shared by every component.
local Util = { lucide = nil, tweenInfos = {} }

function Util.new(className, props, children)
	local object = Instance.new(className)
	local parent
	for key, value in props or {} do
		if key == "Parent" then
			parent = value
		else
			object[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = object
	end
	object.Parent = parent
	return object
end

function Util.tween(object, time, props, style, direction)
	local key = tostring(time) .. tostring(style) .. tostring(direction)
	local info = Util.tweenInfos[key]
	if not info then
		info = TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
		Util.tweenInfos[key] = info
	end
	local tween = tweenService:Create(object, info, props)
	tween:Play()
	return tween
end

function Util.corner(parent, radius)
	return Util.new("UICorner", { CornerRadius = UDim.new(0, radius or 4), Parent = parent })
end

function Util.stroke(parent, color, thickness, transparency, mode)
	return Util.new("UIStroke", {
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 2.4,
		Transparency = transparency or 0,
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border,
		-- Round joins: a Miter join on a rounded (UICorner) frame leaves spikes and gaps at the corners.
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

function Util.sequence(colors)
	if typeof(colors) == "ColorSequence" then
		return colors
	end
	return ColorSequence.new(colors[1], colors[2] or colors[1])
end

function Util.gradient(parent, colors, rotation)
	return Util.new("UIGradient", { Color = Util.sequence(colors), Rotation = rotation or 90, Parent = parent })
end

-- Outlined GothamBlack text; the outline thickness follows the size (Check-UI typography table).
function Util.text(parent, props)
	local size = props.TextSize or 14
	local label = Util.new("TextLabel", {
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		Font = FONT,
		Text = props.Text or "",
		TextSize = size,
		TextColor3 = props.TextColor3 or Theme.Text,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
		TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd,
		TextWrapped = props.TextWrapped or false,
		RichText = props.RichText or false,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		AutoLocalize = false,
		ZIndex = props.ZIndex or 1,
		Parent = parent,
	})
	-- Outline: a UIStroke only on big titles (18px+); everything else uses the text's own legacy stroke, which costs
	-- nothing to render (hundreds of UIStrokes were what made opening the window drop frames).
	if props.Stroke ~= false then
		local thickness = props.Stroke or math.clamp(size * 0.085, 1, 2.8)
		if size >= 18 or props.UIStroke then
			Util.new("UIStroke", {
				Name = "TextStroke",
				Color = props.StrokeColor or Theme.Ink,
				Thickness = thickness,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Parent = label,
			})
		else
			label.TextStrokeColor3 = props.StrokeColor or Theme.Ink
			label.TextStrokeTransparency = thickness >= 1.6 and 0 or 0.35
		end
	end
	return label
end

-- Seamless fading checkerboard (Check-UI §6.4): transparent at the top, textured at the bottom.
function Util.damier(parent, color, tile, zIndex, sequence)
	local image = Util.new("ImageLabel", {
		Name = "Damier",
		BackgroundTransparency = 1,
		Image = Assets.Damier,
		ImageColor3 = color or Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(tile or 22, tile or 22),
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex or 1,
		Parent = parent,
	})
	Util.new("UIGradient", {
		Rotation = 90,
		Transparency = sequence or NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.82),
			NumberSequenceKeypoint.new(0.7, 0.35),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		Parent = image,
	})
	return image
end

-- Recessed card: dark container, black border, translucent slate inner rim (Check-UI §6.8).
function Util.card(parent, props)
	local frame = Util.new("Frame", {
		Name = props.Name or "Card",
		BackgroundColor3 = props.Color or Theme.Card,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.new(1, 0, 0, ROW_HEIGHT),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ClipsDescendants = props.ClipsDescendants or false,
		ZIndex = props.ZIndex or 1,
		Parent = parent,
	})
	Util.corner(frame, props.Radius or 4)
	-- One outline per card (the inner highlight rim was a second frame + stroke on every row: dropped for speed).
	local outer = Util.stroke(frame, Color3.new(0, 0, 0), props.StrokeThickness or 2.4)
	return frame, outer, outer
end

-- 3D beveled surface (Check-UI button anatomy): gradient face, dark bottom extrusion, pastel inner rim, fading
-- checker, outlined label / icon and a center UIScale. Returns the root plus its parts for restyling.
function Util.bevel(parent, props)
	local palette = props.Palette or Palettes.Purple
	local zIndex = props.ZIndex or 2
	local root = Util.new("ImageButton", {
		Name = props.Name or "Bevel",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Image = "",
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromOffset(120, 40),
		ZIndex = zIndex,
		Parent = parent,
	})
	if type(props.Radius) == "number" then
		Util.corner(root, props.Radius)
	end
	local parts = { root = root }
	parts.stroke = Util.stroke(root, Color3.new(0, 0, 0), props.StrokeThickness or 2.6)
	if type(props.Radius) ~= "number" then
		parts.stroke.LineJoinMode = Enum.LineJoinMode.Miter
	end
	parts.gradient = Util.gradient(root, palette.Gradient, 90)
	-- The fading checker only where asked (Damier = true: big headers): a tiled image + gradient on every button is
	-- a real cost once there are dozens of them.
	if props.Damier then
		parts.damier = Util.damier(root, palette.Damier, props.Tile or 18, zIndex, NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.45, 0.8),
			NumberSequenceKeypoint.new(1, 0.55),
			}))
	end
	parts.bevel = Util.new("Frame", {
		Name = "BottomBevel",
		BackgroundColor3 = palette.Bevel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
		ZIndex = zIndex + 1,
		Parent = root,
	})
	local rim = Util.new("Frame", {
		Name = "InnerHighlight",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -1),
		Size = UDim2.new(1, -4, 1, -6),
		ZIndex = zIndex + 1,
		Parent = root,
	})
	if type(props.Radius) == "number" then
		Util.corner(rim, math.max(props.Radius - 2, 0))
	end
	parts.rim = Util.stroke(rim, palette.Rim, 1.2, 0.15)
	-- Minimal (tiny buttons): no inner rim and no checker, which only clutter a 20px face.
	if props.Minimal then
		parts.rim.Enabled = false
		if parts.damier then
			parts.damier.Visible = false
		end
	end
	local iconSize = props.IconSize or 18
	local textOffset = 0
	if props.Icon then
		parts.icon = Util.new("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(iconSize, iconSize),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = zIndex + 2,
			Parent = root,
		})
		Util.icon(parts.icon, props.Icon)
		textOffset = props.Text and props.Text ~= "" and (iconSize + 6) / 2 or 0
		parts.icon.Position = UDim2.new(0.5, props.Text and props.Text ~= "" and -textOffset - 4 or 0, 0.5, -2)
	end
	if props.Text then
		parts.label = Util.text(root, {
			Text = props.Text,
			TextSize = props.TextSize or 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, textOffset, 0.5, -2),
			Size = UDim2.new(1, -12 - textOffset * 2, 1, 0),
			ZIndex = zIndex + 2,
		})
		if parts.icon then
			-- Icon sits right before the text, both centred as one group.
			parts.label.AutomaticSize = Enum.AutomaticSize.X
			parts.label.Size = UDim2.fromScale(0, 1)
			local function place()
				local width = parts.label.TextBounds.X
				parts.label.Position = UDim2.new(0.5, (iconSize + 6) / 2, 0.5, -2)
				parts.icon.Position = UDim2.new(0.5, -width / 2 - 3, 0.5, -2)
			end
			parts.label:GetPropertyChangedSignal("TextBounds"):Connect(place)
			place()
		end
	end
	parts.scale = Util.new("UIScale", { Name = "ButtonScale", Parent = root })
	function parts.setPalette(newPalette)
		palette = newPalette
		parts.gradient.Color = Util.sequence(newPalette.Gradient)
		parts.bevel.BackgroundColor3 = newPalette.Bevel
		parts.rim.Color = newPalette.Rim
		if parts.damier then
			parts.damier.ImageColor3 = newPalette.Damier
		end
	end
	if props.Feedback ~= false then
		Util.feedback(root, parts.scale, props.Hover, props.Press)
	end
	return root, parts
end

-- Center-anchored micro-interactions (Check-UI §8): hover in / out, press, release with Back overshoot.
function Util.feedback(button, scale, hoverFactor, pressFactor)
	hoverFactor, pressFactor = hoverFactor or 1.05, pressFactor or 0.94
	local hovering = false
	button.MouseEnter:Connect(function()
		hovering = true
		Util.tween(scale, 0.08, { Scale = hoverFactor })
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		Util.tween(scale, 0.08, { Scale = 1 })
	end)
	button.MouseButton1Down:Connect(function()
		Util.tween(scale, 0.05, { Scale = pressFactor })
	end)
	button.MouseButton1Up:Connect(function()
		Util.tween(scale, 0.12, { Scale = hovering and hoverFactor or 1 }, Enum.EasingStyle.Back)
	end)
end

-- Lucide icons load in the background (a synchronous HttpGet on the first icon froze the game while the window was
-- built); icons asked for meanwhile wait in pendingIcons and are filled in once the set arrives.
Util.pendingIcons = setmetatable({}, { __mode = "k" })

function Util.startLucide()
	if Util.lucideLoading or Util.lucide ~= nil then
		return
	end
	Util.lucideLoading = true
	task.spawn(function()
		local ok, result = pcall(function()
			return loadstring(game:HttpGet(LUCIDE_URL))()
		end)
		Util.lucide = ok and type(result) == "table" and result or false
		Util.lucideLoading = false
		local pending = Util.pendingIcons
		Util.pendingIcons = setmetatable({}, { __mode = "k" })
		for label, icon in pending do
			if label.Parent then
				Util.icon(label, icon)
			end
		end
	end)
end

-- Never blocks: the set once loaded, nil while it is still on its way.
function Util.loadLucide()
	if Util.lucide == nil then
		Util.startLucide()
		return nil
	end
	return Util.lucide
end

function Util.isLucideName(icon)
	return type(icon) == "string" and icon ~= "" and not icon:find("^rbx") and not icon:find("^https?://") and not icon:find("%.")
end

-- Lucide name ("send", "lucide:send"), rbxassetid / http / workspace file, or { Image, RectOffset, RectSize }.
function Util.resolveIcon(icon)
	if typeof(icon) == "table" then
		return icon.Image, icon.RectOffset, icon.RectSize
	end
	if type(icon) == "number" then
		return "rbxassetid://" .. icon
	end
	if type(icon) ~= "string" or icon == "" then
		return nil
	end
	if icon:find("^rbxassetid://") or icon:find("^rbxasset://") or icon:find("^rbxthumb://") then
		return icon
	end
	local isLocal = false
	if isfile and icon:find("%.") then
		local ok, exists = pcall(isfile, icon)
		isLocal = ok and exists == true
	end
	if icon:find("^https?://") or isLocal then
		return Util.customImage(icon)
	end
	local set = Util.loadLucide()
	if not set then
		return nil
	end
	local entry = (set.Icons and set.Icons[icon:gsub("^lucide:", "")]) or set[icon:gsub("^lucide:", "")]
	if type(entry) == "table" then
		local image = entry.Image
		if type(image) == "number" then
			image = "rbxassetid://" .. image
		end
		return (set.Spritesheets and set.Spritesheets[tostring(image)]) or image, entry.ImageRectPosition, entry.ImageRectSize
	end
	return type(entry) == "string" and entry or nil
end

-- A PNG from a URL or the workspace as a content id (writefile + getcustomasset), cached under ZenityUI/.
Util.imageCache = {}
function Util.customImage(source)
	if Util.imageCache[source] then
		return Util.imageCache[source]
	end
	local ok, asset = pcall(function()
		local path = source
		if source:find("^https?://") then
			path = "ZenityUI/" .. httpService:GenerateGUID(false):sub(1, 8) .. ".png"
			local name = source:match("([^/?#]+)%.png") or source:match("([^/?#]+)$")
			if name then
				path = "ZenityUI/" .. name:gsub("[^%w%-_]", "_") .. ".png"
			end
			if not (isfolder and isfolder("ZenityUI")) then
				makefolder("ZenityUI")
			end
			if not isfile(path) then
				local body
				if request then
					local response = request({ Url = source, Method = "GET" })
					body = response and response.Body
				else
					body = game:HttpGet(source)
				end
				writefile(path, body)
			end
		end
		return getcustomasset(path)
	end)
	Util.imageCache[source] = ok and asset or nil
	return Util.imageCache[source]
end

-- Positions the player dragged (floating button), kept in ZenityUI/positions.json between executions.
function Util.readPositions()
	local ok, data = pcall(function()
		return httpService:JSONDecode(readfile("ZenityUI/positions.json"))
	end)
	return ok and type(data) == "table" and data or {}
end

function Util.loadPosition(key, default)
	local entry = Util.readPositions()[key]
	if type(entry) == "table" and #entry == 4 then
		return UDim2.new(entry[1], entry[2], entry[3], entry[4])
	end
	return default
end

function Util.savePosition(key, position)
	pcall(function()
		local data = Util.readPositions()
		data[key] = { position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset }
		if not isfolder("ZenityUI") then
			makefolder("ZenityUI")
		end
		writefile("ZenityUI/positions.json", httpService:JSONEncode(data))
	end)
end

function Util.icon(imageLabel, icon)
	if Util.isLucideName(icon) and Util.lucide == nil then
		Util.pendingIcons[imageLabel] = icon
		Util.startLucide()
		imageLabel.Image = ""
		return
	end
	Util.pendingIcons[imageLabel] = nil
	local image, offset, size = Util.resolveIcon(icon)
	imageLabel.Image = image or ""
	if offset and size then
		imageLabel.ImageRectOffset = offset
		imageLabel.ImageRectSize = size
	else
		imageLabel.ImageRectOffset = Vector2.zero
		imageLabel.ImageRectSize = Vector2.zero
	end
end

function Util.deviceScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or BASE_VIEWPORT
	if viewport.X <= 0 or viewport.Y <= 0 then
		return 1
	end
	return math.clamp(math.min(viewport.X / BASE_VIEWPORT.X, viewport.Y / BASE_VIEWPORT.Y), 0.52, 1.18)
end

-- Keeps a UIScale on the device scale (times an extra factor the caller may animate).
function Util.responsive(scale, connections, factor)
	local function update()
		scale.Scale = Util.deviceScale() * (factor and factor() or 1)
	end
	update()
	local camera = workspace.CurrentCamera
	if camera then
		table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
	end
	return update
end

function Util.parent(preferred)
	if typeof(preferred) == "Instance" then
		return preferred
	end
	local ok, hidden = pcall(function()
		return gethui()
	end)
	if ok and typeof(hidden) == "Instance" then
		return hidden
	end
	return localPlayer:WaitForChild("PlayerGui")
end

function Util.screen(name, order, parent)
	local target = Util.parent(parent)
	local old = target:FindFirstChild(name)
	if old and old:IsA("ScreenGui") then
		old:Destroy()
	end
	return Util.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 100,
		Parent = target,
	})
end

function Util.isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Util.isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

-- Drags target by handle, kept inside the screen. A drag that started over a "NoDrag" child is ignored.
-- The mouse fires InputChanged many times per frame (high polling rates); moving the whole window on each one
-- re-laid it out several times a frame and dropped FPS. Moves are only recorded there and applied once per frame,
-- on a RenderStepped connection that lives only while the drag does.
function Util.drag(handle, target, connections)
	local dragging, startInput, startPosition, latest, stepper
	local function apply()
		if not latest then
			return
		end
		-- The anchor point stays on screen (40px from the sides, 20px from top / bottom).
		local delta = latest - startInput
		latest = nil
		local gui = target:FindFirstAncestorWhichIsA("ScreenGui")
		local screen = gui and gui.AbsoluteSize or BASE_VIEWPORT
		local offsetX, offsetY = startPosition.X.Offset + delta.X, startPosition.Y.Offset + delta.Y
		local x = startPosition.X.Scale * screen.X + offsetX
		local y = startPosition.Y.Scale * screen.Y + offsetY
		offsetX += math.clamp(x, 40, math.max(40, screen.X - 40)) - x
		offsetY += math.clamp(y, 20, math.max(20, screen.Y - 20)) - y
		target.Position = UDim2.new(startPosition.X.Scale, offsetX, startPosition.Y.Scale, offsetY)
	end
	local function stop()
		dragging = false
		apply()
		if stepper then
			stepper:Disconnect()
			stepper = nil
		end
	end
	table.insert(connections, handle.InputBegan:Connect(function(input)
		if not Util.isPress(input) then
			return
		end
		dragging, startInput, startPosition, latest = true, input.Position, target.Position, nil
		if not stepper then
			stepper = runService.RenderStepped:Connect(apply)
		end
		local ended
		ended = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				stop()
				ended:Disconnect()
			end
		end)
	end))
	table.insert(connections, userInputService.InputChanged:Connect(function(input)
		if dragging and Util.isMove(input) then
			latest = input.Position
		end
	end))
	table.insert(connections, {
		Disconnect = function()
			if stepper then
				stepper:Disconnect()
				stepper = nil
			end
		end,
	})
end

function Util.safeCall(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[Zenity UI] callback error: " .. tostring(err))
	end
end

function Util.selectionArray(value)
	local result = {}
	if type(value) ~= "table" then
		if value ~= nil then
			result[1] = value
		end
		return result
	end
	for key, selected in value do
		if type(key) == "number" then
			table.insert(result, selected)
		elseif selected == true then
			table.insert(result, key)
		end
	end
	return result
end

function Util.selectionMap(value)
	local result = {}
	for _, entry in Util.selectionArray(value) do
		result[entry] = true
	end
	return result
end

-- Options table accepted as (id, options) or (options); Text / Title / Name all name the element.
function Util.options(idOrOptions, options)
	local id, result = nil, {}
	if type(idOrOptions) == "table" then
		options = idOrOptions
	else
		id = idOrOptions
	end
	for key, value in type(options) == "table" and options or {} do
		result[key] = value
	end
	result.Name = result.Name or result.Text or result.Title or (id ~= nil and tostring(id)) or ""
	result.Desc = result.Desc or result.Description
	result.Default = result.Default ~= nil and result.Default or result.Value or result.CurrentOption
	result.Values = result.Values or result.Options or {}
	result.Multi = result.Multi == true or result.MultipleOptions == true
	return result
end

function Util.compact(value)
	value = tonumber(value) or 0
	for _, suffix in { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } } do
		if math.abs(value) >= suffix[1] then
			return (("%.1f"):format(value / suffix[1]):gsub("%.0$", "")) .. suffix[2]
		end
	end
	return tostring(math.floor(value + 0.5))
end

-- ============================================================================================================
-- Containers (tabs and sections): every element builder lives here, so a section works like a tab.
-- ============================================================================================================

local Container = {}
Container.__index = Container

function Container:_nextOrder()
	self._order += 1
	return self._order
end

-- Element shell: a recessed card row in the list, the title (and description) on the left.
function Container:_row(opts, height, rightReserve)
	local hasDesc = type(opts.Desc) == "string" and opts.Desc ~= ""
	height = height or (hasDesc and ROW_HEIGHT + 14 or ROW_HEIGHT)
	local frame, _, rim = Util.card(self.List, { Name = opts.Name ~= "" and opts.Name or "Element", Size = UDim2.new(1, 0, 0, height), LayoutOrder = self:_nextOrder() })
	frame:SetAttribute("NoDrag", true)
	-- The outline lights up purple under the pointer.
	frame.MouseEnter:Connect(function()
		Util.tween(rim, 0.12, { Color = Palettes.Purple.Rim })
	end)
	frame.MouseLeave:Connect(function()
		Util.tween(rim, 0.18, { Color = Color3.new(0, 0, 0) })
	end)
	local title = Util.text(frame, {
		Name = "Title",
		Text = opts.Name,
		TextSize = 15,
		Position = UDim2.fromOffset(14, hasDesc and 7 or 0),
		Size = UDim2.new(1, -(rightReserve or 80) - 20, 0, hasDesc and 22 or ROW_HEIGHT),
		ZIndex = 2,
	})
	local desc
	if hasDesc then
		desc = Util.text(frame, {
			Name = "Description",
			Text = opts.Desc,
			TextSize = 11,
			Stroke = 1.2,
			TextColor3 = Theme.Muted,
			Position = UDim2.fromOffset(14, 29),
			Size = UDim2.new(1, -(rightReserve or 80) - 20, 0, 18),
			ZIndex = 2,
		})
	end
	return frame, title, desc
end

function Container:_handle(frame, element)
	element._frame = frame
	function element:Destroy()
		if frame then
			frame:Destroy()
		end
	end
	if element.SetVisible == nil then
		function element:SetVisible(value)
			frame.Visible = value ~= false
		end
	end
	-- SetValue as an alias of Set, only for elements without their own SetValue (stat tiles have one).
	if element.SetValue == nil then
		element.SetValue = function(first, second)
			local value = first == element and second or first
			if element.Set then
				return element:Set(value)
			end
		end
	end
	return element
end

-- Collapsible section: purple beveled heading with a chevron, its rows below.
function Container:AddSection(text)
	local expanded = true
	if type(text) == "table" then
		expanded = text.Expanded ~= false
		text = text.Name or text.Title or text.Text or ""
	end
	local holder = Util.new("Frame", {
		Name = "Section",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_nextOrder(),
		Parent = self.List,
	})
	Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = holder })
	local headingHolder = Util.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 1, Parent = holder })
	local heading, parts = Util.bevel(headingHolder, {
		Name = "Heading",
		Palette = Palettes.Purple,
		Size = UDim2.new(1, -4, 1, -2),
		Hover = 1.015,
		Press = 0.98,
		Tile = 20,
	})
	heading:SetAttribute("NoDrag", true)
	local title = Util.text(heading, {
		Name = "Title",
		Text = string.upper(tostring(text)),
		TextSize = 15,
		Position = UDim2.fromOffset(14, -2),
		Size = UDim2.new(1, -50, 1, 0),
		ZIndex = 5,
	})
	local chevron = Util.text(heading, {
		Name = "Chevron",
		Text = "▼",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, -2),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 5,
	})
	local list = Util.new("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Visible = expanded,
		Parent = holder,
	})
	Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 7), Parent = list })
	Util.new("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), Parent = list })
	local section = setmetatable({ Name = tostring(text), Window = self.Window, List = list, Expanded = expanded, _order = 0, _frame = holder }, Container)
	local function render(animate)
		list.Visible = section.Expanded
		Util.tween(chevron, animate and 0.18 or 0, { Rotation = section.Expanded and 0 or -90 })
	end
	function section:SetExpanded(value)
		section.Expanded = value ~= false
		render(true)
	end
	function section:SetTitle(value)
		title.Text = string.upper(tostring(value or ""))
	end
	function section:SetVisible(value)
		holder.Visible = value ~= false
	end
	heading.MouseButton1Click:Connect(function()
		section:SetExpanded(not section.Expanded)
	end)
	render(false)
	local _ = parts
	return section
end

-- Toggle: a beveled switch (lime on / silver off) with a sliding white knob.
function Container:AddToggle(idOrOptions, options)
	local opts = Util.options(idOrOptions, options)
	local frame = self:_row(opts, nil, 70)
	local switch = Util.new("Frame", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(56, 28),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = frame,
	})
	Util.stroke(switch, Color3.new(0, 0, 0), 2.4)
	local gradient = Util.gradient(switch, Palettes.Silver.Gradient, 90)
	local bevel = Util.new("Frame", { BackgroundColor3 = Palettes.Silver.Bevel, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), ZIndex = 3, Parent = switch })
	local knob = Util.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, -1),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = switch,
	})
	Util.corner(knob, 4)
	Util.stroke(knob, Color3.new(0, 0, 0), 2)
	Util.gradient(knob, { Color3.new(1, 1, 1), Color3.fromRGB(205, 214, 224) }, 90)
	local knobScale = Util.new("UIScale", { Parent = knob })
	-- ON / OFF on the side the knob is not covering.
	local stateLabel = Util.text(switch, { Text = "OFF", TextSize = 9, Stroke = 1.4, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(0, 28, 1, -3), ZIndex = 4 })
	local hit = Util.new("TextButton", { Name = "Hit", BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = frame })
	local element = { Value = opts.Default == true, Type = "Toggle" }
	local function render(animate)
		local palette = element.Value and Palettes.Lime or Palettes.Silver
		gradient.Color = Util.sequence(palette.Gradient)
		bevel.BackgroundColor3 = palette.Bevel
		stateLabel.Text = element.Value and "ON" or "OFF"
		stateLabel.Position = element.Value and UDim2.fromOffset(3, 0) or UDim2.new(1, -30, 0, 0)
		Util.tween(knob, animate and 0.22 or 0, { Position = element.Value and UDim2.new(1, -23, 0.5, -1) or UDim2.new(0, 3, 0.5, -1) }, Enum.EasingStyle.Back)
		if animate then
			knobScale.Scale = 0.75
			Util.tween(knobScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	function element:Set(value, silent)
		value = value == true
		if value == element.Value then
			return
		end
		element.Value = value
		render(true)
		if not silent then
			Util.safeCall(opts.Callback, value)
		end
	end
	function element:Get()
		return element.Value
	end
	element.SetStage = function(value)
		element:Set(value)
	end
	hit.MouseButton1Click:Connect(function()
		element:Set(not element.Value)
	end)
	render(false)
	self:_handle(frame, element)
	if element.Value then
		Util.safeCall(opts.Callback, true)
	end
	return element
end

-- Slider: recessed trough, orange-to-gold fill with its bevel, a white knob and the value chip.
function Container:AddSlider(idOrOptions, options)
	local opts = Util.options(idOrOptions, options)
	local min, max = tonumber(opts.Min) or 0, tonumber(opts.Max) or 100
	local step = tonumber(opts.Step or opts.Increment) or ((min % 1 == 0 and max % 1 == 0) and 1 or 0.01)
	local hasDesc = type(opts.Desc) == "string" and opts.Desc ~= ""
	local frame = self:_row(opts, ROW_HEIGHT + (hasDesc and 34 or 20), 90)
	local chip = Util.new("Frame", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 9),
		Size = UDim2.fromOffset(74, 26),
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = frame,
	})
	Util.corner(chip, 4)
	Util.stroke(chip, Theme.RecessBorder, 1.2)
	local valueBox = Util.new("TextBox", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 14,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 4,
		Parent = chip,
	})
	Util.new("UIStroke", { Thickness = 1.6, Color = Theme.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = valueBox })
	local trough = Util.new("Frame", {
		Name = "Trough",
		Position = UDim2.new(0, 14, 1, -22),
		Size = UDim2.new(1, -28, 0, 12),
		BackgroundColor3 = Theme.Trough,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = frame,
	})
	Util.corner(trough, 4)
	Util.stroke(trough, Color3.fromRGB(12, 18, 22), 2)
	local fill = Util.new("Frame", { Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = trough })
	Util.corner(fill, 4)
	Util.gradient(fill, { Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 106, 0) }, 90)
	Util.new("Frame", { BackgroundColor3 = Color3.fromRGB(153, 60, 0), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), ZIndex = 5, Parent = fill })
	local knob = Util.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(18, 22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = trough,
	})
	Util.corner(knob, 4)
	Util.stroke(knob, Color3.new(0, 0, 0), 2)
	Util.gradient(knob, { Color3.new(1, 1, 1), Color3.fromRGB(205, 214, 224) }, 90)
	local knobScale = Util.new("UIScale", { Parent = knob })
	local hit = Util.new("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.new(0, 0, 0, -10), Size = UDim2.new(1, 0, 1, 20), ZIndex = 7, Parent = trough })
	hit:SetAttribute("NoDrag", true)
	local element = { Type = "Slider" }
	local function snap(value)
		value = math.clamp(tonumber(value) or min, min, max)
		value = min + math.floor((value - min) / step + 0.5) * step
		if step >= 1 then
			value = math.floor(value + 0.5)
		else
			local decimals = math.max(0, math.ceil(-math.log10(step)))
			value = tonumber(("%." .. decimals .. "f"):format(value))
		end
		return math.clamp(value, min, max)
	end
	local function render(animate)
		local alpha = max > min and (element.Value - min) / (max - min) or 0
		Util.tween(fill, animate and 0.08 or 0, { Size = UDim2.fromScale(alpha, 1) })
		Util.tween(knob, animate and 0.08 or 0, { Position = UDim2.fromScale(alpha, 0.5) })
		if not valueBox:IsFocused() then
			valueBox.Text = tostring(element.Value) .. (opts.Suffix or "")
		end
	end
	function element:Set(value, silent)
		value = snap(value)
		if value == element.Value then
			render(false)
			return
		end
		element.Value = value
		render(true)
		if not silent then
			Util.safeCall(opts.Callback, value)
		end
	end
	function element:Get()
		return element.Value
	end
	element.Value = snap(opts.Default or min)
	local dragging = false
	local function fromInput(input)
		local alpha = math.clamp((input.Position.X - trough.AbsolutePosition.X) / math.max(trough.AbsoluteSize.X, 1), 0, 1)
		element:Set(min + (max - min) * alpha)
	end
	hit.InputBegan:Connect(function(input)
		if Util.isPress(input) then
			dragging = true
			Util.tween(knobScale, 0.1, { Scale = 1.2 })
			fromInput(input)
		end
	end)
	userInputService.InputChanged:Connect(function(input)
		if dragging and Util.isMove(input) then
			fromInput(input)
		end
	end)
	userInputService.InputEnded:Connect(function(input)
		if dragging and Util.isPress(input) then
			dragging = false
			Util.tween(knobScale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end)
	valueBox.FocusLost:Connect(function()
		local number = tonumber((valueBox.Text:gsub("[^%d%.%-]", "")))
		if number then
			element:Set(number)
		end
		render(false)
	end)
	render(false)
	return self:_handle(frame, element)
end

-- Dropdown: the value chip on the row, a list that slides open under it (search box for long lists). Options are
-- TextButtons with a TextLabel "Label" inside, so hub decorators (rarity look, option icons) find them.
function Container:AddDropdown(idOrOptions, options)
	local opts = Util.options(idOrOptions, options)
	local multi = opts.Multi
	local values = opts.Values
	local selected = Util.selectionMap(opts.Default)
	if not multi then
		local first = Util.selectionArray(opts.Default)[1]
		selected = first ~= nil and { [first] = true } or {}
	end
	local frame = self:_row(opts, nil, 190)
	frame.ClipsDescendants = true
	local closedHeight = frame.Size.Y.Offset
	local chip = Util.new("Frame", {
		Name = "ValueChip",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, (closedHeight - 28) / 2),
		Size = UDim2.fromOffset(176, 28),
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = frame,
	})
	Util.corner(chip, 4)
	Util.stroke(chip, Theme.RecessBorder, 1.2)
	local valueLabel = Util.text(chip, { Name = "Value", TextSize = 13, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), ZIndex = 4 })
	local arrow = Util.text(chip, {
		Name = "Arrow",
		Text = "▼",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 4,
	})
	local hit = Util.new("TextButton", { Name = "Hit", BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, closedHeight), ZIndex = 6, Parent = frame })
	-- Open area: one recessed panel under the row holding the toolbar (multi: count + All / None), the search box
	-- (long lists) and the options - plain rows, the picked ones on a purple tint with an accent bar and a check.
	local panelBox = Util.new("Frame", {
		Name = "OptionsPanel",
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, closedHeight + 2),
		Size = UDim2.new(1, -24, 0, 0),
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = frame,
	})
	Util.corner(panelBox, 4)
	Util.stroke(panelBox, Color3.new(0, 0, 0), 2)
	local toolbar = Util.new("Frame", { Name = "Toolbar", BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 22), Visible = multi, ZIndex = 4, Parent = panelBox })
	local countLabel = Util.text(toolbar, { Text = "", TextSize = 11, Stroke = 1.4, TextColor3 = Theme.Muted, Size = UDim2.new(1, -124, 1, 0), ZIndex = 4 })
	local allHolder = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -62, 0, 0), Size = UDim2.fromOffset(56, 22), ZIndex = 4, Parent = toolbar })
	local allButton = Util.bevel(allHolder, { Palette = Palettes.Purple, Size = UDim2.fromScale(1, 1), Text = "ALL", TextSize = 11, ZIndex = 5, Minimal = true, StrokeThickness = 2, Hover = 1.06 })
	local noneHolder = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(56, 22), ZIndex = 4, Parent = toolbar })
	local noneButton = Util.bevel(noneHolder, { Palette = Palettes.Silver, Size = UDim2.fromScale(1, 1), Text = "NONE", TextSize = 11, ZIndex = 5, Minimal = true, StrokeThickness = 2, Hover = 1.06 })
	local search = Util.new("TextBox", {
		Name = "Search",
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Font = FONT,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Color3.fromRGB(120, 150, 165),
		Text = "",
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 0, 26),
		Visible = false,
		ZIndex = 4,
		Parent = panelBox,
	})
	Util.corner(search, 4)
	Util.stroke(search, Theme.RecessBorder, 1.2)
	Util.new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = search })
	local list = Util.new("ScrollingFrame", {
		Name = "Options",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 4,
		Parent = panelBox,
	})
	list:SetAttribute("NoDrag", true)
	Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = list })
	Util.new("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = list })
	local element = { Type = "Dropdown", Open = false }
	local buttons, filter = {}, ""
	local ROW = OPTION_HEIGHT - 2

	local function currentValue()
		if multi then
			local result = {}
			for _, option in values do
				if selected[option] then
					table.insert(result, option)
				end
			end
			return result
		end
		for _, option in values do
			if selected[option] then
				return option
			end
		end
		return next(selected)
	end
	local function renderValue()
		local value = currentValue()
		if multi then
			valueLabel.Text = #value == 0 and "None" or (#value <= 2 and table.concat(value, ", ") or (#value .. " selected"))
			countLabel.Text = ("%d / %d selected"):format(#value, #values)
		else
			valueLabel.Text = value ~= nil and tostring(value) or "None"
		end
	end
	local function paint(button, option)
		local on = selected[option] == true
		button.on = on
		button.root.BackgroundTransparency = (on or button.hovered) and 0 or 1
		button.root.BackgroundColor3 = on and Color3.fromRGB(58, 28, 96) or Theme.Card
		button.bar.Visible = on
		button.check.BackgroundTransparency = on and 0 or 1
		button.checkStroke.Color = on and Color3.new(0, 0, 0) or Theme.Muted
		button.mark.Visible = on
	end
	local function visibleCount()
		local count = 0
		for _, button in buttons do
			if button.root.Visible then
				count += 1
			end
		end
		return count
	end
	local function panelHeight()
		local top = 6 + (toolbar.Visible and 28 or 0)
		search.Position = UDim2.fromOffset(8, top)
		top += search.Visible and 32 or 0
		list.Position = UDim2.fromOffset(6, top)
		local listHeight = math.min(visibleCount(), 6) * (ROW + 2)
		list.Size = UDim2.new(1, -12, 0, listHeight)
		return top + listHeight + 6
	end
	local function openHeight()
		return closedHeight + 2 + panelHeight() + 10
	end
	local function layout(animate)
		panelBox.Size = UDim2.new(1, -24, 0, panelHeight())
		Util.tween(frame, animate and 0.22 or 0, { Size = UDim2.new(1, 0, 0, element.Open and openHeight() or closedHeight) }, Enum.EasingStyle.Quint)
		Util.tween(arrow, animate and 0.2 or 0, { Rotation = element.Open and 180 or 0 })
	end
	local function applyFilter()
		for option, button in buttons do
			button.root.Visible = filter == "" or tostring(option):lower():find(filter, 1, true) ~= nil
		end
	end
	local function build()
		for _, button in buttons do
			button.root:Destroy()
		end
		table.clear(buttons)
		for index, option in values do
			local root = Util.new("TextButton", {
				Name = "Option",
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Card,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, ROW),
				ZIndex = 5,
				Parent = list,
			})
			Util.corner(root, 4)
			local bar = Util.new("Frame", { Name = "Accent", BackgroundColor3 = Palettes.Purple.Rim, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 5), Size = UDim2.new(0, 3, 1, -10), Visible = false, ZIndex = 6, Parent = root })
			Util.corner(bar, 2)
			local optionLabel = Util.text(root, { Name = "Label", Text = tostring(option), TextSize = 13, Stroke = 1.6, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -46, 1, 0), ZIndex = 6 })
			-- Hook for the host (rarity look, option icons): called once per option instead of watching the window.
			if type(Library.OptionHook) == "function" then
				task.defer(Util.safeCall, Library.OptionHook, optionLabel)
			end
			-- Multi: a square box; single: a round one.
			local check = Util.new("Frame", {
				Name = "Check",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 6,
				Parent = root,
			})
			Util.corner(check, multi and 4 or 8)
			Util.gradient(check, Palettes.Purple.Gradient, 90)
			local checkStroke = Util.stroke(check, Theme.Muted, 1.6)
			local mark = Util.text(check, { Text = multi and "✓" or "•", TextSize = multi and 11 or 16, Stroke = 1.2, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 7 })
			local button = { root = root, bar = bar, check = check, checkStroke = checkStroke, mark = mark }
			buttons[option] = button
			paint(button, option)
			root.MouseEnter:Connect(function()
				button.hovered = true
				if not button.on then
					Util.tween(root, 0.08, { BackgroundTransparency = 0 })
				end
			end)
			root.MouseLeave:Connect(function()
				button.hovered = false
				if not button.on then
					Util.tween(root, 0.1, { BackgroundTransparency = 1 })
				end
			end)
			root.MouseButton1Click:Connect(function()
				if multi then
					local now = not selected[option]
					selected[option] = now or nil
					paint(button, option)
					renderValue()
					Util.safeCall(opts.Callback, option, now)
				else
					table.clear(selected)
					selected[option] = true
					for other, otherButton in buttons do
						paint(otherButton, other)
					end
					renderValue()
					element.Open = false
					layout(true)
					Util.safeCall(opts.Callback, option)
				end
			end)
		end
		search.Visible = #values > 8
		applyFilter()
	end
	-- All / None (multi): every change goes through the callback, one option at a time.
	local function setAll(on)
		for _, option in values do
			if (selected[option] == true) ~= on then
				selected[option] = on or nil
				Util.safeCall(opts.Callback, option, on)
			end
		end
		for option, button in buttons do
			paint(button, option)
		end
		renderValue()
	end
	allButton.MouseButton1Click:Connect(function()
		setAll(true)
	end)
	noneButton.MouseButton1Click:Connect(function()
		setAll(false)
	end)
	function element:Set(value, silent)
		table.clear(selected)
		if multi then
			for _, option in Util.selectionArray(value) do
				selected[option] = true
			end
		elseif value ~= nil then
			selected[value] = true
		end
		for option, button in buttons do
			paint(button, option)
		end
		renderValue()
		if not silent then
			if multi then
				Util.safeCall(opts.Callback, currentValue())
			else
				Util.safeCall(opts.Callback, currentValue())
			end
		end
	end
	function element:Get()
		return currentValue()
	end
	function element:Refresh(newValues, keepSelection)
		values = type(newValues) == "table" and newValues or {}
		if not keepSelection then
			table.clear(selected)
		end
		build()
		renderValue()
		layout(false)
	end
	function element:SetOpen(open)
		element.Open = open == true
		layout(true)
	end
	element.GetNewList = function(first, second)
		local value = first == element and second or first
		element:Set(multi and Util.selectionArray(value) or value, true)
	end
	element.SetValues = function(first, second)
		local newValues = first == element and second or first
		element:Refresh(newValues, true)
	end
	hit.MouseButton1Click:Connect(function()
		element.Open = not element.Open
		layout(true)
	end)
	search:GetPropertyChangedSignal("Text"):Connect(function()
		filter = search.Text:lower()
		applyFilter()
		layout(true)
	end)
	build()
	renderValue()
	layout(false)
	return self:_handle(frame, element)
end

-- Text input: recessed box on the right of the row; the callback runs when focus leaves it.
function Container:AddInput(idOrOptions, options)
	local opts = Util.options(idOrOptions, options)
	local frame = self:_row(opts, nil, 220)
	local box = Util.new("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0.48, 0, 0, 30),
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		Font = FONT,
		Text = tostring(opts.Default or ""),
		PlaceholderText = opts.Placeholder or "",
		PlaceholderColor3 = Color3.fromRGB(120, 150, 165),
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		ZIndex = 3,
		Parent = frame,
	})
	Util.corner(box, 4)
	local boxStroke = Util.stroke(box, Theme.RecessBorder, 1.2)
	Util.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = box })
	local element = { Type = "Input", Value = box.Text }
	box.Focused:Connect(function()
		Util.tween(boxStroke, 0.12, { Color = Theme.Accent, Thickness = 2 })
	end)
	box.FocusLost:Connect(function()
		Util.tween(boxStroke, 0.12, { Color = Theme.RecessBorder, Thickness = 1.2 })
		element.Value = box.Text
		Util.safeCall(opts.Callback, box.Text)
	end)
	function element:Set(value, silent)
		box.Text = tostring(value or "")
		element.Value = box.Text
		if not silent then
			Util.safeCall(opts.Callback, box.Text)
		end
	end
	function element:Get()
		return box.Text
	end
	return self:_handle(frame, element)
end

-- Button: the Check-UI beveled button across the row (purple for Primary, cyan otherwise), icon before the text.
function Container:AddButton(options)
	local opts = Util.options(options)
	local holder = Util.new("Frame", { Name = opts.Name ~= "" and opts.Name or "Button", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = self:_nextOrder(), Parent = self.List })
	local palette = opts.Style == "Primary" and Palettes.Purple or (opts.Style == "Danger" and Palettes.Red or (opts.Style == "Success" and Palettes.Lime or Palettes.Cyan))
	local button, parts = Util.bevel(holder, {
		Palette = palette,
		Size = UDim2.new(1, -4, 1, -4),
		Text = opts.Name,
		TextSize = 16,
		Icon = opts.Icon,
		Hover = 1.02,
		Press = 0.97,
	})
	button:SetAttribute("NoDrag", true)
	local element = { Type = "Button" }
	button.MouseButton1Click:Connect(function()
		Util.safeCall(opts.Callback)
	end)
	function element:SetText(value)
		if parts.label then
			parts.label.Text = tostring(value)
		end
	end
	return self:_handle(holder, element)
end

-- Text / label row (no control).
function Container:AddLabel(options)
	local opts = Util.options(options)
	local frame = self:_row(opts, nil, 0)
	local element = { Type = "Label" }
	function element:Set(value)
		frame.Title.Text = tostring(value)
	end
	return self:_handle(frame, element)
end

-- Paragraph: a titled info card with wrapped text (sized to the text).
function Container:AddParagraph(options)
	local opts = Util.options(options)
	local content = tostring(opts.Content or opts.Desc or "")
	local frame = Util.card(self.List, { Name = "Paragraph", Size = UDim2.new(1, 0, 0, 0), LayoutOrder = self:_nextOrder() })
	frame.AutomaticSize = Enum.AutomaticSize.Y
	local title = Util.text(frame, { Name = "Title", Text = opts.Name, TextSize = 15, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 20), ZIndex = 2 })
	local body = Util.text(frame, {
		Name = "Content",
		Text = content,
		TextSize = 12,
		Stroke = 1.2,
		TextColor3 = Theme.Muted,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
	})
	-- Bottom margin of the card (AutomaticSize stops at the text otherwise).
	Util.new("UIPadding", { PaddingBottom = UDim.new(0, 12), Parent = body })
	local element = { Type = "Paragraph" }
	function element:Set(value)
		body.Text = tostring(value or "")
	end
	function element:SetTitle(value)
		title.Text = tostring(value or "")
	end
	return self:_handle(frame, element)
end

-- Keybind: a key chip; click it, press a key (Escape / Backspace clears), the callback runs on that key later.
function Container:AddKeybind(idOrOptions, options)
	local opts = Util.options(idOrOptions, options)
	local frame = self:_row(opts, nil, 110)
	local chipHolder = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(96, 30), ZIndex = 3, Parent = frame })
	local chip, parts = Util.bevel(chipHolder, { Palette = Palettes.Silver, Size = UDim2.fromScale(1, 1), Text = "NONE", TextSize = 13, ZIndex = 4, Hover = 1.05 })
	local element = { Type = "Keybind", Value = typeof(opts.Default) == "EnumItem" and opts.Default or nil, Listening = false }
	local function render()
		parts.label.Text = element.Listening and "..." or (element.Value and element.Value.Name or "NONE")
		parts.setPalette(element.Listening and Palettes.Amber or (element.Value and Palettes.Purple or Palettes.Silver))
	end
	function element:Set(value, silent)
		element.Value = typeof(value) == "EnumItem" and value or (type(value) == "string" and Enum.KeyCode[value]) or nil
		render()
		if not silent then
			Util.safeCall(opts.Changed, element.Value)
		end
	end
	function element:Get()
		return element.Value
	end
	chip.MouseButton1Click:Connect(function()
		element.Listening = true
		render()
	end)
	userInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if element.Listening then
			element.Listening = false
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				element:Set(nil)
			else
				element:Set(input.KeyCode)
			end
		elseif not processed and element.Value and input.KeyCode == element.Value then
			Util.safeCall(opts.Callback, element.Value)
		end
	end)
	render()
	return self:_handle(frame, element)
end

-- Progress: a read-only bar row (Set(fraction, text)), the same trough / fill as the slider.
function Container:AddProgress(idOrOptions, options)
	local opts = Util.options(idOrOptions, options)
	local frame = self:_row(opts, ROW_HEIGHT + 16, 110)
	local valueLabel = Util.text(frame, { Text = "", TextSize = 13, Stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 110, 0, ROW_HEIGHT - 8), ZIndex = 3 })
	local trough = Util.new("Frame", { BackgroundColor3 = Theme.Trough, BorderSizePixel = 0, Position = UDim2.new(0, 14, 1, -20), Size = UDim2.new(1, -28, 0, 10), ClipsDescendants = true, ZIndex = 3, Parent = frame })
	Util.corner(trough, 4)
	Util.stroke(trough, Color3.fromRGB(12, 18, 22), 2)
	local fill = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = trough })
	Util.corner(fill, 4)
	local gradient = Util.gradient(fill, opts.Colors or { Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 106, 0) }, 90)
	local element = { Type = "Progress", Value = 0 }
	function element:Set(fraction, text, colors)
		element.Value = math.clamp(tonumber(fraction) or 0, 0, 1)
		Util.tween(fill, 0.25, { Size = UDim2.fromScale(element.Value, 1) })
		valueLabel.Text = text ~= nil and tostring(text) or (math.floor(element.Value * 100 + 0.5) .. "%")
		if colors then
			gradient.Color = Util.sequence(colors)
		end
	end
	element:Set(opts.Default or 0, opts.Text)
	return self:_handle(frame, element)
end

-- Asset filter: title, "N selected" summary, search box and a list of item cards (icon, name / rarity in the rarity
-- colour, $/s, a FARM / SKIP chip). Built for hundreds of items: cards are created 16 per frame, laid out at fixed
-- positions (no UIListLayout / AutomaticSize), kept light (no buttons inside), and only moved by the search.
-- Items: { Id, Name, Icon, RarityName, RarityColor, Gen }; Selected: the set it reads and writes (shared with the
-- host); Callback(id, selected). The handle's Render() repaints the chips, Refresh() adds items appended to Items.
function Container:AddAssetFilter(options)
	local opts = type(options) == "table" and options or {}
	local items = type(opts.Items) == "table" and opts.Items or {}
	local selectedSet = type(opts.Selected) == "table" and opts.Selected or {}
	local frame = Util.card(self.List, { Name = "AssetFilter", Size = UDim2.new(1, 0, 0, 392), LayoutOrder = self:_nextOrder() })
	frame:SetAttribute("NoDrag", true)
	Util.text(frame, { Name = "Title", Text = string.upper(opts.Text or opts.Name or "Items"), TextSize = 15, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(0.5, -14, 0, 24), ZIndex = 2 })
	local summary = Util.text(frame, {
		Name = "Summary",
		Text = "0 selected",
		TextSize = 12,
		Stroke = 1.4,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.new(0.5, -14, 0, 24),
		ZIndex = 2,
	})
	local search = Util.new("TextBox", {
		Name = "Search",
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		Font = FONT,
		PlaceholderText = opts.Placeholder or "Search...",
		PlaceholderColor3 = Color3.fromRGB(120, 150, 165),
		Text = "",
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Position = UDim2.fromOffset(12, 38),
		Size = UDim2.new(1, -24, 0, 30),
		ZIndex = 2,
		Parent = frame,
	})
	Util.corner(search, 4)
	Util.stroke(search, Theme.RecessBorder, 1.2)
	Util.new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = search })
	local list = Util.new("ScrollingFrame", {
		Name = "List",
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 76),
		Size = UDim2.new(1, -24, 1, -88),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Theme.Accent,
		ZIndex = 2,
		Parent = frame,
	})
	list:SetAttribute("NoDrag", true)
	Util.corner(list, 4)
	Util.stroke(list, Color3.new(0, 0, 0), 1.6)
	local holder = Util.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -16, 0, 0), ZIndex = 2, Parent = list })

	local element = { Type = "AssetFilter", Selected = selectedSet }
	local rows, built, ROW, GAP = {}, {}, 64, 6
	local lime, silver = ColorSequence.new(Palettes.Lime.Gradient[1], Palettes.Lime.Gradient[2]), ColorSequence.new(Palettes.Silver.Gradient[1], Palettes.Silver.Gradient[2])

	local function count()
		local total = 0
		for _, on in selectedSet do
			if on then
				total += 1
			end
		end
		summary.Text = total .. " selected"
	end
	local function paint(row)
		local on = selectedSet[row.id] == true
		row.stroke.Color = on and Palettes.Lime.Gradient[1] or Color3.new(0, 0, 0)
		row.chipText.Text = on and "FARM" or "SKIP"
		row.chipGradient.Color = on and lime or silver
	end
	-- Stacks the rows matching the search and sizes the canvas.
	local function layout()
		local query = search.Text:lower()
		local y = 0
		for _, row in rows do
			local match = query == "" or row.search:find(query, 1, true) ~= nil
			row.frame.Visible = match
			if match then
				if row.y ~= y then
					row.y = y
					row.frame.Position = UDim2.fromOffset(0, y)
				end
				y += ROW + GAP
			end
		end
		holder.Size = UDim2.new(1, -16, 0, y)
		list.CanvasSize = UDim2.fromOffset(0, y + 12)
	end
	local function buildRow(item)
		local id = item.Id or item.Name
		local color = typeof(item.RarityColor) == "Color3" and item.RarityColor or Theme.CardHighlight
		local row = { id = id, search = (tostring(item.Name or "") .. " " .. tostring(id)):lower() }
		row.frame = Util.new("TextButton", { AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Text = "", Size = UDim2.new(1, 0, 0, ROW), ZIndex = 3, Parent = holder })
		Util.corner(row.frame, 5)
		row.stroke = Util.stroke(row.frame, Color3.new(0, 0, 0), 2)
		Util.new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color:Lerp(Theme.Card, 0.6)), ColorSequenceKeypoint.new(0.5, Theme.Card), ColorSequenceKeypoint.new(1, Theme.Card) }), Parent = row.frame })
		local well = Util.new("Frame", { BackgroundColor3 = Theme.Recess, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(52, 52), ZIndex = 4, Parent = row.frame })
		Util.corner(well, 5)
		Util.stroke(well, color, 1.6)
		local icon = Util.new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = well })
		Util.icon(icon, item.Icon)
		Util.text(row.frame, { Name = "Label", Text = tostring(item.Name or id), TextSize = 14, TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3), Position = UDim2.fromOffset(70, 8), Size = UDim2.new(1, -170, 0, 18), ZIndex = 4 })
		Util.text(row.frame, { Text = string.upper(tostring(item.RarityName or item.Rarity or "")), TextSize = 10, Stroke = 1.2, TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.15), Position = UDim2.fromOffset(70, 27), Size = UDim2.new(1, -170, 0, 13), ZIndex = 4 })
		if item.Gen then
			Util.text(row.frame, { Text = "$" .. Util.compact(item.Gen) .. "/s", TextSize = 12, Stroke = 1.4, TextColor3 = Palettes.Lime.Gradient[1], Position = UDim2.fromOffset(70, 42), Size = UDim2.new(1, -170, 0, 15), ZIndex = 4 })
		end
		-- State chip: a light frame (gradient + outline + dark bevel line) with its text, not a full button.
		local chip = Util.new("Frame", { AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(76, 28), ZIndex = 4, Parent = row.frame })
		Util.stroke(chip, Color3.new(0, 0, 0), 2.2).LineJoinMode = Enum.LineJoinMode.Miter
		row.chipGradient = Util.gradient(chip, Palettes.Silver.Gradient, 90)
		Util.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), ZIndex = 5, Parent = chip })
		row.chipText = Util.text(chip, { Text = "SKIP", TextSize = 13, Stroke = 2, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, -1), ZIndex = 6 })
		paint(row)
		row.frame.MouseButton1Click:Connect(function()
			selectedSet[id] = not selectedSet[id] or nil
			paint(row)
			count()
			Util.safeCall(opts.Callback, id, selectedSet[id] == true)
		end)
		return row
	end
	-- Builds every item not built yet, 16 per frame, then lays the list out.
	local building = false
	local function buildAll()
		if building then
			return
		end
		building = true
		task.spawn(function()
			local made = 0
			for _, item in items do
				if not built[item] then
					built[item] = true
					local ok, row = pcall(buildRow, item)
					if ok then
						table.insert(rows, row)
					end
					made += 1
					if made % 16 == 0 then
						layout()
						task.wait()
					end
				end
			end
			building = false
			layout()
			count()
		end)
	end
	function element:Render()
		for _, row in rows do
			paint(row)
		end
		count()
	end
	function element:Refresh()
		buildAll()
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		list.CanvasPosition = Vector2.zero
		layout()
	end)
	buildAll()
	count()
	return self:_handle(frame, element)
end

-- Log card (Steal Log): rarity-tinted card with the animal preview, its name, details, stats and a time chip.
function Container:AddAssetLogItem(item)
	local frame = Util.new("Frame", {
		Name = "LogItem",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 80),
		LayoutOrder = self:_nextOrder(),
		ClipsDescendants = true,
		Parent = self.List,
	})
	Util.corner(frame, 6)
	local frameStroke = Util.stroke(frame, Theme.CardHighlight, 2.4)
	local gradient = Util.new("UIGradient", { Rotation = 0, Parent = frame })
	local preview = Util.new("Frame", { Name = "Preview", BackgroundColor3 = Theme.Recess, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(56, 56), Parent = frame })
	Util.corner(preview, 6)
	local previewStroke = Util.stroke(preview, Theme.CardHighlight, 1.6)
	local icon = Util.new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, Parent = preview })
	local badge = Util.new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 4, 1, 4), Size = UDim2.fromOffset(22, 22), ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Visible = false, Parent = preview })
	local name = Util.text(frame, { Name = "Name", Text = "", TextSize = 16, Position = UDim2.fromOffset(80, 10), Size = UDim2.new(1, -170, 0, 22) })
	local details = Util.text(frame, { Name = "Details", Text = "", TextSize = 11, Stroke = 1.2, TextColor3 = Theme.Muted, Position = UDim2.fromOffset(80, 33), Size = UDim2.new(1, -170, 0, 16) })
	local stats = Util.text(frame, { Name = "Stats", Text = "", RichText = true, TextSize = 12, Stroke = 1.2, Position = UDim2.fromOffset(80, 51), Size = UDim2.new(1, -100, 0, 18) })
	-- A TextLabel itself (not a frame around one), so a hub restyle that clears the card's texts clears it too.
	local chip = Util.text(frame, {
		Name = "Chip",
		Text = "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(78, 24),
	})
	chip.BackgroundTransparency = 0
	chip.BackgroundColor3 = Theme.Recess
	Util.corner(chip, 4)
	Util.stroke(chip, Color3.new(0, 0, 0), 1.6)
	local element = self:_handle(frame, { Type = "LogItem" })
	-- Repaints the same card with another entry (pooled logs reuse their oldest card instead of building a new one).
	function element:SetItem(data)
		data = type(data) == "table" and data or {}
		local rarityColor = typeof(data.RarityColor) == "Color3" and data.RarityColor or Theme.CardHighlight
		frameStroke.Color, previewStroke.Color = rarityColor, rarityColor
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rarityColor:Lerp(Theme.Card, 0.55)),
			ColorSequenceKeypoint.new(0.45, Theme.Card),
			ColorSequenceKeypoint.new(1, Theme.Card),
		})
		Util.icon(icon, data.Icon)
		local hasEgg = data.EggIcon ~= nil and data.EggIcon ~= ""
		badge.Visible = hasEgg
		if hasEgg then
			Util.icon(badge, data.EggIcon)
		end
		name.Text = tostring(data.Name or "?")
		name.TextColor3 = rarityColor:Lerp(Color3.new(1, 1, 1), 0.25)
		details.Text = tostring(data.Details or "")
		stats.Text = tostring(data.Stats or "")
		chip.Visible = data.Chip ~= nil
		chip.Text = tostring(data.Chip or "")
	end
	element:SetItem(item)
	return element
end


-- Event card: a big pill on the left (a time, OPEN, LIVE...), the event's title and detail line, a progress bar.
-- Set(big, detail, colors, fraction): fraction nil hides the bar.
function Container:AddEventCard(options)
	local opts = Util.options(options)
	local frame = Util.card(self.List, { Name = "EventCard", Size = UDim2.new(1, 0, 0, 66), LayoutOrder = self:_nextOrder() })
	local pill = Util.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Position = UDim2.new(0, 10, 0.5, -4), Size = UDim2.fromOffset(96, 36), ZIndex = 2, Parent = frame })
	Util.corner(pill, 5)
	Util.stroke(pill, Color3.new(0, 0, 0), 2.2)
	local pillGradient = Util.gradient(pill, Hud.Grey, 90)
	local big = Util.text(pill, { Text = "--", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
	local icon
	if opts.Icon then
		icon = Util.new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(116, 8), Size = UDim2.fromOffset(18, 18), ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Parent = frame })
		Util.icon(icon, opts.Icon)
	end
	local left = opts.Icon and 140 or 116
	Util.text(frame, { Text = string.upper(opts.Name), TextSize = 13, Position = UDim2.fromOffset(left, 8), Size = UDim2.new(1, -left - 10, 0, 18), ZIndex = 2 })
	local detail = Util.text(frame, { Text = "", TextSize = 11, Stroke = 1.2, TextColor3 = Theme.Muted, Position = UDim2.fromOffset(116, 28), Size = UDim2.new(1, -126, 0, 14), ZIndex = 2 })
	local trough = Util.new("Frame", { BackgroundColor3 = Theme.Trough, BorderSizePixel = 0, Position = UDim2.new(0, 116, 1, -16), Size = UDim2.new(1, -126, 0, 6), ZIndex = 2, Parent = frame })
	Util.corner(trough, 3)
	local fill = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 3, Parent = trough })
	Util.corner(fill, 3)
	local fillGradient = Util.gradient(fill, Hud.Grey, 0)
	local element = { Type = "EventCard" }
	function element:Set(bigText, detailText, colors, fraction)
		big.Text = tostring(bigText or "--")
		detail.Text = tostring(detailText or "")
		Hud.setColors(pillGradient, colors or Hud.Grey)
		Hud.setColors(fillGradient, colors or Hud.Grey)
		trough.Visible = type(fraction) == "number"
		if trough.Visible then
			fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		end
	end
	return self:_handle(frame, element)
end

-- Stat tiles: a row of equal tiles, each a value over its caption (caption in the tile's colour), an icon if given.
-- tiles = { { Caption, Colors, Icon } }; SetValue(index, text).
function Container:AddStatTiles(tiles)
	tiles = type(tiles) == "table" and tiles or {}
	local withIcons = false
	for _, tile in tiles do
		if tile.Icon then
			withIcons = true
		end
	end
	local holder = Util.new("Frame", { Name = "StatTiles", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, withIcons and 74 or 52), LayoutOrder = self:_nextOrder(), Parent = self.List })
	local values = {}
	local count = math.max(#tiles, 1)
	for index, tile in tiles do
		local card = Util.card(holder, { Name = "Tile", Position = UDim2.new((index - 1) / count, index == 1 and 0 or 3, 0, 0), Size = UDim2.new(1 / count, -6 + (index == 1 and 3 or 0), 1, 0) })
		values[index] = Util.text(card, { Text = "--", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, 20), ZIndex = 2 })
		Util.text(card, { Text = tostring(tile.Caption or ""), TextSize = 9, Stroke = 1.2, TextColor3 = (tile.Colors or Hud.Grey)[1], TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 12), ZIndex = 2 })
		if tile.Icon then
			local image = Util.new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 42), Size = UDim2.fromOffset(24, 24), ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Parent = card })
			Util.icon(image, tile.Icon)
		end
	end
	local element = { Type = "StatTiles" }
	function element:SetValue(index, text)
		if values[index] then
			values[index].Text = tostring(text)
		end
	end
	return self:_handle(holder, element)
end

-- Filter chips: a segmented row; the picked chip takes its colours, the rest stay dark. Values = { { Key, Text,
-- Colors } }; Callback(key); SetText(key, text) (e.g. counts); Set(key).
function Container:AddChips(options)
	local opts = Util.options(options)
	local holder = Util.new("Frame", { Name = "Chips", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = self:_nextOrder(), Parent = self.List })
	local chips = {}
	local element = { Type = "Chips", Value = opts.Default }
	local count = math.max(#opts.Values, 1)
	local function paint()
		for key, chip in chips do
			local on = element.Value == key
			chip.gradient.Enabled = on
			chip.frame.BackgroundColor3 = on and Color3.new(1, 1, 1) or Theme.Card
			chip.label.TextColor3 = on and Color3.new(1, 1, 1) or Theme.Muted
		end
	end
	for index, entry in opts.Values do
		local key = entry.Key or entry[1]
		local frame = Util.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Position = UDim2.new((index - 1) / count, index == 1 and 0 or 3, 0, 0), Size = UDim2.new(1 / count, -6 + (index == 1 and 3 or 0), 1, 0), ZIndex = 2, Parent = holder })
		Util.corner(frame, 4)
		Util.stroke(frame, Color3.new(0, 0, 0), 2)
		local gradient = Util.gradient(frame, entry.Colors or entry[3] or Palettes.Purple.Gradient, 90)
		local label = Util.text(frame, { Text = tostring(entry.Text or entry[2] or key), TextSize = 11, Stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
		chips[key] = { frame = frame, gradient = gradient, label = label }
		frame.MouseButton1Click:Connect(function()
			element.Value = key
			paint()
			Util.safeCall(opts.Callback, key)
		end)
	end
	function element:Set(key)
		element.Value = key
		paint()
	end
	function element:SetText(key, text)
		if chips[key] then
			chips[key].label.Text = tostring(text)
		end
	end
	paint()
	return self:_handle(holder, element)
end

-- Card grid: pooled item cards in columns (a refresh repaints the pool, never rebuilds it). Items = { { Name, Icon,
-- Badge, RarityColor, Rarity, Value, Info, Extra, Pill, PillColors, Progress } }; Progress nil hides the bar.
-- SetItems(items) returns nothing; SetPill(index, text, colors, progress) updates one card's pill / bar (timers).
function Container:AddCardGrid(options)
	local opts = type(options) == "table" and options or {}
	local columns = opts.Columns or 2
	local holder = Util.new("Frame", { Name = "CardGrid", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_nextOrder(), Parent = self.List })
	Util.new("UIGridLayout", { CellSize = UDim2.new(1 / columns, -5, 0, 78), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	local empty = Util.text(holder, { Text = opts.EmptyText or "Nothing here", TextSize = 12, Stroke = 1.4, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 2 })
	empty.LayoutOrder = 0
	local pool = {}
	local function makeCard()
		local card = {}
		card.frame = Util.new("Frame", { Name = "Card", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = holder })
		Util.corner(card.frame, 5)
		card.stroke = Util.stroke(card.frame, Color3.new(0, 0, 0), 2)
		card.tint = Util.new("UIGradient", { Parent = card.frame })
		card.well = Util.new("Frame", { BackgroundColor3 = Theme.Recess, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(46, 46), ZIndex = 3, Parent = card.frame })
		Util.corner(card.well, 5)
		card.wellStroke = Util.stroke(card.well, Theme.CardHighlight, 1.4)
		card.icon = Util.new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = card.well })
		card.badge = Util.new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 4, 1, 4), Size = UDim2.fromOffset(18, 18), ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = card.well })
		card.name = Util.text(card.frame, { TextSize = 12, Position = UDim2.fromOffset(58, 5), Size = UDim2.new(1, -136, 0, 15), ZIndex = 3 })
		card.rarity = Util.text(card.frame, { TextSize = 9, Stroke = 1, Position = UDim2.fromOffset(58, 20), Size = UDim2.new(1, -136, 0, 11), ZIndex = 3 })
		card.value = Util.text(card.frame, { TextSize = 11, Stroke = 1.4, RichText = true, TextColor3 = Palettes.Lime.Gradient[1], Position = UDim2.fromOffset(58, 32), Size = UDim2.new(1, -62, 0, 13), ZIndex = 3 })
		card.extra = Util.text(card.frame, { TextSize = 9, Stroke = 1, TextColor3 = Theme.Muted, Position = UDim2.fromOffset(58, 45), Size = UDim2.new(1, -62, 0, 11), ZIndex = 3 })
		card.pill = Util.new("Frame", { AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(66, 16), ZIndex = 3, Parent = card.frame })
		Util.corner(card.pill, 4)
		Util.stroke(card.pill, Color3.new(0, 0, 0), 1.6)
		card.pillGradient = Util.gradient(card.pill, Hud.Grey, 90)
		card.pillText = Util.text(card.pill, { TextSize = 10, Stroke = 1.4, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })
		card.track = Util.new("Frame", { BackgroundColor3 = Theme.Trough, BorderSizePixel = 0, Position = UDim2.new(0, 6, 1, -8), Size = UDim2.new(1, -12, 0, 4), ZIndex = 3, Parent = card.frame })
		Util.corner(card.track, 2)
		card.progress = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = card.track })
		Util.corner(card.progress, 2)
		card.progressGradient = Util.gradient(card.progress, Hud.Grey, 0)
		return card
	end
	local element = { Type = "CardGrid" }
	function element:SetPill(index, text, colors, progress)
		local card = pool[index]
		if not card or not card.frame.Visible then
			return
		end
		card.pill.Visible = text ~= nil and text ~= ""
		card.pillText.Text = tostring(text or "")
		Hud.setColors(card.pillGradient, colors or Hud.Grey)
		card.track.Visible = type(progress) == "number"
		if card.track.Visible then
			card.progress.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
			Hud.setColors(card.progressGradient, colors or Hud.Grey)
		end
	end
	function element:SetItems(items)
		items = type(items) == "table" and items or {}
		empty.Visible = #items == 0
		for index, item in items do
			local card = pool[index]
			if not card then
				card = makeCard()
				pool[index] = card
			end
			local color = typeof(item.RarityColor) == "Color3" and item.RarityColor or Theme.CardHighlight
			card.frame.Visible = true
			card.frame.LayoutOrder = index
			card.tint.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color:Lerp(Theme.Card, 0.55)), ColorSequenceKeypoint.new(0.6, Theme.Card), ColorSequenceKeypoint.new(1, Theme.Card) })
			card.stroke.Color = item.Highlight and Palettes.Purple.Rim or Color3.new(0, 0, 0)
			card.wellStroke.Color = color
			if item.Icon ~= card.iconId then
				card.iconId = item.Icon
				Util.icon(card.icon, item.Icon)
			end
			card.badge.Visible = item.Badge ~= nil and item.Badge ~= ""
			if card.badge.Visible and item.Badge ~= card.badgeId then
				card.badgeId = item.Badge
				Util.icon(card.badge, item.Badge)
			end
			card.name.Text = tostring(item.Name or "?")
			card.name.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3)
			card.rarity.Text = string.upper(tostring(item.Rarity or ""))
			card.rarity.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.15)
			local info = item.Info and item.Info ~= "" and ('  <font color="#FFC83C">%s</font>'):format(tostring(item.Info)) or ""
			card.value.Text = tostring(item.Value or "") .. info
			card.extra.Text = tostring(item.Extra or "")
			element:SetPill(index, item.Pill, item.PillColors, item.Progress)
		end
		for index = #items + 1, #pool do
			pool[index].frame.Visible = false
		end
	end
	element:SetItems(opts.Items or {})
	return self:_handle(holder, element)
end

-- Info list: pooled text rows (left and right, both RichText); a row with Header = true is a coloured caption.
-- SetRows(rows) with rows = { { Left, Right, Header, Colors } }.
function Container:AddInfoList(options)
	local opts = type(options) == "table" and options or {}
	local holder = Util.new("Frame", { Name = "InfoList", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_nextOrder(), Parent = self.List })
	Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = holder })
	local pool = {}
	local element = { Type = "InfoList" }
	function element:SetRows(rows)
		rows = type(rows) == "table" and rows or {}
		for index, row in rows do
			local entry = pool[index]
			if not entry then
				local frame = Util.new("Frame", { BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 26), ZIndex = 2, Parent = holder })
				Util.corner(frame, 4)
				local left = Util.text(frame, { TextSize = 11, Stroke = 1.4, RichText = true, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.62, -10, 1, 0), ZIndex = 3 })
				local right = Util.text(frame, { TextSize = 11, Stroke = 1.4, RichText = true, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.38, -10, 1, 0), ZIndex = 3 })
				entry = { frame = frame, left = left, right = right }
				pool[index] = entry
			end
			entry.frame.Visible = true
			entry.frame.LayoutOrder = index
			entry.frame.BackgroundTransparency = row.Header and 1 or 0
			entry.frame.Size = UDim2.new(1, 0, 0, row.Header and 18 or 26)
			entry.left.Text = tostring(row.Left or "")
			entry.left.TextColor3 = row.Header and ((row.Colors or Hud.Gold)[1]) or Theme.Text
			entry.right.Text = tostring(row.Right or "")
		end
		for index = #rows + 1, #pool do
			pool[index].frame.Visible = false
		end
	end
	element:SetRows(opts.Rows or {})
	return self:_handle(holder, element)
end
Container.Section = Container.AddSection
Container.Toggle = Container.AddToggle
Container.Slider = Container.AddSlider
Container.Dropdown = Container.AddDropdown
Container.Input = Container.AddInput
Container.Button = Container.AddButton
Container.Label = Container.AddLabel
Container.AssetFilter = Container.AddAssetFilter
Container.Paragraph = Container.AddParagraph
Container.Keybind = Container.AddKeybind
Container.Progress = Container.AddProgress

-- ============================================================================================================
-- Window
-- ============================================================================================================

local Window = {}
Window.__index = Window

-- 3D beveled square header button (Check-UI §3.1 for the close [X]; amber for minimize).
local function headerButton(parent, text, palette, offset)
	local button, parts = Util.bevel(parent, {
		Name = text == "X" and "CloseButton" or "MinimizeButton",
		Palette = palette,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, offset, 0.5, -2),
		Size = UDim2.fromOffset(38, 38),
		StrokeThickness = 2.8,
		Text = text,
		TextSize = text == "X" and 24 or 26,
		ZIndex = 25,
	})
	parts.bevel.Size = UDim2.new(1, 0, 0, 4)
	parts.bevel.Position = UDim2.new(0, 0, 1, -4)
	return button
end

function Library:CreateWindow(opts)
	opts = type(opts) == "table" and opts or {}
	local self = setmetatable({ Tabs = {}, CurrentTab = nil, Visible = true, ReducedMotion = false, _connections = {}, _openFactor = 1 }, Window)
	local connections = self._connections
	local gui = Util.screen(opts.Name or "BloomWindow", 100, opts.Parent)
	self.Gui = gui
	local logo = opts.Logo or opts.Icon or Assets.OpenLogo
	Library._logo = logo

	local root = Util.new("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(opts.Width or 660, opts.Height or 440),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	self.Root = root
	local deviceScale = Util.new("UIScale", { Name = "WindowScale", Parent = root })
	Util.responsive(deviceScale, connections)
	-- Soft drop shadow under the window, so it lifts off whatever the game draws behind it.
	local shadow = Util.new("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = Assets.Shadow,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, 60, 1, 60),
		ZIndex = 0,
		Parent = root,
	})
	self.Shadow = shadow

	local main = Util.new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Canvas,
		BorderSizePixel = 0,
		Parent = root,
	})
	self.Main = main
	Util.corner(main, 6)
	Util.stroke(main, Theme.Border, 3.5)

	-- Header: purple gradient, top highlight, fading checker, logo on a rotating sunburst, title and subtitle.
	local header = Util.new("Frame", {
		Name = "Header",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		ZIndex = 10,
		ClipsDescendants = true,
		Parent = main,
	})
	Util.corner(header, 6)
	Util.gradient(header, Palettes.Purple.Gradient, 90)
	Util.new("Frame", { Name = "SquareBottom", BackgroundColor3 = Palettes.Purple.Gradient[2], BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8), ZIndex = 10, Parent = header })
	Util.damier(header, Palettes.Purple.Damier, 26, 11)
	Util.new("Frame", { Name = "TopHighlight", BackgroundColor3 = Palettes.Purple.Rim, BackgroundTransparency = 0.35, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 0, 2), ZIndex = 12, Parent = header })
	local sunburst = Util.new("ImageLabel", {
		Name = "Sunburst",
		BackgroundTransparency = 1,
		Image = Assets.Sunburst,
		ImageColor3 = Palettes.Purple.Rim,
		ImageTransparency = 0.45,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(36, HEADER_HEIGHT / 2),
		Size = UDim2.fromOffset(96, 96),
		ZIndex = 12,
		Parent = header,
	})

	local logoImage = Util.new("ImageLabel", {
		Name = "Logo",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(36, HEADER_HEIGHT / 2),
		Size = UDim2.fromOffset(48, 48),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 13,
		Parent = header,
	})
	Util.icon(logoImage, logo)
	self.Logo = logoImage
	local titleLabel = Util.text(header, {
		Name = "Title",
		Text = opts.Title or "Zenity Hub",
		TextSize = 26,
		Stroke = 3.2,
		Position = UDim2.fromOffset(70, 8),
		Size = UDim2.new(1, -190, 0, 28),
		ZIndex = 13,
	})
	self.TitleLabel = titleLabel
	local subtitle = Util.text(header, {
		Name = "Subtitle",
		Text = opts.Subtitle or "",
		TextSize = 13,
		Stroke = 1.8,
		TextColor3 = Color3.fromRGB(236, 214, 255),
		Position = UDim2.fromOffset(71, 35),
		Size = UDim2.new(1, -190, 0, 16),
		ZIndex = 13,
	})
	self.SubtitleLabel = subtitle
	if not opts.Subtitle then
		task.spawn(function()
			local ok, info = pcall(function()
				return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
			end)
			if ok and type(info) == "table" and info.Name and subtitle.Text == "" then
				subtitle.Text = info.Name
			end
		end)
	end
	local close = headerButton(main, "X", Palettes.Close, -30)
	close.ZIndex = 30
	local minimize = headerButton(main, "–", Palettes.Amber, -76)
	minimize.ZIndex = 30
	close.Position = UDim2.new(1, -30, 0, HEADER_HEIGHT / 2 - 2)
	minimize.Position = UDim2.new(1, -76, 0, HEADER_HEIGHT / 2 - 2)
	-- 2-tier divider: the dark purple accent line, then pure black.
	Util.new("Frame", { Name = "DivDark", BackgroundColor3 = Palettes.Purple.Dark, BorderSizePixel = 0, Position = UDim2.fromOffset(0, HEADER_HEIGHT), Size = UDim2.new(1, 0, 0, 3), ZIndex = 10, Parent = main })
	Util.new("Frame", { Name = "DivBlack", BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Position = UDim2.fromOffset(0, HEADER_HEIGHT + 3), Size = UDim2.new(1, 0, 0, 3), ZIndex = 10, Parent = main })

	-- Body: sidebar of tabs on the left, the pages on the right.
	local body = Util.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER_HEIGHT + 6),
		Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT - 6),
		ZIndex = 2,
		Parent = main,
	})
	self.Body = body
	local sidebar = Util.new("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -20),
		ZIndex = 2,
		Parent = body,
	})
	Util.corner(sidebar, 4)
	Util.stroke(sidebar, Color3.new(0, 0, 0), 2.4)
	local sidebarRim = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -4, 1, -4), ZIndex = 2, Parent = sidebar })
	Util.corner(sidebarRim, 3)
	Util.stroke(sidebarRim, Theme.RecessBorder, 1.2, 0.5)
	-- Player card pinned at the bottom of the sidebar: avatar, display name and the hide key.
	local profile = Util.new("Frame", {
		Name = "Profile",
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -6),
		Size = UDim2.new(1, -12, 0, 46),
		ZIndex = 3,
		Parent = sidebar,
	})
	Util.corner(profile, 4)
	Util.stroke(profile, Color3.new(0, 0, 0), 2)
	local avatar = Util.new("ImageLabel", {
		BackgroundColor3 = Theme.Recess,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(34, 34),
		Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(localPlayer.UserId),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 4,
		Parent = profile,
	})
	Util.corner(avatar, 4)
	Util.stroke(avatar, Palettes.Purple.Rim, 1.6)
	Util.text(profile, { Text = localPlayer.DisplayName, TextSize = 12, Stroke = 1.6, Position = UDim2.fromOffset(46, 6), Size = UDim2.new(1, -52, 0, 16), ZIndex = 4 })
	self.KeyLabel = Util.text(profile, {
		Text = "RightCtrl to hide",
		TextSize = 10,
		Stroke = 1.2,
		TextColor3 = Theme.Muted,
		Position = UDim2.fromOffset(46, 23),
		Size = UDim2.new(1, -52, 0, 14),
		ZIndex = 4,
	})
	local tabList = Util.new("ScrollingFrame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 1, -64),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Theme.Accent,
		ZIndex = 3,
		Parent = sidebar,
	})
	tabList:SetAttribute("NoDrag", true)
	Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = tabList })
	Util.new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 4), Parent = tabList })
	self.TabList = tabList
	local content = Util.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(SIDEBAR_WIDTH + 20, 10),
		Size = UDim2.new(1, -SIDEBAR_WIDTH - 30, 1, -20),
		ZIndex = 2,
		Parent = body,
	})
	self.Content = content

	-- Floating open button (logo on a purple bevel) while the window is hidden.
	local openHolder = Util.new("Frame", {
		Name = "OpenButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = opts.OpenPosition or UDim2.new(0, 64, 0.5, -150),
		Size = UDim2.fromOffset(64, 64),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	Util.responsive(Util.new("UIScale", { Parent = openHolder }), connections)
	local openSunburst = Util.new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = Assets.Sunburst,
		ImageColor3 = Palettes.Purple.Rim,
		ImageTransparency = 0.35,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(120, 120),
		Parent = openHolder,
	})

	local openButton, openParts = Util.bevel(openHolder, { Palette = Palettes.Purple, Size = UDim2.fromScale(1, 1), StrokeThickness = 3, ZIndex = 3 })
	local openLogo = Util.new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -2), Size = UDim2.fromOffset(48, 48), ScaleType = Enum.ScaleType.Fit, ZIndex = 6, Parent = openButton })
	Util.icon(openLogo, opts.OpenLogo or Assets.OpenLogo)
	self.OpenButton = openHolder
	local _ = openParts
	-- Fixed in place (not draggable): one click opens the window.
	openButton.MouseButton1Click:Connect(function()
		self:Toggle(true)
	end)

	close.MouseButton1Click:Connect(function()
		self:Toggle(false)
	end)
	minimize.MouseButton1Click:Connect(function()
		self:Toggle(false)
	end)
	Util.drag(header, root, connections)
	self.Keybind = opts.Keybind or Enum.KeyCode.RightControl
	table.insert(connections, userInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self.Keybind then
			self:Toggle(not self.Visible)
		end
	end))
	-- Sunbursts turn at 20°/s, only the one on screen (header while open, floating button while closed), and not
	-- at all with ReducedMotion.
	table.insert(connections, runService.RenderStepped:Connect(function(deltaTime)
		if self.ReducedMotion or Library.ReducedMotion then
			return
		end
		local image = self.Visible and sunburst or openSunburst
		image.Rotation = (image.Rotation + 20 * deltaTime) % 360
	end))

	-- Intro: the same short slide as opening (no scaling of the whole window).
	main.Position = UDim2.new(0.5, 0, 0.5, 18)
	Util.tween(main, 0.2, { Position = UDim2.fromScale(0.5, 0.5) })
	return self
end

Library.Window = Library.CreateWindow

function Window:Toggle(open)
	if open == nil then
		open = not self.Visible
	end
	open = open == true
	if open == self.Visible then
		return
	end
	self.Visible = open
	self._toggleId = (self._toggleId or 0) + 1
	local id = self._toggleId
	-- Open / close slide the window a few pixels at its final size (and fade the shadow). Scaling the whole window
	-- re-laid-out and re-rasterized every text in it each frame, which is what dropped frames on open.
	local rest, below = UDim2.fromScale(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 18)
	if open then
		self.OpenButton.Visible = false
		self.Main.Position = below
		self.Shadow.ImageTransparency = 1
		self.Root.Visible = true
		Util.tween(self.Main, 0.18, { Position = rest })
		Util.tween(self.Shadow, 0.18, { ImageTransparency = 0.45 })
	else
		Util.tween(self.Main, 0.14, { Position = below }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Util.tween(self.Shadow, 0.14, { ImageTransparency = 1 })
		task.delay(0.14, function()
			if self._toggleId == id and not self.Visible then
				self.Root.Visible = false
				self.OpenButton.Visible = true
			end
		end)
	end
end

function Window:SetKeybind(keyCode)
	self.Keybind = keyCode
	if self.KeyLabel and typeof(keyCode) == "EnumItem" then
		self.KeyLabel.Text = keyCode.Name .. " to hide"
	end
end

function Window:SetTitle(value)
	self.TitleLabel.Text = tostring(value or "")
end

function Window:SetSubtitle(value)
	self.SubtitleLabel.Text = tostring(value or "")
end

-- Tab: a sidebar button (icon + name; the selected one turns into a purple bevel) and its scrolling page.
function Window:CreateTab(opts, icon)
	if type(opts) ~= "table" then
		opts = { Name = opts, Icon = icon }
	end
	local name = opts.Name or opts.Title or "Tab"
	local index = #self.Tabs + 1
	local holder = Util.new("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = index, Parent = self.TabList })
	local button, parts = Util.bevel(holder, {
		Name = "TabButton",
		Palette = Palettes.Silver,
		Size = UDim2.new(1, -2, 1, -2),
		Hover = 1,
		Press = 0.96,
		Tile = 16,
		ZIndex = 4,
	})
	button:SetAttribute("NoDrag", true)
	-- Idle look: a dark card; the bevel parts only show on the selected tab.
	local idle = Util.new("Frame", { Name = "Idle", BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 8, Parent = button })
	-- Hover lightens the idle card instead of growing the button (a grown button spilled past the tab list, which
	-- clips it, and its black outline was cut off on the sides).
	button.MouseEnter:Connect(function()
		idle.BackgroundColor3 = Theme.Card:Lerp(Color3.new(1, 1, 1), 0.07)
	end)
	button.MouseLeave:Connect(function()
		idle.BackgroundColor3 = Theme.Card
	end)

	local iconImage = Util.new("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, -1),
		Size = UDim2.fromOffset(18, 18),
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Theme.Muted,
		ZIndex = 9,
		Parent = button,
	})
	Util.icon(iconImage, opts.Icon)
	local caption = Util.text(button, { Name = "Caption", Text = name, TextSize = 13, Stroke = 2, TextColor3 = Theme.Muted, Position = UDim2.fromOffset(opts.Icon and 34 or 12, -1), Size = UDim2.new(1, opts.Icon and -40 or -18, 1, 0), ZIndex = 9 })
	local page = Util.new("ScrollingFrame", {
		Name = name .. "Page",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 2,
		Parent = self.Content,
	})
	page:SetAttribute("NoDrag", true)
	Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = page })
	Util.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10), Parent = page })
	-- Page title: the tab's icon and name, over a purple accent line.
	local titleRow = Util.new("Frame", { Name = "PageTitle", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 0, Parent = page })
	local titleIcon = Util.new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 4), Size = UDim2.fromOffset(22, 22), ScaleType = Enum.ScaleType.Fit, Parent = titleRow })
	Util.icon(titleIcon, opts.Icon)
	Util.text(titleRow, { Text = string.upper(name), TextSize = 22, Stroke = 2.8, Position = UDim2.fromOffset(opts.Icon and 32 or 2, 0), Size = UDim2.new(1, -40, 0, 30) })
	local accent = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), Parent = titleRow })
	Util.new("UIGradient", { Color = Util.sequence(Palettes.Purple.Gradient), Transparency = NumberSequence.new(0, 1), Parent = accent })
	local tab = setmetatable({ Name = name, Window = self, List = page, Page = page, Button = button, _order = 0, _idle = idle, _icon = iconImage, _caption = caption, _parts = parts }, Container)
	table.insert(self.Tabs, tab)
	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	if not self.CurrentTab then
		self:SelectTab(tab)
	end
	return tab
end

Window.Tab = Window.CreateTab

function Window:SelectTab(target)
	if type(target) == "number" then
		target = self.Tabs[target]
	end
	if not target or self.CurrentTab == target then
		return
	end
	local previous = self.CurrentTab
	self.CurrentTab = target
	if previous then
		previous.Page.Visible = false
		Util.tween(previous._idle, 0.15, { BackgroundTransparency = 0 })
		previous._caption.TextColor3 = Theme.Muted
		previous._icon.ImageColor3 = Theme.Muted
		previous._parts.setPalette(Palettes.Silver)
	end
	target._parts.setPalette(Palettes.Purple)
	Util.tween(target._idle, 0.15, { BackgroundTransparency = 1 })
	target._caption.TextColor3 = Theme.Text
	target._icon.ImageColor3 = Theme.Text
	-- New page slides up a little and fades its rows in.
	local page = target.Page
	page.Visible = true
	page.Position = UDim2.fromOffset(0, 14)
	Util.tween(page, 0.25, { Position = UDim2.new() }, Enum.EasingStyle.Quint)
	target._parts.scale.Scale = 0.92
	Util.tween(target._parts.scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

function Window:Notify(opts)
	return Library:Notify(opts)
end

function Window:Destroy()
	for _, connection in self._connections do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(self._connections)
	if self.Gui then
		self.Gui:Destroy()
	end
end

-- ============================================================================================================
-- Notifications: stacked toasts at the bottom right, sliding in, a draining timer bar, click to dismiss.
-- ============================================================================================================

function Library:Notify(opts)
	opts = type(opts) == "table" and opts or { Title = tostring(opts) }
	local gui = Library._notifyGui
	if not (gui and gui.Parent) then
		gui = Util.screen("BloomNotify", 1000)
		Library._notifyGui = gui
		local holder = Util.new("Frame", {
			Name = "Holder",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.fromOffset(310, 500),
			BackgroundTransparency = 1,
			Parent = gui,
		})
		Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), Parent = holder })
		Util.responsive(Util.new("UIScale", { Parent = holder }), {})
		Library._notifyOrder = 0
	end
	local holder = gui.Holder
	Library._notifyOrder -= 1
	local duration = tonumber(opts.Duration) or 4
	local text = tostring(opts.Content or opts.Text or "")
	-- Fixed height from the measured text (no AutomaticSize: the timer bar hangs off the bottom edge).
	local textHeight = game:GetService("TextService"):GetTextSize(text, 13, FONT, Vector2.new(286, 1000)).Y
	local height = 40 + math.max(textHeight, 14) + 22
	local slot = Util.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = Library._notifyOrder, Parent = holder })
	local toast = Util.new("TextButton", {
		Name = "Toast",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Theme.Canvas,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(340, 0),
		Size = UDim2.fromScale(1, 1),
		Parent = slot,
	})
	Util.corner(toast, 5)
	Util.stroke(toast, Theme.Border, 3)
	local strip = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30), Parent = toast })
	Util.corner(strip, 5)
	Util.gradient(strip, Palettes.Purple.Gradient, 90)
	Util.damier(strip, Palettes.Purple.Damier, 18, 2)
	Util.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 3), Parent = strip })
	local icon = Util.new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(22, 22), ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = strip })
	Util.icon(icon, opts.Icon or Library._logo or Assets.Logo)
	Util.text(strip, { Text = string.upper(tostring(opts.Title or "Notice")), TextSize = 14, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -44, 1, 0), ZIndex = 3 })
	Util.text(toast, {
		Text = text,
		TextSize = 13,
		Stroke = 1.6,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.new(1, -24, 0, math.max(textHeight, 14) + 2),
	})
	local trough = Util.new("Frame", { AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = Theme.Trough, BorderSizePixel = 0, Position = UDim2.new(0, 10, 1, -8), Size = UDim2.new(1, -20, 0, 5), Parent = toast })
	Util.corner(trough, 2)
	local bar = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Parent = trough })
	Util.corner(bar, 2)
	Util.gradient(bar, Palettes.Lime.Gradient, 90)
	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		Util.tween(toast, 0.2, { Position = UDim2.fromOffset(340, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.22, function()
			slot:Destroy()
		end)
	end
	toast.MouseButton1Click:Connect(dismiss)
	Util.tween(toast, 0.4, { Position = UDim2.new() }, Enum.EasingStyle.Back)
	Util.tween(bar, duration, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
	task.delay(duration, dismiss)
	local children = 0
	for _, child in holder:GetChildren() do
		if child:IsA("Frame") then
			children += 1
		end
	end
	if children > 5 then
		local oldest, order = nil, -math.huge
		for _, child in holder:GetChildren() do
			if child:IsA("Frame") and child.LayoutOrder > order then
				oldest, order = child, child.LayoutOrder
			end
		end
		if oldest then
			oldest:Destroy()
		end
	end
	return { Dismiss = dismiss }
end

Library.Notification = Library.Notify

-- ============================================================================================================
-- HUD helpers (Status / Steal): plates, pills, 3D previews.
-- ============================================================================================================

function Hud.setColors(gradient, colors)
	gradient.Color = Util.sequence(colors)
end

function Hud.pill(parent, text, colors, layoutOrder)
	local pill = Util.new("Frame", { Name = "Pill", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = layoutOrder or 0, Parent = parent })
	Util.corner(pill, 4)
	Util.stroke(pill, Color3.new(0, 0, 0), 2)
	local gradient = Util.gradient(pill, colors or Hud.Grey, 90)
	Util.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = pill })
	-- A real UIStroke on pill text: the legacy text stroke looked blotchy at these sizes (pills are few, cheap enough).
	local label = Util.text(pill, { Text = text or "", TextSize = 11, Stroke = 1.3, UIStroke = true, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), TextXAlignment = Enum.TextXAlignment.Center })
	return pill, label, gradient
end

-- A copy of the model in a ViewportFrame, centred, with the camera distance that frames it.
function Hud.preview(viewport, camera, source)
	for _, child in viewport:GetChildren() do
		if child ~= camera then
			child:Destroy()
		end
	end
	camera.Parent = viewport
	local copy
	pcall(function()
		local archivable = source.Archivable
		source.Archivable = true
		copy = source:Clone()
		source.Archivable = archivable
	end)
	if not copy then
		return nil
	end
	if not copy:IsA("Model") then
		local holder = Instance.new("Model")
		copy.Parent = holder
		copy = holder
	end
	for _, descendant in copy:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") or descendant:IsA("Sound") or descendant:IsA("ParticleEmitter") or descendant:IsA("Beam")
			or descendant:IsA("Trail") or descendant:IsA("Light") or descendant:IsA("BillboardGui") or descendant:IsA("ProximityPrompt")
			or descendant:IsA("ClickDetector") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
	local ok, boxFrame, boxSize = pcall(copy.GetBoundingBox, copy)
	if not ok then
		copy:Destroy()
		return nil
	end
	copy:PivotTo(boxFrame:ToObjectSpace(copy:GetPivot()))
	copy.Parent = viewport
	local radius = boxSize.Magnitude / 2
	return { model = copy, distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.08 }
end

-- Opaque HUD plate: canvas colour, charcoal outline, faint checker.
function Hud.plate(parent, props)
	local frame = Util.new("Frame", {
		Name = props.Name or "Plate",
		BackgroundColor3 = Theme.Canvas,
		BorderSizePixel = 0,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position or UDim2.new(),
		Size = props.Size or UDim2.fromOffset(300, 100),
		ClipsDescendants = props.ClipsDescendants or false,
		Parent = parent,
	})
	Util.corner(frame, 6)
	Util.stroke(frame, Theme.Border, 3.2)
	return frame
end

-- ============================================================================================================
-- Status HUD (compact): a header strip with the stats, a task tile in the grey body (icon or turning 3D preview inside
-- a ring of progress segments, one simple motion per kind of task), state / tag pills, title, detail or chips, steps
-- and a thin progress line.
-- info for status:Set: { Text, Detail, State = "active" | "waiting" | "idle", Tag, Icon, Model,
--   Chips = { { Text, Colors } }, Steps = { Names, Current }, Bar = { Fraction, Text, Colors } }
-- ============================================================================================================

function Library:CreateStatus(opts)
	opts = type(opts) == "table" and opts or {}
	local status = { Visible = true, _connections = {}, _stats = {}, _statOrder = 0 }
	local connections = status._connections
	local gui = Util.screen(opts.Name or "BloomStatus", 995)
	status.Gui = gui
	local home = opts.Position or UDim2.new(0.5, 0, 0, 12)
	local frame = Hud.plate(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = home, Size = UDim2.fromOffset(470, 104) })
	status.Frame = frame
	Util.responsive(Util.new("UIScale", { Parent = frame }), connections)

	-- Header strip: logo, title, the stat pills on the right.
	local strip = Util.new("Frame", { Name = "Header", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 24), ZIndex = 2, ClipsDescendants = true, Parent = frame })
	Util.corner(strip, 6)
	Util.gradient(strip, Palettes.Purple.Gradient, 90)
	Util.new("Frame", { BackgroundColor3 = Palettes.Purple.Gradient[2], BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 6), ZIndex = 2, Parent = strip })
	Util.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 2), ZIndex = 2, Parent = frame })
	local logo = Util.new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 3), Size = UDim2.fromOffset(18, 18), ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = strip })
	Util.icon(logo, opts.Logo or Assets.Logo)
	Util.text(strip, { Text = string.upper(opts.Title or "Zenity Hub"), TextSize = 12, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(0.3, 0, 1, 0), ZIndex = 4 })
	local stats = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.7, -30, 0, 18), ZIndex = 4, Parent = strip })
	Util.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = stats })
	Util.drag(strip, frame, connections)

	-- Task tile (the grey body, left): the icon or a turning 3D preview, a ring of progress segments around it,
	-- and one simple motion per kind of task (bob, shake, pulse, turn...).
	local tile = Util.new("Frame", { Name = "Tile", BackgroundColor3 = Theme.Recess, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 32), Size = UDim2.fromOffset(64, 64), ZIndex = 2, Parent = frame })
	Util.corner(tile, 8)
	local tileStroke = Util.stroke(tile, Hud.StateColors.idle[1], 2)
	local segments = {}
	for index = 1, 20 do
		local angle = (index - 1) / 20 * math.pi * 2 - math.pi / 2
		local segment = Util.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(50, 66, 76), BorderSizePixel = 0, Size = UDim2.fromOffset(3, 6), Rotation = math.deg(angle) + 90, Position = UDim2.new(0.5, math.cos(angle) * 27, 0.5, math.sin(angle) * 27), ZIndex = 3, Parent = tile })
		Util.corner(segment, 2)
		segments[index] = segment
	end
	local holder = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), ZIndex = 4, Parent = tile })
	local holderScale = Util.new("UIScale", { Parent = holder })
	local icon = Util.new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = holder })
	local viewport = Util.new("ViewportFrame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Ambient = Color3.fromRGB(200, 200, 210), LightColor = Color3.new(1, 1, 1), ZIndex = 4, Parent = holder })
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Texts (right): state / tag pills, the title, the detail or chips, then steps; a thin progress line at the bottom.
	local pills = Util.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(84, 31), Size = UDim2.new(1, -94, 0, 18), ZIndex = 2, Parent = frame })
	Util.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = pills })
	local statePill, stateText, stateGradient = Hud.pill(pills, "IDLE", Hud.StateColors.idle, 1)
	statePill.Size = UDim2.fromOffset(0, 18)
	local tagPill, tagText = Hud.pill(pills, "", Hud.Bloom, 2)
	tagPill.Size = UDim2.fromOffset(0, 18)
	local title = Util.text(frame, { Name = "Title", TextSize = 15, Position = UDim2.fromOffset(84, 51), Size = UDim2.new(1, -94, 0, 18), ZIndex = 2 })
	local detail = Util.text(frame, { Name = "Detail", TextSize = 11, Stroke = 1.2, TextColor3 = Theme.Muted, Position = UDim2.fromOffset(84, 70), Size = UDim2.new(1, -94, 0, 14), ZIndex = 2 })
	local chipRow = Util.new("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromOffset(84, 69), Size = UDim2.new(1, -94, 0, 16), Visible = false, ZIndex = 2, Parent = frame })
	Util.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = chipRow })
	local chipPool = {}
	local steps = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 31), Size = UDim2.fromOffset(200, 18), Visible = false, ZIndex = 2, Parent = frame })
	Util.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = steps })
	local stepPool = {}
	local line = Util.new("Frame", { BackgroundColor3 = Theme.Trough, BorderSizePixel = 0, Position = UDim2.fromOffset(84, 89), Size = UDim2.new(1, -94, 0, 6), Visible = false, ZIndex = 2, Parent = frame })
	Util.corner(line, 3)
	local lineFill = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 3, Parent = line })
	Util.corner(lineFill, 3)
	local lineGradient = Util.gradient(lineFill, Hud.Sky, 0)

	function status:SetStat(name, value, colors)
		local entry = status._stats[name]
		if not entry then
			status._statOrder += 1
			local pill, label, gradient = Hud.pill(stats, "", colors or Hud.Grey, status._statOrder)
			pill.Size = UDim2.fromOffset(0, 16)
			label.TextSize = 10
			pill.ZIndex = 5
			entry = { pill = pill, label = label, gradient = gradient }
			status._stats[name] = entry
		end
		entry.label.Text = string.upper(name) .. " " .. tostring(value)
		if colors then
			Hud.setColors(entry.gradient, colors)
		end
	end

	local function renderChips(list)
		list = type(list) == "table" and list or {}
		chipRow.Visible = #list > 0
		detail.Visible = #list == 0
		for index, chip in list do
			local entry = chipPool[index]
			if not entry then
				local pill, label, gradient = Hud.pill(chipRow, "", Hud.Grey, index)
				pill.Size = UDim2.fromOffset(0, 16)
				label.TextSize = 10
				entry = { frame = pill, label = label, gradient = gradient }
				chipPool[index] = entry
			end
			entry.frame.Visible = true
			entry.label.Text = tostring(chip.Text or "")
			Hud.setColors(entry.gradient, chip.Colors or Hud.Grey)
		end
		for index = #list + 1, #chipPool do
			chipPool[index].frame.Visible = false
		end
	end

	local function renderSteps(info)
		steps.Visible = type(info) == "table" and type(info.Names) == "table"
		if not steps.Visible then
			return
		end
		local current = info.Current or 0
		for index, name in info.Names do
			local entry = stepPool[index]
			if not entry then
				local pill, label, gradient = Hud.pill(steps, "", Hud.Grey, index)
				pill.Size = UDim2.fromOffset(0, 16)
				label.TextSize = 10
				entry = { frame = pill, label = label, gradient = gradient }
				stepPool[index] = entry
			end
			entry.frame.Visible = true
			entry.label.Text = (index < current and "✓ " or "") .. string.upper(name)
			Hud.setColors(entry.gradient, index == current and Hud.Gold or (index < current and Hud.Green or Hud.Grey))
		end
		for index = #info.Names + 1, #stepPool do
			stepPool[index].frame.Visible = false
		end
	end

	-- Progress: the ring segments around the tile and the thin line; the tile's motion follows the task's style.
	local motion = { target = 0, shown = 0, style = "run", clock = 0, lit = -1 }
	local MOTIONS = {
		run = "bob", carry = "bob", chase = "shake", capture = "pulse", race = "lean", join = "spin", sky = "float",
		magic = "pulse", altar = "pulse", wisp = "float", plant = "bob", belt = "bounce", flutter = "float",
		music = "bounce", arc = "float", scan = "sweep", idle = "breathe",
	}
	local function renderBar(bar)
		local shown = type(bar) == "table"
		line.Visible = shown
		if not shown then
			motion.target, motion.style = 0, "idle"
			return
		end
		motion.target = math.clamp(tonumber(bar.Fraction) or 0, 0, 1)
		motion.style = MOTIONS[bar.Style] or "bob"
		motion.colors = bar.Colors or Hud.Sky
		Hud.setColors(lineGradient, motion.colors)
		if bar.Text and bar.Text ~= "" and #(status._chips or {}) == 0 then
			detail.Text = tostring(bar.Text)
		end
	end

	local function stepMotion(deltaTime)
		motion.clock += deltaTime
		motion.shown += (motion.target - motion.shown) * math.min(1, deltaTime * 6)
		lineFill.Size = UDim2.fromScale(motion.shown, 1)
		-- Segments: lit up to the progress in the bar's colour; the sweep style runs a light around the ring instead.
		local lit = math.floor(motion.shown * 20 + 0.001)
		local sweep = motion.style == "sweep"
		local head = math.floor(motion.clock * 14) % 20 + 1
		if sweep or lit ~= motion.lit or motion.colorsSet ~= motion.colors then
			motion.lit, motion.colorsSet = lit, motion.colors
			local on = (motion.colors or Hud.Sky)[1]
			for index, segment in segments do
				local active = sweep and ((head - index) % 20 < 5) or (not sweep and index <= lit)
				segment.BackgroundColor3 = active and on or Color3.fromRGB(50, 66, 76)
			end
		end
		if Library.ReducedMotion then
			holder.Position, holder.Rotation, holderScale.Scale = UDim2.fromScale(0.5, 0.5), 0, 1
			return
		end
		local t, x, y, rotation, scale = motion.clock, 0, 0, 0, 1
		local kind = motion.style
		if kind == "bob" then
			y = -math.abs(math.sin(t * 6)) * 3
		elseif kind == "shake" then
			x = math.sin(t * 40) * 1.5
		elseif kind == "pulse" then
			scale = 1 + math.sin(t * 4) * 0.08
		elseif kind == "lean" then
			rotation = math.sin(t * 3) * 8
		elseif kind == "spin" then
			rotation = (t * 120) % 360
		elseif kind == "float" then
			y = math.sin(t * 2) * 3
		elseif kind == "bounce" then
			y = -math.abs(math.sin(t * 9)) * 4
		elseif kind == "sweep" then
			rotation = math.sin(t * 3) * 15
		else
			scale = 1 + math.sin(t * 1.6) * 0.05
		end
		holder.Position = UDim2.new(0.5, x, 0.5, y)
		holder.Rotation = rotation
		holderScale.Scale = scale
	end

	function status:SetModel(model)
		if model == status._modelSource then
			return
		end
		status._modelSource = model
		if status._preview and status._preview.model then
			pcall(status._preview.model.Destroy, status._preview.model)
		end
		local ok, preview = false, nil
		if model then
			ok, preview = pcall(Hud.preview, viewport, camera, model)
		end
		status._preview = ok and preview or nil
		viewport.Visible = status._preview ~= nil
		icon.Visible = status._preview == nil
	end

	function status:Set(info)
		info = type(info) == "table" and info or {}
		local state = Hud.StateColors[info.State] and info.State or "idle"
		stateText.Text = Hud.StateWords[state]
		Hud.setColors(stateGradient, Hud.StateColors[state])
		tileStroke.Color = Hud.StateColors[state][1]
		tagPill.Visible = type(info.Tag) == "string" and info.Tag ~= ""
		tagText.Text = info.Tag or ""
		title.Text = info.Text or opts.Title or "Zenity Hub"
		detail.Text = info.Detail or ""
		status._chips = info.Chips
		if info.Icon ~= status._icon then
			status._icon = info.Icon
			Util.icon(icon, info.Icon or opts.Logo or Assets.Logo)
		end
		status:SetModel(info.Model)
		renderChips(info.Chips)
		renderSteps(info.Steps)
		renderBar(info.Bar)
	end

	function status:SetVisible(value)
		status.Visible = value ~= false
		frame.Visible = status.Visible
	end

	function status:Destroy()
		for _, connection in connections do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(connections)
		gui:Destroy()
	end

	local startedAt = os.clock()
	local frames, clock, spin = 0, 0, 0
	table.insert(connections, runService.RenderStepped:Connect(function(deltaTime)
		frames += 1
		clock += deltaTime
		if status.Visible then
			stepMotion(deltaTime)
		end
		if clock >= 0.5 then
			local up = math.floor(os.clock() - startedAt)
			status:SetStat("TIME", up >= 3600 and ("%d:%02d:%02d"):format(up // 3600, up % 3600 // 60, up % 60) or ("%d:%02d"):format(up // 60, up % 60), Hud.Lilac)
			local fps = math.floor(frames / clock + 0.5)
			frames, clock = 0, 0
			status:SetStat("FPS", fps, fps >= 50 and Hud.Green or (fps >= 25 and Hud.Gold or Hud.Red))
			local ok, ping = pcall(function()
				return localPlayer:GetNetworkPing() * 1000
			end)
			if ok and ping then
				ping = math.floor(ping + 0.5)
				status:SetStat("PING", ping, ping <= 120 and Hud.Green or (ping <= 250 and Hud.Gold or Hud.Red))
			end
		end
		local preview = status._preview
		if preview and status.Visible and not Library.ReducedMotion then
			spin = (spin + deltaTime * 40) % 360
			local position = (CFrame.Angles(0, math.rad(spin), 0) * CFrame.new(0, preview.distance * 0.18, preview.distance)).Position
			camera.CFrame = CFrame.lookAt(position, Vector3.zero)
		elseif preview and status._spinSet ~= preview then
			status._spinSet = preview
			camera.CFrame = CFrame.lookAt(Vector3.new(0, preview.distance * 0.18, preview.distance), Vector3.zero)
		end
	end))

	frame.Position = home - UDim2.fromOffset(0, 30)
	Util.tween(frame, 0.4, { Position = home }, Enum.EasingStyle.Back)
	status:Set({ Text = opts.Title or "Zenity Hub", Detail = opts.Detail or "Nothing running", State = "idle" })
	return status
end

-- ============================================================================================================
-- Steal panel: a side panel of pooled egg cards (STEAL / CANCEL, queue, reorder), a sort switch and a pull tab
-- that slides it off the screen edge.
-- ============================================================================================================

function Hud.stealCard(panel, list)
	local card = { panel = panel }
	local frame = Util.new("Frame", { Name = "EggCard", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 78), Parent = list })
	Util.corner(frame, 6)
	card.frame = frame
	card.stroke = Util.stroke(frame, Color3.new(0, 0, 0), 2.4)
	card.tint = Util.new("UIGradient", { Rotation = 0, Parent = frame })
	-- Hover: a small lift (from the centre) and a brighter rim; back to the card's own rim on leave.
	card.pop = Util.new("UIScale", { Name = "PopScale", Parent = frame })
	frame.MouseEnter:Connect(function()
		card.hovered = true
		Util.tween(card.pop, 0.1, { Scale = 1.02 })
		Util.tween(card.stroke, 0.1, { Color = card.baseStroke and card.baseStroke:Lerp(Color3.new(1, 1, 1), 0.35) or Palettes.Purple.Rim })
	end)
	frame.MouseLeave:Connect(function()
		card.hovered = false
		Util.tween(card.pop, 0.12, { Scale = 1 })
		Util.tween(card.stroke, 0.12, { Color = card.baseStroke or Color3.new(0, 0, 0) })
	end)
	local well = Util.new("Frame", { BackgroundColor3 = Theme.Recess, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(58, 58), ZIndex = 2, Parent = frame })
	Util.corner(well, 6)
	card.wellStroke = Util.stroke(well, Color3.new(0, 0, 0), 1.8)
	card.well = well
	card.icon = Util.new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = well })
	card.badge = Util.new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 5, 1, 5), Size = UDim2.fromOffset(22, 22), ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = well })
	card.queue = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(24, 18), ZIndex = 5, Visible = false, Parent = well })
	Util.corner(card.queue, 4)
	Util.stroke(card.queue, Color3.new(0, 0, 0), 1.8)
	Util.gradient(card.queue, Hud.Sky, 90)
	card.queueText = Util.text(card.queue, { TextSize = 11, Stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6 })
	card.name = Util.text(frame, { Name = "Name", TextSize = 15, Position = UDim2.fromOffset(78, 8), Size = UDim2.new(1, -178, 0, 20), ZIndex = 2 })
	card.rarity = Util.text(frame, { Name = "Rarity", TextSize = 10, Stroke = 1.4, Position = UDim2.fromOffset(78, 28), Size = UDim2.new(1, -178, 0, 14), ZIndex = 2 })
	card.value = Util.text(frame, { Name = "Value", TextSize = 13, Stroke = 1.6, RichText = true, TextColor3 = Palettes.Lime.Gradient[1], Position = UDim2.fromOffset(78, 43), Size = UDim2.new(1, -178, 0, 16), ZIndex = 2 })

	card.extra = Util.text(frame, { Name = "Extra", TextSize = 10, Stroke = 1.2, TextColor3 = Theme.Muted, Position = UDim2.fromOffset(78, 59), Size = UDim2.new(1, -178, 0, 14), ZIndex = 2 })
	card.tagPill, card.tagText, card.tagGradient = Hud.pill(frame, "", Hud.Gold, 0)
	card.tagPill.AnchorPoint = Vector2.new(1, 0)
	card.tagPill.Position = UDim2.new(1, -10, 0, 8)
	card.tagPill.Size = UDim2.fromOffset(0, 18)
	card.tagPill.ZIndex = 3
	local actionHolder = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -38, 1, -8), Size = UDim2.fromOffset(86, 30), ZIndex = 3, Parent = frame })
	card.action, card.actionParts = Util.bevel(actionHolder, { Palette = Palettes.Lime, Size = UDim2.fromScale(1, 1), Text = "STEAL", TextSize = 13, ZIndex = 4, Hover = 1.06 })
	local queueHolder = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -8), Size = UDim2.fromOffset(26, 30), ZIndex = 3, Parent = frame })
	card.queueButton, card.queueParts = Util.bevel(queueHolder, { Palette = Palettes.Cyan, Size = UDim2.fromScale(1, 1), Text = "+", TextSize = 16, ZIndex = 4, Hover = 1.08, Minimal = true, StrokeThickness = 2.2 })
	local arrows = Util.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(56, 20), Visible = false, ZIndex = 3, Parent = frame })
	card.arrows = arrows
	local upHolder = Util.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 18), Parent = arrows })
	card.up = Util.bevel(upHolder, { Palette = Palettes.Silver, Size = UDim2.fromScale(1, 1), Text = "▲", TextSize = 10, ZIndex = 4, Hover = 1.1, Minimal = true, StrokeThickness = 2 })
	local downHolder = Util.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.fromOffset(26, 18), Parent = arrows })
	card.down = Util.bevel(downHolder, { Palette = Palettes.Silver, Size = UDim2.fromScale(1, 1), Text = "▼", TextSize = 10, ZIndex = 4, Hover = 1.1, Minimal = true, StrokeThickness = 2 })
	card.action.MouseButton1Click:Connect(function()
		if card.id ~= nil then
			Util.safeCall(panel.OnSteal, card.id)
		end
	end)
	card.queueButton.MouseButton1Click:Connect(function()
		if card.id ~= nil then
			Util.safeCall(panel.OnQueue, card.id)
		end
	end)
	card.up.MouseButton1Click:Connect(function()
		if card.id ~= nil and card.canUp then
			Util.safeCall(panel.OnMove, card.id, -1)
		end
	end)
	card.down.MouseButton1Click:Connect(function()
		if card.id ~= nil and card.canDown then
			Util.safeCall(panel.OnMove, card.id, 1)
		end
	end)
	function card:Render(item, order)
		local isNew = card.id ~= item.Id
		card.id = item.Id
		card.canUp, card.canDown = item.CanUp == true, item.CanDown == true
		frame.LayoutOrder = order
		frame.Visible = true
		local color = typeof(item.RarityColor) == "Color3" and item.RarityColor or Theme.CardHighlight
		-- Featured (being stolen / the pick) is the biggest with a purple rim; BEST is a step up with a gold one.
		local best = item.Tag == "BEST"
		local big = item.Featured or best
		frame.Size = UDim2.new(1, 0, 0, item.Featured and 92 or (best and 86 or 78))
		card.baseStroke = item.Featured and Palettes.Purple.Rim or (best and Hud.Gold[1] or Color3.new(0, 0, 0))
		card.featured = item.Featured == true
		if not card.hovered then
			card.stroke.Color = card.baseStroke
		end
		card.stroke.Thickness = big and 3 or 2.4
		card.tint.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color:Lerp(Theme.Card, 0.45)),
			ColorSequenceKeypoint.new(0.5, Theme.Card),
			ColorSequenceKeypoint.new(1, Theme.Card),
		})
		card.wellStroke.Color = color
		card.name.Text = tostring(item.Name or "?")
		card.name.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3)
		card.rarity.Text = string.upper(tostring(item.Rarity or ""))
		card.rarity.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.15)
		local info = item.Info and item.Info ~= "" and ('  <font color="#FFC83C">%s</font>'):format(tostring(item.Info)) or ""
		card.value.Text = tostring(item.Value or "") .. info
		-- Bigger cards get a bigger preview, the texts move right with it.
		local wellSize = item.Featured and 70 or (best and 64 or 58)
		card.well.Size = UDim2.fromOffset(wellSize, wellSize)
		local shift = wellSize + 20
		card.name.Position, card.rarity.Position = UDim2.fromOffset(shift, 8), UDim2.fromOffset(shift, 28)
		card.value.Position, card.extra.Position = UDim2.fromOffset(shift, 43), UDim2.fromOffset(shift, 59)
		-- $/s, kg and mutations stop before the STEAL / CANCEL and + / − buttons (bottom right, ~124px wide).
		card.value.Size, card.extra.Size = UDim2.new(1, -(shift + 132), 0, 16), UDim2.new(1, -(shift + 132), 0, 14)
		card.extra.Text = tostring(item.Extra or "")
		if item.Icon ~= card._icon then
			card._icon = item.Icon
			Util.icon(card.icon, item.Icon)
		end
		card.badge.Visible = item.Badge ~= nil
		if item.Badge and item.Badge ~= card._badge then
			card._badge = item.Badge
			Util.icon(card.badge, item.Badge)
		end
		card.tagPill.Visible = type(item.Tag) == "string" and item.Tag ~= ""
		card.tagText.Text = item.Tag or ""
		Hud.setColors(card.tagGradient, item.TagColors or (item.Tag == "BEST" and Hud.Gold or Hud.Bloom))
		card.queue.Visible = item.Queued ~= nil
		card.queueText.Text = item.Queued and ("#" .. item.Queued) or ""
		card.arrows.Visible = item.Queued ~= nil
		-- The arrows take the top-right corner of a queued card; a tag then sits to their left.
		card.tagPill.Position = UDim2.new(1, card.arrows.Visible and -70 or -10, 0, 8)
		-- The name stops before whatever holds the top-right corner (tag, arrows or both).
		local reserved = (card.tagPill.Visible and 70 or 0) + (card.arrows.Visible and 64 or 0)
		local left = wellSize + 20
		card.name.Size = UDim2.new(1, -(left + math.max(reserved, 12) + 4), 0, 20)
		card.queueParts.label.Text = item.Queued and "−" or "+"
		local actionText = tostring(item.ActionText or "STEAL")
		card.actionParts.label.Text = actionText
		card.actionParts.setPalette(actionText == "STEAL" and Palettes.Lime or (actionText == "DELIVERING" and Palettes.Amber or Palettes.Red))
		if isNew and not Library.ReducedMotion then
			local scale = frame:FindFirstChild("PopScale") or Util.new("UIScale", { Name = "PopScale", Parent = frame })
			scale.Scale = 0.9
			Util.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	return card
end

function Library:CreateStealPanel(opts)
	opts = type(opts) == "table" and opts or {}
	local panel = { Collapsed = false, Visible = true, OnSteal = opts.OnSteal, OnQueue = opts.OnQueue, OnMove = opts.OnMove, _cards = {}, _connections = {} }
	local connections = panel._connections
	local gui = Util.screen(opts.Name or "BloomSteal", 994)
	panel.Gui = gui
	local right = opts.Side ~= "Left"
	local width, height = opts.Width or 350, opts.Height or 460
	-- Opens left of the screen-edge button column (the game's right-side buttons and ours), never over it.
	local openPosition = UDim2.new(right and 1 or 0, right and -(opts.EdgeGap or 112) or (opts.EdgeGap or 112), 0.5, 0)
	local holder = Util.new("Frame", { AnchorPoint = Vector2.new(right and 1 or 0, 0.5), Position = openPosition, Size = UDim2.fromOffset(width, height), BackgroundTransparency = 1, Parent = gui })
	panel.Holder = holder
	Util.responsive(Util.new("UIScale", { Parent = holder }), connections)
	local frame = Hud.plate(holder, { Size = UDim2.fromScale(1, 1), ClipsDescendants = true })

	local header = Util.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 56), ZIndex = 2, ClipsDescendants = true, Parent = frame })
	Util.corner(header, 6)
	Util.gradient(header, Palettes.Purple.Gradient, 90)
	Util.damier(header, Palettes.Purple.Damier, 22, 3)
	Util.new("Frame", { BackgroundColor3 = Palettes.Purple.Gradient[2], BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 6), ZIndex = 2, Parent = header })
	Util.new("Frame", { BackgroundColor3 = Palettes.Purple.Dark, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 3), ZIndex = 2, Parent = frame })
	Util.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Position = UDim2.fromOffset(0, 59), Size = UDim2.new(1, 0, 0, 3), ZIndex = 2, Parent = frame })
	local titleLabel = Util.text(header, { Text = string.upper(opts.Title or "Steal Panel"), TextSize = 20, Stroke = 2.8, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -150, 0, 26), ZIndex = 4 })
	local subtitle = Util.text(header, { Text = opts.Subtitle or "", TextSize = 12, Stroke = 1.6, TextColor3 = Color3.fromRGB(236, 214, 255), Position = UDim2.fromOffset(15, 32), Size = UDim2.new(1, -28, 0, 16), ZIndex = 4 })

	-- Sort switch (segmented): the selected one is the purple bevel.
	local sortRow = Util.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 0, 30), ZIndex = 2, Parent = frame })
	local sortButtons = {}
	local sorts = type(opts.Sorts) == "table" and opts.Sorts or {}
	for index, name in sorts do
		local cell = Util.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new((index - 1) / #sorts, 2, 0, 0), Size = UDim2.new(1 / #sorts, -4, 1, 0), Parent = sortRow })
		local button, parts = Util.bevel(cell, { Palette = Palettes.Silver, Size = UDim2.fromScale(1, 1), Text = "SORT: " .. string.upper(name), TextSize = 12, ZIndex = 3, Hover = 1.03 })
		sortButtons[name] = parts
		button.MouseButton1Click:Connect(function()
			panel:SetSort(name)
			Util.safeCall(opts.OnSort, name)
		end)
	end
	function panel:SetSort(value)
		panel.Sort = value
		for name, parts in sortButtons do
			parts.setPalette(name == value and Palettes.Purple or Palettes.Silver)
		end
	end
	if #sorts > 0 then
		panel:SetSort(opts.Sort or sorts[1])
	end
	local listTop = #sorts > 0 and 110 or 72
	local list = Util.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, listTop),
		Size = UDim2.new(1, -20, 1, -listTop - 10),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent,
		ZIndex = 2,
		Parent = frame,
	})
	Util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = list })
	Util.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8), Parent = list })
	-- Empty state: the logo, faded, over the empty text.
	local empty = Util.new("Frame", { Name = "Empty", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, listTop + 40), Size = UDim2.new(1, 0, 0, 120), ZIndex = 3, Parent = frame })
	local emptyLogo = Util.new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(72, 72), ImageTransparency = 0.55, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = empty })
	Util.icon(emptyLogo, Library._logo or Assets.OpenLogo)
	Util.text(empty, { Text = opts.EmptyText or "Nothing here", TextSize = 14, Stroke = 2, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 24), ZIndex = 3 })
	-- Egg count pill on the header's right.
	local countPill, countText = Hud.pill(header, "0 EGGS", Hud.Gold, 0)
	countPill.AnchorPoint = Vector2.new(1, 0)
	countPill.Position = UDim2.new(1, -50, 0, 8)
	countPill.ZIndex = 5
	-- The featured card's rim breathes (stopped with ReducedMotion).
	local glowClock = 0
	table.insert(connections, runService.RenderStepped:Connect(function(deltaTime)
		if Library.ReducedMotion or not holder.Visible or panel.Collapsed then
			return
		end
		glowClock += deltaTime
		for _, card in panel._cards do
			if card.featured and card.frame.Visible and not card.hovered then
				card.stroke.Transparency = 0.35 - math.cos(glowClock * 3) * 0.35
			elseif card.stroke.Transparency ~= 0 then
				card.stroke.Transparency = 0
			end
		end
	end))

	-- Toggle button in the game's own button style (a purple 3D square with an icon and a count badge), fixed in the
	-- game's right-side button column, one step above its first button. It slides the panel off screen and back.
	local buttonHolder = Util.new("Frame", {
		Name = "StealButton",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = opts.ButtonPosition or UDim2.new(right and 1 or 0, right and -54 or 54, 0.5, -220),
		Size = UDim2.fromOffset(56, 56),
		Parent = gui,
	})
	local buttonScale = Util.new("UIScale", { Parent = buttonHolder })
	local toggle, toggleParts = Util.bevel(buttonHolder, { Palette = Palettes.Purple, Size = UDim2.fromScale(1, 1), StrokeThickness = 3, Icon = opts.ButtonIcon or "hand-coins", IconSize = 30, ZIndex = 3, Hover = 1.08 })
	if toggleParts.icon then
		toggleParts.icon.Size = UDim2.fromScale(0.56, 0.56)
	end
	-- The icon is kept on its own image: re-applied whenever it went blank or was swapped (a late Lucide load, a pooled
	-- label reused elsewhere); a "$" stands in while the set is unavailable.
	local buttonIcon = opts.ButtonIcon or "hand-coins"
	local iconFallback = toggleParts.icon and Util.text(toggleParts.icon.Parent, {
		Text = "$", TextSize = 30, Stroke = 2.6, TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1), ZIndex = toggleParts.icon.ZIndex,
	})
	if iconFallback then
		iconFallback.Visible = false
	end
	local function keepIcon()
		local icon = toggleParts.icon
		if not icon then return end
		local image, offset, rectSize = Util.resolveIcon(buttonIcon)
		if image then
			offset, rectSize = offset or Vector2.zero, rectSize or Vector2.zero
			if icon.Image ~= image or icon.ImageRectOffset ~= offset or icon.ImageRectSize ~= rectSize then
				icon.Image, icon.ImageRectOffset, icon.ImageRectSize = image, offset, rectSize
			end
			if icon.ImageTransparency ~= 0 then icon.ImageTransparency = 0 end
		end
		if iconFallback then
			iconFallback.Visible = image == nil and Util.lucide == false
		end
	end
	-- Alignment with the game's own button column: opts.AlignWith() returns its first visible button and the one
	-- under it; ours takes the first one's size and sits one step (their spacing) above it, re-checked every half
	-- second (their HUD scales with the screen). Without them it keeps its default spot and the responsive scale.
	-- Cutscenes shrink / slide / hide the game's HUD: a reading taken then (HUD disabled or hidden, the button smaller
	-- than the last good size or off screen) is ignored and the last good size and spot are kept; the last good size
	-- only resets when the screen itself changes size.
	local alignClock = 1
	local goodSize, goodViewport
	local function hudShown(object)
		local node = object
		while node and not node:IsA("LayerCollector") do
			if node:IsA("GuiObject") and not node.Visible then return false end
			node = node.Parent
		end
		return node == nil or not node:IsA("ScreenGui") or node.Enabled
	end
	table.insert(connections, runService.Heartbeat:Connect(function(deltaTime)
		alignClock += deltaTime
		if alignClock < 0.5 then
			return
		end
		alignClock = 0
		keepIcon()
		local ok, top, below = pcall(function()
			if type(opts.AlignWith) == "function" then
				return opts.AlignWith()
			end
		end)
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.zero
		if viewport ~= goodViewport then
			goodViewport, goodSize = viewport, nil
		end
		if not ok or typeof(top) ~= "Instance" or not top:IsA("GuiObject") or top.AbsoluteSize.X <= 0 then
			if not goodSize then
				buttonScale.Scale = Util.deviceScale()
			end
			return
		end
		local size = top.AbsoluteSize
		local position = top.AbsolutePosition
		local onScreen = position.X >= 0 and position.Y >= 0 and position.X + size.X <= viewport.X + 1 and position.Y + size.Y <= viewport.Y + 1
		if not hudShown(top) or not onScreen or (goodSize and size.X < goodSize.X * 0.9) then
			return
		end
		goodSize = size
		local step = (typeof(below) == "Instance" and below:IsA("GuiObject")) and (below.AbsolutePosition.Y - top.AbsolutePosition.Y) or (size.Y * 1.35)
		if step < size.Y * 0.9 or step > size.Y * 2.5 then
			step = size.Y * 1.35
		end
		local center = top.AbsolutePosition + size / 2
		buttonScale.Scale = 1
		buttonHolder.Size = UDim2.fromOffset(size.X, size.Y)
		-- AbsolutePosition is screen space; our Position is relative to our own ScreenGui, whose origin may differ
		-- from the game's (topbar inset, CoreGui / gethui container), so convert through our gui's AbsolutePosition.
		local origin = gui.AbsolutePosition
		buttonHolder.Position = UDim2.fromOffset(center.X - origin.X, center.Y - step - origin.Y)
		if panel._badge then
			panel._badge.Size = UDim2.fromOffset(size.X * 0.38, size.X * 0.38)
		end
	end))
	local badge = Util.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Color3.fromRGB(230, 20, 40), BorderSizePixel = 0, ZIndex = 8, Parent = buttonHolder })
	Util.corner(badge, 999)
	Util.stroke(badge, Color3.new(1, 1, 1), 2)
	local badgeText = Util.text(badge, { Text = "0", TextSize = 13, Stroke = 1.8, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 9 })
	panel._badge, panel._badgeText = badge, badgeText
	function panel:SetCollapsed(value)
		panel.Collapsed = value == true
		panel._collapseId = (panel._collapseId or 0) + 1
		local id = panel._collapseId
		-- Closing slides it past the screen edge: its on-screen width (after the responsive UIScale) plus the gap it
		-- opens at, then hides it. Opening shows it and slides it back to its spot.
		local shown = holder.AbsoluteSize.X > 0 and holder.AbsoluteSize.X or width
		local gap = opts.EdgeGap or 112
		if panel.Collapsed then
			Util.tween(holder, 0.3, { Position = openPosition + UDim2.fromOffset(right and shown + gap + 30 or -(shown + gap + 30), 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.3, function()
				if panel._collapseId == id and panel.Collapsed then
					holder.Visible = false
				end
			end)
		else
			holder.Visible = panel.Visible ~= false
			Util.tween(holder, 0.35, { Position = openPosition }, Enum.EasingStyle.Back)
		end
	end
	toggle.MouseButton1Click:Connect(function()
		panel:SetCollapsed(not panel.Collapsed)
	end)
	-- The panel's own [X] (Check-UI close button) in its header closes it; the side button brings it back.
	local close = Util.bevel(header, {
		Name = "CloseButton",
		Palette = Palettes.Close,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, -2),
		Size = UDim2.fromOffset(32, 32),
		StrokeThickness = 2.6,
		Text = "X",
		TextSize = 20,
		ZIndex = 6,
	})
	close.MouseButton1Click:Connect(function()
		panel:SetCollapsed(true)
	end)
	Util.drag(header, holder, connections)

	function panel:SetItems(items)
		items = type(items) == "table" and items or {}
		empty.Visible = #items == 0
		countText.Text = #items .. (#items == 1 and " EGG" or " EGGS")
		panel._badgeText.Text = #items > 99 and "99+" or tostring(#items)
		panel._badge.Visible = #items > 0
		for index, item in items do
			local card = panel._cards[index]
			if not card then
				card = Hud.stealCard(panel, list)
				panel._cards[index] = card
			end
			card:Render(item, index)
		end
		for index = #items + 1, #panel._cards do
			panel._cards[index].frame.Visible = false
			panel._cards[index].id = nil
		end
	end
	function panel:SetTitle(value)
		titleLabel.Text = string.upper(tostring(value or ""))
	end
	function panel:SetSubtitle(value, color)
		subtitle.Text = tostring(value or "")
		subtitle.TextColor3 = typeof(color) == "Color3" and color:Lerp(Color3.new(1, 1, 1), 0.35) or Color3.fromRGB(236, 214, 255)
	end
	function panel:SetVisible(value)
		panel.Visible = value ~= false
		holder.Visible = panel.Visible and not panel.Collapsed
	end
	function panel:Destroy()
		for _, connection in connections do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(connections)
		gui:Destroy()
	end

	holder.Position = openPosition + UDim2.fromOffset(right and width * 1.3 + 30 or -(width * 1.3 + 30), 0)
	Util.tween(holder, 0.45, { Position = openPosition }, Enum.EasingStyle.Back)
	return panel
end

Library.CreateSteal = Library.CreateStealPanel

-- Compatibility no-ops for options the previous library had.
function Library:PreloadIcons()
	return Util.loadLucide() ~= false
end

function Library:UseGameFont() end

Library.Util = Util
-- Icons start downloading as soon as the library loads, before any window is built.
Util.startLucide()
Library.Container = Container
return Library
