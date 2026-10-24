class_name Hud
extends CanvasLayer
## Textos na tela: vida e arma do jogador, estado da zona, vivos e mensagens.

@onready var _status: Label = $Status
@onready var _zone: Label = $Zone
@onready var _alive: Label = $Alive
@onready var _message: Label = $Message

var _message_tween: Tween


func update_hud(player: Fighter, zone: Zone, alive_count: int) -> void:
	if player == null:
		_status.text = "Modo espectador"
	elif not player.alive:
		_status.text = "Eliminado"
	else:
		var weapon_text: String = Weapons.DATA[player.weapon].name
		if player.ammo > 0:
			weapon_text += " (%d)" % player.ammo
		_status.text = "Vida %d   %s" % [ceili(player.health), weapon_text]
	_zone.text = zone.status_text()
	_alive.text = "Vivos: %d" % alive_count


## Mostra uma mensagem no centro. Com duration > 0 ela some sozinha.
func show_message(text: String, duration := 0.0) -> void:
	if _message_tween:
		_message_tween.kill()
	_message.text = text
	_message.modulate.a = 1.0
	if duration > 0.0:
		_message_tween = create_tween()
		_message_tween.tween_interval(duration)
		_message_tween.tween_property(_message, "modulate:a", 0.0, 0.5)
