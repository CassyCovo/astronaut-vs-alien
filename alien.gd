extends CharacterBody2D

signal hp_changed(current_hp: int)
signal defeated

@export var speed := 200.0
@export var gravity := 1400.0
@export var attack_distance := 200.0

@export var start_delay := 3.0
@export var wait_time_min := 1.0
@export var wait_time_max := 3.0

@export var attack_damage := 10
@export var attack_duration := 0.25
@export var attack_cooldown := 0.8

@export var max_hp: int = 100

@export var idle_texture: Texture2D
@export var attack_texture: Texture2D
@export var block_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_range: Area2D = $AttackRange

var astronaut: Node2D
var can_chase := false
var is_attacking := false
var is_blocking := false
var can_attack := true
var hit_applied_this_attack := false
var hp: int


func _ready():
	randomize()

	hp = max_hp
	hp_changed.emit(hp)

	astronaut = get_tree().get_first_node_in_group("astronaut")

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = true

	# TURN OFF AttackRange so the alien stops hitting itself
	attack_range.monitoring = false
	attack_range.monitorable = false

	if idle_texture:
		sprite.texture = idle_texture

	print("Alien ready. HP:" + str(hp) + "/" + str(max_hp))

	start_ai_loop()


func _physics_process(delta):
	if hp <= 0:
		velocity.x = 0
		move_and_slide()
		return

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

	if dir != 0:
		sprite.flip_h = dir > 0

	if can_chase and not is_attacking and not is_blocking and distance > attack_distance:
		velocity.x = dir * speed
	else:
		velocity.x = 0

	move_and_slide()


func start_ai_loop():
	await get_tree().create_timer(start_delay).timeout

	while true:
		if hp <= 0:
			return

		if astronaut == null:
			await get_tree().process_frame
			continue

		can_chase = true

		while astronaut != null:
			if hp <= 0:
				return

			var d = abs(astronaut.global_position.x - global_position.x)

			if d <= attack_distance:
				break

			await get_tree().process_frame

		can_chase = false

		if astronaut != null and can_attack and hp > 0 and not is_blocking:
			var d = abs(astronaut.global_position.x - global_position.x)

			if d <= attack_distance:
				await start_attack()

		var wait_time = randf_range(wait_time_min, wait_time_max)
		await get_tree().create_timer(wait_time).timeout


func start_attack():
	if hp <= 0:
		return

	can_attack = false
	is_attacking = true
	hit_applied_this_attack = false

	print("Alien ATTACK START")

	velocity.x = 0

	if attack_texture:
		sprite.texture = attack_texture

	attack_hitbox.monitoring = true
	print("AttackHitbox ON")

	await get_tree().create_timer(attack_duration).timeout

	attack_hitbox.monitoring = false
	print("AttackHitbox OFF")

	is_attacking = false

	if hp > 0 and idle_texture:
		sprite.texture = idle_texture

	await get_tree().create_timer(attack_cooldown).timeout

	if hp > 0:
		can_attack = true


func take_damage(amount: int):
	if hp <= 0:
		return

	if is_blocking:
		print("Alien BLOCKED")
		return

	hp -= amount
	hp = max(hp, 0)

	print("Alien HP:" + str(hp) + "/" + str(max_hp))
	hp_changed.emit(hp)

	if hp <= 0:
		can_chase = false
		can_attack = false
		is_attacking = false
		is_blocking = false
		attack_hitbox.monitoring = false
		velocity.x = 0

		if idle_texture:
			sprite.texture = idle_texture

		print("Alien defeated")
		defeated.emit()


func _on_attack_hitbox_area_entered(area):
	print("Alien touched area:" + area.name)

	if not is_attacking:
		return

	if hit_applied_this_attack:
		return

	if hp <= 0:
		return

	var target = area.get_parent()

	if target == self:
		return

	if target != null and target.has_method("take_damage"):
		print("Alien HIT:" + target.name)
		target.take_damage(attack_damage)
		hit_applied_this_attack = true
