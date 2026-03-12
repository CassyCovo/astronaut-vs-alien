extends CharacterBody2D

@export var speed := 420.0
@export var gravity := 1400.0
@export var jump_velocity := -600.0

@export var max_jumps := 2
var jumps_left := 2

@export var idle_texture: Texture2D
@export var kick_texture: Texture2D
@export var block_texture: Texture2D
@export var jump_texture: Texture2D
@export var double_jump_texture: Texture2D
@export var kick_duration := 0.3

@export var max_hp: int = 100
var hp: int
signal hp_changed(current_hp: int)

@export var regen_delay := 3.0
@export var regen_amount := 2
@export var regen_interval := 0.25
var time_since_last_hit := 0.0
var regen_tick_timer := 0.0

var is_kicking := false
var hit_applied_this_kick := false
var did_double_jump := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var kick_hitbox: Area2D = $KickHitbox


func _ready() -> void:
	hp = max_hp
	hp_changed.emit(hp)
	jumps_left = max_jumps

	kick_hitbox.monitoring = false
	kick_hitbox.monitorable = false

	print("Astronaut ready. HP:", str(hp) + "/" + str(max_hp))


func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		jumps_left = max_jumps
		did_double_jump = false

	# block (freeze while held)
	if Input.is_action_pressed("block") and not is_kicking:
		velocity.x = 0
		sprite.texture = block_texture
		move_and_slide()
		handle_regen(delta)
		return

	# kick freeze
	if is_kicking:
		velocity.x = 0
		sprite.texture = kick_texture
		move_and_slide()
		handle_regen(delta)
		return

	# horizontal
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	# jump / double jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			jumps_left = max_jumps - 1
			did_double_jump = false
			sprite.texture = jump_texture
		elif jumps_left > 0:
			velocity.y = jump_velocity
			jumps_left -= 1
			did_double_jump = true
			sprite.texture = double_jump_texture

	# choose texture when not blocking/kicking
	if is_on_floor():
		sprite.texture = idle_texture
	elif did_double_jump:
		sprite.texture = double_jump_texture
	else:
		sprite.texture = jump_texture

	# start kick
	if Input.is_action_just_pressed("kick") and not is_kicking:
		start_kick()

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
		print("Astronaut regen HP:", str(hp) + "/" + str(max_hp))


func start_kick() -> void:
	is_kicking = true
	hit_applied_this_kick = false

	sprite.texture = kick_texture
	kick_hitbox.monitorable = true
	kick_hitbox.monitoring = true

	await get_tree().create_timer(kick_duration).timeout

	kick_hitbox.monitoring = false
	kick_hitbox.monitorable = false
	is_kicking = false


func take_damage(amount: int) -> void:
	# If blocking, take NO damage and print
	if Input.is_action_pressed("block") and not is_kicking:
		print("Astronaut BLOCKED")
		return

	time_since_last_hit = 0.0
	regen_tick_timer = 0.0

	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp)
	print("Astronaut HP:", str(hp) + "/" + str(max_hp))


func _on_kick_hitbox_area_entered(area: Area2D) -> void:
	if not is_kicking:
		return
	if hit_applied_this_kick:
		return

	if area.name == "Hurtbox":
		hit_applied_this_kick = true
		var alien = area.get_parent()
		if alien != null and alien.has_method("take_damage"):
			alien.take_damage(10)
