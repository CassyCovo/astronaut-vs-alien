extends CharacterBody2D

@export var speed: float = 180.0

# Drag your Astronaut node into this field in the Inspector
@export var astronaut_path: NodePath

@onready var chase_timer: Timer = $ChaseTimer
var astronaut: Node2D = null

var chasing: bool = false
var chase_time_left: float = 0.0

func _ready() -> void:
	if astronaut_path != NodePath():
		astronaut = get_node_or_null(astronaut_path)

	# when the timer fires, decide to chase
	if not chase_timer.timeout.is_connected(_on_chase_timer_timeout):
		chase_timer.timeout.connect(_on_chase_timer_timeout)

func _physics_process(delta: float) -> void:
	if astronaut == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if chasing:
		chase_time_left -= delta
		if chase_time_left <= 0.0:
			chasing = false

		var dir := (astronaut.global_position - global_position)
		# only move if we're not basically already on top of them
		if dir.length() > 10.0:
			dir = dir.normalized()
			velocity = dir * speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _on_chase_timer_timeout() -> void:
	# 60% chance to chase each time the timer pings
	var roll := randf()
	if roll < 0.6:
		chasing = true
		chase_time_left = randf_range(0.6, 1.2) # chase for a short burst

	# schedule next "decision"
	chase_timer.wait_time = randf_range(1.0, 2.0)
	chase_timer.start()
