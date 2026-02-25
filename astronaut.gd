extends CharacterBody2D

@export var speed := 420.0
@export var gravity := 1400.0
@export var jump_velocity := -600.0

@export var idle_texture: Texture2D
@export var kick_texture: Texture2D
@export var block_texture: Texture2D
@export var kick_duration := 0.3

# ----------------------------
# HEALTH (NEW)
# ----------------------------
@export var max_hp: int = 100
var hp: int
signal hp_changed(current_hp: int)

var is_kicking := false
var hit_applied_this_kick := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var kick_hitbox: Area2D = $KickHitbox


func _ready() -> void:
	print("Astronaut ready")

	# HEALTH init (NEW)
	hp = max_hp
	hp_changed.emit(hp)

	# Hitbox OFF until we kick
	kick_hitbox.monitoring = false
	kick_hitbox.monitorable = false


func _physics_process(delta: float) -> void:
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# --- BLOCK (only while held) ---
	if Input.is_action_pressed("block") and not is_kicking:
		velocity.x = 0
		sprite.texture = block_texture
		move_and_slide()
		return

	# --- KICK STATE (freeze while kicking) ---
	if is_kicking:
		velocity.x = 0
		sprite.texture = kick_texture
		move_and_slide()
		return

	# --- Movement ---
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	# --- Jump ---
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# --- Default idle ---
	sprite.texture = idle_texture

	# --- Start Kick ---
	if Input.is_action_just_pressed("kick") and not is_kicking:
		start_kick()

	move_and_slide()


func start_kick() -> void:
	is_kicking = true
	hit_applied_this_kick = false

	sprite.texture = kick_texture

	kick_hitbox.monitorable = true
	kick_hitbox.monitoring = true
	# print("KICK pressed, hitbox ON")

	await get_tree().create_timer(kick_duration).timeout

	kick_hitbox.monitoring = false
	kick_hitbox.monitorable = false
	#print("Kick finished, hitbox OFF")

	is_kicking = false


# ----------------------------
# TAKE DAMAGE (NEW)
# ----------------------------
func take_damage(amount: int) -> void:
	# optional: reduce damage if blocking right now
	if Input.is_action_pressed("block") and not is_kicking:
		amount = int(amount * 0.3)  # 70% reduction while blocking

	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp)
	print("Astronaut HP:", hp)


# IMPORTANT: enemy "Hurtbox" is an Area2D
func _on_kick_hitbox_area_entered(area: Area2D) -> void:
	# Only one hit per kick window
	if not is_kicking:
		return
	if hit_applied_this_kick:
		return

	if area.name == "Hurtbox":
		hit_applied_this_kick = true
		print("HIT!")
		var alien = area.get_parent()
		if alien != null and alien.has_method("take_damage"):
			alien.take_damage(10)
