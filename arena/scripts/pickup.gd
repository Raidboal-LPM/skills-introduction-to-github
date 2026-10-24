class_name Pickup
extends Area2D
## Item no chão (arma ou cura). Flutua um pouco para chamar atenção.

@export var kind := Weapons.Kind.SWORD

## Usos restantes; -1 usa o padrão da arma (veja weapons.gd).
var ammo := -1

var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("pickups")
	_time = randf() * TAU
	_sprite.texture = Weapons.TEXTURES[kind]
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * 3.0) * 1.5 - 2.0


func _draw() -> void:
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.3))


func _on_body_entered(body: Node2D) -> void:
	if body is Fighter:
		(body as Fighter).on_pickup_touched(self)
