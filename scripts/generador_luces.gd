extends Node3D

const LUZ_PLANTILLA = preload("res://scenes/luz_foco.tscn")

@export_group("Configuración de Cuadrícula")
## Cuántas luces poner a lo largo (Eje X)
@export var cantidad_x: int = 67
## Cuántas luces poner a lo ancho (Eje Z)
@export var cantidad_z: int = 67
## Distancia en metros entre cada luz 5.7 MEJOR
@export var separacion_metros: float = 5.6
## Altura fija del techo donde se colocarán las luces (Eje Y)
@export var altura_techo: float = 6.

@export_group("Ajuste de Desfase (Offsets)")
## Mueve toda la cuadrícula de luces hacia la izquierda o derecha en X
@export var desfase_x: float = -1.5
## Mueve toda la cuadrícula de luces hacia adelante o atrás en Z
@export var desfase_z: float = -1

func _ready() -> void:
	await get_tree().process_frame
	_generar_matriz_de_luces()

func _generar_matriz_de_luces() -> void:
	var centro_x = (cantidad_x - 1) * separacion_metros / 2.0
	var centro_z = (cantidad_z - 1) * separacion_metros / 2.0
	
	for x in range(cantidad_x):
		for z in range(cantidad_z):
			var nueva_luz = LUZ_PLANTILLA.instantiate() as OmniLight3D
			add_child(nueva_luz)
			
			var pos_local = Vector3(
				((x * separacion_metros) - centro_x) + desfase_x,
				altura_techo,
				((z * separacion_metros) - centro_z) + desfase_z
			)
			nueva_luz.global_position = global_position + pos_local
