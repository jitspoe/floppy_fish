extends Spatial

const MIN_TIME_BETWEEN_VO := 1.0
const TIME_BETWEEN_FILLER_VO := 120.0
onready var MainCamera : Camera = $Camera
onready var Fish : Spatial = $Fish
onready var SubtitleLabel : Label = $HUD/Subtitle
onready var VOPlayer : AudioStreamPlayer = $VOPlayer
onready var MusicPlayer : AudioStreamPlayer = $MusicPlayer
var GameTime := 0.0
var Completed := false
var TimeVOPlayed := {}
var VOQueue := []
var TimeSinceLastVO := 0.0
var MusicPlaying := false
var MusicFade := 1.0
const MUSIC_FADE_SPEED := 0.25
var MusicStopTime := 0.0
var CurrentTime := 0.0
var VOPlaying := false
var VOEnabled := true
var GameStarted := false
var MasterVolume := 1.0
var MusicVolume := 0.25
var EffectsVolume := 1.0
var VOOnlyNewLines := false


class VOQueueData:
	var TimeToPlay := 0.0
	var TimeToSkip := 0.0
	var VOLine : String


func _ready():
	$EndScreen.visible = false
	SubtitleLabel.visible = false
	OS.window_maximized = true
	MusicPlayer.volume_db = linear2db(MusicVolume)
	OpenMenu()


func _process(delta : float):
	CurrentTime = OS.get_ticks_msec() / 1000.0
	TimeSinceLastVO += delta
	if (VOPlaying):
		TimeSinceLastVO = 0.0
	if (TimeSinceLastVO > 0.0):
		if (TimeSinceLastVO > 1.0):
			SubtitleLabel.visible = false
		else:
			SubtitleLabel.modulate.a = (1.0 - TimeSinceLastVO)
	UpdateVO()
	if (MusicPlaying):
		if (TimeSinceLastVO > MIN_TIME_BETWEEN_VO && CurrentTime > MusicStopTime):
			MusicFade -= delta * MUSIC_FADE_SPEED
		else:
			MusicFade += delta * MUSIC_FADE_SPEED
		MusicFade = min(1.0, MusicFade)
		MusicPlayer.volume_db = linear2db(MusicFade * MusicVolume)
		if (MusicFade <= 0.0):
			MusicPlayer.stop()
			MusicPlaying = false
		else:
			MusicPlaying = true
	if (Input.is_action_just_pressed("ui_cancel")):
		OpenMenu()


func OpenMenu():
	$MainMenu.visible = true
	$MainMenu/CenterContainer/GridContainer/OnlyPlayNewLines.pressed = VOOnlyNewLines
	$MainMenu/CenterContainer/GridContainer/NarrationCheckbox.pressed = VOEnabled
	$MainMenu/CenterContainer/GridContainer/GridContainer/MasterVolumeSlider.value = MasterVolume
	$MainMenu/CenterContainer/GridContainer/GridContainer/EffectsVolumeSlider.value = EffectsVolume
	$MainMenu/CenterContainer/GridContainer/GridContainer/MusicVolumeSlider.value = MusicVolume
	if (GameStarted):
		$MainMenu/CenterContainer/GridContainer/ButtonPlay.visible = false
		$MainMenu/CenterContainer/GridContainer/ButtonResume.visible = true
		$MainMenu/CenterContainer/GridContainer/ButtonRestart.visible = true
	get_tree().paused = true


func UpdateVO():
	if (VOQueue.size()):
		if (TimeSinceLastVO > MIN_TIME_BETWEEN_VO):
			if (CurrentTime >= VOQueue[0].TimeToPlay):
				PlayVONow(VOQueue[0].VOLine)
				VOQueue.remove(0)
	else:
		if (TimeSinceLastVO > TIME_BETWEEN_FILLER_VO && CurrentTime > MusicStopTime):
			PlayFillerVO()


func PlayFillerVO():
	var r := rand_range(0.0, 3.0)
	if (r < 1.0):
		QueueVO("indie_flop", 5.0, 5.0)
	elif (r < 2.0):
		QueueVO("keep_floundering", 5.0, 5.0)
	elif (r < 3.0):
		QueueVO("goop_loop_unintentional", 5.0, 5.0)


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
	TimeSinceLastVO = 0.0
	VOQueue.clear()
	TimeVOPlayed.clear()


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
		QueueVO("goop_loop_end_plug")
		print("You win.  Time:", GameTime)
		Completed = true


func _on_RestartButton_pressed():
	call_deferred("Restart")


func HasPlayedLine(VOLine : String) -> bool:
	return TimeVOPlayed.has(VOLine)


func AddPlayedLine(VOLine : String):
	TimeVOPlayed[VOLine] = OS.get_ticks_msec()


func PlayVONow(VOLine : String):
	if (!HasPlayedLine(VOLine)):
		SubtitleLabel.visible = true
		SubtitleLabel.modulate.a = 1.0
		SubtitleLabel.text = tr(VOLine)
		VOPlayer.stream = load("res://VO/%s.ogg" % VOLine)
		VOPlayer.play()
		VOPlaying = true
		AddPlayedLine(VOLine)


func PlayMusic():
	if (!MusicPlaying):
		MusicPlayer.play(0.0)
		MusicPlaying = true


func QueueVO(VOLine : String, MusicLeadIn := 0.0, TimeBeforeSkip := 3.0):
	if (VOEnabled):
		if (!HasPlayedLine(VOLine)):
			if (MusicLeadIn > 0.0 && !MusicPlaying):
				PlayMusic()
			var TimeToPlay := MusicLeadIn + CurrentTime
			var TimeToSkip := TimeToPlay + TimeBeforeSkip
			for ExistingQueue in VOQueue:
				if ExistingQueue.VOLine == VOLine:
					ExistingQueue.TimeToSkip = TimeToSkip
					return
			var VQD := VOQueueData.new()
			VQD.VOLine = VOLine
			VQD.TimeToPlay = TimeToPlay
			VQD.TimeToSkip = TimeToSkip
			VOQueue.append(VQD)
			MusicStopTime = max(MusicStopTime, CurrentTime + MusicLeadIn)


func _on_StartTrigger_body_entered(_body):
	QueueVO("start_controls1", 5.0, 5.0)
	QueueVO("start_controls2", 1.0, 5.0 + 13.59)
	QueueVO("start_controls3", 1.0, 5.0 + 13.59 + 11.3)
	QueueVO("start_controls4", 1.0, 5.0 + 13.59 + 11.3 + 16.47)
	QueueVO("start_controls5", 1.0, 5.0 + 13.59 + 11.3 + 16.47 + 8)


func _on_VOPlayer_finished():
	VOPlaying = false


func _on_HardTrigger_body_entered(_body):
	QueueVO("multiple_ways", 5.0, 5.0)


func PlayOrResume():
	$MainMenu.visible = false
	get_tree().paused = false
	GameStarted = true


func _on_ButtonPlay_pressed():
	PlayOrResume()


func _on_ButtonRestart_pressed():
	PlayOrResume()
	call_deferred("Restart")


func _on_ButtonResume_pressed():
	PlayOrResume()


func StopVO():
	$VOPlayer.stop()
	VOQueue.clear()


func _on_NarrationCheckbox_toggled(button_pressed):
	VOEnabled = button_pressed
	if (!VOEnabled):
		StopVO()
