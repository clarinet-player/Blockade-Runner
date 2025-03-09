extends StaticBody3D
class_name Part


@export var type : String
@export var mass : float
@export var health : float
@export var attributes : Dictionary
@export var color_indexes := [0]


func _ready():
	load_materials()
	if "enemy" in get_parent():
		collision_layer = 0b10
	else:
		collision_layer = 0b01


func load_materials():
	var surface_index = 0
	for color in color_indexes:
		get_node("Mesh").mesh.set("surface_" + var_to_str(surface_index) + "/material", get_parent().color_scheme[color])
		surface_index += 1


func destroy():
	var vfx = load("res://fx/hit_effect.tscn").instantiate()
	add_sibling(vfx)
	vfx.global_position = global_position
	get_parent().remove_child(self)
	queue_free()
