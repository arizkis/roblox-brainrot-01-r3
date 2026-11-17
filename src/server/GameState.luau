--!strict
-- The ONLY runtime state home. No timers, economy, claiming or networking yet.
-- Future systems require this module instead of keeping parallel ownership maps.
export type PlayerRecord = {
	Cash: number,
	IncomePerSecond: number,
	Rebirths: number,
	BaseId: number?,
	CarriedCharacterId: string?,
}

export type CharacterRecord = {
	Id: string,
	CharacterId: string,
	MutationId: string?,
	Model: Model,
	OwnerUserId: number?,
	Location: string,
}

export type BaseRecord = {
	Id: number,
	Plot: Model,
	Zone: BasePart,
	Pads: { BasePart },
	OwnerLabel: TextLabel,
	LockButton: BasePart,
	OwnerUserId: number?,
}

export type WorldRecord = {
	Model: Model,
	Spawn: SpawnLocation,
	ConveyorStart: BasePart,
	ConveyorEnd: BasePart,
	BasesById: { [number]: BaseRecord },
}

local State: {
	PlayersByUserId: { [number]: PlayerRecord },
	CharactersById: { [string]: CharacterRecord },
	BasesById: { [number]: BaseRecord },
	World: WorldRecord?,
} = {
	PlayersByUserId = {},
	CharactersById = {},
	BasesById = {},
	World = nil,
}

return State
