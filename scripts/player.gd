extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.003

# Variables para los pasos del jugador
@export var sonidos_pasos: Array[AudioStream] = []
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
var paso_acumulado: float = 0.0
const DISTANCIA_PASO_CAMINAR = 2.0  # Un paso cada 2 metros caminando
const DISTANCIA_PASO_CORRER = 2.6   # Un paso cada 2.6 metros corriendo

# Variables para el menu de inicio
var puede_moverse: bool = false:
	set(valor):
		puede_moverse = valor
		if puede_moverse:
			_ignorar_primer_movimiento = true
var _ignorar_primer_movimiento: bool = false

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
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await get_tree().create_timer(0.15).timeout
	if not puede_moverse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not puede_moverse:
		return

	# Mouse look logic
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _ignorar_primer_movimiento:
			_ignorar_primer_movimiento = false
			return
			
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# Cursor logic
	if event.is_action_pressed("quit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if not puede_moverse:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# logica de estamina y sprint
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
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if velocity.length() > 0 and is_on_floor():
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera_3d.transform.origin = _headbob(t_bob)
	else:
		camera_3d.transform.origin = camera_3d.transform.origin.lerp(Vector3.ZERO, 10 * delta)
	
	# Pasos sonido
	if is_on_floor() and velocity.length() > 0.1:
		paso_acumulado += velocity.length() * delta
		var distancia_necesaria = DISTANCIA_PASO_CORRER if quiere_correr else DISTANCIA_PASO_CAMINAR
		
		if paso_acumulado >= distancia_necesaria:
			_reproducir_sonido_paso()
			paso_acumulado = 0.0
	else:
		# Si se detiene o está en el aire, reiniciamos el acumulador
		paso_acumulado = 0.0

	move_and_slide()

func _headbob (time) -> Vector3:
	var pos = Vector3.ZERO
	# Sine wave for vertical movement
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	# Cosine wave for horizontal movement (creates a figure-8 sway)
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func _reproducir_sonido_paso() -> void:
	if sonidos_pasos.is_empty() or not footstep_player:
		return
	var sonido_aleatorio = sonidos_pasos.pick_random()
	footstep_player.stream = sonido_aleatorio
	footstep_player.pitch_scale = randf_range(0.85, 1.15)
	
	footstep_player.play()
