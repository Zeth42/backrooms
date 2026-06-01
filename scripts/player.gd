extends CharacterBody3D

var SPEED = 5.0
const MOUSE_SENSITIVITY = 0.003
var BOB_FREQ = 2.0
var BOB_AMP = 0.08

@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head

var t_bob = 0.0

func _ready():
	#Hide the cursor
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	#Run logic
	if event.is_action_pressed("sprint"):
		SPEED = 10
		BOB_FREQ = 3.0
		BOB_AMP = 0.08
	elif event.is_action_released("sprint"):
		SPEED = 5
		BOB_FREQ = 2.0
		BOB_AMP = 0.08

	#Mouse look logic
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#Rotate the body left/right (Y axis)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		#Rotate the body up/down ( axis)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		#Clamp head rotation
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	#Cursor logic
	if event.is_action_pressed("quit"):
		#Make the cursor visible again
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
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	#Head bouncing logic
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
