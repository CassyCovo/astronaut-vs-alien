extends CharacterBody2D

@export var speed := 200.0
@export var gravity := 1400.0
@export var jump_velocity := -600.0

@export var max_jumps := 2
var jumps_left := 2
var did_double_jump := false

@export var idle_texture: Texture2D
@export var jump_texture: Texture2D
@export var double_jump_texture: Texture2D
@export var attack_texture: Texture2D
@export var block_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

# ----------------------------
# HEALTH
# ----------------------------
@export var max_hp: int = 100
var hp: int
signal hp_changed(current_hp: int)

@export var regen_delay := 3.0
@export var regen_amount := 2
@export var regen_interval := 0.25
var time_since_last_hit := 0.0
var regen_tick_timer := 0.0

# ----------------------------
# ATTACK
# ----------------------------
@export var attack_damage := 10
@export var attack_duration := 0.2
@export var attack_cooldown := 0.8

# ----------------------------
# BLOCK (RANDOM)
# ----------------------------
@export var block_duration := 0.35
@export var block_cooldown := 0.8
@export_range(0.0, 1.0, 0.05) var block_chance := 0.5

# ----------------------------
# MOVEMENT
# ----------------------------
@export var stop_distance := 60.0
@export var face_buffer := 20.0

var is_blocking := false
var can_block := true

var target: Node2D = null
var is_attacking := false
var can_attack := true
var hit_applied := false

@onready var attack_hitbox: Area2D = $AttackHitbox


func _ready() -> void:
	hp = max_hp
	hp_changed.emit(hp)
	jumps_left = max_jumps

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false

	print("Alien ready. HP:", str(hp) + "/" + str(max_hp))


func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		jumps_left = max_jumps
		did_double_jump = false

	# safety: if target got deleted
	if target != null and not is_instance_valid(target):
		target = null

	# always face target, but do not flip when too close/overlapping
	if target != null:
		var dx_face = target.global_position.x - global_position.x

		if dx_face < -face_buffer:
			sprite.flip_h = false
		elif dx_face > face_buffer:
			sprite.flip_h = true

	# freeze while blocking
	if is_blocking:
		velocity.x = 0
		sprite.texture = block_texture
		move_and_slide()
		handle_regen(delta)
		return

	# freeze while attacking
	if is_attacking:
		velocity.x = 0
		sprite.texture = attack_texture
		move_and_slide()
		handle_regen(delta)
		return

	# chase + attack
	if target != null:
		var dx = target.global_position.x - global_position.x
		var distance_x = abs(dx)
		var dir = sign(dx)

		if distance_x > stop_distance:
			velocity.x = dir * speed
		else:
			velocity.x = 0

		if can_attack:
			start_attack()
	else:
		velocity.x = 0

	sprite.texture = idle_texture

	move_and_slide()
	handle_regen(delta)


func handle_regen(delta: float) -> void:
	time_since_last_hit += delta

	if hp >= max_hp:
		return

	if time_since_last_hit < regen_delay:
		return

	regen_tick_timer += delta

	if regen_tick_timer >= regen_interval:
		regen_tick_timer = 0.0
		hp += regen_amount
		hp = min(hp, max_hp)
		hp_changed.emit(hp)
		print("Alien regen HP:", str(hp) + "/" + str(max_hp))


func start_attack() -> void:
	can_attack = false
	is_attacking = true
	hit_applied = false

	attack_hitbox.monitorable = true
	attack_hitbox.monitoring = true

	await get_tree().create_timer(attack_duration).timeout

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func _on_attack_range_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		target = area.get_parent()


func _on_attack_range_area_exited(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent() == target:
			target = null


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if not is_attacking:
		return
	if hit_applied:
		return

	if area.name == "Hurtbox":
		hit_applied = true
		var astronaut = area.get_parent()
		if astronaut and astronaut.has_method("take_damage"):
			print("Alien HIT Astronaut")
			astronaut.take_damage(attack_damage)


func astronaut_is_kicking(astronaut: Node) -> bool:
	return astronaut != null and ("is_kicking" in astronaut) and astronaut.is_kicking == true


func start_block() -> void:
	can_block = false
	is_blocking = true

	await get_tree().create_timer(block_duration).timeout
	is_blocking = false

	await get_tree().create_timer(block_cooldown).timeout
	can_block = true


func take_damage(amount: int) -> void:
	if can_block and target != null and astronaut_is_kicking(target):
		var r := randf()
		if r < block_chance:
			print("Alien BLOCKED")
			start_block()
			return

	time_since_last_hit = 0.0
	regen_tick_timer = 0.0

	print("Astronaut HIT Alien")
	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp)
	print("Alien HP:", str(hp) + "/" + str(max_hp))
