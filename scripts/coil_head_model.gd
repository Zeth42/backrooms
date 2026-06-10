extends CharacterBody3D

enum State { CHASE, DISABLED }
var current_state: State = State.CHASE 

var mapa_listo: bool = false
var sonado_golpe: bool = false 

# CONFIGURACIÓN DE AUDIO (INSPECTOR)
@export_group("Recursos de Audio")
@export var sonidos_pasos: Array[AudioStream] = []   # Los 4 BareFootstep
@export var sonidos_resorte: Array[AudioStream] = [] # Los 3 Spring

# CONTROL DEL RITMO DE LOS PASOS
@export var tiempo_entre_pasos: float = 0.10        # Menos tiempo = pasos más pegados y frenéticos
@export var debounce_resorte: float = 0.4  # Tiempo mínimo en segundos entre sonidos
var cronometro_resorte: float = 0.0        # Controla el tiempo transcurrido

@export_group("Nodos Reproductores")
@export var pasos_player: AudioStreamPlayer3D      
@export var golpe_metal_player: AudioStreamPlayer3D 

# Variables para el sistema Anti-Atasco
var ultima_posicion: Vector3 = Vector3.ZERO
var tiempo_estancado: float = 0.0
const TIEMPO_LIMITE_ESTANCADO: float = 0.8

@export var speed_chase: float = 10.0

var player: CharacterBody3D = null
var cronometro_pasos: float = 0.0 # Reemplaza la señal 'finished' para evitar los espacios en blanco

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

func _ready() -> void:
	$Sketchfab_model.rotation.y = deg_to_rad(180)
	nav_agent.path_desired_distance = 1.5
	nav_agent.target_desired_distance = 1.5
	
	if pasos_player:
		pasos_player.pitch_scale = 1.5 # Un ligero aumento de tono para agilidad
	else:
		print("[ERROR AUDIO] No has asignado el nodo FootstepsPlayer en el Inspector")
		
	if not golpe_metal_player:
		print("[ERROR AUDIO] No has asignado el nodo SpringPlayer en el Inspector")
	
	await get_tree().create_timer(0.5).timeout
	var jugadores = get_tree().get_nodes_in_group("Player")
	if jugadores.size() > 0:
		player = jugadores[0] as CharacterBody3D
		
	mapa_listo = true
	
func _physics_process(delta: float) -> void:
	if not mapa_listo or not player:
		return

	# El cronómetro del resorte siempre avanza con el tiempo del juego
	cronometro_resorte += delta

	var mirando = _is_player_looking_at_me()

	if mirando:
		velocity = Vector3.ZERO
		
		# --- AUDIO AL MIRARLO ---
		if pasos_player and pasos_player.playing:
			pasos_player.stop() 
			
		# Solo suena si NO ha sonado en este ciclo Y ya pasaron más de 0.2 segundos desde el último golpe
		if golpe_metal_player and not sonado_golpe and sonidos_resorte.size() > 0:
			if cronometro_resorte >= debounce_resorte:
				var resorte_aleatorio = sonidos_resorte.pick_random()
				golpe_metal_player.stream = resorte_aleatorio
				golpe_metal_player.play() 
				cronometro_resorte = 0.0 # Reiniciamos el debounce
				
			sonado_golpe = true # Bloquea el sonido mientras lo sigas viendo de forma continua
			
		return

	# NO lo miran -> persecución completa
	sonado_golpe = false

	# --- SISTEMA DE RITMO DE PASOS INDUSTRIAL ---
	cronometro_pasos += delta
	if cronometro_pasos >= tiempo_entre_pasos:
		_reproducir_paso_aleatorio()
		cronometro_pasos = 0.0 # Reinicia el temporizador manual

	# --- NAVEGACIÓN Y MOVIMIENTO ---
	nav_agent.target_position = player.global_position
	var next_pos = nav_agent.get_next_path_position()
	_move_towards(next_pos, speed_chase, delta)

	# --- SISTEMA ANTI-ATASCO ---
	var distancia_movida = global_position.distance_to(ultima_posicion)

	if distancia_movida < 0.02:
		tiempo_estancado += delta
		if tiempo_estancado >= TIEMPO_LIMITE_ESTANCADO:
			_ejecutar_teletransporte_rescate()
			tiempo_estancado = 0.0
	else:
		tiempo_estancado = 0.0

	ultima_posicion = global_position

func _move_towards(target: Vector3, speed: float, delta: float) -> void:
	var direccion = target - global_position
	direccion.y = 0
	direccion = direccion.normalized()

	velocity.x = direccion.x * speed
	velocity.z = direccion.z * speed

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	move_and_slide()

	var velocity_flat = Vector3(velocity.x, 0, velocity.z)
	if velocity_flat.length() > 0.5:
		look_at(global_position + velocity_flat, Vector3.UP)

# --- FUNCIONES DE CONTROL DE AUDIO ---

func _reproducir_paso_aleatorio() -> void:
	if pasos_player and sonidos_pasos.size() > 0:
		pasos_player.stream = sonidos_pasos.pick_random()
		pasos_player.play()

func _is_player_looking_at_me() -> bool:
	if not notifier.is_on_screen():
		return false
	if not player:
		return false
		
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.5, global_position + Vector3.UP * 1.5)
	query.exclude = [self.get_rid(), player.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return false

func _ejecutar_teletransporte_rescate() -> void:
	if not player:
		return
		
	var direccion_empujon = (player.global_position - global_position).normalized()
	direccion_empujon.y = 0
	direccion_empujon = direccion_empujon.normalized()
	
	global_position += direccion_empujon * 1.2
	var punto_malla_seguro = NavigationServer3D.map_get_closest_point(nav_agent.get_navigation_map(), global_position)
	global_position = punto_malla_seguro
	
	nav_agent.target_position = player.global_position
