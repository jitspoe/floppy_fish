extends RigidBody

var PreCollisionVelocity : Vector3
onready var StreamPlayer : AudioStreamPlayer3D = $AudioStreamPlayer3D
const IMPACT_SOUND1 := preload("res://Sound/impact1.wav")
const IMPACT_SOUND2 := preload("res://Sound/impact2.wav")
const IMPACT_SOUND3 := preload("res://Sound/impact3.wav")
const IMPACT_SOUND4 := preload("res://Sound/impact4.wav")
const IMPACT_SOUND5 := preload("res://Sound/impact5.wav")
const IMPACT_SOUND6 := preload("res://Sound/impact6.wav")
const IMPACT_SOUND7 := preload("res://Sound/impact7.wav")
const IMPACT_SOUND8 := preload("res://Sound/impact8.wav")
const IMPACT_SOUND_TAIL1 := preload("res://Sound/tail_impact1.wav")
const IMPACT_SOUND_TAIL2 := preload("res://Sound/tail_impact2.wav")
const IMPACT_SOUND_TAIL3 := preload("res://Sound/tail_impact3.wav")
const IMPACT_SOUND_TAIL4 := preload("res://Sound/tail_impact4.wav")
const IMPACT_SOUND_TAIL5 := preload("res://Sound/tail_impact5.wav")
const IMPACT_SOUND_TAIL6 := preload("res://Sound/tail_impact6.wav")
const IMPACT_SOUND_TAIL7 := preload("res://Sound/tail_impact7.wav")
const IMPACT_SOUND_TAIL8 := preload("res://Sound/tail_impact8.wav")

const VELOCITY_SOUND_THRESHOLD := 0.3
const VELOCITY_SOUND_SCALE := 0.3

func _physics_process(_delta):
	PreCollisionVelocity = linear_velocity



func _on_body_entered(_body):
	var VelocityDiff = PreCollisionVelocity.distance_to(linear_velocity)
	if (VelocityDiff > VELOCITY_SOUND_THRESHOLD):
		var r = rand_range(0.0, 8.0)
		if (r < 1.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND1
		elif (r < 2.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND2
		elif (r < 3.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND3
		elif (r < 4.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND4
		elif (r < 5.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND5
		elif (r < 6.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND6
		elif (r < 7.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND7
		else:
			StreamPlayer.stream.audio_stream = IMPACT_SOUND8

		StreamPlayer.unit_db = linear2db(clamp((VelocityDiff - VELOCITY_SOUND_THRESHOLD) * VELOCITY_SOUND_SCALE, 0.1, 2.0))
		StreamPlayer.play()
		get_parent().SlapPlayed(VelocityDiff)



func _on_FishTail4_body_entered(_body):
	var VelocityDiff = PreCollisionVelocity.distance_to(linear_velocity)
	if (VelocityDiff > VELOCITY_SOUND_THRESHOLD):
		var r = rand_range(0.0, 8.0)
		if (r < 1.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL1
		elif (r < 2.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL2
		elif (r < 3.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL3
		elif (r < 4.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL4
		elif (r < 5.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL5
		elif (r < 6.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL6
		elif (r < 7.0):
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL7
		else:
			StreamPlayer.stream.audio_stream = IMPACT_SOUND_TAIL8

		StreamPlayer.unit_db = linear2db(clamp((VelocityDiff - VELOCITY_SOUND_THRESHOLD) * VELOCITY_SOUND_SCALE, 0.1, 2.0))
		StreamPlayer.play()
