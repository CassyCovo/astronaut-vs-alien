extends CharacterBody2D

@export var speed := 200.0
@export var gravity := 1400.0
@export var attack_distance := 120.0

@export var start_delay := 3.0
@export var wait_time_min := 1.0
@export var wait_time_max := 3.0

@export var attack_damage := 10
@export var attack_duration := 0.25
@export var attack_cooldown := 0.8

@export var idle_texture: Texture2D
@export var attack_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox

var astronaut : Node2D
var can_chase := false
var is_attacking := false
var can_attack := true


func _ready():

	randomize()

	# find astronaut automatically
	astronaut = get_tree().get_first_node_in_group("astronaut")

	attack_hitbox.monitoring = false

	start_ai_loop()


func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if astronaut == null:
		move_and_slide()
		return


	var dx = astronaut.global_position.x - global_position.x
	var distance = abs(dx)
	var dir = sign(dx)

	# face astronaut
	sprite.flip_h = dir > 0

	# movement
	if can_chase and distance > attack_distance:
		velocity.x = dir * speed
	else:
		velocity.x = 0

	move_and_slide()


func start_ai_loop():

	await get_tree().create_timer(start_delay).timeout

	while true:

		# start chasing
		can_chase = true

		# wait until close
		while astronaut != null:
			var d = abs(astronaut.global_position.x - global_position.x)

			if d <= attack_distance:
				break

			await get_tree().process_frame

		can_chase = false

		if can_attack:
			await start_attack()

		var wait_time = randf_range(wait_time_min, wait_time_max)
		await get_tree().create_timer(wait_time).timeout


func start_attack():

	can_attack = false
	is_attacking = true

	if attack_texture:
		sprite.texture = attack_texture

	attack_hitbox.monitoring = true

	await get_tree().create_timer(attack_duration).timeout

	attack_hitbox.monitoring = false
	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout

	can_attack = true


func _on_attack_hitbox_area_entered(area):

	if not is_attacking:
		return

	if area.name == "Hurtbox":

		var astronaut = area.get_parent()

		if astronaut.has_method("take_damage"):
			print("Alien HIT Astronaut")
			astronaut.take_damage(attack_damage)
