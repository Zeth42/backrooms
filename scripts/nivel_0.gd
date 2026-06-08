extends Node3D

@onready var menu_ui = $Main_Menu/Menu_Container
@onready var boton_jugar = $Main_Menu/Menu_Container/Button
@onready var player = $Player

func _ready():
	# 1. Mostrar el cursor del mouse para que puedan darle clic al botón
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 2. Desactivar el movimiento del jugador temporalmente
	player.set_process_input(true)
	player.set_physics_process(true)
	
	# 3. Conectar el clic del botón a la función que inicia el juego
	boton_jugar.pressed.connect(_on_jugar_pressed)

func _on_jugar_pressed():
	# 1. Capturar el mouse para que la cámara 3D vuelva a girar al mover el ratón
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# 2. Reactivar al jugador (ahora sí puede caminar y correr)
	player.set_process_input(true)
	player.set_physics_process(true)
	
	# 3. Hacer desaparecer el menú con un efecto suave (Fade Out)
	var tween = create_tween()
	# Transiciona la opacidad (modulate:a) del menú a 0 en 1.5 segundos
	tween.tween_property(menu_ui, "modulate:a", 0.0, 1.5)
	# Cuando termine la animación, borra el menú para liberar memoria
	tween.finished.connect(func(): menu_ui.queue_free())
