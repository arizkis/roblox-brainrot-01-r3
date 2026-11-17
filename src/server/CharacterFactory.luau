--!strict
-- Builds visuals only. The caller chooses the cast id and optional single mutation,
-- owns the returned unparented model, then parents/PivotTo's it when appropriate.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.GameConfig)

local Factory = {}
local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(17, 23, 42)
local GLITCH_COLORS = {
	Color3.fromRGB(255, 60, 180), Color3.fromRGB(45, 237, 255), Color3.fromRGB(117, 255, 87),
}

local function rotation(degrees: Vector3): CFrame
	return CFrame.Angles(math.rad(degrees.X), math.rad(degrees.Y), math.rad(degrees.Z))
end

local function bounds(parts: { Config.PartRecipe }): (Vector3, Vector3)
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local high = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, spec in parts do
		local transform = CFrame.new(spec.position) * rotation(spec.rotation)
		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				for z = -1, 1, 2 do
					local corner = transform:PointToWorldSpace(spec.size * Vector3.new(x, y, z) * 0.5)
					low = low:Min(corner)
					high = high:Max(corner)
				end
			end
		end
	end
	return low, high
end

local function addPart(model: Model, root: Part, name: string, shape: string, size: Vector3,
	transform: CFrame, color: Color3, neon: boolean?): BasePart
	local part: BasePart
	if shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local primitive = Instance.new("Part")
		if shape == "Ball" then
			primitive.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			primitive.Shape = Enum.PartType.Cylinder
		else
			assert(shape == "Block", "Unknown recipe shape: " .. shape)
		end
		part = primitive
	end
	part.Name = name
	part.Size = size
	part.CFrame = transform
	part.Color = color
	part.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Name = "RootWeld"
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function amount(value: number): string
	local digits = tostring(math.floor(value))
	local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function nameplate(root: Part, character: Config.CharacterDefinition, height: number, income: number, mutationId: string?)
	local attachment = Instance.new("Attachment")
	attachment.Name = "NameplateAnchor"
	attachment.Position = Vector3.new(0, height + 0.75, 0)
	attachment.Parent = root
	local board = Instance.new("BillboardGui")
	board.Name = "CharacterNameplate"
	board.Adornee = attachment
	board.Size = UDim2.fromOffset(310, 112)
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.MaxDistance = 110
	board.Parent = attachment
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = INK
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Parent = board
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = panel

	local function line(name: string, text: string, top: number, fraction: number, maxSize: number, color: Color3?)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Position = UDim2.fromScale(0.025, top)
		label.Size = UDim2.fromScale(0.95, fraction)
		label.BackgroundTransparency = if color then 0 else 1
		label.BackgroundColor3 = color or INK
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.TextColor3 = WHITE
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0
		label.TextScaled = true
		label.TextWrapped = false
		label.Parent = panel
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = 12
		limit.MaxTextSize = maxSize
		limit.Parent = label
	end
	line("CharacterName", character.name, 0.02, 0.39, 32, nil)
	line("Rarity", string.upper(character.tier), 0.43, 0.24, 24, Config.Tiers[character.tier].color)
	local incomeText = "$" .. amount(income) .. "/s"
	if mutationId then
		incomeText ..= "  |  " .. mutationId .. " x" .. Config.Mutations[mutationId].multiplier
	end
	line("Income", incomeText, 0.69, 0.29, 28, nil)
end

local function mutationVisuals(model: Model, root: Part, mutationId: string, width: number, height: number)
	local mutation = Config.Mutations[mutationId]
	local color = mutation.color
	local function accent(name: string, shape: string, size: Vector3, pos: Vector3, tint: Color3, transparency: number?, roll: number?): BasePart
		local transform = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(roll or 0))
		local part = addPart(model, root, name, shape, size, transform, tint, true)
		part.Transparency = transparency or 0
		part.CastShadow = false
		return part
	end
	if mutationId == "Golden" or mutationId == "Diamond" then
		local span = math.max(width * 0.82, 1.5)
		for _, side in { -1, 1 } do
			accent("MutationTrim", "Block", Vector3.new(span, 0.12, 0.12), Vector3.new(0, 0.15, side * 0.65), color)
			accent("MutationTrim", "Block", Vector3.new(0.12, 0.12, 1.3), Vector3.new(side * span / 2, 0.15, 0), color)
		end
		if mutationId == "Diamond" then
			for _, side in { -1, 1 } do
				accent("CyanGlint", "Block", Vector3.new(0.27, 0.65, 0.12),
					Vector3.new(side * (width / 2 + 0.12), height * 0.72, 0), WHITE, nil, 45)
			end
		end
	elseif mutationId == "Glitch" then
		for index, tint in GLITCH_COLORS do
			accent("RGBEcho" .. index, "Block", Vector3.new(width * 0.6, 0.12, 0.18),
				Vector3.new((index - 2) * 0.18, height * (0.22 + index * 0.18), -0.85 - index * 0.08), tint, 0.2)
		end
	elseif mutationId == "Void" then
		accent("VoidAura", "Ball", Vector3.new(width + 0.65, height * 0.9, width + 0.65),
			Vector3.new(0, height * 0.5, 0), Color3.fromRGB(42, 14, 77), 0.82)
		for index = 1, 4 do
			local angle = index * math.pi / 2
			accent("VoidOrb" .. index, "Ball", Vector3.new(0.28, 0.28, 0.28),
				Vector3.new(math.cos(angle) * (width / 2 + 0.3), height * 0.6, math.sin(angle) * (width / 2 + 0.3)), color)
		end
	end
	local glow = Instance.new("PointLight")
	glow.Name = "MutationGlow"
	glow.Color = color
	glow.Brightness = 0.7
	glow.Range = 7
	glow.Shadows = false
	glow.Parent = root
end

-- Pivot is the character's ground point, facing -Z. All pieces are welded to an
-- anchored root; a future carry system can unanchor that root as a single assembly.
function Factory.Create(characterId: string, mutationId: string?): Model
	local character = Config.CharactersById[characterId]
	assert(character ~= nil, "Unknown character id: " .. characterId)
	local mutation = if mutationId then Config.Mutations[mutationId] else nil
	assert(mutationId == nil or mutation ~= nil, "Unknown mutation: " .. tostring(mutationId))
	local tier = Config.Tiers[character.tier]
	local multiplier = if mutation then mutation.multiplier else 1
	assert(multiplier <= Config.MaxMutationMultiplier, "Mutation multiplier exceeds x15")
	local low, high = bounds(character.parts)
	local scale = tier.height / (high.Y - low.Y)
	local function position(point: Vector3): Vector3
		return (point - Vector3.new(0, low.Y, 0)) * scale
	end
	local model = Instance.new("Model")
	model.Name = character.name
	model:SetAttribute("CharacterId", characterId)
	model:SetAttribute("Tier", character.tier)
	model:SetAttribute("Mutation", mutationId or "None")
	model:SetAttribute("MutationMultiplier", multiplier)
	model:SetAttribute("BaseIncomePerSecond", tier.income)
	model:SetAttribute("IncomePerSecond", tier.income * multiplier)
	model:SetAttribute("BuyPrice", tier.price)
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.4, 0.1, 0.4)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Parent = model
	model.PrimaryPart = root
	for index, spec in character.parts do
		local color = spec.color
		if mutationId == "Golden" then
			color = color:Lerp(Config.Mutations.Golden.color, 0.38)
		elseif mutationId == "Diamond" then
			color = color:Lerp(Config.Mutations.Diamond.color, 0.25)
		elseif mutationId == "Glitch" then
			color = GLITCH_COLORS[(index - 1) % #GLITCH_COLORS + 1]
		elseif mutationId == "Void" then
			color = color:Lerp(Color3.fromRGB(38, 19, 65), 0.65)
		end
		local part = addPart(model, root, spec.name, spec.shape, spec.size * scale,
			CFrame.new(position(spec.position)) * rotation(spec.rotation), color, spec.neon)
		if mutationId == "Golden" or mutationId == "Diamond" then
			part.Material = if spec.neon then Enum.Material.Neon else Enum.Material.Metal
			part.Reflectance = if mutationId == "Diamond" then 0.25 else 0.12
		end
	end
	local face = character.face
	if face then
		for _, side in { -1, 1 } do
			local eyePosition = position(face.position + Vector3.new(side * face.spacing / 2, 0, 0))
			local size = (face.eyeSize or 0.18) * scale
			addPart(model, root, if side < 0 then "EyeLeft" else "EyeRight", "Ball",
				Vector3.new(size, size * 1.3, size * 0.55), CFrame.new(eyePosition), face.eyeColor or INK)
			addPart(model, root, "EyeGlint", "Ball", Vector3.one * size * 0.3,
				CFrame.new(eyePosition + Vector3.new(-size * 0.17, size * 0.2, -size * 0.3)), WHITE)
		end
	end
	if mutationId then
		mutationVisuals(model, root, mutationId, (high.X - low.X) * scale, tier.height)
	end
	nameplate(root, character, tier.height, tier.income * multiplier, mutationId)
	return model
end

return Factory
