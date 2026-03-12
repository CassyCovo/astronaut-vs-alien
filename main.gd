extends Node2D

@onready var alien = $CharacterBody2D
@onready var astronaut = $Astronaut

@onready var alien_bar: ProgressBar = $UI/Control/AlienHPBar
@onready var astronaut_bar: ProgressBar = $UI/Control/AstronautHPBar

@onready var mid_fight_comic: Control = $UI/MidFightComic
@onready var comic_page: TextureRect = $UI/MidFightComic/ComicPage
@onready var continue_button: Button = $UI/MidFightComic/ContinueButton

var astronaut_midfight_triggered := false
var astronaut_losing_comic = preload("res://astronau_losing_dummy.png")


func _ready() -> void:
	# HP bars
	alien_bar.min_value = 0
	alien_bar.max_value = 100
	alien_bar.value = 100

	astronaut_bar.min_value = 0
	astronaut_bar.max_value = 100
	astronaut_bar.value = 100

	# Hide comic at start
	mid_fight_comic.visible = false

	# Force comic image to cover whole screen
	comic_page.position = Vector2.ZERO
	comic_page.size = get_viewport_rect().size
	comic_page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	comic_page.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# Safe signal connections
	if not alien.is_connected("hp_changed", Callable(self, "_on_alien_hp_changed")):
		alien.connect("hp_changed", Callable(self, "_on_alien_hp_changed"))

	if not astronaut.is_connected("hp_changed", Callable(self, "_on_astronaut_hp_changed")):
		astronaut.connect("hp_changed", Callable(self, "_on_astronaut_hp_changed"))

	if not continue_button.is_connected("pressed", Callable(self, "_on_continue_button_pressed")):
		continue_button.connect("pressed", Callable(self, "_on_continue_button_pressed"))


func _on_alien_hp_changed(current_hp: int) -> void:
	alien_bar.value = current_hp


func _on_astronaut_hp_changed(current_hp: int) -> void:
	astronaut_bar.value = current_hp
	check_astronaut_midfight_trigger()


func check_astronaut_midfight_trigger() -> void:
	if astronaut_midfight_triggered:
		return

	if astronaut_bar.value <= 50:
		start_astronaut_midfight_comic()


func start_astronaut_midfight_comic() -> void:
	astronaut_midfight_triggered = true

	comic_page.texture = astronaut_losing_comic
	mid_fight_comic.visible = true

	get_tree().paused = true
	mid_fight_comic.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	comic_page.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	continue_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _on_continue_button_pressed() -> void:
	mid_fight_comic.visible = false
	get_tree().paused = false
