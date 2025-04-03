extends Node3D
class_name Enemy



var enemy



@export var max_speed := 30.0
@export var thrust := 1.0
@export var turning := 1.0
@export var target_distance := Vector2(40, 80)
@export var innacuracy := 1.0
@export var attack_speed := 1.0
@export var attack_damage := 1.0
@export var projectile_speed := 45.0
@export var health := 10.0
@export var color_scheme : Array[StandardMaterial3D]



var velocity := Vector3.ZERO
var target_vel := Vector3.ZERO
var target_facing := Vector3(0, 0, 1)

enum s {
	approaching,
	attacking,
	fleeing
}
var state := s.approaching

var destroyed := false
var current_health := 10.0
var fire_time := 0

var thrust_directions := Vector3i.ZERO



func _ready():
	current_health = health
	global_rotation = Vector3(randf_range(0, 180), randf_range(0, 180), 0)



func _process(delta):
	if destroyed:
		return
	var pos = get_viewport().get_camera_3d().unproject_position(global_position)
	$HBoxContainer.position = pos - $HBoxContainer.size / 2 - Vector2(0, 20)
	
	if acos(Vector2(1, 0).dot((pos - get_viewport().size / 2.0))) < PI / 2:
		if get_viewport().get_camera_3d().global_basis.z.dot(get_viewport().get_camera_3d().global_position.direction_to(global_position)) < 0:
			$Control.rotation = acos(Vector2(0, -1).dot((pos - get_viewport().size / 2.0).normalized()))
		else:
			$Control.rotation = acos(Vector2(0, -1).dot((pos - get_viewport().size / 2.0).normalized())) + PI
	else:
		if get_viewport().get_camera_3d().global_basis.z.dot(get_viewport().get_camera_3d().global_position.direction_to(global_position)) < 0:
			$Control.rotation = acos(Vector2(0, 1).dot((pos - get_viewport().size / 2.0).normalized())) + PI
		else:
			$Control.rotation = acos(Vector2(0, 1).dot((pos - get_viewport().size / 2.0).normalized()))
	
	if get_viewport().get_camera_3d().is_position_in_frustum(global_position):
		$HBoxContainer.show()
		$Control.hide()
	else:
		$HBoxContainer.hide()
		$Control.show()
	
	if is_equal_approx(health, current_health):
		$HBoxContainer/GreyHeath.hide()
	else:
		$HBoxContainer/GreyHeath.show()
		$HBoxContainer/GreyHeath.size_flags_stretch_ratio = health - current_health
		$HBoxContainer/RedHealth.size_flags_stretch_ratio = current_health



func _physics_process(delta):
	if destroyed:
		global_translate(velocity * delta)
		return
	
	
	match state:
		
		s.approaching:
			if global_position.distance_to(Ship.global_position) < target_distance.y and global_position.distance_to(Ship.global_position) > target_distance.x:
				state = s.attacking
				fire_time = Time.get_ticks_msec()
			
			target_vel = global_position.direction_to(Ship.global_position) * max_speed
			thrust_directions = global_basis * velocity.direction_to(target_vel) * 7.5
			velocity += (velocity.direction_to(target_vel) * thrust * delta).limit_length(velocity.distance_to(target_vel))
			
			target_facing = velocity.direction_to(target_vel)
			if target_facing.cross(-global_basis.z).normalized().is_normalized():
				global_rotate(target_facing.cross(global_basis.z).normalized(), min(acos(target_facing.dot(global_basis.z)), turning * delta))
		
		
		
		s.attacking:
			if global_position.distance_to(Ship.global_position) > target_distance.y:
				state = s.approaching
			if global_position.distance_to(Ship.global_position) < target_distance.x:
				state = s.fleeing
			
			target_vel = Ship.velocity
			thrust_directions = global_basis * velocity.direction_to(target_vel) * 7.5
			velocity += (velocity.direction_to(target_vel) * thrust * 0.5 * delta).limit_length(velocity.distance_to(target_vel))
			for enemy in get_tree().get_nodes_in_group("Enemies"):
				if enemy == self:
					continue
				velocity -= global_position.direction_to(enemy.global_position) / global_position.distance_to(enemy.global_position) * delta * 0.8
			
			var lead := Vector3.ZERO
			for i in range(8):
				var relative_vel = Ship.velocity - velocity
				var travel_time = global_position.distance_to(Ship.global_position + lead) / projectile_speed
				lead = lead.lerp(relative_vel * travel_time, 0.9)
			
			target_facing = global_position.direction_to(Ship.global_position + lead)
			if target_facing.cross(-global_basis.z).normalized().is_normalized():
				global_rotate(target_facing.cross(global_basis.z).normalized(), min(acos(target_facing.dot(global_basis.z)), turning * delta))
			
			custom_process()
		
		
		
		s.fleeing:
			if global_position.distance_to(Ship.global_position) > target_distance.x + 10:
				state = s.attacking
				fire_time = Time.get_ticks_msec()
			
			target_vel = global_position.direction_to(Ship.global_position) * max_speed * -1
			thrust_directions = global_basis * velocity.direction_to(target_vel) * 7.5
			velocity += (velocity.direction_to(target_vel) * thrust * delta).limit_length(velocity.distance_to(target_vel))
			
			target_facing = velocity.direction_to(target_vel)
			if target_facing.cross(-global_basis.z).normalized().is_normalized():
				global_rotate(target_facing.cross(global_basis.z).normalized(), min(acos(target_facing.dot(global_basis.z)), turning * delta))
	
	velocity = velocity.limit_length(max_speed)
	global_translate(velocity * delta)



func damage(amount : float, part : Node3D, knockback := Vector3.ZERO, sfx := ""):
	current_health -= max(amount, part.health)
	velocity += knockback
	part.destroy()
	
	var audio = load("res://classes/audio_player.tscn").instantiate()
	if !sfx.is_empty():
		audio.start(self, sfx)
	elif current_health < 0.1:
		audio.start(self, "res://fx/destroy.mp3")
	else:
		audio.start(self, "res://fx/hit.mp3")
	
	if current_health < 0.1:
		for child in get_children():
			if child is Node3D:
				load("res://classes/part_ragdoll.tscn").instantiate().take_part(child)
		destroyed = true
		$HBoxContainer.hide()
		$Control.hide()
		await get_tree().create_timer(1).timeout
		queue_free()



func custom_process():
	if Time.get_ticks_msec() - fire_time > (1.0 / attack_speed) * 1000 and !destroyed and get_parent().tokens > 0:
		fire_time = Time.get_ticks_msec()
		get_parent().tokens -= 1
		
		var audio = load("res://classes/audio_player.tscn").instantiate()
		audio.start(self, "res://fx/shoot.mp3")
		
		var bullet = load("res://classes/bullet.tscn").instantiate()
		bullet.velocity = global_basis.z * -projectile_speed + velocity + Vector3(randf_range(-innacuracy, innacuracy), randf_range(-innacuracy, innacuracy), randf_range(-innacuracy, innacuracy))
		bullet.damage = attack_damage
		GameManager.add_child(bullet)
		bullet.global_position = global_position

