--!strict
-- Immutable definitions only. Runtime ownership lives in server/GameState.
local rgb = Color3.fromRGB
local v = Vector3.new

export type PartRecipe = {
	name: string,
	shape: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	rotation: Vector3,
	neon: boolean,
}

export type CharacterDefinition = {
	id: string, name: string, tier: string, recipe: string, parts: { PartRecipe },
	face: { position: Vector3, spacing: number, eyeSize: number?, eyeColor: Color3? }?,
}
export type TierDefinition = { price: number, income: number, color: Color3, height: number }
export type MutationDefinition = { multiplier: number, color: Color3, treatment: string }

local function p(name: string, shape: string, size: Vector3, position: Vector3, color: Color3, rotation: Vector3?, neon: boolean?): PartRecipe
	return { name = name, shape = shape, size = size, position = position, color = color,
		rotation = rotation or Vector3.zero, neon = neon == true }
end

local Config = {}
Config.Title = "BRAINROT BAZAAR"
Config.TierOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine" }
Config.Tiers = {
	Common = { price = 25, income = 1, color = rgb(116, 151, 175), height = 3.1 },
	Uncommon = { price = 100, income = 4, color = rgb(61, 208, 102), height = 3.3 },
	Rare = { price = 450, income = 14, color = rgb(48, 143, 255), height = 3.6 },
	Epic = { price = 1800, income = 45, color = rgb(174, 74, 255), height = 3.9 },
	Legendary = { price = 7500, income = 150, color = rgb(255, 178, 27), height = 4.2 },
	Mythic = { price = 30000, income = 550, color = rgb(255, 66, 123), height = 4.6 },
	Divine = { price = 150000, income = 2400, color = rgb(67, 239, 230), height = 5 },
} :: { [string]: TierDefinition }

Config.MaxMutationMultiplier = 15
Config.MutationOrder = { "Golden", "Diamond", "Glitch", "Void" }
Config.Mutations = {
	Golden = { multiplier = 3, color = rgb(255, 202, 48), treatment = "gold trim" },
	Diamond = { multiplier = 6, color = rgb(108, 246, 255), treatment = "cyan glint" },
	Glitch = { multiplier = 10, color = rgb(255, 68, 228), treatment = "RGB shifted parts" },
	Void = { multiplier = 15, color = rgb(137, 63, 223), treatment = "dark void aura" },
} :: { [string]: MutationDefinition }
-- Absolute spawn probabilities, NOT relative weights or independent rolls.
-- Future spawner: one roll, cumulative in MutationOrder, with the remainder normal.
-- A character has at most ONE mutation, so multipliers never stack past x15.
Config.MutationOddsByTier = {
	Common = { Golden = 0.060, Diamond = 0.015, Glitch = 0.004, Void = 0.001 }, -- 8%
	Uncommon = { Golden = 0.060, Diamond = 0.015, Glitch = 0.004, Void = 0.001 },
	Rare = { Golden = 0.075, Diamond = 0.025, Glitch = 0.008, Void = 0.002 }, -- 11%
	Epic = { Golden = 0.090, Diamond = 0.035, Glitch = 0.012, Void = 0.003 }, -- 14%
	Legendary = { Golden = 0.100, Diamond = 0.040, Glitch = 0.017, Void = 0.003 }, -- 16%
	Mythic = { Golden = 0.110, Diamond = 0.045, Glitch = 0.021, Void = 0.004 }, -- 18%
	Divine = { Golden = 0.110, Diamond = 0.045, Glitch = 0.021, Void = 0.004 },
}

Config.World = {
	plazaSize = 190,
	baseCount = 6,
	baseRadius = 64,
	baseSize = v(30, 1, 24),
	startingPads = 6,
	maxPads = 10,
	padSpacing = 4.5,
	beltLength = 98,
	beltWidth = 10,
	beltYawDegrees = -35,
	baseColors = { rgb(255, 96, 145), rgb(255, 181, 48), rgb(170, 235, 58),
		rgb(45, 218, 201), rgb(91, 155, 255), rgb(189, 116, 255) },
}

-- Recipes face local -Z and use local stud coordinates. The factory grounds
-- and scales each entire recipe to its tier's height, including rotated parts.
Config.Characters = {
	{
		id = "wet_floor_sign", name = "Wet Floor Sign", tier = "Common",
		recipe = "Yellow A-frame warning sign, black exclamation, splayed orange feet.",
		parts = {
			p("FrontPanel", "Block", v(1.8, 2.5, 0.18), v(0, 1.5, -0.32), rgb(255, 223, 33), v(-14, 0, 0)),
			p("BackPanel", "Block", v(1.8, 2.5, 0.18), v(0, 1.5, 0.32), rgb(255, 185, 18), v(14, 0, 0)),
			p("Handle", "Block", v(1.3, 0.28, 0.32), v(0, 2.9, 0), rgb(255, 233, 60)),
			p("LeftFoot", "Block", v(0.7, 0.25, 1.7), v(-0.6, 0.15, 0), rgb(255, 136, 20)),
			p("RightFoot", "Block", v(0.7, 0.25, 1.7), v(0.6, 0.15, 0), rgb(255, 136, 20)),
			p("WarningBar", "Block", v(0.2, 0.7, 0.16), v(0, 1.05, -0.62), rgb(26, 31, 48)),
			p("WarningDot", "Ball", v(0.23, 0.23, 0.17), v(0, 0.55, -0.72), rgb(26, 31, 48)),
		}, face = { position = v(0, 2.1, -0.3), spacing = 0.65 },
	},
	{
		id = "expired_yogurt_cup", name = "Expired Yogurt Cup", tier = "Common",
		recipe = "Pink cylindrical cup, white foil lid, green spill and a towering bent spoon.",
		parts = {
			p("Cup", "Cylinder", v(1.9, 2.1, 2.1), v(0, 1.1, 0), rgb(255, 126, 176), v(0, 0, 90)),
			p("LabelBand", "Cylinder", v(0.65, 2.18, 2.18), v(0, 1.05, 0), rgb(255, 236, 241), v(0, 0, 90)),
			p("FoilLid", "Cylinder", v(0.15, 2.3, 2.3), v(0, 2.12, 0), rgb(224, 237, 247), v(0, 0, 90)),
			p("SpoiledBlob", "Ball", v(0.9, 0.65, 0.9), v(-0.55, 2.35, -0.3), rgb(133, 217, 62)),
			p("SpoonStem", "Block", v(0.16, 1.5, 0.16), v(0.6, 2.7, 0.2), rgb(172, 202, 219), v(0, 0, -20)),
			p("SpoonBowl", "Ball", v(0.5, 0.7, 0.18), v(0.85, 3.4, 0.2), rgb(218, 243, 255)),
		}, face = { position = v(0, 1.2, -1.1), spacing = 0.7 },
	},
	{
		id = "moldy_muffin", name = "Moldy Muffin", tier = "Common",
		recipe = "Pleated orange wrapper, oversized brown muffin dome, lumpy lime mold spots.",
		parts = {
			p("Wrapper", "Cylinder", v(1.5, 2, 2), v(0, 0.8, 0), rgb(216, 124, 64), v(0, 0, 90)),
			p("PleatLeft", "Block", v(0.14, 1.2, 0.18), v(-0.65, 0.8, -0.85), rgb(255, 179, 87)),
			p("PleatRight", "Block", v(0.14, 1.2, 0.18), v(0.65, 0.8, -0.85), rgb(255, 179, 87)),
			p("MuffinTop", "Ball", v(2.7, 2.1, 2.5), v(0, 2, 0), rgb(153, 87, 53)),
			p("MoldLeft", "Ball", v(0.9, 0.75, 0.8), v(-0.75, 2.65, -0.25), rgb(116, 195, 79)),
			p("MoldRight", "Ball", v(0.65, 0.7, 0.6), v(0.8, 2.4, -0.7), rgb(48, 150, 100)),
			p("TopCrumb", "Ball", v(0.5, 0.45, 0.5), v(0.2, 3, 0.2), rgb(210, 154, 88)),
		}, face = { position = v(0, 1.9, -1.23), spacing = 0.8 },
	},
	{
		id = "roomba_with_a_knife", name = "Roomba With A Knife", tier = "Uncommon",
		recipe = "Low charcoal robot disk, teal bumper, red sensor and an upright silver knife.",
		parts = {
			p("Bumper", "Cylinder", v(0.35, 3, 3), v(0, 0.35, 0), rgb(57, 210, 203), v(0, 0, 90)),
			p("RobotBody", "Cylinder", v(0.8, 2.8, 2.8), v(0, 0.75, 0), rgb(43, 53, 69), v(0, 0, 90)),
			p("Sensor", "Ball", v(0.55, 0.55, 0.55), v(0, 1.35, 0), rgb(255, 71, 83), nil, true),
			p("KnifeHandle", "Block", v(0.32, 0.9, 0.35), v(0.9, 1.55, 0), rgb(113, 64, 50), v(0, 0, -12)),
			p("KnifeBlade", "Wedge", v(0.7, 1.65, 0.15), v(1.13, 2.7, 0), rgb(213, 233, 244), v(0, 0, -12)),
		}, face = { position = v(0, 0.85, -1.4), spacing = 0.85 },
	},
	{
		id = "radical_garden_gnome", name = "Radical Garden Gnome", tier = "Uncommon",
		recipe = "Turquoise coat, cream beard, stepped red pointy hat, big orange boots.",
		parts = {
			p("BootLeft", "Block", v(0.7, 0.45, 1.1), v(-0.45, 0.25, -0.1), rgb(239, 117, 40)),
			p("BootRight", "Block", v(0.7, 0.45, 1.1), v(0.45, 0.25, -0.1), rgb(239, 117, 40)),
			p("Coat", "Ball", v(1.8, 1.6, 1.4), v(0, 1.15, 0), rgb(27, 188, 177)),
			p("Head", "Ball", v(1.4, 1.2, 1.25), v(0, 2.1, 0), rgb(255, 205, 162)),
			p("Beard", "Wedge", v(1.15, 1.2, 0.5), v(0, 1.7, -0.65), rgb(255, 246, 218), v(0, 180, 180)),
			p("HatBrim", "Block", v(1.7, 0.35, 1.5), v(0, 2.65, 0), rgb(240, 52, 76)),
			p("HatPoint", "Wedge", v(1.2, 1.1, 1.1), v(0, 3.2, 0), rgb(255, 68, 92)),
			p("Nose", "Ball", v(0.45, 0.4, 0.5), v(0, 2.1, -0.75), rgb(255, 166, 128)),
		}, face = { position = v(0, 2.3, -0.6), spacing = 0.65 },
	},
	{
		id = "rusty_clippy", name = "Rusty Clippy", tier = "Uncommon",
		recipe = "Tall bent paperclip outline of rusty orange rods, two oversized white eyes.",
		parts = {
			p("OuterLeft", "Block", v(0.25, 2.75, 0.25), v(-0.65, 1.7, 0), rgb(180, 104, 61)),
			p("OuterTop", "Block", v(1.5, 0.25, 0.25), v(0, 3.05, 0), rgb(211, 139, 77)),
			p("OuterRight", "Block", v(0.25, 2.2, 0.25), v(0.65, 2.05, 0), rgb(166, 85, 48)),
			p("InnerBottom", "Block", v(0.9, 0.25, 0.25), v(0.3, 1, 0), rgb(211, 139, 77)),
			p("InnerRod", "Block", v(0.25, 1.45, 0.25), v(-0.05, 1.65, 0), rgb(180, 104, 61)),
			p("BentFoot", "Block", v(1.25, 0.25, 0.25), v(-0.15, 0.3, 0), rgb(166, 85, 48), v(0, 0, 10)),
			p("EyeLeft", "Ball", v(0.7, 0.8, 0.45), v(-0.45, 2.5, -0.3), rgb(255, 246, 226)),
			p("EyeRight", "Ball", v(0.7, 0.8, 0.45), v(0.4, 2.5, -0.3), rgb(255, 246, 226)),
		}, face = { position = v(-0.02, 2.5, -0.55), spacing = 0.85, eyeSize = 0.22 },
	},
	{
		id = "inflatable_tube_man", name = "Inflatable Tube Man", tier = "Rare",
		recipe = "Tall zigzag coral tube, yellow flailing arms, purple blower and blue hair strips.",
		parts = {
			p("Blower", "Cylinder", v(0.6, 1.7, 1.7), v(0, 0.3, 0), rgb(98, 66, 185), v(0, 0, 90)),
			p("TubeLower", "Block", v(0.85, 1.6, 0.85), v(-0.15, 1.3, 0), rgb(255, 92, 99), v(0, 0, 15)),
			p("TubeUpper", "Block", v(0.85, 1.7, 0.85), v(0.1, 2.7, 0), rgb(255, 110, 80), v(0, 0, -20)),
			p("LeftArm", "Block", v(1.8, 0.35, 0.4), v(-1.1, 2.7, 0), rgb(255, 218, 48), v(0, 0, -35)),
			p("RightArm", "Block", v(1.8, 0.35, 0.4), v(1.15, 2.55, 0), rgb(255, 218, 48), v(0, 0, 55)),
			p("HairLeft", "Block", v(0.18, 0.8, 0.2), v(-0.1, 3.8, 0), rgb(53, 159, 255), v(0, 0, 20)),
			p("HairRight", "Block", v(0.18, 0.8, 0.2), v(0.3, 3.8, 0), rgb(53, 159, 255), v(0, 0, -20)),
		}, face = { position = v(0.2, 3.05, -0.46), spacing = 0.45 },
	},
	{
		id = "grandma_turbo", name = "Grandma Turbo", tier = "Rare",
		recipe = "Purple dress, silver bun, spectacles, chunky wheels and twin red turbo rockets.",
		parts = {
			p("Dress", "Wedge", v(1.8, 1.9, 1.45), v(0, 1.5, 0), rgb(158, 100, 215)),
			p("Head", "Ball", v(1.35, 1.35, 1.25), v(0, 2.9, 0), rgb(255, 209, 174)),
			p("HairCap", "Ball", v(1.45, 0.6, 1.3), v(0, 3.45, 0.12), rgb(211, 224, 237)),
			p("HairBun", "Ball", v(0.75, 0.75, 0.75), v(0, 3.55, 0.6), rgb(241, 245, 255)),
			p("WheelLeft", "Cylinder", v(0.4, 1, 1), v(-1, 0.5, 0), rgb(38, 44, 69)),
			p("WheelRight", "Cylinder", v(0.4, 1, 1), v(1, 0.5, 0), rgb(38, 44, 69)),
			p("RocketLeft", "Cylinder", v(1.9, 0.55, 0.55), v(-0.8, 1.55, 0.7), rgb(255, 88, 74), v(0, 0, 90)),
			p("RocketRight", "Cylinder", v(1.9, 0.55, 0.55), v(0.8, 1.55, 0.7), rgb(255, 88, 74), v(0, 0, 90)),
			p("Spectacles", "Block", v(1.2, 0.14, 0.15), v(0, 3.02, -0.68), rgb(111, 53, 160)),
		}, face = { position = v(0, 3, -0.73), spacing = 0.65 },
	},
	{
		id = "caffeinated_cactus", name = "Caffeinated Cactus", tier = "Rare",
		recipe = "Lime cactus in a terracotta pot, forked raised arms, white coffee cup and orange spikes.",
		parts = {
			p("Pot", "Cylinder", v(0.95, 1.8, 1.8), v(0, 0.5, 0), rgb(216, 105, 64), v(0, 0, 90)),
			p("PotRim", "Cylinder", v(0.24, 2, 2), v(0, 0.95, 0), rgb(250, 156, 83), v(0, 0, 90)),
			p("Trunk", "Block", v(0.9, 2.5, 0.8), v(0, 2.2, 0), rgb(108, 203, 66)),
			p("LeftBranch", "Block", v(1.1, 0.45, 0.55), v(-0.75, 2, 0), rgb(75, 175, 71)),
			p("LeftTip", "Block", v(0.45, 1.1, 0.55), v(-1.1, 2.4, 0), rgb(108, 203, 66)),
			p("RightBranch", "Block", v(1.2, 0.45, 0.55), v(0.85, 1.8, 0), rgb(75, 175, 71)),
			p("Coffee", "Cylinder", v(0.75, 0.65, 0.65), v(1.2, 2.35, -0.2), rgb(255, 249, 223), v(0, 0, 90)),
			p("CoffeeTop", "Cylinder", v(0.08, 0.5, 0.5), v(1.2, 2.76, -0.2), rgb(89, 54, 40), v(0, 0, 90)),
			p("SpikeLeft", "Wedge", v(0.35, 0.55, 0.3), v(-0.5, 3, 0), rgb(255, 212, 116), v(0, 0, 60)),
			p("SpikeTop", "Wedge", v(0.3, 0.55, 0.3), v(0.2, 3.65, 0), rgb(255, 212, 116)),
		}, face = { position = v(0, 2.8, -0.43), spacing = 0.5 },
	},
	{
		id = "disco_potato", name = "Disco Potato", tier = "Epic",
		recipe = "Lumpy tan dancer, hot pink glasses, silver disco crown, platform shoes and microphone.",
		parts = {
			p("Potato", "Ball", v(2.1, 2.7, 1.7), v(0, 1.75, 0), rgb(192, 135, 76)),
			p("ShoeLeft", "Block", v(0.8, 0.5, 1.3), v(-0.65, 0.3, -0.2), rgb(157, 59, 233)),
			p("ShoeRight", "Block", v(0.8, 0.5, 1.3), v(0.65, 0.3, -0.2), rgb(157, 59, 233)),
			p("DiscoCrown", "Ball", v(1.65, 1.25, 1.5), v(0, 3.25, 0), rgb(181, 224, 247)),
			p("CrownTileA", "Block", v(0.45, 0.45, 0.18), v(-0.4, 3.35, -0.7), rgb(255, 73, 206), nil, true),
			p("CrownTileB", "Block", v(0.45, 0.45, 0.18), v(0.35, 3.5, -0.65), rgb(55, 237, 255), nil, true),
			p("GlassesBar", "Block", v(1.9, 0.17, 0.16), v(0, 2.3, -0.88), rgb(255, 64, 180)),
			p("MicArm", "Block", v(1.2, 0.25, 0.3), v(1.1, 1.8, 0), rgb(192, 135, 76), v(0, 0, 25)),
			p("MicHead", "Ball", v(0.5, 0.5, 0.5), v(1.65, 2.15, -0.1), rgb(65, 57, 98)),
		}, face = { position = v(0, 2.15, -0.85), spacing = 0.8 },
	},
	{
		id = "neon_ninja_noodle", name = "Neon Ninja Noodle", tier = "Epic",
		recipe = "Zigzag cyan noodle with magenta headband, black ninja mask and a glowing lime sword.",
		parts = {
			p("LowerCoil", "Block", v(1.75, 0.45, 0.6), v(0, 0.35, 0), rgb(46, 229, 239), nil, true),
			p("CoilRise", "Block", v(0.5, 1.3, 0.6), v(-0.6, 1.1, 0), rgb(58, 189, 255), v(0, 0, -15), true),
			p("MiddleCoil", "Block", v(1.75, 0.45, 0.6), v(0, 1.65, 0), rgb(46, 229, 239), v(0, 0, 15), true),
			p("UpperCoil", "Block", v(0.6, 1.3, 0.6), v(0.6, 2.35, 0), rgb(58, 189, 255), v(0, 0, 10), true),
			p("Head", "Block", v(1.5, 1, 0.85), v(0.35, 3.1, 0), rgb(46, 229, 239)),
			p("Mask", "Block", v(1.55, 0.42, 0.1), v(0.35, 2.85, -0.47), rgb(29, 32, 69)),
			p("Headband", "Block", v(1.65, 0.18, 1), v(0.35, 3.5, 0), rgb(255, 61, 190)),
			p("BandTail", "Block", v(1.5, 0.2, 0.35), v(-0.85, 3.3, 0.3), rgb(255, 61, 190), v(0, 0, 15)),
			p("Sword", "Block", v(0.18, 2.5, 0.2), v(-1.2, 2.1, 0.2), rgb(181, 255, 72), v(0, 0, -25), true),
		}, face = { position = v(0.35, 3.15, -0.48), spacing = 0.65 },
	},
	{
		id = "celestial_sushi_roll", name = "Celestial Sushi Roll", tier = "Epic",
		recipe = "Midnight seaweed cylinder, white rice cap, salmon block, golden stars and floating fins.",
		parts = {
			p("Seaweed", "Cylinder", v(2.2, 2.6, 2.6), v(0, 1.3, 0), rgb(30, 70, 79), v(0, 0, 90)),
			p("Rice", "Cylinder", v(0.22, 2.4, 2.4), v(0, 2.5, 0), rgb(247, 248, 230), v(0, 0, 90)),
			p("Salmon", "Block", v(1, 0.3, 0.8), v(0, 2.7, 0), rgb(255, 135, 155)),
			p("StarLeft", "Block", v(0.7, 0.7, 0.25), v(-1.9, 2.5, 0), rgb(255, 224, 83), v(0, 0, 45), true),
			p("StarRight", "Block", v(0.6, 0.6, 0.25), v(1.8, 3.1, 0), rgb(255, 224, 83), v(0, 0, 45), true),
			p("TopStar", "Block", v(0.5, 0.5, 0.25), v(0.25, 3.6, 0), rgb(138, 245, 255), v(0, 0, 45), true),
			p("LeftFin", "Wedge", v(1.2, 0.5, 1.1), v(-1.5, 1.15, 0), rgb(113, 165, 255), v(0, 0, -20)),
			p("RightFin", "Wedge", v(1.2, 0.5, 1.1), v(1.5, 1.15, 0), rgb(113, 165, 255), v(0, 0, 20)),
		}, face = { position = v(0, 1.6, -1.31), spacing = 0.9 },
	},
	{
		id = "buff_goldfish", name = "Buff Goldfish", tier = "Legendary",
		recipe = "Broad orange fish body, huge spherical biceps, fan tail and golden three-point crown.",
		parts = {
			p("Body", "Ball", v(2.4, 2.7, 1.7), v(0, 1.9, 0), rgb(255, 148, 35)),
			p("Chest", "Ball", v(2.1, 1.35, 0.75), v(0, 2.05, -0.65), rgb(255, 199, 76)),
			p("BicepLeft", "Ball", v(1.2, 1.5, 1.2), v(-1.55, 2.05, 0), rgb(255, 148, 35)),
			p("BicepRight", "Ball", v(1.2, 1.5, 1.2), v(1.55, 2.05, 0), rgb(255, 148, 35)),
			p("FistLeft", "Ball", v(0.9, 0.9, 0.9), v(-1.8, 2.85, 0), rgb(255, 191, 57)),
			p("FistRight", "Ball", v(0.9, 0.9, 0.9), v(1.8, 2.85, 0), rgb(255, 191, 57)),
			p("Tail", "Wedge", v(2.5, 1.7, 0.45), v(0, 1.2, 1), rgb(255, 111, 45), v(0, 0, 180)),
			p("CrownBand", "Block", v(1.6, 0.3, 1.1), v(0, 3.3, 0), rgb(255, 218, 55)),
			p("CrownLeft", "Wedge", v(0.45, 0.65, 0.5), v(-0.55, 3.7, 0), rgb(255, 228, 97)),
			p("CrownCenter", "Wedge", v(0.45, 0.85, 0.5), v(0, 3.8, 0), rgb(255, 228, 97)),
			p("CrownRight", "Wedge", v(0.45, 0.65, 0.5), v(0.55, 3.7, 0), rgb(255, 228, 97)),
		}, face = { position = v(0, 2.8, -0.82), spacing = 0.9 },
	},
	{
		id = "temporal_tuba", name = "Temporal Tuba", tier = "Legendary",
		recipe = "Golden rectangular brass loop, flared stacked bell, white clock face and blue time sparks.",
		parts = {
			p("LoopBottom", "Block", v(2.4, 0.45, 0.7), v(0, 0.3, 0), rgb(223, 167, 43)),
			p("LoopLeft", "Cylinder", v(2.9, 0.55, 0.55), v(-0.95, 1.65, 0), rgb(255, 202, 66), v(0, 0, 90)),
			p("LoopRight", "Cylinder", v(2.2, 0.55, 0.55), v(0.95, 1.3, 0), rgb(255, 202, 66), v(0, 0, 90)),
			p("BellStem", "Cylinder", v(0.8, 0.9, 0.9), v(-0.95, 3, 0), rgb(255, 202, 66), v(0, 0, 90)),
			p("BellFlare", "Cylinder", v(0.5, 1.5, 1.5), v(-0.95, 3.5, 0), rgb(255, 217, 87), v(0, 0, 90)),
			p("BellLip", "Cylinder", v(0.2, 2, 2), v(-0.95, 3.85, 0), rgb(255, 235, 135), v(0, 0, 90)),
			p("BellInside", "Cylinder", v(0.04, 1.7, 1.7), v(-0.95, 3.97, 0), rgb(83, 57, 41), v(0, 0, 90)),
			p("Clock", "Cylinder", v(0.22, 1.7, 1.7), v(0, 1.8, -0.45), rgb(244, 251, 240), v(0, 90, 0)),
			p("ClockHour", "Block", v(0.14, 0.55, 0.1), v(0, 2, -0.62), rgb(57, 55, 91)),
			p("ClockMinute", "Block", v(0.55, 0.12, 0.1), v(0.2, 1.8, -0.63), rgb(57, 55, 91)),
			p("TimeSpark", "Block", v(0.45, 0.45, 0.25), v(1.45, 3.5, 0), rgb(97, 246, 255), v(0, 0, 45), true),
		},
	},
	{
		id = "solar_samurai_squirrel", name = "Solar Samurai Squirrel", tier = "Mythic",
		recipe = "Orange squirrel with enormous curled tail, crimson armor, gold helmet horns and solar blade.",
		parts = {
			p("FootLeft", "Block", v(0.75, 0.4, 1.1), v(-0.5, 0.25, -0.1), rgb(105, 53, 48)),
			p("FootRight", "Block", v(0.75, 0.4, 1.1), v(0.5, 0.25, -0.1), rgb(105, 53, 48)),
			p("Armor", "Block", v(1.9, 1.8, 1.3), v(0, 1.45, 0), rgb(215, 61, 64)),
			p("Head", "Ball", v(1.7, 1.4, 1.3), v(0, 2.85, -0.1), rgb(244, 157, 68)),
			p("TailBase", "Ball", v(1.8, 2.2, 1.8), v(0.6, 1.5, 1.1), rgb(216, 109, 49)),
			p("TailCurl", "Ball", v(2, 2.1, 1.6), v(0.75, 2.9, 1.3), rgb(255, 185, 75)),
			p("Helmet", "Block", v(1.9, 0.45, 1.5), v(0, 3.5, -0.1), rgb(105, 53, 72)),
			p("HornLeft", "Wedge", v(0.45, 1, 0.5), v(-0.8, 3.95, -0.15), rgb(255, 214, 67), v(0, 0, 25)),
			p("HornRight", "Wedge", v(0.45, 1, 0.5), v(0.8, 3.95, -0.15), rgb(255, 214, 67), v(0, 0, -25)),
			p("SolarBlade", "Block", v(0.2, 3.3, 0.32), v(-1.6, 2.3, 0), rgb(255, 239, 125), v(0, 0, -18), true),
			p("SwordGuard", "Block", v(0.9, 0.18, 0.5), v(-1.3, 1.2, 0), rgb(255, 151, 45), v(0, 0, -18)),
		}, face = { position = v(0, 2.9, -0.79), spacing = 0.8 },
	},
	{
		id = "velvet_void_vortex", name = "Velvet Void Vortex", tier = "Mythic",
		recipe = "Floating midnight core, purple diamond plates, crossed lavender orbit bars and watchful eyes.",
		parts = {
			p("LowerShard", "Block", v(1.1, 1.1, 0.8), v(0, 0.65, 0), rgb(73, 30, 125), v(0, 20, 45)),
			p("MiddlePlate", "Block", v(2.2, 0.35, 2.2), v(0, 1.4, 0), rgb(126, 56, 186), v(0, 30, 0)),
			p("Core", "Ball", v(2.3, 2.4, 2), v(0, 2.55, 0), rgb(31, 23, 61)),
			p("UpperPlate", "Block", v(2.7, 0.25, 2.7), v(0, 3.8, 0), rgb(126, 56, 186), v(0, 55, 0)),
			p("CrownShard", "Block", v(0.8, 0.8, 0.8), v(0, 4.5, 0), rgb(218, 141, 255), v(0, 0, 45), true),
			p("OrbitLeft", "Block", v(4.2, 0.15, 0.15), v(0, 2.5, 0.3), rgb(167, 84, 255), v(0, 25, 28), true),
			p("OrbitRight", "Block", v(4.2, 0.15, 0.15), v(0, 2.5, 0.3), rgb(106, 117, 255), v(0, -25, -28), true),
		}, face = { position = v(0, 2.7, -1), spacing = 0.85, eyeColor = rgb(231, 175, 255) },
	},
	{
		id = "the_blue_screen", name = "The Blue Screen", tier = "Divine",
		recipe = "Towering blue monitor slab, silver feet, white error glyph and cyan floating pixel fragments.",
		parts = {
			p("FootLeft", "Block", v(1, 0.35, 1.2), v(-1, 0.2, 0), rgb(175, 204, 223)),
			p("FootRight", "Block", v(1, 0.35, 1.2), v(1, 0.2, 0), rgb(175, 204, 223)),
			p("MonitorFrame", "Block", v(3.2, 3.9, 0.65), v(0, 2.4, 0), rgb(46, 65, 126)),
			p("BlueScreen", "Block", v(2.8, 3.5, 0.1), v(0, 2.4, -0.39), rgb(22, 109, 255), nil, true),
			p("ErrorLineA", "Block", v(1.85, 0.12, 0.1), v(-0.15, 1.55, -0.47), rgb(194, 246, 255), nil, true),
			p("ErrorLineB", "Block", v(1.4, 0.12, 0.1), v(-0.35, 1.25, -0.47), rgb(194, 246, 255), nil, true),
			p("ErrorMouth", "Block", v(0.65, 0.14, 0.1), v(0, 2.5, -0.47), rgb(255, 255, 255), v(0, 0, 15), true),
			p("PixelLeft", "Block", v(0.6, 0.6, 0.6), v(-2.05, 3.85, 0), rgb(71, 241, 255), v(0, 20, 20), true),
			p("PixelRight", "Block", v(0.45, 0.45, 0.45), v(2.05, 2.9, 0), rgb(145, 188, 255), v(0, 30, 15), true),
			p("PixelTop", "Block", v(0.55, 0.55, 0.55), v(0.8, 4.8, 0), rgb(71, 241, 255), v(0, 20, 45), true),
		}, face = { position = v(0, 3.05, -0.48), spacing = 1, eyeColor = rgb(255, 255, 255) },
	},
	{
		id = "ascended_shopping_cart", name = "Ascended Shopping Cart", tier = "Divine",
		recipe = "Silver open basket on four blue wheels, golden wings, pink handle and a square halo.",
		parts = {
			p("BasketFloor", "Block", v(2.6, 0.2, 1.8), v(0, 1.2, 0), rgb(198, 228, 244)),
			p("BasketTop", "Block", v(2.8, 0.18, 0.18), v(0, 2.7, -0.85), rgb(198, 228, 244)),
			p("BasketBack", "Block", v(2.8, 0.18, 0.18), v(0, 2.7, 0.85), rgb(198, 228, 244)),
			p("SideLeft", "Block", v(0.18, 1.65, 1.8), v(-1.3, 1.95, 0), rgb(198, 228, 244)),
			p("SideRight", "Block", v(0.18, 1.65, 1.8), v(1.3, 1.95, 0), rgb(198, 228, 244)),
			p("BarLeft", "Block", v(0.12, 1.5, 0.15), v(-0.65, 1.95, -0.85), rgb(198, 228, 244)),
			p("BarCenter", "Block", v(0.12, 1.5, 0.15), v(0, 1.95, -0.85), rgb(198, 228, 244)),
			p("BarRight", "Block", v(0.12, 1.5, 0.15), v(0.65, 1.95, -0.85), rgb(198, 228, 244)),
			p("Handle", "Block", v(2.9, 0.28, 0.3), v(0, 3, 1.05), rgb(255, 118, 193)),
			p("WheelFL", "Ball", v(0.65, 0.65, 0.65), v(-1, 0.45, -0.65), rgb(61, 147, 239)),
			p("WheelFR", "Ball", v(0.65, 0.65, 0.65), v(1, 0.45, -0.65), rgb(61, 147, 239)),
			p("WheelBL", "Ball", v(0.65, 0.65, 0.65), v(-1, 0.45, 0.65), rgb(61, 147, 239)),
			p("WheelBR", "Ball", v(0.65, 0.65, 0.65), v(1, 0.45, 0.65), rgb(61, 147, 239)),
			p("WingLeft", "Wedge", v(2.1, 1.5, 0.5), v(-2.05, 2.7, 0.15), rgb(255, 224, 106), v(0, 0, -25)),
			p("WingRight", "Wedge", v(2.1, 1.5, 0.5), v(2.05, 2.7, 0.15), rgb(255, 224, 106), v(0, 180, 25)),
			p("HaloFront", "Block", v(1.8, 0.16, 0.16), v(0, 4.2, -0.65), rgb(255, 240, 135), nil, true),
			p("HaloBack", "Block", v(1.8, 0.16, 0.16), v(0, 4.2, 0.65), rgb(255, 240, 135), nil, true),
			p("HaloLeft", "Block", v(0.16, 0.16, 1.3), v(-0.85, 4.2, 0), rgb(255, 240, 135), nil, true),
			p("HaloRight", "Block", v(0.16, 0.16, 1.3), v(0.85, 4.2, 0), rgb(255, 240, 135), nil, true),
		}, face = { position = v(0, 2.15, -0.97), spacing = 0.95 },
	},
} :: { CharacterDefinition }

local charactersById: { [string]: CharacterDefinition } = {}
for _, character in Config.Characters do
	assert(charactersById[character.id] == nil, "Duplicate character id: " .. character.id)
	charactersById[character.id] = character
end
Config.CharactersById = charactersById

local function freezeDeep(value: any)
	if type(value) ~= "table" or table.isfrozen(value) then
		return
	end
	for _, child in value do
		freezeDeep(child)
	end
	table.freeze(value)
end
freezeDeep(Config)
return Config
