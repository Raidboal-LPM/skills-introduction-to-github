class_name Arena
extends Node2D
## Desenha o chão da arena e cria as paredes e os obstáculos com colisão.

const BOUNDS := Rect2(16, 22, 448, 236)
const OBSTACLES := [
	Rect2(130, 80, 22, 14),
	Rect2(328, 80, 22, 14),
	Rect2(130, 186, 22, 14),
	Rect2(328, 186, 22, 14),
	Rect2(228, 58, 24, 10),
	Rect2(228, 212, 24, 10),
]
const TILE := 16.0
const WALL_THICKNESS := 32.0


func _ready() -> void:
	_build_collision()


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var b := BOUNDS
	var t := WALL_THICKNESS
	var rects: Array[Rect2] = [
		Rect2(b.position.x - t, b.position.y - t, b.size.x + 2.0 * t, t),
		Rect2(b.position.x - t, b.end.y, b.size.x + 2.0 * t, t),
		Rect2(b.position.x - t, b.position.y, t, b.size.y),
		Rect2(b.end.x, b.position.y, t, b.size.y),
	]
	rects.append_array(OBSTACLES)
	for rect in rects:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = rect.get_center()
		body.add_child(collision)


## true se o ponto estiver fora da arena ou em cima de um obstáculo.
func is_blocked(point: Vector2, margin := 8.0) -> bool:
	if not BOUNDS.grow(-margin).has_point(point):
		return true
	for rect: Rect2 in OBSTACLES:
		if rect.grow(margin).has_point(point):
			return true
	return false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("1d1b26"))
	draw_rect(BOUNDS.grow(3.0), Color("4a3d33"))
	var cols := ceili(BOUNDS.size.x / TILE)
	var rows := ceili(BOUNDS.size.y / TILE)
	for x in cols:
		for y in rows:
			var tile := Rect2(BOUNDS.position + Vector2(x, y) * TILE, Vector2(TILE, TILE)).intersection(BOUNDS)
			draw_rect(tile, Color("3d4c40") if (x + y) % 2 == 0 else Color("39473b"))
	for rect: Rect2 in OBSTACLES:
		draw_rect(rect.grow(1.0), Color("2a221c"))
		draw_rect(rect, Color("6b5a45"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("8a7558"))
