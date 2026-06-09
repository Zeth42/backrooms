extends Node3D

var player: CharacterBody3D = null

func _ready():
	# 1. Encontrar al jugador mediante el grupo global
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	
	# 2. Asegurar que el mouse sea visible para interactuar con la UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 3. Congelar los procesos del jugador para que no caiga ni gaste estamina en el fondo
	if player:
		player.puede_moverse = false
		player.set_process_input(false)
		player.set_physics_process(false)
