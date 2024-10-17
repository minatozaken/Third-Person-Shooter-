extends CharacterBody3D

@onready var cam_aim: Node = $cam_aim
@onready var camera_aim = $cam_aim/h/v/camera_aim
@onready var camera_view = $cam_aim/h/v/fp_aim/camera_view
@onready var camera_scope = $cam_aim/h/v/scope/camera_scope
@onready var pistol = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/pistol_attach/pistol
@onready var pistol2 = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/pistol_attach2/pistol
@onready var rifle = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/rifle_attach/rifle
@onready var rifle2 = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/rifle_attach2/rifle
@onready var knife = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/knife_attach/knife
@onready var knife2 = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/knife_attach2/knife
@onready var cam_anim = $CamAnim
@onready var mesh = $mesh
@onready var weapon_fire = [preload("res://sounds/gun_sounds/pistol_fire.mp3"), preload("res://sounds/gun_sounds/rifle_fire.mp3")]
@onready var weapon_reload = [preload("res://sounds/gun_sounds/pistol_load.mp3"), preload("res://sounds/gun_sounds/rifle_reload.mp3")]
@onready var muzzle_flash_pistol = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/pistol_attach/pistol/Muzzleflash
@onready var muzzle_flash_rifle = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/rifle_attach/rifle/Muzzleflash
@onready var gun_barrel_pistol = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/pistol_attach/pistol/raycast
@onready var gun_barrel_rifle = $mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/rifle_attach/rifle/raycast
@onready var controls = $Status/Label6

var direction = Vector3.ZERO
var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var aim_turn = 0
var lerp_speed = 10.0

var movement_speed = 0
var crouch_speed = 0.5
var walk_speed = 1.5
var run_speed = 4.0
var acceleration = 10.0
var angular_acceleration = 3.0
var jump_magnitude = 9.0
var last_velocity = Vector3.ZERO
var crouching_depth = -0.1

var bullet = load("res://scenes/bullet.tscn")
var instance

var state_machine

var pistol_bullets_in_mag = 13
var pistol_bullets_in_mag_max = 13
var pistol_ammo_backup = 50
var pistol_ammo_backup_max = 50

var rifle_bullets_in_mag = 30
var rifle_bullets_in_mag_max = 30
var rifle_ammo_backup_max = 90
var rifle_ammo_backup = 90

@onready var health = $Health/TextureProgressBar
@onready var stamina = $Stamina/TextureProgressBar

var can_regen = false
var time_to_wait = 1.5
var s_timer = 0
var can_start_timer = true

signal player_hit
signal paladin_hit

const HIT_STAGGER = 8.0

var death = 0
var kill = 0

var can_shoot = false

var gravity = 20.0

@export var pause_spawn: bool = false : 
	set(value):
		pause_spawn = value
		if pause_spawn:
			get_tree().paused = true
			$"../pause_spawn".hide()
			$"../pause_spawn2".show()
		else:
			get_tree().paused = false
			$"../pause_spawn".show()
			$"../pause_spawn2".hide()

@export var first_person: bool = false : 
	set(value):
		first_person = value
		if first_person:
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/mesh_0_1.hide()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/head_attach.hide()
			$cam_aim/h/v/fp_aim/camera_view.current = true
			$UI/Crosshair.hide()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
			$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
			$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
			$AnimationTree2.set("parameters/conditions/aim", false)
			$AnimationTree2.set("parameters/conditions/aim_cancel", true)
		else:
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/mesh_0_1.show()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/head_attach.show()
			$cam_aim/h/v/fp_aim/camera_view.current = false
			$UI/Crosshair.hide()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
			$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
			$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
			$AnimationTree2.set("parameters/conditions/aim", false)
			$AnimationTree2.set("parameters/conditions/aim_cancel", true)

@export var crouch: bool = false : 
	set(value):
		crouch = value
		if crouch:
			camera_view.position.y = crouching_depth
			$AnimationTree.set("parameters/sc_transition/transition_request", "crouching")
		else:
			camera_view.position.y = 0.0
			$AnimationTree.set("parameters/sc_transition/transition_request", "standing")

#@export var aim: bool = false : 
#	set(value):
#		aim = value
#		if aim:
#			can_shoot = true
#			$UI/Crosshair.show()
#			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.start()
#			$AnimationTree.set("parameters/aim_transition/transition_request", "aiming")
#			$AnimationTree.set("parameters/gun_transition/transition_request","gun_aim")
#			$AnimationTree2.set("parameters/conditions/aim", true)
#			$AnimationTree2.set("parameters/conditions/aim_cancel", false)
#			$"../android_buttons/UI/fire".show()
#			$"../android_buttons/UI/fire2".show()
#			$"../android_buttons/UI/scope".hide()
#			$"../android_buttons/UI/no_weapon".hide()
#			$"../android_buttons/UI/knife".hide()
#			$"../android_buttons/UI/weapon1".hide()
#			$"../android_buttons/UI/weapon2".hide()
#			$"../android_buttons/UI/fpview".hide()
#			$"../android_buttons/UI/Virtual joystick right".hide()
#		else:
#			can_shoot = false
#			$UI/Crosshair.hide()
#			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
#			$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
#			$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
#			$AnimationTree2.set("parameters/conditions/aim", false)
#			$AnimationTree2.set("parameters/conditions/aim_cancel", true)
#			$"../android_buttons/UI/fire".hide()
#			$"../android_buttons/UI/fire2".hide()
#			$"../android_buttons/UI/scope".show()
#			$"../android_buttons/UI/no_weapon".show()
#			$"../android_buttons/UI/knife".show()
#			$"../android_buttons/UI/weapon1".show()
#			$"../android_buttons/UI/weapon2".show()
#			$"../android_buttons/UI/fpview".show()
#			$"../android_buttons/UI/Virtual joystick right".show()

@export var melee: bool = false : 
	set(value):
		melee = value
		if melee:
			$AnimationTree.set("parameters/gun_out/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			$AnimationTree.set("parameters/mk_blend/blend_amount", 0)
			$AnimationTree.set("parameters/mw_blend/blend_amount", 0)
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/left_hand.stop()
			pistol.hide()
			knife2.show()
			rifle.hide()
			knife.hide()
			pistol2.show()
			rifle2.show()
			$"UI/Pistol Mag/Mag".hide()
			$"UI/Rifle Mag/Mag".hide()
			$UI/Knife/Knife_Icon.hide()
			$"UI/Pistol Mag/Pistol_Icon".hide()
			$"UI/Rifle Mag/Rifle_Icon".hide()
			$UI/Crosshair.hide()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
			$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
			$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
			$AnimationTree2.set("parameters/conditions/aim", false)
			$AnimationTree2.set("parameters/conditions/aim_cancel", true)
#		$"../android_buttons/UI/knife_attack".hide()
#		$"../android_buttons/UI/fire".hide()
#		$"../android_buttons/UI/fire2".hide()
#		$"../android_buttons/UI/aim".hide()
#		$"../android_buttons/UI/scope".hide()
#		$"../android_buttons/UI/reload".hide()
#		$"../android_buttons/UI/no_weapon".hide()
#		$"../android_buttons/UI/knife".show()
#		$"../android_buttons/UI/weapon1".show()
#		$"../android_buttons/UI/weapon2".show()

@export var knife_weapon: bool = false : 
	set(value):
		knife_weapon = value
		if knife_weapon:
			$AnimationTree.set("parameters/mk_blend/blend_amount", 1)
			$AnimationTree.set("parameters/mw_blend/blend_amount", 0)
			$AnimationTree.set("parameters/knife_transition/transition_request", "knife_idle_attack")
			$AnimationTree.set("parameters/knife_in/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/left_hand.stop()
			$knife_in.play()
			knife.show()
			knife2.hide()
			pistol.hide()
			rifle.hide()
			pistol2.show()
			rifle2.show()
			$"UI/Pistol Mag/Mag".hide()
			$"UI/Rifle Mag/Mag".hide()
			$UI/Knife/Knife_Icon.show()
			$"UI/Pistol Mag/Pistol_Icon".hide()
			$"UI/Rifle Mag/Rifle_Icon".hide()
			$UI/Crosshair.hide()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
			$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
			$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
			$AnimationTree2.set("parameters/conditions/aim", false)
			$AnimationTree2.set("parameters/conditions/aim_cancel", true)
#		$"../android_buttons/UI/knife_attack".show()
#		$"../android_buttons/UI/fire".hide()
#		$"../android_buttons/UI/fire2".hide()
#		$"../android_buttons/UI/aim".hide()
#		$"../android_buttons/UI/scope".hide()
#		$"../android_buttons/UI/reload".hide()
#		$"../android_buttons/UI/no_weapon".show()
#		$"../android_buttons/UI/knife".hide()
#		$"../android_buttons/UI/weapon1".show()
#		$"../android_buttons/UI/weapon2".show()

@export var weapon_1: bool = false : 
	set(value):
		weapon_1 = value
		if weapon_1:
			$AnimationTree.set("parameters/kg_transition/transition_request", "gun_in")
			$AnimationTree.set("parameters/mk_blend/blend_amount", 0)
			$AnimationTree.set("parameters/gun_blend 2/blend_position", 0)
			$AnimationTree.set("parameters/idle_blend/blend_amount", 0)
			$AnimationTree.set("parameters/mw_blend/blend_amount", 1)
			$AnimationTree.set("parameters/gun_in/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/left_hand.stop()
			$pistol_load.play()
			knife.hide()
			knife2.show()
			pistol.show()
			rifle.hide()
			pistol2.hide()
			rifle2.show()
			$"UI/Pistol Mag/Mag".show()
			$"UI/Rifle Mag/Mag".hide()
			$UI/Knife/Knife_Icon.hide()
			$"UI/Pistol Mag/Pistol_Icon".show()
			$"UI/Rifle Mag/Rifle_Icon".hide()
			$UI/Crosshair.hide()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
			$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
			$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
			$AnimationTree2.set("parameters/conditions/aim", false)
			$AnimationTree2.set("parameters/conditions/aim_cancel", true)
#		$"../android_buttons/UI/knife_attack".hide()
#		$"../android_buttons/UI/fire".hide()
#		$"../android_buttons/UI/fire2".hide()
#		$"../android_buttons/UI/aim".show()
#		$"../android_buttons/UI/scope".hide()
#		$"../android_buttons/UI/reload".show()
#		$"../android_buttons/UI/no_weapon".show()
#		$"../android_buttons/UI/knife".show()
#		$"../android_buttons/UI/weapon1".hide()
#		$"../android_buttons/UI/weapon2".show()

@export var weapon_2: bool = false : 
	set(value):
		weapon_2 = value
		if weapon_2:
			$AnimationTree.set("parameters/kg_transition/transition_request", "gun_in")
			$AnimationTree.set("parameters/gun_blend 2/blend_position", 1)
			$AnimationTree.set("parameters/idle_blend/blend_amount", 1)
			$AnimationTree.set("parameters/mw_blend/blend_amount", 1)
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/left_hand.start()
			$AnimationTree.set("parameters/gun_in/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			$rifle_load.play()
			knife.hide()
			knife2.show()
			pistol.hide()
			rifle.show()
			pistol2.show()
			rifle2.hide()
			$"UI/Pistol Mag/Mag".hide()
			$"UI/Rifle Mag/Mag".show()
			$UI/Knife/Knife_Icon.hide()
			$"UI/Pistol Mag/Pistol_Icon".hide()
			$"UI/Rifle Mag/Rifle_Icon".show()
			$UI/Crosshair.hide()
			$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
			$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
			$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
			$AnimationTree2.set("parameters/conditions/aim", false)
			$AnimationTree2.set("parameters/conditions/aim_cancel", true)
#		$"../android_buttons/UI/knife_attack".hide()
#		$"../android_buttons/UI/fire".hide()
#		$"../android_buttons/UI/fire2".hide()
#		$"../android_buttons/UI/aim".show()
#		$"../android_buttons/UI/scope".show()
#		$"../android_buttons/UI/reload".show()
#		$"../android_buttons/UI/no_weapon".show()
#		$"../android_buttons/UI/knife".show()
#		$"../android_buttons/UI/weapon1".show()
#		$"../android_buttons/UI/weapon2".hide()

func _ready():
	state_machine = $AnimationTree2.get("parameters/playback")
	stamina.value = stamina.max_value
	health.value = health.max_value
	
func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015
	
	if event is InputEventKey:
		if event.as_text() == "W" || event.as_text() == "S" || event.as_text() == "A" || event.as_text() == "D" || event.as_text() == "Space" || event.as_text() == "Shift" || event.as_text() == "1" || event.as_text() == "2" || event.as_text() == "3" || event.as_text() == "Ctrl" || event.as_text() == "R" || event.as_text() == "Q" || event.as_text() == "F" || event.as_text() == "G":
			if event.pressed:
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")

func _process(delta):
	
	$Status/Label7.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if can_regen == false && stamina.value != 100 or stamina.value == 0:
		can_start_timer = true
		if can_start_timer:
			s_timer += delta
			if s_timer >= time_to_wait:
				can_regen = true
				can_start_timer = false
				s_timer = 0
	if stamina.value == 100:
		can_regen == false
	if can_regen == true:
		stamina.value += 5.0
		can_start_timer = false
		s_timer = 0

func _physics_process(delta):
	
	var h_rot = $cam_aim/h.global_transform.basis.get_euler().y
	
	if Input.is_action_just_pressed("pause_spawn"):
		pause_spawn = ! pause_spawn

#	if Input.is_action_just_pressed("aim"):
#		aim = ! aim

	if Input.is_action_just_pressed("fpview"):
		first_person = ! first_person

	if Input.is_action_just_pressed("scope") && Input.is_action_pressed("aim") && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 1:
		$UI/Crosshair.show()
		$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.start()
		$AnimationTree.set("parameters/aim_transition/transition_request", "aiming")
		$AnimationTree.set("parameters/gun_transition/transition_request","gun_aim")
		camera_scope.current = true
		$cam_aim/h/v/scope/Control/TextureRect.show()
#			$"../android_buttons/UI/scope".show()
#			$"../android_buttons/UI/fpview".hide()
#			$"../android_buttons/UI/aim".hide()
#			$"../android_buttons/UI/fire".show()
#			$"../android_buttons/UI/fire2".show()
#			$"../android_buttons/UI/no_weapon".hide()
#			$"../android_buttons/UI/knife".hide()
#			$"../android_buttons/UI/weapon1".hide()
#			$"../android_buttons/UI/weapon2".hide()
#			$"../android_buttons/UI/Virtual joystick right".hide()
	elif Input.is_action_just_released("scope") && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 1:
		$UI/Crosshair.hide()
		$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/mesh_0_1.hide()
		$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/head_attach.hide()
		$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
		$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
		$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
		camera_view.current = true
		$cam_aim/h/v/scope/Control/TextureRect.hide()
#			$"../android_buttons/UI/fpview".show()
#			$"../android_buttons/UI/aim".show()
#			$"../android_buttons/UI/fire".hide()
#			$"../android_buttons/UI/fire2".hide()
#			$"../android_buttons/UI/no_weapon".show()
#			$"../android_buttons/UI/knife".show()
#			$"../android_buttons/UI/weapon1".show()
#			$"../android_buttons/UI/weapon2".hide()
#			$"../android_buttons/UI/Virtual joystick right".show()

	if Input.is_action_just_pressed("crouch"):
		crouch = ! crouch 
	elif Input.is_action_pressed("forward") || Input.is_action_pressed("backward") || Input.is_action_pressed("left") || Input.is_action_pressed("right"):
		$AnimationTree.set("parameters/cw_blend/blend_amount", 1)
		movement_speed = crouch_speed
	else:
		$AnimationTree.set("parameters/cw_blend/blend_amount", 0)
		movement_speed = 0

	if Input.is_action_just_pressed("melee") && !Input.is_action_pressed("scope"):
		melee = ! melee
	
	if Input.is_action_just_pressed("knife") && !Input.is_action_pressed("scope"):
		knife_weapon = ! knife_weapon

		
	if Input.is_action_just_pressed("weapon1") && !Input.is_action_pressed("scope"):
		weapon_1 = ! weapon_1

		
	if Input.is_action_just_pressed("weapon2" )&& !Input.is_action_pressed("scope"):
		weapon_2 = ! weapon_2

	if Input.is_action_pressed("reload") && pistol_bullets_in_mag <= 12 && pistol_ammo_backup && !$AnimationTree.get("parameters/mw_blend/blend_amount") == 0 && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 0:
		if $shoot_timer.is_stopped() && !$AnimationTree.get("parameters/reload/active"):
			$shoot_timer.start()
			$AnimationTree.set("parameters/reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			$rifle_reload.play()
			var empty = pistol_bullets_in_mag_max - pistol_bullets_in_mag
			pistol_bullets_in_mag += min(empty, pistol_ammo_backup)
			pistol_ammo_backup -= min(empty, pistol_ammo_backup)
			$"UI/Pistol Mag/Mag/Mag2/Current Ammo".text = str(pistol_bullets_in_mag)
			$"UI/Pistol Mag/Mag/Mag2/Backup Ammo".text = str(pistol_ammo_backup)
			if !$reloading.playing:
				$reloading.play()
	if Input.is_action_pressed("reload") && rifle_bullets_in_mag <= 29 && rifle_ammo_backup && !$AnimationTree.get("parameters/mw_blend/blend_amount") == 0 && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 1:
		$cam_aim/h/v/fp_aim/camera_view.current = true
		$cam_aim/h/v/scope/Control/TextureRect.hide()
		if $shoot_timer.is_stopped() && !$AnimationTree.get("parameters/reload/active"):
			$shoot_timer.start()
			$AnimationTree.set("parameters/reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			$rifle_reload.play()
			var empty = rifle_bullets_in_mag_max - rifle_bullets_in_mag
			rifle_bullets_in_mag += min(empty, rifle_ammo_backup)
			rifle_ammo_backup -= min(empty, rifle_ammo_backup)
			$"UI/Rifle Mag/Mag/Mag2/Current Ammo".text = str(rifle_bullets_in_mag)
			$"UI/Rifle Mag/Mag/Mag2/Backup Ammo".text = str(rifle_ammo_backup)
			if !$reloading.playing:
				$reloading.play()
	
	if Input.is_action_pressed("aim") || Input.is_action_pressed("fire") || !$aim_stay_delay.is_stopped() && !$AnimationTree.get("parameters/mw_blend/blend_amount") == 0:
		$UI/Crosshair.show()
		if Input.is_action_pressed("fire") && pistol_bullets_in_mag && !$AnimationTree.get("parameters/mw_blend/blend_amount") == 0 && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 0:
			$aim_stay_delay.start()
			if $shoot_timer.is_stopped() && !$AnimationTree.get("parameters/gun_in/active") && !$AnimationTree.get("parameters/reload/active"):
				muzzle_flash_pistol.restart()
				muzzle_flash_pistol.emitting = true
				instance = bullet.instantiate()
				instance.position = gun_barrel_pistol.global_position
				instance.transform.basis = gun_barrel_pistol.global_transform.basis
				get_parent().add_child(instance)
				$shoot_timer.start()
				$pistol_fire_fx.play()
				pistol_bullets_in_mag -= 1
				$"UI/Pistol Mag/Mag/Mag2/Current Ammo".text = str(pistol_bullets_in_mag)
				$Status/Fire.color = Color("ff6666")
			else:
				$Status/Fire.color = Color("ffffff")
		elif not pistol_bullets_in_mag && pistol_ammo_backup && !$AnimationTree.get("parameters/mw_blend/blend_amount") == 0 && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 0:
			if $shoot_timer.is_stopped() && !$AnimationTree.get("parameters/reload/active"):
				$shoot_timer.start()
				$AnimationTree.set("parameters/reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				$rifle_reload.play()
				var empty = pistol_bullets_in_mag_max - pistol_bullets_in_mag
				pistol_bullets_in_mag += min(empty, pistol_ammo_backup)
				pistol_ammo_backup -= min(empty, pistol_ammo_backup)
				$"UI/Pistol Mag/Mag/Mag2/Current Ammo".text = str(pistol_bullets_in_mag)
				$"UI/Pistol Mag/Mag/Mag2/Backup Ammo".text = str(pistol_ammo_backup)
				if !$reloading.playing:
					$reloading.play()
				
		if Input.is_action_pressed("fire") && rifle_bullets_in_mag && !$AnimationTree.get("parameters/mw_blend/blend_amount") == 0 && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 1:
			$aim_stay_delay.start()
			if $shoot_timer.is_stopped() && !$AnimationTree.get("parameters/gun_in/active") && !$AnimationTree.get("parameters/reload/active"):
				muzzle_flash_rifle.restart()
				muzzle_flash_rifle.emitting = true
				instance = bullet.instantiate()
				instance.position = gun_barrel_rifle.global_position
				instance.transform.basis = gun_barrel_rifle.global_transform.basis
				get_parent().add_child(instance)
				$shoot_timer.start()
				$rifle_fire_fx.play()
				rifle_bullets_in_mag -= 1
				$"UI/Rifle Mag/Mag/Mag2/Current Ammo".text = str(rifle_bullets_in_mag)
				$Status/Fire.color = Color("ff6666")
			else:
				$Status/Fire.color = Color("ffffff")
		elif not rifle_bullets_in_mag && rifle_ammo_backup && !$AnimationTree.get("parameters/mw_blend/blend_amount") == 0 && $AnimationTree.get("parameters/gun_blend 2/blend_position") == 1:
			if $shoot_timer.is_stopped() && !$AnimationTree.get("parameters/reload/active"):
				$shoot_timer.start()
				$AnimationTree.set("parameters/reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				$rifle_reload.play()
				var empty = rifle_bullets_in_mag_max - rifle_bullets_in_mag
				rifle_bullets_in_mag += min(empty, rifle_ammo_backup)
				rifle_ammo_backup -= min(empty, rifle_ammo_backup)
				$"UI/Rifle Mag/Mag/Mag2/Current Ammo".text = str(rifle_bullets_in_mag)
				$"UI/Rifle Mag/Mag/Mag2/Backup Ammo".text = str(rifle_ammo_backup)
				if !$reloading.playing:
					$reloading.play()
#		$mesh/soldier.rotation.y = lerp_angle($mesh/soldier.rotation.y, h_rot, delta * angular_acceleration)
		$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.start()
		$AnimationTree.set("parameters/aim_transition/transition_request", "aiming")
		$AnimationTree.set("parameters/gun_transition/transition_request","gun_aim")
		$AnimationTree2.set("parameters/conditions/aim", true)
		$AnimationTree2.set("parameters/conditions/aim_cancel", false)
		
		if Input.is_action_pressed("fire") && $AnimationTree.get("parameters/mk_blend/blend_amount") == 1:
			$AnimationTree2.set("parameters/conditions/aim", false)
			$AnimationTree2.set("parameters/conditions/aim_cancel", false)
			if $shoot_timer.is_stopped() && !$AnimationTree.get("parameters/knife_in/active") && !$AnimationTree.get("parameters/slash/active"):
				$shoot_timer.start()
				$AnimationTree.set("parameters/knife_transition/transition_request", "knife_idle_attack")
				$AnimationTree.set("parameters/slash/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				$knife_slash.play()
	
#		$Status/Aim.color = Color("ff6666")

	else:
		$UI/Crosshair.hide()
		$mesh/soldier.rotation.y = lerp_angle($mesh/soldier.rotation.y, atan2(direction.x, direction.z), delta * angular_acceleration)
		$mesh/soldier/AuxScene8/AuxScene7/AuxScene6/AuxScene5/AuxScene4/AuxScene3/AuxScene2/Node2/Skeleton3D/spine_ik.stop()
		$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
		$AnimationTree.set("parameters/gun_transition/transition_request","gun_idle")
		$AnimationTree2.set("parameters/conditions/aim", false)
		$AnimationTree2.set("parameters/conditions/aim_cancel", true)
#		$Status/Aim.color = Color("ffffff")
	
	if Input.is_action_pressed("forward") || Input.is_action_pressed("backward") || Input.is_action_pressed("left") || Input.is_action_pressed("right"):
		
		direction = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
					0,
					Input.get_action_strength("forward") - Input.get_action_strength("backward"))
		
		strafe_dir = direction
		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
	
		if Input.is_action_pressed("run") && stamina.value:
			movement_speed = run_speed
#			$AnimationTree.set("parameters/iwr_blend/blend_amount", 1)
			stamina.value -= 2
			can_regen = false
			s_timer = 0
			$walk.stop()
			if is_on_floor() and !$run.playing:
				$run.play()
		else:
			movement_speed = walk_speed
#			$AnimationTree.set("parameters/iwr_blend/blend_amount", 0)
			$run.stop()
			if is_on_floor() and  !$walk.playing:
				$walk.play()
	else:
#		$AnimationTree.set("parameters/iwr_blend/blend_amount", -1)
		movement_speed = 0
		strafe_dir = Vector3.ZERO
		$walk.stop()
		$run.stop()
		
		if $AnimationTree.get("parameters/aim_transition/transition_request") == "aiming":
			direction = $cam_aim/h.global_transform.basis.z
	
	if !is_on_floor():
		velocity.y -= gravity * delta
	
	if !is_on_floor():
		if last_velocity.y <= -1.0:
			$AnimationTree.set("parameters/jl_transition/transition_request", "landed")
			$walk.stop()
			$run.stop()
	
	if !is_on_floor():
		if last_velocity.y <= -7.0:
			health.value -= 1000
			if !$death.playing:
				$death.play()
				$hit_react.stop()
			$AnimationTree.set("parameters/ad_transition/transition_request", "dead")
			movement_speed = 0
			await get_tree().create_timer(1.0).timeout
			health.value += 1000
			position = Vector3(0, 9, -110)
			$AnimationTree.set("parameters/ad_transition/transition_request", "alive")
	
	if !Input.is_action_pressed("aim") || Input.is_action_pressed("fire"):
		if Input.is_action_just_pressed("jump") and is_on_floor():
			if $switch_timer.is_stopped():
				$switch_timer.start()
				$AnimationTree.set("parameters/ag_transition/transition_request", "on_air")
				$AnimationTree.set("parameters/jl_transition/transition_request", "jump")
				velocity.y = jump_magnitude
		elif !Input.is_action_just_pressed("jump") and is_on_floor():
			$AnimationTree.set("parameters/ag_transition/transition_request", "on_ground")
		else:
			$jump.play()
	else:
		$AnimationTree.set("parameters/ag_transition/transition_request", "on_ground")
		
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)
	
	last_velocity = velocity;
	
	move_and_slide()
	
#	if $AnimationTree.get("parameters/aim_transition/transition_request") == "not_aiming":
#		$mesh/soldier.rotation.y = lerp_angle($mesh/soldier.rotation.y, atan2(direction.x, direction.z), delta * angular_acceleration)
#	else:
#		$mesh/soldier.rotation.y = lerp_angle($mesh/soldier.rotation.y, h_rot, delta * angular_acceleration)
	
	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
	
	$AnimationTree.set("parameters/strafe/blend_position", Vector2(strafe.x, strafe.z))
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)
	
	if velocity.length() <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount", iw_blend)
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount", wr_blend)

	aim_turn = 0

func hit(dir):
	health.value -= 100
	emit_signal("player_hit")
	if !$hit_react.playing:
		$hit_react.play()
		$death.stop()
	$AnimationTree.set("parameters/hit_react/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	velocity += dir * HIT_STAGGER
	if health.value <= 0:
		if !$death.playing:
			$death.play()
			$hit_react.stop()
			death += 1
		$AnimationTree.set("parameters/ad_transition/transition_request", "dead")
		movement_speed = 0
		await get_tree().create_timer(1.0).timeout
		health.value += 1000
		position = Vector3(0, 9, -110)
		$AnimationTree.set("parameters/ad_transition/transition_request", "alive")
