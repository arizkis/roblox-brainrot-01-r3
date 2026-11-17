--!strict
-- Foundation boot only. Player assignment and gameplay are added in later turns.
local State = require(script.GameState)
local WorldBuilder = require(script.WorldBuilder)

local world = WorldBuilder.Build()
State.World = world
State.BasesById = world.BasesById
