extends Spatial

const MOTOR_SPEED := 50 #34 is decent for a 180 flip, but not strong enough for much height.
const TAIL_SWIM_FACTOR := 0.25
const STICK_DEADZONE_MIN := 0.3
const STICK_DEADZONE_MAX := 0.9
const STICK_ENABLED := true
var MouseAnalogEnabled := true
var MouseDeadzone := 0.3
onready var HingeTail1 : HingeJoint = $HingeTail1
onready var HingeTail2 : HingeJoint = $HingeTail2
onready var HingeTail3 : HingeJoint = $HingeTail3
onready var HingeHead : HingeJoint = $HingeHead
onready var FishHead : RigidBody = $FishHead
onready var FishMid : RigidBody = $FishMid
onready var FishTail1 : RigidBody = $FishTail1
onready var FishTail2 : RigidBody = $FishTail2
onready var FishTail3 : RigidBody = $FishTail3
onready var FishTail4 : RigidBody = $FishTail4
onready var FishHeadAnim : AnimationPlayer = $FishHead/fish_mesh_head/AnimationPlayer
onready var FishMaterial : SpatialMaterial = $FishHead/fish_mesh_head/Armature/Skeleton/Head.get_surface_material(0)
var NonRed := 1.0
const RED_FADE := 0.005


var PreviousAngleBetweenTails := 0.0
var AverageLocation : Vector3

var FishHeadTransform : Transform
var FishMidTransform : Transform
var FishTail1Transform : Transform
var FishTail2Transform : Transform
var FishTail3Transform : Transform
var FishTail4Transform : Transform


func _ready():
	FishHeadTransform = FishHead.global_transform
	FishMidTransform = FishMid.global_transform
	FishTail1Transform = FishTail1.global_transform
	FishTail2Transform = FishTail2.global_transform
	FishTail3Transform = FishTail3.global_transform
	FishTail4Transform = FishTail4.global_transform
# warning-ignore:return_value_discarded
	#connect("tree_exiting", self, "TreeExiting")


func Gasp():
	FishHeadAnim.play("gasp")
	$GaspTimer.start(rand_range(1.0, 3.0))

func Restart():
	FishHead.global_transform = FishHeadTransform
	FishMid.global_transform = FishMidTransform
	FishTail1.global_transform = FishTail1Transform
	FishTail2.global_transform = FishTail2Transform
	FishTail3.global_transform = FishTail3Transform
	FishTail4.global_transform = FishTail4Transform

	FishHead.linear_velocity = Vector3.ZERO
	FishHead.angular_velocity = Vector3.ZERO
	FishMid.linear_velocity = Vector3.ZERO
	FishMid.angular_velocity = Vector3.ZERO
	FishTail1.linear_velocity = Vector3.ZERO
	FishTail1.angular_velocity = Vector3.ZERO
	FishTail2.linear_velocity = Vector3.ZERO
	FishTail2.angular_velocity = Vector3.ZERO
	FishTail3.linear_velocity = Vector3.ZERO
	FishTail3.angular_velocity = Vector3.ZERO
	FishTail4.linear_velocity = Vector3.ZERO
	FishTail4.angular_velocity = Vector3.ZERO


func _physics_process(_delta : float):
	var MotorEnabled := false
	var MotorSpeed := 0.0
	if Input.is_action_pressed("flop_left"):
		MotorEnabled = true
		MotorSpeed -= 1.0
	if Input.is_action_pressed("flop_right"):
		MotorEnabled = true
		MotorSpeed += 1.0
	if (STICK_ENABLED):
		var StickDirX := Input.get_joy_axis(0, JOY_AXIS_2) # Right stick
		var StickDirX2 := Input.get_joy_axis(0, JOY_AXIS_0) # Left stick
		if (abs(StickDirX2) > abs(StickDirX)):
			StickDirX = StickDirX2
		var StickDirX3 := Input.get_joy_axis(0, JOY_AXIS_7) - Input.get_joy_axis(0, JOY_AXIS_6) # Left and right triggers
		if (abs(StickDirX3) > abs(StickDirX)):
			StickDirX = StickDirX3
		if (abs(StickDirX) > STICK_DEADZONE_MIN):
			MotorSpeed = inverse_lerp(STICK_DEADZONE_MIN, STICK_DEADZONE_MAX, abs(StickDirX)) * sign(StickDirX)
			MotorEnabled = true
	if (MouseAnalogEnabled):
		var MousePositionX := get_viewport().get_mouse_position().x
		var HalfWidth := get_viewport().size.x / 2
		var MouseFraction := (MousePositionX - HalfWidth) / HalfWidth
		MouseFraction *= 4.0 # Only use about 1/4 of the screen
		if abs(MouseFraction) > MouseDeadzone:
			MouseFraction = inverse_lerp(MouseDeadzone, 1.0, abs(MouseFraction)) * sign(MouseFraction)
			MotorSpeed += MouseFraction
			MotorEnabled = true
	MotorSpeed = clamp(MotorSpeed, -1.0, 1.0) * MOTOR_SPEED
	HingeTail1.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeTail1.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorSpeed)
	HingeTail2.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeTail2.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorSpeed)
	HingeTail3.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeTail3.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorSpeed)
	HingeHead.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeHead.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorSpeed)
	AverageLocation = (FishHead.global_transform.origin + FishMid.global_transform.origin + FishTail1.global_transform.origin + FishTail2.global_transform.origin + FishTail3.global_transform.origin) / 5.0
	var AngleBetweenTails := FishTail3.global_transform.basis.x.angle_to(FishTail4.global_transform.basis.x)
	AngleBetweenTails += FishTail2.global_transform.basis.x.angle_to(FishTail3.global_transform.basis.x)
	AngleBetweenTails += FishTail1.global_transform.basis.x.angle_to(FishTail2.global_transform.basis.x)
	var AngleDiff := abs(AngleBetweenTails - PreviousAngleBetweenTails)
	PreviousAngleBetweenTails = AngleBetweenTails
	FishMid.apply_central_impulse(FishMid.global_transform.basis.x * AngleDiff * TAIL_SWIM_FACTOR)


func _on_GaspTimer_timeout():
	Gasp()


# Too late.
#func _exit_tree():
#	get_parent().SetFishSaveData(GetSaveData())

#func TreeExiting():
#	get_parent().SetFishSaveData(GetSaveData())


func GetSaveData() -> Dictionary:
	return {
		"HeadTransform" : FishHead.global_transform,
		"MidTransform" : FishMid.global_transform,
		"Tail1Transform" : FishTail1.global_transform,
		"Tail2Transform" : FishTail2.global_transform,
		"Tail3Transform" : FishTail3.global_transform,
		"Tail4Transform" : FishTail4.global_transform
		}


func LoadSaveData(SaveData : Dictionary):
	FishHead.global_transform = SaveData["HeadTransform"]
	FishMid.global_transform = SaveData["MidTransform"]
	FishTail1.global_transform = SaveData["Tail1Transform"]
	FishTail2.global_transform = SaveData["Tail2Transform"]
	FishTail3.global_transform = SaveData["Tail3Transform"]
	FishTail4.global_transform = SaveData["Tail4Transform"]


func TurnRed():
	NonRed = 0.1
	FishMaterial.albedo_color = Color(1.0, NonRed, NonRed, 1.0)


func SlapPlayed(VelocityDiff : float):
	if (VelocityDiff > 1.0):
		if (NonRed < 1.0):
			NonRed += RED_FADE
			FishMaterial.albedo_color = Color(1.0, NonRed, NonRed, 1.0)
