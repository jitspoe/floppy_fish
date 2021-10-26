extends Spatial

onready var MainCamera : Camera = $Camera
onready var Fish : Spatial = $Fish
var GameTime := 0.0
var Completed := false


func _ready():
	$EndScreen.visible = false


func _physics_process(delta : float):
	if (!Completed):
		MainCamera.global_transform.origin.y = max(0.0, Fish.AverageLocation.y) + 0.6
		MainCamera.global_transform.origin.x = Fish.AverageLocation.x
		GameTime += delta
	if (Input.is_action_just_pressed("restart")):
		Restart()


func Restart():
	$EndScreen.visible = false
	Fish.Restart()
	GameTime = 0.0
	Completed = false


func TimeFormat(Time : float):
	var Minutes : int = int(Time / 60)
# warning-ignore:integer_division
	var Hours : int = int(Minutes / 60)
	Minutes -= Hours * 60
	var Seconds : int = int(Time - Hours*60*60 - Minutes*60)
# warning-ignore:narrowing_conversion
	var ms : int = (Time - int(Time)) * 1000
	return "%02d:%02d:%02d.%03d" % [ Hours, Minutes, Seconds, ms ]


func _on_EndTrigger_body_entered(body):
	if (!Completed):
		$EndScreen.visible = true
		$EndScreen/CenterContainer/GridContainer/Label.text = "Completed in %s" % TimeFormat(GameTime)
		$SoundSplashEnd.global_transform.origin = body.global_transform.origin
		$SoundSplashEnd.play()
		print("You win.  Time:", GameTime)
		Completed = true


func _on_RestartButton_pressed():
	call_deferred("Restart")
