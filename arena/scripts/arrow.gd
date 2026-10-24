class_name Arrow
extends Area2D
## Flecha disparada pelo arco. Some ao acertar alguém, uma parede ou depois de um tempo.

const SPEED := 260.0
const LIFETIME := 1.0

var direction := Vector2.RIGHT
var damage := 15.0
var shooter: Fighter

var _life := LIFETIME


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body is Fighter:
		var target := body as Fighter
		if not target.alive:
			return
		target.take_damage(damage, shooter, direction * 90.0)
	queue_free()
