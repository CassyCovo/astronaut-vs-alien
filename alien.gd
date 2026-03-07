extends CharacterBody2D

@export var speed := 200.0
@export var gravity := 1400.0

# ----------------------------
# HEALTH
# ----------------------------
@export var max_hp: int = 100
var hp: int
signal hp_changed(current_hp: int)

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
@export_range(0.0, 1.0, 0.05) var block_chance := 0.5  # 35% chance to block a kick

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

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false

	print("Alien ready. HP:", str(hp) + "/" + str(max_hp))


func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# safety: if target got deleted
	if target != null and not is_instance_valid(target):
		target = null

	# freeze while blocking
	if is_blocking:
		velocity.x = 0
		move_and_slide()
		return

	# freeze while attacking
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	# chase + attack
	if target != null:
		var dir = sign(target.global_position.x - global_position.x)
		velocity.x = dir * speed

		if can_attack:
			start_attack()
	else:
		velocity.x = 0

	move_and_slide()


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


# ----------------------------
# RANGE SIGNALS (AttackRange)
# ----------------------------
func _on_attack_range_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		target = area.get_parent()


func _on_attack_range_area_exited(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent() == target:
			target = null


# ----------------------------
# HIT CONFIRM (AttackHitbox)
# ----------------------------
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


# ----------------------------
# BLOCK HELPERS
# ----------------------------
func astronaut_is_kicking(astronaut: Node) -> bool:
	return astronaut != null and ("is_kicking" in astronaut) and astronaut.is_kicking == true


func start_block() -> void:
	can_block = false
	is_blocking = true

	await get_tree().create_timer(block_duration).timeout
	is_blocking = false

	await get_tree().create_timer(block_cooldown).timeout
	can_block = true


# ----------------------------
# TAKE DAMAGE (Astronaut hits Alien)
# ----------------------------
func take_damage(amount: int) -> void:
	# If astronaut is kicking and we are allowed to block, sometimes block
	if can_block and target != null and astronaut_is_kicking(target):
		var r := randf()
		if r < block_chance:
			print("Alien BLOCKED")
			start_block()
			return

	# otherwise take damage normally
	print("Astronaut HIT Alien")
	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp)
	print("Alien HP:", str(hp) + "/" + str(max_hp))
