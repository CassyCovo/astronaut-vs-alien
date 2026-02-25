extends CharacterBody2D

@export var speed: float = 180.0
@export var astronaut_path: NodePath
@export var chase_duration: float = 1.2

# ----------------------------
# HEALTH (NEW)
# ----------------------------
@export var max_hp: int = 100
var hp: int
signal hp_changed(current_hp: int)

@onready var chase_timer: Timer = $ChaseTimer

var astronaut: Node2D = null
var chasing: bool = false
var chase_time_left: float = 0.0


func _ready() -> void:
	# HEALTH init (NEW)
	hp = max_hp
	hp_changed.emit(hp)
	print("Alien ready. HP:", hp, "/", max_hp)

	astronaut = get_node_or_null(astronaut_path) as Node2D
	if astronaut == null:
		push_error("Alien: Astronaut Path not assigned (or wrong).")
		return

	chase_timer.one_shot = false
	if chase_timer.wait_time <= 0.0:
		chase_timer.wait_time = 2.0

	if not chase_timer.timeout.is_connected(_on_chase_timer_timeout):
		chase_timer.timeout.connect(_on_chase_timer_timeout)

	chase_timer.start()


func _on_chase_timer_timeout() -> void:
	chasing = true
	chase_time_left = chase_duration


func _physics_process(delta: float) -> void:
	if astronaut == null:
		return

	if chasing:
		chase_time_left -= delta
		if chase_time_left <= 0.0:
			chasing = false

	if chasing:
		var dir: float = sign(astronaut.global_position.x - global_position.x)
		velocity.x = dir * speed
	else:
		velocity.x = 0.0

	move_and_slide()

# ----------------------------
# TAKE DAMAGE (NEW)
# ----------------------------
func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	hp_changed.emit(hp)
	print("Alien took", amount, "damage. HP:", hp, "/", max_hp)

	if hp == 0:
		print("Alien defeated!")
		# Optional:
		# queue_free()
