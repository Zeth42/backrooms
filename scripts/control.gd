extends Control

@onready var logo_backrooms = $TextureRect
@onready var boton_play = $Button

# Cambiamos la ruta fija por una variable vacía que buscaremos en el _ready
var player: CharacterBody3D = null

func _ready():
	# Encontrar al jugador de forma segura por su grupo
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		
	# Mantenemos el mouse visible al inicio
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	boton_play.pressed.connect(_on_play_pressed)

func _on_play_pressed():
	boton_play.disabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if player:
		# Activamos la variable custom de tu player.gd
		player.puede_moverse = true
		# Nos aseguramos de reactivar sus procesos nativos por si acaso
		player.set_process_input(true)
		player.set_physics_process(true)
	else:
		print("ERROR en control.gd: No se encontró al jugador en el grupo 'Player'")
	
	# Animación de desvanecimiento
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	await tween.finished
	queue_free()
