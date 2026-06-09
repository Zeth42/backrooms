extends Node3D

# Usamos rutas absolutas o relativas basadas en lo que se vio en tu árbol de nodos
@onready var menu_ui = $Menu_Inicio # El contenedor principal de tu interfaz de inicio
@onready var boton_jugar = $Menu_Inicio/Control/Button # Ajusta esta ruta exacta hasta tu botón si es necesario

# Al jugador lo buscamos de forma segura mediante su grupo, así no importa si está dentro de la navegación
var player: CharacterBody3D = null

func _ready():
	# 1. Encontrar al jugador en la escena mediante el grupo global que configuramos
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	
	# 2. Mostrar el cursor del mouse para que puedan darle clic al botón
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 3. Desactivar el movimiento del jugador temporalmente al empezar
	if player:
		player.set_process_input(false)
		player.set_physics_process(false)
	
	# 4. Conectar el clic del botón a la función que inicia el juego
	if boton_jugar:
		boton_jugar.pressed.connect(_on_jugar_pressed)
	else:
		print("ERROR: ¡No se encontró el botón de jugar! Revisa la ruta en @onready var boton_jugar")

func _on_jugar_pressed():
	# 1. Capturar el mouse para que la cámara 3D vuelva a girar al mover el ratón
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# 2. Reactivar al jugador (ahora sí puede caminar y correr)
	if player:
		player.set_process_input(true)
		player.set_physics_process(true)
	
	# 3. Hacer desaparecer el menú con un efecto suave (Fade Out)
	if menu_ui:
		var tween = create_tween()
		# Transiciona la opacidad (modulate:a) del menú a 0 en 1.5 segundos
		tween.tween_property(menu_ui, "modulate:a", 0.0, 1.5)
		# Cuando termine la animación, borra el menú para liberar memoria
		tween.finished.connect(func(): menu_ui.queue_free())
