extends Node

func _process(delta):
	get_parent().ProcessWhilePaused(delta)
