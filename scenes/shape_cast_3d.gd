extends ShapeCast3D
@rpc("any_peer","call_local","reliable")
func _physics_process(delta: float) -> void:
	if (is_colliding()):
		var colliding_target = get_collider(0)
		if(get_collision_mask_value(3) || get_collision_mask_value(2)):
			var enemyPath=colliding_target.get_path()
			sync_enemy(enemyPath).rpc(enemyPath)

func sync_enemy(enemy_Path:NodePath):
	var enode = get_node_or_null(enemy_Path)
	if enode:
		enode.visible=true
