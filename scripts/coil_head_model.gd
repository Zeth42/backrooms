extends CharacterBody3D

enum State { CHASE, DISABLED }
var current_state: State = State.CHASE # Siempre en cacería activa

var mapa_listo: bool = false

# Variables para el sistema Anti-Atasco
var ultima_posicion: Vector3 = Vector3.ZERO
var tiempo_estancado: float = 0.0
const TIEMPO_LIMITE_ESTANCADO: float = 0.8

@export var speed_chase: float = 10.0

var player: CharacterBody3D = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

func _ready() -> void:
	$Sketchfab_model.rotation.y = deg_to_rad(180)
	nav_agent.path_desired_distance = 1.5
	nav_agent.target_desired_distance = 1.5
	
	# Conseguir la referencia del jugador automáticamente (usando su grupo)
	await get_tree().create_timer(0.5).timeout
	var jugadores = get_tree().get_nodes_in_group("Player")
	if jugadores.size() > 0:
		player = jugadores[0] as CharacterBody3D
		
	mapa_listo = true
	print("[SISTEMA] Coil Head activado a nivel global. ¡La cacería comenzó!")

func _physics_process(delta: float) -> void:
	if not mapa_listo or not player:
		return

	var mirando = _is_player_looking_at_me()

	if mirando:
		velocity = Vector3.ZERO
		return


	# NO lo miran -> persecución completa

	nav_agent.target_position = player.global_position
	var next_pos = nav_agent.get_next_path_position()

	if Engine.get_physics_frames() % 60 == 0:
		print("[CACERÍA GLOBAL] Distancia: ",
			global_position.distance_to(player.global_position))

	_move_towards(next_pos, speed_chase, delta)


	# Anti-atasco
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
		look_at(
			global_position + velocity_flat,
			Vector3.UP
		)

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
		
	print("[SISTEMA RESCATE] Coil Head atrapado en colisión. Ejecutando salto de malla...")
		
	# 1. Calculamos la dirección hacia el jugador
	var direccion_empujon = (player.global_position - global_position).normalized()
	direccion_empujon.y = 0
	direccion_empujon = direccion_empujon.normalized()
	
	# 2. Aumentamos el empujón a 1.2 metros para superar el grosor de las esquinas modulares
	var posicion_tentativa = global_position + (direccion_empujon * 1.2)
	
	# 3. Buscamos el punto seguro más cercano en la NavMesh
	var mapa_navegacion = nav_agent.get_navigation_map()
	var punto_malla_seguro = NavigationServer3D.map_get_closest_point(mapa_navegacion, posicion_tentativa)
	
	# 4. Hacemos el salto físico
	global_position = punto_malla_seguro
	
	# 5. Forzamos al agente de navegación a recalcular el camino en este frame
	nav_agent.target_position = player.global_position
