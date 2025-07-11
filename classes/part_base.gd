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
	if !"color_scheme" in get_parent():
		return
	var surface_index = 0
	for color in color_indexes:
		for child in get_children():
			if child is MeshInstance3D:
				child.mesh.set("surface_" + var_to_str(surface_index) + "/material", get_parent().color_scheme[int(color) % get_parent().color_scheme.size()])
		surface_index += 1



func highlight():
	for child in get_children():
		if child is MeshInstance3D:
			child.material_overlay = load("res://assets/editor_highlight.tres")



func unhighlight():
	for child in get_children():
		if child is MeshInstance3D:
			child.material_overlay = null



func destroy():
	var vfx = load("res://fx/hit_effect.tscn").instantiate()
	add_sibling(vfx)
	vfx.global_position = global_position
	get_parent().remove_child(self)
	queue_free()
