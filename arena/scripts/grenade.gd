class_name Grenade
extends Node2D
## Granada arremessada: voa até o alvo, pisca e explode causando dano em área.

const FLIGHT_TIME := 0.55
const FUSE_TIME := 1.4
const BOOM_TIME := 0.35

var start := Vector2.ZERO
var target := Vector2.ZERO
var damage := 45.0
var radius := 38.0
var thrower: Fighter
var exploded := false

var _time := 0.0
var _boom := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("grenades")
	global_position = start


func _process(delta: float) -> void:
	_time += delta
	if exploded:
		_boom += delta
		if _boom >= BOOM_TIME:
			queue_free()
	else:
		var k := minf(_time / FLIGHT_TIME, 1.0)
		global_position = start.lerp(target, k)
		_sprite.position.y = -sin(k * PI) * 18.0
		_sprite.rotation += delta * 12.0 * (1.0 - k)
		if _time > FUSE_TIME - 0.5:
			_sprite.modulate = Color(1, 0.4, 0.4) if int(_time * 12.0) % 2 == 0 else Color.WHITE
		if _time >= FUSE_TIME:
			_explode()
	queue_redraw()


func _explode() -> void:
	exploded = true
	_sprite.hide()
	for node in get_tree().get_nodes_in_group("fighters"):
		var fighter := node as Fighter
		if not fighter.alive:
			continue
		var dist := fighter.global_position.distance_to(global_position)
		if dist <= radius:
			var falloff := lerpf(1.0, 0.4, dist / radius)
			fighter.take_damage(damage * falloff, thrower, global_position.direction_to(fighter.global_position) * 220.0)


func _draw() -> void:
	if exploded:
		var k := _boom / BOOM_TIME
		draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * k), Color(1.0, 0.8 - 0.5 * k, 0.25, 0.9 * (1.0 - k)))
		return
	if _time >= FLIGHT_TIME:
		# Aviso no chão de onde vai explodir.
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1, 0.3, 0.3, 0.5), 1.0)
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 3.5, Color(0, 0, 0, 0.3))
