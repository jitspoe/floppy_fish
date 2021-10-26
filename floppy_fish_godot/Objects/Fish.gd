extends Spatial

const MOTOR_SPEED := 50 #34 is decent for a 180 flip, but not strong enough for much height.
const TAIL_SWIM_FACTOR := 0.25
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
	var MotorVelocity := 0.0
	if Input.is_action_pressed("flop_left"):
		MotorEnabled = true
		MotorVelocity -= MOTOR_SPEED
	if Input.is_action_pressed("flop_right"):
		MotorEnabled = true
		MotorVelocity += MOTOR_SPEED
	HingeTail1.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeTail1.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorVelocity)
	HingeTail2.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeTail2.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorVelocity)
	HingeTail3.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeTail3.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorVelocity)
	HingeHead.set_flag(HingeJoint.FLAG_ENABLE_MOTOR, MotorEnabled)
	HingeHead.set_param(HingeJoint.PARAM_MOTOR_TARGET_VELOCITY, MotorVelocity)
	AverageLocation = (FishHead.global_transform.origin + FishMid.global_transform.origin + FishTail1.global_transform.origin + FishTail2.global_transform.origin + FishTail3.global_transform.origin) / 5.0
	var AngleBetweenTails := FishTail3.global_transform.basis.x.angle_to(FishTail4.global_transform.basis.x)
	AngleBetweenTails += FishTail2.global_transform.basis.x.angle_to(FishTail3.global_transform.basis.x)
	AngleBetweenTails += FishTail1.global_transform.basis.x.angle_to(FishTail2.global_transform.basis.x)
	var AngleDiff := abs(AngleBetweenTails - PreviousAngleBetweenTails)
	PreviousAngleBetweenTails = AngleBetweenTails
	FishMid.apply_central_impulse(FishMid.global_transform.basis.x * AngleDiff * TAIL_SWIM_FACTOR)

