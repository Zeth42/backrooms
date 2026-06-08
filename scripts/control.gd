extends Control

@onready var logo_backrooms = $TextureRect
@onready var boton_play = $Button

@onready var player = $"../../Player"

func _ready():
	# Mantenemos el mouse visible al inicio
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	boton_play.pressed.connect(_on_play_pressed)

func _on_play_pressed():
	boton_play.disabled = true
	
	# Capturamos el mouse primero para centrarlo física y silenciosamente
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Le damos el control al jugador inmediatamente
	if player:
		player.puede_moverse = true
	
	# Animación de desvanecimiento
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	await tween.finished
	queue_free()
