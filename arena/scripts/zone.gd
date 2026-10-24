class_name Zone
extends Node2D
## Zona segura circular que encolhe em fases. Quem fica fora toma dano.

## wait: segundos parada antes de fechar | shrink: segundos fechando
## radius: raio ao fim da fase | dps: dano por segundo fora da zona durante a fase
const PHASES := [
	{"wait": 10.0, "shrink": 10.0, "radius": 170.0, "dps": 3.0},
	{"wait": 10.0, "shrink": 10.0, "radius": 110.0, "dps": 5.0},
	{"wait": 8.0, "shrink": 10.0, "radius": 65.0, "dps": 8.0},
	{"wait": 6.0, "shrink": 8.0, "radius": 30.0, "dps": 12.0},
	{"wait": 5.0, "shrink": 8.0, "radius": 6.0, "dps": 20.0},
]
const TICK := 0.5

@export var center := Vector2(240, 140)
@export var start_radius := 262.0

var radius: float
var phase := 0
var shrinking := false

var _timer := 0.0
var _from_radius := 0.0
var _tick_timer := TICK
var _dps := 2.0


func _ready() -> void:
	add_to_group("zone")
	radius = start_radius
	_timer = PHASES[0].wait


func _process(delta: float) -> void:
	_update_phase(delta)
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer += TICK
		_damage_outside()
	queue_redraw()


func _update_phase(delta: float) -> void:
	if phase >= PHASES.size():
		return
	var current: Dictionary = PHASES[phase]
	_timer -= delta
	if not shrinking:
		if _timer <= 0.0:
			shrinking = true
			_from_radius = radius
			_timer = current.shrink
			_dps = current.dps
		return
	radius = lerpf(current.radius, _from_radius, maxf(_timer, 0.0) / current.shrink)
	if _timer <= 0.0:
		shrinking = false
		phase += 1
		if phase < PHASES.size():
			_timer = PHASES[phase].wait


func is_inside(pos: Vector2) -> bool:
	return pos.distance_to(center) <= radius


## Raio onde é seguro ficar: o tamanho final da fase atual.
func safe_radius() -> float:
	return PHASES[phase].radius if phase < PHASES.size() else radius


func status_text() -> String:
	if phase >= PHASES.size():
		return "Zona final!"
	if shrinking:
		return "A zona está fechando!"
	return "Zona fecha em %d s" % ceili(_timer)


func _damage_outside() -> void:
	for node in get_tree().get_nodes_in_group("fighters"):
		var fighter := node as Fighter
		if fighter.alive and not is_inside(fighter.global_position):
			fighter.take_damage(_dps * TICK)


func _draw() -> void:
	var outer := 700.0
	draw_arc(center, radius + outer / 2.0, 0.0, TAU, 128, Color(0.85, 0.15, 0.3, 0.28), outer)
	draw_arc(center, radius, 0.0, TAU, 128, Color(1.0, 0.85, 0.9, 0.9), 1.0)
	if not shrinking and phase < PHASES.size():
		draw_arc(center, safe_radius(), 0.0, TAU, 96, Color(1, 1, 1, 0.3), 1.0)
