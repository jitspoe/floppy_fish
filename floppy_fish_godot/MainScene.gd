extends Spatial

onready var MainCamera : Camera = $Camera
onready var Fish : Spatial = $Fish

func _physics_process(_delta : float):
	MainCamera.global_transform.origin.y = Fish.AverageLocation.y + 0.3
	MainCamera.global_transform.origin.x = Fish.AverageLocation.x
