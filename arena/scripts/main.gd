extends Node2D
## Controla a partida: cria os lutadores, espalha itens e decide o vencedor.
##
## Argumentos opcionais (depois de "--" na linha de comando):
##   --espectador  os 4 lutadores são bots
##   --teste       encerra o jogo ao fim da partida e imprime o vencedor

const FIGHTER_SCENE := preload("res://scenes/fighter.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")

const FIGHTERS := [
	{"name": "Amarelo", "texture": preload("res://assets/sprites/lutador_amarelo.png"), "color": Color("efe39b"), "spawn": Vector2(90, 65)},
	{"name": "Azul", "texture": preload("res://assets/sprites/lutador_azul.png"), "color": Color("4a85d6"), "spawn": Vector2(390, 65)},
	{"name": "Verde", "texture": preload("res://assets/sprites/lutador_verde.png"), "color": Color("8cb05e"), "spawn": Vector2(90, 215)},
	{"name": "Vermelho", "texture": preload("res://assets/sprites/lutador_vermelho.png"), "color": Color("c0504f"), "spawn": Vector2(390, 215)},
]
const START_ITEMS := [
	Weapons.Kind.SWORD, Weapons.Kind.SWORD,
	Weapons.Kind.BOW, Weapons.Kind.BOW,
	Weapons.Kind.GRENADE, Weapons.Kind.GRENADE,
	Weapons.Kind.HEAL, Weapons.Kind.HEAL,
]
const MAX_ITEMS := 10
const SPAWN_INTERVAL := 6.0
const TEST_TIMEOUT := 240.0

var _player: Fighter
var _alive := 0
var _game_over := false
var _spawn_timer := SPAWN_INTERVAL
var _elapsed := 0.0
var _test_mode := false

@onready var _arena: Arena = $Arena
@onready var _zone: Zone = $Zone
@onready var _items: Node2D = $Items
@onready var _fighters: Node2D = $Fighters
@onready var _hud: Hud = $HUD


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var spectator := "--espectador" in args
	_test_mode = "--teste" in args
	for i in FIGHTERS.size():
		_spawn_fighter(FIGHTERS[i], i == 0 and not spectator)
	for kind: Weapons.Kind in START_ITEMS:
		_spawn_item(kind)
	_hud.show_message("Último sobrevivente vence!", 2.5)


func _process(delta: float) -> void:
	_elapsed += delta
	if not _game_over:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = SPAWN_INTERVAL
			if get_tree().get_nodes_in_group("pickups").size() < MAX_ITEMS:
				_spawn_item(Weapons.random_kind())
	_hud.update_hud(_player, _zone, _alive)
	if _test_mode and _elapsed > TEST_TIMEOUT:
		print("TESTE: tempo esgotado sem vencedor")
		get_tree().quit(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()


func _spawn_fighter(info: Dictionary, player: bool) -> void:
	var fighter := FIGHTER_SCENE.instantiate() as Fighter
	fighter.display_name = info.name
	fighter.body_texture = info.texture
	fighter.bar_color = info.color
	fighter.is_player = player
	fighter.position = info.spawn
	fighter.died.connect(_on_fighter_died)
	_fighters.add_child(fighter)
	_alive += 1
	if player:
		_player = fighter


## Coloca um item num ponto livre dentro da zona segura.
func _spawn_item(kind: Weapons.Kind) -> void:
	var max_dist := minf(_zone.radius, _zone.safe_radius()) * 0.85
	for attempt in 30:
		var point := _zone.center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * max_dist
		if _arena.is_blocked(point, 10.0):
			continue
		var pickup := PICKUP_SCENE.instantiate() as Pickup
		pickup.kind = kind
		pickup.position = point
		_items.add_child(pickup)
		return


func _on_fighter_died(fighter: Fighter) -> void:
	_alive -= 1
	if fighter == _player and _alive > 1:
		_hud.show_message("Você foi eliminado!\nR para reiniciar")
	if _alive > 1 or _game_over:
		return
	_game_over = true
	var winner: Fighter = null
	for node in get_tree().get_nodes_in_group("fighters"):
		if (node as Fighter).alive:
			winner = node
	var text := "Empate!"
	if winner == _player and winner != null:
		text = "Você venceu!"
	elif winner:
		text = "%s venceu!" % winner.display_name
	_hud.show_message(text + "\nR para jogar de novo")
	if _test_mode:
		print("TESTE: %s (%.1f s)" % [text, _elapsed])
		get_tree().quit()
