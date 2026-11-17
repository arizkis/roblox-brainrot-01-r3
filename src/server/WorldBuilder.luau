--!strict
-- Static geometry only: no player listeners, claiming, cash, timers or prompts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local GameState = require(script.Parent.GameState)

local WorldBuilder = {}
local rgb = Color3.fromRGB
local v = Vector3.new
local WHITE = rgb(255, 255, 255)
local INK = rgb(31, 39, 72)
local CREAM = rgb(255, 246, 210)

local function part(parent: Instance, name: string, size: Vector3, transform: CFrame,
	color: Color3, material: Enum.Material?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = transform
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Anchored = true
	item.Parent = parent
	return item
end

local function group(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

local function sign(board: BasePart, text: string, color: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignFace"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 45
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Position = UDim2.fromScale(0.04, 0.06)
	label.Size = UDim2.fromScale(0.92, 0.88)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = color or WHITE
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	return label
end

local function marker(parent: Instance, name: string, transform: CFrame): Part
	local item = part(parent, name, v(0.3, 0.3, 0.3), transform, WHITE)
	item.Transparency = 1
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	return item
end

local function buildConveyor(world: Model): (BasePart, BasePart)
	local settings = Config.World
	local belt = group(world, "Conveyor")
	local frame = CFrame.Angles(0, math.rad(settings.beltYawDegrees), 0)
	local length = settings.beltLength
	local width = settings.beltWidth
	part(belt, "BeltFoundation", v(width + 2, 0.5, length + 1), frame * CFrame.new(0, 0.25, 0), INK)
	part(belt, "BeltSurface", v(width, 0.35, length), frame * CFrame.new(0, 0.66, 0), rgb(49, 73, 108))
	for _, side in { -1, 1 } do
		part(belt, "SideRail", v(0.45, 0.65, length), frame * CFrame.new(side * (width / 2 + 0.35), 0.85, 0), rgb(255, 209, 66))
		part(belt, "RailGlow", v(0.14, 0.12, length), frame * CFrame.new(side * (width / 2 + 0.35), 1.22, 0), rgb(90, 255, 208), Enum.Material.Neon)
	end
	for index = -5, 5 do
		local z = index * 8
		part(belt, "BeltSeam", v(width - 0.4, 0.025, 0.1), frame * CFrame.new(0, 0.85, z + 3), rgb(76, 107, 139))
		for _, side in { -1, 1 } do
			local arrow = part(belt, "DirectionChevron", v(0.22, 0.04, 1.8),
				frame * CFrame.new(side * 0.65, 0.87, z + 0.4) * CFrame.Angles(0, math.rad(side * 45), 0), rgb(121, 255, 205), Enum.Material.Neon)
			arrow.CanCollide = false
		end
	end
	local archZ = length / 2 - 2
	for _, side in { -1, 1 } do
		part(belt, "SpawnArchPillar", v(1.4, 8.5, 1.7), frame * CFrame.new(side * 6.8, 4.25, archZ), rgb(255, 109, 173))
		part(belt, "PillarFoot", v(2.5, 0.6, 2.8), frame * CFrame.new(side * 6.8, 0.3, archZ), CREAM)
	end
	local arch = part(belt, "SpawnArchSign", v(16, 3.1, 1), frame * CFrame.new(0, 8.7, archZ), rgb(137, 72, 211))
	sign(arch, "FRESH BRAINROT", WHITE)
	part(belt, "ArchCrown", v(17, 0.3, 1.2), frame * CFrame.new(0, 10.4, archZ), rgb(255, 220, 69), Enum.Material.Neon)
	local exit = part(belt, "BeltEndSign", v(11, 2, 0.4), frame * CFrame.new(0, 3, -length / 2) * CFrame.Angles(0, math.pi, 0), INK)
	sign(exit, "NEXT STOP: YOUR BASE", rgb(116, 255, 207))
	-- Root ground positions: future Conveyor module moves models between these.
	local start = marker(belt, "Start", frame * CFrame.new(0, 0.85, length / 2 - 7))
	local finish = marker(belt, "Finish", frame * CFrame.new(0, 0.85, -length / 2 + 5))
	return start, finish
end

local function buildBase(parent: Model, id: number): GameState.BaseRecord
	local settings = Config.World
	local angle = math.rad(30 + (id - 1) * 360 / settings.baseCount)
	local center = v(math.cos(angle) * settings.baseRadius, 0, math.sin(angle) * settings.baseRadius)
	-- Local -Z faces the plaza center, +Z is the owner board at the back.
	local frame = CFrame.lookAt(center, Vector3.zero)
	local color = settings.baseColors[id]
	local plot = group(parent, string.format("Base%02d", id))
	plot:SetAttribute("BaseId", id)
	plot:SetAttribute("PadCapacity", settings.startingPads)
	plot:SetAttribute("MaxPadCapacity", settings.maxPads)
	part(plot, "Platform", settings.baseSize, frame * CFrame.new(0, 0.5, 0), color)
	part(plot, "Deck", v(28.5, 0.1, 22.5), frame * CFrame.new(0, 1.04, 0), CREAM)
	part(plot, "EntryStep", v(12, 0.5, 2.5), frame * CFrame.new(0, 0.25, -12.5), color)
	part(plot, "EntryStripe", v(12, 0.08, 0.35), frame * CFrame.new(0, 1.12, -10.5), color, Enum.Material.Neon)
	part(plot, "PadRowArea", v(27.5, 0.1, 6.5), frame * CFrame.new(0, 1.12, 0), rgb(225, 225, 223))
	local pads: { BasePart } = {}
	local padGroup = group(plot, "Pads")
	for padId = 1, settings.startingPads do
		local x = (padId - (settings.startingPads + 1) / 2) * settings.padSpacing
		local pad = part(padGroup, string.format("Pad%02d", padId), v(3.8, 0.24, 4.2), frame * CFrame.new(x, 1.3, 0), color)
		pad:SetAttribute("BaseId", id)
		pad:SetAttribute("PadId", padId)
		part(padGroup, "PadInset", v(3.3, 0.06, 3.7), frame * CFrame.new(x, 1.45, 0), rgb(255, 252, 238))
		table.insert(pads, pad)
	end
	-- Empty back strip reserves room for the four future rebirth pads.
	part(plot, "ExpansionArea", v(20, 0.07, 3.4), frame * CFrame.new(0, 1.12, 5.2), rgb(235, 232, 218))
	for _, side in { -1, 1 } do
		part(plot, "OwnerSignPost", v(0.45, 6, 0.45), frame * CFrame.new(side * 7, 4, 9.5), color)
	end
	local board = part(plot, "OwnerSign", v(17, 3.6, 0.5), frame * CFrame.new(0, 7.1, 9.5), INK)
	local ownerLabel = sign(board, string.format("UNCLAIMED\nBASE %02d", id), color)
	part(plot, "LockPedestal", v(2.8, 2.1, 2.8), frame * CFrame.new(10.8, 2.1, -7.4), INK)
	local lockButton = part(plot, "LockButton", v(2.3, 0.4, 2.3), frame * CFrame.new(10.8, 3.35, -7.4), rgb(82, 237, 159), Enum.Material.Neon)
	lockButton:SetAttribute("BaseId", id)
	local lockLabel = part(plot, "LockLabel", v(4.8, 1.1, 0.2), frame * CFrame.new(10.5, 4.5, -6), INK)
	sign(lockLabel, "BASE LOCK", WHITE)
	-- This is only a spatial reference, with no collision or protection logic yet.
	local zone = part(plot, "BaseZone", v(settings.baseSize.X, 14, settings.baseSize.Z), frame * CFrame.new(0, 8, 0), color)
	zone.Transparency = 1
	zone.CanCollide = false
	zone.CanTouch = false
	zone.CanQuery = false
	return { Id = id, Plot = plot, Zone = zone, Pads = pads, OwnerLabel = ownerLabel, LockButton = lockButton }
end

local function buildDecoration(world: Model)
	local decor = group(world, "Decoration")
	local half = Config.World.plazaSize / 2
	for _, side in { -1, 1 } do
		part(decor, "PlazaBorder", v(Config.World.plazaSize, 0.6, 1.5), CFrame.new(0, 0.3, side * (half - 1)), rgb(255, 225, 94))
		part(decor, "PlazaBorder", v(1.5, 0.6, Config.World.plazaSize), CFrame.new(side * (half - 1), 0.3, 0), rgb(255, 225, 94))
	end
	for index = 1, 12 do
		local angle = math.rad(index * 30 + 15)
		local center = v(math.cos(angle) * 85, 0, math.sin(angle) * 85)
		local color = Config.World.baseColors[(index - 1) % #Config.World.baseColors + 1]
		local tree = group(decor, string.format("CandyTree%02d", index))
		part(tree, "Planter", v(4, 0.65, 4), CFrame.new(center + v(0, 0.325, 0)), CREAM)
		part(tree, "Trunk", v(0.8, 4, 0.8), CFrame.new(center + v(0, 2.65, 0)), rgb(169, 105, 78))
		local crown = part(tree, "Crown", v(4.5, 4.5, 4.5), CFrame.new(center + v(0, 5.5, 0)), color)
		crown.Shape = Enum.PartType.Ball
		local shine = part(tree, "CrownShine", v(1.1, 1.1, 1.1), CFrame.new(center + v(-1, 6.6, -1.3)), WHITE)
		shine.Shape = Enum.PartType.Ball
	end
	local titleFrame = CFrame.new(0, 0, -87) * CFrame.Angles(0, math.pi, 0)
	for _, side in { -1, 1 } do
		part(decor, "TitlePost", v(1, 12, 1), titleFrame * CFrame.new(side * 18, 6, 0), rgb(255, 122, 178))
	end
	local title = part(decor, "TitleBoard", v(42, 6.2, 1), titleFrame * CFrame.new(0, 11, 0), INK)
	sign(title, Config.Title, rgb(255, 235, 111))
	part(decor, "TitleTopTrim", v(43, 0.4, 1.2), titleFrame * CFrame.new(0, 14.35, 0), rgb(116, 255, 207), Enum.Material.Neon)
end

function WorldBuilder.Build(): GameState.WorldRecord
	assert(Workspace:FindFirstChild("BrainrotBazaar") == nil, "Plaza already built")
	-- Build off-tree; players see the world only once its references are complete.
	local world = Instance.new("Model")
	world.Name = "BrainrotBazaar"
	part(world, "PlazaFloor", v(Config.World.plazaSize, 1, Config.World.plazaSize), CFrame.new(0, -0.5, 0), rgb(88, 213, 188))
	part(world, "CentralInlay", v(88, 0.06, 88), CFrame.new(0, 0.03, 0) * CFrame.Angles(0, math.rad(10), 0), rgb(129, 231, 205))
	local bases = group(world, "Bases")
	local basesById: { [number]: GameState.BaseRecord } = {}
	for id = 1, Config.World.baseCount do
		basesById[id] = buildBase(bases, id)
		local angle = math.rad(30 + (id - 1) * 360 / Config.World.baseCount)
		local direction = v(math.cos(angle), 0, math.sin(angle))
		local path = CFrame.lookAt(direction * 33, direction * 50)
		part(world, "BaseWalkway", v(5, 0.07, 36), path * CFrame.new(0, 0.075, 0), CREAM)
	end
	local conveyorStart, conveyorEnd = buildConveyor(world)
	buildDecoration(world)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Size = v(8, 0.5, 8)
	spawn.CFrame = CFrame.lookAt(v(9, 0.3, 23), v(0, 0.3, 0))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.Neon
	spawn.Color = rgb(255, 228, 99)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = world
	-- Hide Roblox's stock spawn decal; the custom arrival pad remains visible.
	for _, child in spawn:GetChildren() do
		if child:IsA("Decal") then
			child:Destroy()
		end
	end
	world.Parent = Workspace
	return { Model = world, Spawn = spawn, ConveyorStart = conveyorStart, ConveyorEnd = conveyorEnd, BasesById = basesById }
end

return WorldBuilder
