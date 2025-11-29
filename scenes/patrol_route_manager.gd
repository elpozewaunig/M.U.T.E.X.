# patrol_route_manager.gd
extends Node3D

func get_random_route() -> Dictionary:
	var paths = get_tree().get_nodes_in_group("PatrolPaths")
	
	if paths.is_empty():
		push_error("No patrol paths found!")
		return {"points": [], "spawn_pos": Vector3.ZERO}
	
	var selected_path: Path3D = paths.pick_random()
	var curve: Curve3D = selected_path.curve
	
	var points: Array[Vector3] = []
	for i in range(curve.point_count):
		var local_point = curve.get_point_position(i)
		var global_point = selected_path.to_global(local_point)
		points.append(global_point)
	
	# Spawn-Position ist der erste Punkt
	var spawn_position = points[0] if points.size() > 0 else Vector3.ZERO
	
	return {
		"points": points,
		"spawn_pos": spawn_position
	}
