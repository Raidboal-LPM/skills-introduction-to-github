class_name Fighter
extends CharacterBody2D
## Um lutador da arena. É controlado pelo jogador (teclado + mouse) ou por um Bot.

signal died(fighter: Fighter)

const PICKUP_REACH := 16.0

@export var display_name := "Lutador"
@export var body_texture: Texture2D
@export var bar_color := Color.WHITE
@export var speed := 70.0
@export var max_health := 100.0

var is_player := false
var bot: Bot
var health: float
var weapon := Weapons.Kind.NONE
var ammo := -1
var aim_dir := Vector2.RIGHT
var move_dir := Vector2.ZERO
var alive := true

# Carregadas em tempo de execução (com preload haveria referência circular entre as cenas).
var _arrow_scene: PackedScene = load("res://scenes/arrow.tscn")
var _grenade_scene: PackedScene = load("res://scenes/grenade.tscn")
var _pickup_scene: PackedScene = load("res://scenes/pickup.tscn")
var _cooldown := 0.0
var _knockback := Vector2.ZERO
var _swing := 0.0

@onready var _body: Sprite2D = $Body
@onready var _hand: Node2D = $Hand
@onready var _weapon_sprite: Sprite2D = $Hand/WeaponSprite
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	health = max_health
	add_to_group("fighters")
	if body_texture:
		_body.texture = body_texture
	set_weapon(Weapons.Kind.NONE)
	if not is_player:
		bot = Bot.new(self)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_player:
		_player_control()
	elif bot:
		bot.think(delta)
	velocity = move_dir.limit_length(1.0) * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()
	_update_visuals()


func _player_control() -> void:
	move_dir = Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	var mouse := get_global_mouse_position()
	if mouse.distance_to(global_position) > 1.0:
		aim_dir = global_position.direction_to(mouse)
	if Input.is_action_pressed("atacar"):
		attack(mouse)
	if Input.is_action_just_pressed("pegar"):
		pick_up_nearest()


func can_attack() -> bool:
	return alive and _cooldown <= 0.0


func attack(target_pos: Vector2) -> void:
	if not can_attack():
		return
	var data: Dictionary = Weapons.DATA[weapon]
	_cooldown = data.cooldown
	match weapon:
		Weapons.Kind.BOW:
			_shoot_arrow(data)
		Weapons.Kind.GRENADE:
			_throw_grenade(target_pos, data)
		_:
			_melee(data)
	if ammo > 0:
		ammo -= 1
		if ammo == 0:
			set_weapon(Weapons.Kind.NONE)


func _melee(data: Dictionary) -> void:
	var tween := create_tween()
	if weapon == Weapons.Kind.SWORD:
		_swing = -1.2
		tween.tween_property(self, "_swing", 1.2, 0.12)
		tween.tween_property(self, "_swing", 0.0, 0.1)
	else:
		tween.tween_property(_body, "position", aim_dir * 3.0, 0.06)
		tween.tween_property(_body, "position", Vector2.ZERO, 0.1)
	for node in get_tree().get_nodes_in_group("fighters"):
		var other := node as Fighter
		if other == self or not other.alive:
			continue
		var to := other.global_position - global_position
		if to.length() <= data.range + 7.0 and absf(aim_dir.angle_to(to)) <= deg_to_rad(75.0):
			other.take_damage(data.damage, self, to.normalized() * 160.0)


func _shoot_arrow(data: Dictionary) -> void:
	var arrow := _arrow_scene.instantiate() as Arrow
	arrow.position = global_position + aim_dir * 8.0
	arrow.direction = aim_dir
	arrow.damage = data.damage
	arrow.shooter = self
	_root("fx_root").add_child(arrow)


func _throw_grenade(target_pos: Vector2, data: Dictionary) -> void:
	var landing := global_position + (target_pos - global_position).limit_length(data.range)
	var bounds := Arena.BOUNDS.grow(-4.0)
	var grenade := _grenade_scene.instantiate() as Grenade
	grenade.start = global_position
	grenade.target = landing.clamp(bounds.position, bounds.end)
	grenade.damage = data.damage
	grenade.thrower = self
	_root("fx_root").add_child(grenade)


func take_damage(amount: float, source: Fighter = null, knockback := Vector2.ZERO) -> void:
	if not alive:
		return
	health -= amount
	if bot:
		bot.on_hit(source)
	_knockback += knockback
	_flash(Color(1.0, 0.35, 0.35))
	queue_redraw()
	if health <= 0.0:
		_die()


func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	_flash(Color(0.5, 1.0, 0.5))
	queue_redraw()


## Chamado quando o lutador encosta num item: pega sozinho só se estiver de mãos vazias,
## se for munição da arma atual ou se for cura.
func on_pickup_touched(pickup: Pickup) -> void:
	if not alive:
		return
	if pickup.kind == Weapons.Kind.HEAL:
		if health < max_health:
			collect(pickup)
	elif weapon == Weapons.Kind.NONE or (pickup.kind == weapon and ammo > 0):
		collect(pickup)


## Pega o item: cura, soma munição ou troca de arma (a arma antiga cai no chão).
func collect(pickup: Pickup) -> void:
	if pickup.is_queued_for_deletion() or not alive:
		return
	if pickup.kind == Weapons.Kind.HEAL:
		heal(Weapons.HEAL_AMOUNT)
	elif pickup.kind == weapon:
		if ammo <= 0:
			return
		ammo += pickup.ammo if pickup.ammo > 0 else int(Weapons.DATA[weapon].ammo)
	else:
		if weapon != Weapons.Kind.NONE:
			_drop_weapon()
		set_weapon(pickup.kind, pickup.ammo)
	pickup.queue_free()


func pick_up_nearest() -> void:
	var best: Pickup = null
	var best_dist := PICKUP_REACH
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup := node as Pickup
		var dist := pickup.global_position.distance_to(global_position)
		if dist < best_dist and not pickup.is_queued_for_deletion():
			best = pickup
			best_dist = dist
	if best:
		collect(best)


func set_weapon(kind: Weapons.Kind, new_ammo := -1) -> void:
	weapon = kind
	ammo = new_ammo if new_ammo > 0 else int(Weapons.DATA[kind].ammo)
	_weapon_sprite.texture = Weapons.TEXTURES.get(kind)
	_weapon_sprite.visible = kind != Weapons.Kind.NONE
	# A espada é desenhada na vertical; giramos para apontar na direção da mira.
	_weapon_sprite.rotation = PI / 2.0 if kind == Weapons.Kind.SWORD else 0.0
	_weapon_sprite.offset = Vector2(0, -4) if kind == Weapons.Kind.SWORD else Vector2.ZERO


func _drop_weapon() -> void:
	var pickup := _pickup_scene.instantiate() as Pickup
	pickup.kind = weapon
	pickup.ammo = ammo
	pickup.position = global_position + Vector2.from_angle(randf() * TAU) * 10.0
	_root("items_root").call_deferred("add_child", pickup)


func _die() -> void:
	alive = false
	health = 0.0
	if weapon != Weapons.Kind.NONE:
		_drop_weapon()
	set_weapon(Weapons.Kind.NONE)
	_shape.set_deferred("disabled", true)
	_body.rotation = PI / 2.0
	_body.modulate = Color(0.55, 0.55, 0.55, 0.8)
	queue_redraw()
	died.emit(self)


func _flash(color: Color) -> void:
	if not alive:
		return
	_body.modulate = color
	create_tween().tween_property(_body, "modulate", Color.WHITE, 0.15)


func _update_visuals() -> void:
	var flip := aim_dir.x < 0.0
	_body.flip_h = flip
	_hand.rotation = aim_dir.angle() + (-_swing if flip else _swing)
	_weapon_sprite.flip_v = flip and weapon != Weapons.Kind.SWORD


func _root(group: String) -> Node:
	var node := get_tree().get_first_node_in_group(group)
	return node if node else get_parent()


func _draw() -> void:
	# Sombra no chão.
	draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	if not alive:
		return
	# Barra de vida.
	var width := 14.0
	var top := Vector2(-width / 2.0, -15.0)
	draw_rect(Rect2(top, Vector2(width, 2)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(top, Vector2(width * health / max_health, 2)), bar_color)
	# Setinha marcando o jogador.
	if is_player:
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -20), Vector2(2, -20), Vector2(0, -17)]), Color.WHITE)
