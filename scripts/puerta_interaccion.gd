extends Area3D

# Almacena si el jugador está dentro de la zona de la puerta
var jugador_en_zona: bool = false

# YA NO DARÁ ERROR POR RUTAS: Ahora puedes asignar tu Label directamente 
# desde el Inspector a la derecha seleccionando este nodo.
@export var cartel_interaccion: Label 

func _ready() -> void:
	# Conectamos las señales físicas del Area3D a funciones de este script
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Aseguramos que el cartel empiece oculto al iniciar el mapa
	if cartel_interaccion:
		cartel_interaccion.visible = false

func _process(_delta: float) -> void:
	# Si el jugador está en la zona y presiona la tecla E (interactuar)
	if jugador_en_zona and Input.is_action_just_pressed("interactuar"):
		cambiar_a_escena_final()

func _on_body_entered(body: Node3D) -> void:
	# Verificamos si el cuerpo que entró es el jugador. 
	if body.name == "Player":
		jugador_en_zona = true
		if cartel_interaccion:
			cartel_interaccion.visible = true # Muestra el texto "Salir (E)"

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		jugador_en_zona = false
		if cartel_interaccion:
			cartel_interaccion.visible = false # Oculta el texto si el jugador se aleja
			
func cambiar_a_escena_final() -> void:
	if cartel_interaccion:
		cartel_interaccion.visible = false
	
	# Liberar el cursor para que vuelva a ser visible e interactivo en los menús
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Cambia a la escena final utilizando tu ruta exacta del proyecto
	get_tree().change_scene_to_file("res://Pantallas-menu_in,menu_fin/Escena_FIn.tscn")
