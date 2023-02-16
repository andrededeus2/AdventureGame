extends KinematicBody

onready var espada = $FEHSKEL/Skeleton/espada

#LIFE==========================================================================
onready var hp_bar = get_node("../Interface/Bars/LifeBar/TextureProgress")

var max_hp = 400
var current_hp
var damage = 20
var percentage_hp
#LIFE==========================================================================

#HEAL===========================================================================
var heal = max_hp
#HEAL===========================================================================

var direction = Vector3.FORWARD
var velocity = Vector3.ZERO

var vertical_velocity = 0
var gravity = 28

var weight_on_ground = 4

var movement_speed = 0
var walk_speed = 1
var run_speed = 4
var acceleration = 5 
var angular_acceleration = 6

var jump_magnitude = 9

var ag_transition = "parameters/ag_transition/current"
var ag_weapon_transition = "parameters/ag_weapon_transition/current"
var cs_transition = "parameters/cs_transition/current"
#var ir_rifle_blend = "parameters/ir_rifle_blend/blend_amount"
var iwr_blend = "parameters/iwr_blend/blend_amount"
var jump_blend = "parameters/jump_blend/blend_position"
var walk_blendspace = "parameters/walk/blend_position"
var weapon_blend = "parameters/weapon_blend/blend_amount"

var weapon_blend_target = 1
var idle_weapon = 1
	

#LIFEBAR========================================================================
func _ready():
	current_hp = max_hp
	
func OnHit(_damage):
	current_hp -= damage
	LifeBarUpdate()
	if current_hp <= 0:
		OnDeath()
		
#HEAL===========================================================================
func OnHeal(heal_amount):
	current_hp += heal_amount
	if current_hp >= max_hp:
		current_hp = max_hp
	LifeBarUpdate()
#HEAL===========================================================================
		
		
func LifeBarUpdate():
	percentage_hp = int((float(current_hp) / max_hp) * 100) 
	hp_bar.value = percentage_hp
	if percentage_hp >= 60:
		hp_bar.set_tint_progress("14e114")#verde
	elif percentage_hp <= 60 and percentage_hp >=25:
		hp_bar.set_tint_progress("e1be32")#laranja
	else:
		hp_bar.set_tint_progress("e11e1e")#vermelho
	
func OnDeath():
	get_tree().change_scene("res://GameOver.tscn")
#LIFEBAR========================================================================
	
func _input(event):
	
	if event is InputEventKey:
		if event.as_text() == "W" || event.as_text() == "A" || event.as_text() == "S" || event.as_text() == "D" || event.as_text() == "Space" || event.as_text() == "Kp_3" || event.as_text() == "3":
			if event.pressed:
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")
	
	#============================================================
	
	if event.is_action_pressed("holster"):
		weapon_blend_target = 1 - weapon_blend_target
		espada.set("visible", !espada.get("visible"))
		
	if event.is_action_pressed("crouch"):
		idle_weapon = 1 - idle_weapon
		$AnimationTree.set(ag_transition, idle_weapon)
	
	#============================================================
	
func _physics_process(delta):
	
	if Input.is_action_pressed("forward") || Input.is_action_pressed("backward") || Input.is_action_pressed("left") || Input.is_action_pressed("right"):
		
		var h_rot = $Camroot/h.global_transform.basis.get_euler().y
		
		direction = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
		0,
		Input.get_action_strength("forward") - Input.get_action_strength("backward")).rotated(Vector3.UP, h_rot).normalized()
		
		if Input.is_action_pressed("sprint"):
			movement_speed = run_speed
		else:
			movement_speed = walk_speed
	else:
		movement_speed = 0
	
	
	if is_on_floor():
		
		$AnimationTree.set(ag_transition, 1)
		
		if Input.is_action_just_pressed("jump"):
			vertical_velocity = jump_magnitude
			$Soundjump.play()
	else:
		$AnimationTree.set(ag_transition, 0)
		
		$AnimationTree.set(jump_blend, lerp($AnimationTree.get(jump_blend), vertical_velocity/jump_magnitude, delta * 10))
	
	
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)
	
	move_and_slide(velocity + Vector3.UP * vertical_velocity - get_floor_normal() * weight_on_ground, Vector3.UP)
	
	if !is_on_floor():
		
		vertical_velocity -= gravity * delta
	else:
		vertical_velocity = 0
		
		$FEHSKEL/Skeleton.rotation.y = lerp_angle($FEHSKEL/Skeleton.rotation.y, atan2(direction.x, direction.z), delta * angular_acceleration)
	
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)
	
	if velocity.length() <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , iw_blend)
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , wr_blend)
	
	#==========================================================================
	
		#$AnimationTree.set(weapon_blend, lerp($AnimationTree.get(weapon_blend), weapon_blend_target, delta * 10))
		#$AnimationTree.set(weapon_blend, lerp($AnimationTree.get(weapon_blend), weapon_blend_target, delta * 5))
	
	#==========================================================================
	
	$Status/Space/Label2.text = "direction : " + String(is_on_floor())
	$Status/Space/Label3.text = "direction.length() : " + String(direction.length())
	$Status/Space/Label4.text = "velocity : " + String(velocity)
	$Status/Space/Label5.text = "velocity.length() : " + String(velocity.length())

#DAMAGE========================================================================
func _on_Enemy_body_entered(body):
	if body.is_in_group("Player"):
		body.OnHit(damage)
	$Sounddamage.play()
#DAMAGE========================================================================

#HEAL===========================================================================
func _on_Healer_body_entered(body):
	if body.is_in_group("Player"):
		body.OnHeal(heal)
	$Soundrecover.play()
#HEAL===========================================================================

#PORTAL=========================================================================
func _on_ChangeScene_body_entered(body):
	if body.is_in_group("Player"):
		get_tree().change_scene("res://Cena_05.tscn")

func _on_PassCena03_body_entered(body):
	if body.is_in_group("Player"):
		get_tree().change_scene("res://Cena_02.tscn")
