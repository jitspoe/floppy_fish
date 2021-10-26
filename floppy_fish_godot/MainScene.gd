extends Spatial

const MIN_TIME_BETWEEN_VO := 1.0
onready var MainCamera : Camera = $Camera
onready var Fish : Spatial = $Fish
onready var SubtitleLabel : Label = $HUD/Subtitle
onready var VOPlayer : AudioStreamPlayer = $VOPlayer
var GameTime := 0.0
var Completed := false
var TimeSinceVOPlayed := {}
var VOQueue := []
var TimeSinceLastVO := 99999999.9

class VOQueueData:
	var TimeQueued := 0.0
	var TimeToSkip := 0.0
	var VOLine : String

func _ready():
	$EndScreen.visible = false
	SubtitleLabel.visible = false
	OS.window_maximized = true


func _process(delta : float):
	TimeSinceLastVO += delta
	if (VOPlayer.playing):
		TimeSinceLastVO = 0.0
	if (TimeSinceLastVO > 0.0):
		if (TimeSinceLastVO > 1.0):
			SubtitleLabel.visible = false
		else:
			SubtitleLabel.modulate.a = (1.0 - TimeSinceLastVO)


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
		QueueVO("buoy_did_it")
		print("You win.  Time:", GameTime)
		Completed = true


func _on_RestartButton_pressed():
	call_deferred("Restart")


func PlayVO(VOLine : String):
	SubtitleLabel.visible = true
	SubtitleLabel.modulate.a = 1.0
	SubtitleLabel.text = tr(VOLine)
	VOPlayer.stream = load("res://VO/%s.ogg" % VOLine)
	VOPlayer.play()


func QueueVO(VOLine : String, TimeBeforeSkip := 3.0):
	
	PlayVO(VOLine)
	pass
