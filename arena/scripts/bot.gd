class_name Bot
extends RefCounted
## IA simples dos lutadores controlados pelo computador.
## Prioridades: fugir de granada > voltar para a zona > pegar cura/arma > lutar > explorar.

const LOW_HEALTH := 45.0
const ZONE_MARGIN := 14.0
const HEAL_SEARCH_RADIUS := 220.0
## Distância em que o bot nota um inimigo e parte para a briga.
const AGGRO_RADIUS := 80.0
## Segundos iniciais em que o bot só procura itens (a menos que seja atacado).
const LOOT_TIME := 8.0

var fighter: Fighter

var _target: Fighter
var _retarget_timer := 0.0
var _strafe := 1.0
var _strafe_timer := 0.0
var _hesitate := 0.0
var _stuck_check := 0.4
var _last_pos := Vector2.ZERO
var _unstuck_dir := Vector2.ZERO
var _unstuck_timer := 0.0
var _wander_point := Vector2.ZERO
var _wander_timer := 0.0
var _age := 0.0


func _init(owner_fighter: Fighter) -> void:
	fighter = owner_fighter
	_strafe = [-1.0, 1.0].pick_random()


func think(delta: float) -> void:
	var tree := fighter.get_tree()
	var pos := fighter.global_position
	var zone := tree.get_first_node_in_group("zone") as Zone
	_update_timers(delta, pos)
	_age += delta

	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not _target.alive:
		var nearest := _nearest_enemy(tree, pos)
		if nearest and _age > LOOT_TIME and pos.distance_to(nearest.global_position) <= AGGRO_RADIUS:
			_target = nearest
		elif _target and not _target.alive:
			_target = null
		_retarget_timer = 1.0

	var move := _grenade_dodge(tree, pos)
	if move == Vector2.ZERO:
		if zone and pos.distance_to(zone.center) > maxf(zone.safe_radius() - ZONE_MARGIN, 4.0):
			move = pos.direction_to(zone.center)
		else:
			var goal := _wanted_pickup(tree, pos, zone)
			if goal:
				if pos.distance_to(goal.global_position) < 10.0:
					fighter.collect(goal)
				move = pos.direction_to(goal.global_position)
			elif _target:
				move = _combat_move(pos)
			else:
				move = _wander(pos, zone, delta)
	if _unstuck_timer > 0.0:
		move = _unstuck_dir
	fighter.move_dir = move

	if _target:
		fighter.aim_dir = pos.direction_to(_target.global_position)
		_try_attack(pos)


## Chamado pelo lutador quando leva dano: revida em quem atacou.
func on_hit(source: Fighter) -> void:
	if source and source != fighter and source.alive:
		_target = source
		_retarget_timer = 2.0


func _wander(pos: Vector2, zone: Zone, delta: float) -> Vector2:
	_wander_timer -= delta
	if _wander_timer <= 0.0 or pos.distance_to(_wander_point) < 8.0:
		var center := zone.center if zone else Arena.BOUNDS.get_center()
		var max_dist := zone.safe_radius() * 0.8 if zone else 100.0
		_wander_point = center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * max_dist
		var bounds := Arena.BOUNDS.grow(-12.0)
		_wander_point = _wander_point.clamp(bounds.position, bounds.end)
		_wander_timer = randf_range(2.0, 4.0)
	return pos.direction_to(_wander_point) * 0.8


func _update_timers(delta: float, pos: Vector2) -> void:
	_hesitate -= delta
	_unstuck_timer -= delta
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe = -_strafe
		_strafe_timer = randf_range(1.5, 3.0)
	# Se tentou andar e quase não saiu do lugar, desvia para o lado por um instante.
	_stuck_check -= delta
	if _stuck_check <= 0.0:
		if fighter.move_dir != Vector2.ZERO and pos.distance_to(_last_pos) < 2.0:
			_unstuck_dir = fighter.move_dir.orthogonal() * _strafe
			_unstuck_timer = 0.5
		_last_pos = pos
		_stuck_check = 0.4


func _nearest_enemy(tree: SceneTree, pos: Vector2) -> Fighter:
	var best: Fighter = null
	var best_dist := INF
	for node in tree.get_nodes_in_group("fighters"):
		var other := node as Fighter
		if other == fighter or not other.alive:
			continue
		var dist := pos.distance_to(other.global_position)
		if dist < best_dist:
			best = other
			best_dist = dist
	return best


func _grenade_dodge(tree: SceneTree, pos: Vector2) -> Vector2:
	for node in tree.get_nodes_in_group("grenades"):
		var grenade := node as Grenade
		if not grenade.exploded and pos.distance_to(grenade.target) < grenade.radius + 8.0:
			var away := grenade.target.direction_to(pos)
			return away if away != Vector2.ZERO else Vector2.RIGHT.rotated(randf() * TAU)
	return Vector2.ZERO


func _wanted_pickup(tree: SceneTree, pos: Vector2, zone: Zone) -> Pickup:
	var goal: Pickup = null
	if fighter.health < LOW_HEALTH:
		goal = _nearest_pickup(tree, pos, zone, true, HEAL_SEARCH_RADIUS)
	if goal == null and fighter.weapon == Weapons.Kind.NONE:
		goal = _nearest_pickup(tree, pos, zone, false, INF)
	return goal


func _nearest_pickup(tree: SceneTree, pos: Vector2, zone: Zone, heal: bool, max_dist: float) -> Pickup:
	var best: Pickup = null
	var best_dist := max_dist
	for node in tree.get_nodes_in_group("pickups"):
		var pickup := node as Pickup
		if pickup.is_queued_for_deletion() or (pickup.kind == Weapons.Kind.HEAL) != heal:
			continue
		if zone and pickup.global_position.distance_to(zone.center) > zone.safe_radius():
			continue
		var dist := pos.distance_to(pickup.global_position)
		if dist < best_dist:
			best = pickup
			best_dist = dist
	return best


func _combat_move(pos: Vector2) -> Vector2:
	var to := _target.global_position - pos
	var dist := to.length()
	var dir := to / maxf(dist, 0.01)
	var side := dir.orthogonal() * _strafe
	var preferred := _preferred_distance()
	if dist > preferred.y:
		return (dir + side * 0.3).normalized()
	if dist < preferred.x:
		return (-dir + side * 0.5).normalized()
	return side


## Distância (mínima, máxima) que o bot tenta manter do alvo com a arma atual.
func _preferred_distance() -> Vector2:
	match fighter.weapon:
		Weapons.Kind.BOW:
			return Vector2(90, 150)
		Weapons.Kind.GRENADE:
			return Vector2(60, 110)
		_:
			return Vector2(0, 14)


func _try_attack(pos: Vector2) -> void:
	if _hesitate > 0.0 or not _target.alive or not fighter.can_attack():
		return
	var target_pos := _target.global_position
	var dist := pos.distance_to(target_pos)
	var data: Dictionary = Weapons.DATA[fighter.weapon]
	match fighter.weapon:
		Weapons.Kind.BOW:
			if dist > data.range:
				return
			target_pos += _target.velocity * (dist / Arrow.SPEED)
		Weapons.Kind.GRENADE:
			if dist < 40.0 or dist > data.range:
				return
			target_pos += _target.velocity * 0.6
		_:
			if dist > data.range + 7.0:
				return
	fighter.aim_dir = pos.direction_to(target_pos).rotated(randf_range(-0.15, 0.15))
	fighter.attack(target_pos)
	_hesitate = randf_range(0.15, 0.6)
