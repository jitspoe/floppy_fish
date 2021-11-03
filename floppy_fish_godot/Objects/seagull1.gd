extends Spatial

onready var AnimTree : AnimationTree = $AnimationTree
#onready var AnimNode : AnimationNode = AnimTree.tree_root

#var t := 0.0

#func _process(delta):
#	LookAtPosition(Vector3.ZERO)
#	t += delta


func LookAtPosition(TargetPosition : Vector3):
	#var DirectionToTarget := global_transform.origin.direction_to(TargetPosition)
	var DirectionToTarget := to_local(TargetPosition).normalized()
	#AnimNode.set_parameter("blend_position", sin(t))
	#AnimTree.set("parameters/blend_position", Vector2(sin(t), 0.0))
	var FishPosInAnim := Vector2(-DirectionToTarget.x, DirectionToTarget.y)
	
	AnimTree.set("parameters/blend_position", FishPosInAnim)
