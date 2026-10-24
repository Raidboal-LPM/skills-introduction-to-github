class_name Weapons
extends RefCounted
## Dados das armas e itens. Ajuste os números aqui para balancear o jogo.

enum Kind { NONE, SWORD, BOW, GRENADE, HEAL }

const HEAL_AMOUNT := 35.0

## damage: dano por acerto | range: alcance em pixels | cooldown: segundos entre ataques
## ammo: quantos usos vêm com a arma (-1 = infinito)
const DATA := {
	Kind.NONE: {"name": "Punhos", "damage": 5.0, "range": 13.0, "cooldown": 0.45, "ammo": -1},
	Kind.SWORD: {"name": "Espada", "damage": 16.0, "range": 22.0, "cooldown": 0.55, "ammo": -1},
	Kind.BOW: {"name": "Arco", "damage": 12.0, "range": 170.0, "cooldown": 0.7, "ammo": 10},
	Kind.GRENADE: {"name": "Granada", "damage": 40.0, "range": 130.0, "cooldown": 0.9, "ammo": 3},
	Kind.HEAL: {"name": "Cura", "damage": 0.0, "range": 0.0, "cooldown": 0.0, "ammo": -1},
}

const TEXTURES := {
	Kind.SWORD: preload("res://assets/sprites/espada.png"),
	Kind.BOW: preload("res://assets/sprites/arco.png"),
	Kind.GRENADE: preload("res://assets/sprites/granada.png"),
	Kind.HEAL: preload("res://assets/sprites/cura.png"),
}

## Peso de cada item ao sortear o que aparece na arena.
const SPAWN_WEIGHTS := {
	Kind.SWORD: 3,
	Kind.BOW: 3,
	Kind.GRENADE: 2,
	Kind.HEAL: 3,
}


static func random_kind() -> Kind:
	var total := 0
	for weight: int in SPAWN_WEIGHTS.values():
		total += weight
	var roll := randi() % total
	for kind: Kind in SPAWN_WEIGHTS:
		roll -= SPAWN_WEIGHTS[kind]
		if roll < 0:
			return kind
	return Kind.HEAL
