extends Node2D

@onready var alien = $CharacterBody2D/alien
@onready var bar: ProgressBar = $UI/AlienHPBar

func _ready() -> void:
	if alien == null:
		push_error("Alien node not found at $CharacterBody2D/alien")
		return

	print("Main ready. BAR NODE:", bar)

	# TEMP: HP bar disabled while we build alien moves/animations
	# bar.min_value = 0
	# bar.max_value = alien.max_hp
	# bar.value = alien.hp

	# TEMP: signal connect disabled
	# if alien.hp_changed.is_connected(_on_alien_hp_changed) == false:
	# 	alien.hp_changed.connect(_on_alien_hp_changed)

# TEMP: disabled while HP system is off
# func _on_alien_hp_changed(current_hp: int) -> void:
# 	bar.value = current_hp
# 	print("HP BAR UPDATE:", current_hp, "/", bar.max_value)
