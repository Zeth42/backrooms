extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.003

# Variables de velocidad base
const WALK_SPEED = 5.0
const SPRINT_SPEED = 10.0
var SPEED = WALK_SPEED

# Variables del movimiento de camara
var BOB_FREQ = 2.0
var BOB_AMP = 0.08
var t_bob = 0.0

# sistema de estamina
@export_group("Sistema de Estamina")
@export var estamina_maxima: float = 100.0
@export var velocidad_gasto: float = 20.0     # Cuánta estamina gasta por segundo al correr
@export var velocidad_recarga: float = 15.0    # Cuánta estamina recupera por segundo
@export var delay_recarga: float = 1.5         # Segundos a esperar para recargar tras dejar de correr

var estamina_actual: float = 100.0
var tiempo_para_recargar: float = 0.0
var esta_cansado: bool = false                 # Bloquea el sprint si llega a 0%

@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head

func _ready():
	# Inicializar la estamina al máximo al empezar
	estamina_actual = estamina_maxima
	# Hide the cursor
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look logic
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate the body left/right (Y axis)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Rotate the body up/down (X axis)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		# Clamp head rotation
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Cursor logic
	if event.is_action_pressed("quit"):
		# Make the cursor visible again
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# logica de estamina y sprint
	# Solo quiere correr si: aprieta el botón, se está moviendo y NO está exhausto (esta_cansado = false)
	var quiere_correr = Input.is_action_pressed("sprint") and direction.length() > 0 and not esta_cansado
	
	if quiere_correr and estamina_actual > 0.0:
		# Estado: Corriendo
		SPEED = SPRINT_SPEED
		BOB_FREQ = 3.0
		
		# Restar estamina frame por frame
		estamina_actual -= velocidad_gasto * delta
		tiempo_para_recargar = delay_recarga # Resetea el tiempo de espera para volver a recargar
		
		# Si se agota por completo la energía
		if estamina_actual <= 0.0:
			estamina_actual = 0.0
			esta_cansado = true # Activamos el bloqueo por cansancio
	else:
		# Estado: Caminando, quieto, o recuperándose
		SPEED = WALK_SPEED
		BOB_FREQ = 2.0
		
		# Manejar el temporizador de retraso antes de recargar
		if tiempo_para_recargar > 0.0:
			tiempo_para_recargar -= delta
		else:
			# Si ya pasó el tiempo de espera, recargar estamina paulatinamente
			if estamina_actual < estamina_maxima:
				estamina_actual += velocidad_recarga * delta
				if estamina_actual > estamina_maxima:
					estamina_actual = estamina_maxima
				
				# Si ya descansó lo suficiente (ej. recuperó el 30% de la barra), quitamos el bloqueo
				if esta_cansado and estamina_actual >= (estamina_maxima * 0.3):
					esta_cansado = false

	# Aplicar las velocidades calculadas en la física
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Head bouncing logic
	if velocity.length() > 0 and is_on_floor():
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera_3d.transform.origin = _headbob(t_bob)
	else:
		# Reset camera smoothly when stop
		camera_3d.transform.origin = camera_3d.transform.origin.lerp(Vector3.ZERO, 10 * delta)
	
	move_and_slide()

func _headbob (time) -> Vector3:
	var pos = Vector3.ZERO
	# Sine wave for vertical movement
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	# Cosine wave for horizontal movement (creates a figure-8 sway)
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
