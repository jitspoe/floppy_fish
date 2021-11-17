extends Spatial

const MIN_TIME_BETWEEN_VO := 1.0
const TIME_BETWEEN_FILLER_VO := 120.0
onready var MainCamera : Camera = $Camera
onready var Fish : Spatial = $Fish
onready var SubtitleLabel : Label = $HUD/Subtitle
onready var VOPlayer : AudioStreamPlayer = $VOPlayer
onready var MusicPlayer : AudioStreamPlayer = $MusicPlayer
onready var BucketSplash : AudioStreamPlayer3D = $PaintBucketTrigger/BucketSplash
onready var Seagull = $mooring1/seagull1
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
const MASTER_BUS := 0
const SOUND_BUS := 1
const VO_BUS := 2
const MUSIC_BUS := 3
const FISH_SAVE_DATA := "user://FishSave.cfg"
const SETTINGS_DATA := "user://Settings.cfg"


class VOQueueData:
	var TimeToPlay := 0.0
	var TimeToSkip := 0.0
	var VOLine : String


func _ready():
	$EndScreen.visible = false
	SubtitleLabel.visible = false
	OS.window_maximized = true
	MusicPlayer.volume_db = linear2db(MusicVolume)
	LoadSettings()
	LoadSaveData()
	OpenMenu()


func _process(delta : float):
	CurrentTime = OS.get_ticks_msec() / 1000.0
	TimeSinceLastVO += delta
	Seagull.LookAtPosition(Fish.AverageLocation)
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
		if (MusicFade <= 0.0):
			MusicPlayer.stop()
			MusicPlaying = false
		else:
			MusicPlayer.volume_db = linear2db(MusicFade * MusicVolume)


func SaveGame():
	# Fish is already removed, so this doesn't work:
	var FishSaveData = $Fish.GetSaveData()
	if (!FishSaveData.empty()):
		var SaveFile := ConfigFile.new()
		SaveFile.set_value("FishData", "FishData", FishSaveData)
		SaveFile.set_value("VOData", "TimeVOPlayed", TimeVOPlayed)
		SaveFile.set_value("GameData", "GameTime", GameTime)
		SaveFile.set_value("GameData", "Completed", Completed)
		var Err := SaveFile.save(FISH_SAVE_DATA)
		if (Err != OK):
			print("Error saving: ", Err)


func LoadSaveData():
	var SaveDataFile := ConfigFile.new()
	if (SaveDataFile.load(FISH_SAVE_DATA) == OK):
		Completed = SaveDataFile.get_value("GameData", "Completed", false)
		if (!Completed):
			var FishData = SaveDataFile.get_value("FishData", "FishData", null)
			if (FishData):
				$Fish.LoadSaveData(FishData)
		TimeVOPlayed = SaveDataFile.get_value("VOData", "TimeVOPlayed", {})
		GameTime = SaveDataFile.get_value("GameData", "GameTime", 0.0)


func QuitRequested():
	if (GameStarted):
		SaveGame()
	SaveSettings()


func LoadSettings():
	var SaveDataFile := ConfigFile.new()
	var Err := SaveDataFile.load(SETTINGS_DATA)
	if (Err == OK):
		SetMasterVolume(SaveDataFile.get_value("Sound", "MasterVolume", MasterVolume))
		SetMusicVolume(SaveDataFile.get_value("Sound", "MusicVolume", MusicVolume))
		SetEffectsVolume(SaveDataFile.get_value("Sound", "EffectsVolume", EffectsVolume))
		VOEnabled = SaveDataFile.get_value("Sound", "VOEnabled", VOEnabled)
		VOOnlyNewLines = SaveDataFile.get_value("Sound", "VOOnlyNewLines", VOOnlyNewLines)
		Fish.MouseAnalogEnabled = SaveDataFile.get_value("Fish", "MouseAnalog", Fish.MouseAnalogEnabled)
	else:
		print("Error loading settings: ", Err)


func SaveSettings():
	var SettingsFile := ConfigFile.new()
	SettingsFile.set_value("Sound", "MasterVolume", MasterVolume)
	SettingsFile.set_value("Sound", "MusicVolume", MusicVolume)
	SettingsFile.set_value("Sound", "EffectsVolume", EffectsVolume)
	SettingsFile.set_value("display", "window/size/fullscreen", OS.window_fullscreen)
	SettingsFile.set_value("Sound", "VOEnabled", VOEnabled)
	SettingsFile.set_value("Sound", "VOOnlyNewLines", VOOnlyNewLines)
	SettingsFile.set_value("Fish", "MouseAnalog", Fish.MouseAnalogEnabled)
	var Err := SettingsFile.save(SETTINGS_DATA)
	if (Err != OK):
		print("Error saving settings: ", Err)


func _notification(what):
	if (what == NOTIFICATION_WM_QUIT_REQUEST):
		QuitRequested()


func ProcessWhilePaused(_delta):
	if (Input.is_action_just_pressed("ui_cancel")):
		if ($MainMenu.visible):
			CloseMenu()
		else:
			OpenMenu()


func OpenMenu():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$MainMenu.visible = true
	$MainMenu/CenterContainer/GridContainer/Fullscreen.pressed = OS.window_fullscreen
	$MainMenu/CenterContainer/GridContainer/GridContainer/MasterVolumeSlider.value = MasterVolume
	$MainMenu/CenterContainer/GridContainer/GridContainer/EffectsVolumeSlider.value = EffectsVolume
	$MainMenu/CenterContainer/GridContainer/GridContainer/MusicVolumeSlider.value = MusicVolume
	$MainMenu/CenterContainer/GridContainer/NarrationCheckbox.pressed = VOEnabled
	$MainMenu/CenterContainer/GridContainer/OnlyPlayNewLines.pressed = VOOnlyNewLines
	$MainMenu/CenterContainer/GridContainer/MouseAnalog.pressed = Fish.MouseAnalogEnabled
	if (GameStarted):
		$MainMenu/CenterContainer/GridContainer/ButtonPlay.visible = false
		$MainMenu/CenterContainer/GridContainer/ButtonResume.visible = true
		$MainMenu/CenterContainer/GridContainer/ButtonResume.grab_focus()
		$MainMenu/CenterContainer/GridContainer/ButtonRestart.visible = true
	else:
		$MainMenu/CenterContainer/GridContainer/ButtonPlay.grab_focus()
	if (OS.get_name() == "HTML5"):
		$MainMenu/CenterContainer/GridContainer/ButtonQuit.visible = false # Don't show quit button in web builds
	get_tree().paused = true


func CloseMenu():
	if (GameStarted):
		$MainMenu.visible = false
		get_tree().paused = false
		SetMouseMode()


func SetMouseMode():
	if (Fish.MouseAnalogEnabled):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
	LostProgressTriggerForwardHit = false
	VOQueue.clear()
	if (!VOOnlyNewLines):
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
	SetMouseMode()
	get_tree().paused = false
	if (Completed && !GameStarted): # Hit play after loading the game after completing it.
		Restart()
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


func _on_MasterVolumeSlider_value_changed(value):
	SetMasterVolume(value)


func SetMasterVolume(value):
	MasterVolume = value
	AudioServer.set_bus_volume_db(MASTER_BUS, linear2db(value))


func _on_EffectsVolumeSlider_value_changed(value):
	SetEffectsVolume(value)


func SetEffectsVolume(value):
	EffectsVolume = value
	AudioServer.set_bus_volume_db(SOUND_BUS, linear2db(value))


func _on_MusicVolumeSlider_value_changed(value):
	SetMusicVolume(value)


func SetMusicVolume(value):
	MusicVolume = value # Fade takes care of this so we don't need to adjust the bus.


func _on_OnlyPlayNewLines_toggled(button_pressed):
	VOOnlyNewLines = button_pressed


func _on_ButtonQuit_pressed():
	QuitRequested()
	get_tree().quit()



func _on_Fullscreen_toggled(button_pressed):
	if (button_pressed):
		OS.window_maximized = true
	OS.window_fullscreen = button_pressed


func _on_PaintBucketTrigger_body_entered(_body):
	Fish.TurnRed()
	if (!BucketSplash.playing):
		var r = rand_range(0.0, 3.0)
		if (r < 1.0):
			BucketSplash.stream = preload("res://Sound/small_splash1.wav")
		elif (r < 2.0):
			BucketSplash.stream = preload("res://Sound/small_splash2.wav")
		elif (r < 3.0):
			BucketSplash.stream = preload("res://Sound/small_splash3.wav")
		BucketSplash.pitch_scale = rand_range(0.9, 1.1)
		BucketSplash.play()
	if (TimeSinceLastVO > 1.0):
		QueueVO("red_herring1", 1.0)
		QueueVO("red_herring2", 1.0)


func _on_MouseAnalog_toggled(button_pressed):
	Fish.MouseAnalogEnabled = button_pressed

var LostProgressTriggerForwardHit := false


func _on_LostProgressTriggerBack_body_entered(_body):
	if (LostProgressTriggerForwardHit):
		QueueVO("lost_progress", 1.0)

func _on_LostProgressTriggerForward_body_entered(_body):
	LostProgressTriggerForwardHit = true
