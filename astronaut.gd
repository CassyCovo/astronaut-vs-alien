extends CharacterBody2D

@export var speed := 420.0
@export var gravity := 1400.0
@export var jump_velocity := -600.0

@export var max_jumps := 2
var jumps_left := 2

@export var idle_texture: Texture2D
@export var kick_texture: Texture2D
@export var block_texture: Texture2D
@export var kick_duration := 0.3

@export var max_hp: int = 100
var hp: int
signal hp_changed(current_hp: int)

var is_kicking := false
var hit_applied_this_kick := false

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

	# block (freeze while held)
	if Input.is_action_pressed("block") and not is_kicking:
		velocity.x = 0
		sprite.texture = block_texture
		move_and_slide()
		return

	# kick freeze
	if is_kicking:
		velocity.x = 0
		sprite.texture = kick_texture
		move_and_slide()
		return

	# horizontal
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	# jump (double jump)
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			jumps_left = max_jumps - 1
		elif jumps_left > 0:
			velocity.y = jump_velocity
			jumps_left -= 1

	sprite.texture = idle_texture

	# start kick
	if Input.is_action_just_pressed("kick") and not is_kicking:
		start_kick()

	move_and_slide()


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


# ----------------------------
# ASTRONAUT TAKES DAMAGE
# ----------------------------
func take_damage(amount: int) -> void:
	# If blocking, take NO damage and print
	if Input.is_action_pressed("block") and not is_kicking:
		print("Astronaut BLOCKED")
		return

	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp)
	print("Astronaut HP:", str(hp) + "/" + str(max_hp))


# ----------------------------
# ASTRONAUT HITS ALIEN
# ----------------------------
func _on_kick_hitbox_area_entered(area: Area2D) -> void:
	if not is_kicking:
		return
	if hit_applied_this_kick:
		return

	if area.name == "Hurtbox":
		hit_applied_this_kick = true
		var alien = area.get_parent()
		if alien != null and alien.has_method("take_damage"):
			alien.take_damage(10)  # alien decides whether it blocks and prints
