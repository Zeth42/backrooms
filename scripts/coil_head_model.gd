extends CharacterBody3D

enum State { WANDER, CHASE, DISABLED }
var current_state: State = State.WANDER

@export var speed_wander: float = 7.0
@export var speed_chase: float = 10.0 # igual a jugador sprinteando
@export var wander_radius: float = 10.0

var player: CharacterBody3D = null
var wander_target: Vector3 = Vector3.ZERO

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var chase_timer: Timer = $ChaseTimer
@onready var wander_timer: Timer = $WanderTimer
@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

func _ready() -> void:
	# Configurar Timers
	cooldown_timer.wait_time = 40.0
	cooldown_timer.one_shot = true
	chase_timer.wait_time = 10.0
	chase_timer.one_shot = true
	
	_make_new_wander_target()

func _physics_process(delta: float) -> void:
	if current_state == State.DISABLED:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# REGLA DE ORO: Si el jugador lo está mirando (y hay línea de visión), se congela por completo
	if _is_player_looking_at_me():
		velocity = Vector3.ZERO
		move_and_slide()
		# Si estaba persiguiendo y lo miras, detenemos temporalmente el contador de los 10s
		if current_state == State.CHASE and not chase_timer.is_paused():
			chase_timer.set_paused(true)
		return
	else:
		# Si no lo estás mirando y estaba persiguiendo, reanuda su tiempo de persecución
		if current_state == State.CHASE && chase_timer.is_paused():
			chase_timer.set_paused(false)

	# Lógica de movimiento según el estado actual
	match current_state:
		State.WANDER:
			_move_towards(wander_target, speed_wander, delta)
			if nav_agent.is_navigation_finished():
				_make_new_wander_target()
				
		State.CHASE:
			if player:
				nav_agent.target_position = player.global_position
				var next_pos = nav_agent.get_next_path_position()
				_move_towards(next_pos, speed_chase, delta)

func _move_towards(target: Vector3, speed: float, delta: float) -> void:
	var current_pos = global_transform.origin
	var next_pos = target
	var new_velocity = (next_pos - current_pos).normalized() * speed
	
	# Evitar que se mueva en el eje Y bruscamente (mantenerlo en el suelo)
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	move_and_slide()
	
# Rotar hacia donde camina (solo si no está en la misma posición)
	if velocity.length() > 0.2:
		var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
		# PROTECCIÓN: Solo mirar si el objetivo no es exactamente nuestra posición actual
		if global_position.distance_to(look_target) > 0.001:
			look_at(look_target, Vector3.UP)

func _is_player_looking_at_me() -> bool:
	# 1. Validación rápida: ¿Está dentro de la pantalla/cámara del jugador?
	if not notifier.is_on_screen():
		return false
		
	if not player:
		return false
		
	# 2. Validación de obstáculos (Raycast): ¿Hay una pared entre la cámara y el Coil Head?
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.5, global_position + Vector3.UP * 1.5)
	# Asegúrate de que el Raycast ignore al propio Coil Head y al jugador
	query.exclude = [self.get_rid(), player.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		# No hay nada obstruyendo la vista
		return true
	
	return false # Hay una pared en medio

func _make_new_wander_target() -> void:
	# Genera un punto aleatorio en el mapa de navegación para merodear
	var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	wander_target = global_position + random_dir * wander_radius
	nav_agent.target_position = wander_target
	wander_timer.start(randf_range(3.0, 7.0)) # Cambia de rumbo cada tanto

# --- SEÑALES ---

# Conecta la señal body_entered de tu DetectionArea (Area3D)
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and current_state == State.WANDER:
		player = body
		current_state = State.CHASE
		chase_timer.start() # Inicia la cuenta regresiva de 10 segundos de persecución

# Conecta la señal timeout de tu ChaseTimer
func _on_chase_timer_timeout() -> void:
	# Pasaron los 10 segundos continuos de persecución activa
	current_state = State.DISABLED
	cooldown_timer.start() # Inicia los 40 segundos de desactivación

# Conecta la señal timeout de tu CooldownTimer
func _on_cooldown_timer_timeout() -> void:
	# Terminaron los 40 segundos de paz, vuelve a merodear
	current_state = State.WANDER
	_make_new_wander_target()

# Conecta la señal timeout de tu WanderTimer
func _on_wander_timer_timeout() -> void:
	if current_state == State.WANDER:
		_make_new_wander_target()
