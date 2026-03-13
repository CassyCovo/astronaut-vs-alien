extends Node2D

@onready var alien = $CharacterBody2D/alien
@onready var astronaut = $Astronaut

@onready var alien_bar: ProgressBar = $UI/Control/AlienHPBar
@onready var astronaut_bar: ProgressBar = $UI/Control/AstronautHPBar

@onready var mid_fight_comic: Control = $UI/MidFightComic
@onready var comic_page: TextureRect = $UI/MidFightComic/ComicPage
@onready var continue_button: Button = $UI/MidFightComic/ContinueButton
@onready var comic_title: Label = $UI/MidFightComic/ComicTitle

var astronaut_midfight_triggered := false
var showing_end_comic := false

var astronaut_losing_comic = preload("res://astronau_losing_dummy.png")
var alien_defeated_comic = preload("res://alien_deafeated.png")


func _ready() -> void:
	alien_bar.min_value = 0
	alien_bar.max_value = 100
	alien_bar.value = 100

	astronaut_bar.min_value = 0
	astronaut_bar.max_value = 100
	astronaut_bar.value = 100

	mid_fight_comic.visible = false
	comic_title.text = ""

	comic_page.position = Vector2.ZERO
	comic_page.size = get_viewport_rect().size
	comic_page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	comic_page.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if not alien.is_connected("hp_changed", Callable(self, "_on_alien_hp_changed")):
		alien.connect("hp_changed", Callable(self, "_on_alien_hp_changed"))

	if not alien.is_connected("defeated", Callable(self, "_on_alien_defeated")):
		alien.connect("defeated", Callable(self, "_on_alien_defeated"))

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

	if showing_end_comic:
		return

	if astronaut_bar.value <= 50:
		start_astronaut_midfight_comic()


func start_astronaut_midfight_comic() -> void:
	astronaut_midfight_triggered = true
	comic_title.text = ""
	comic_page.texture = astronaut_losing_comic
	continue_button.visible = true
	mid_fight_comic.visible = true

	get_tree().paused = true
	mid_fight_comic.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	comic_page.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	continue_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	comic_title.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _on_alien_defeated() -> void:
	showing_end_comic = true

	comic_page.texture = alien_defeated_comic
	mid_fight_comic.visible = true
	continue_button.visible = false

	comic_title.text = "ALIEN DEFEATED"

	get_tree().paused = true
	mid_fight_comic.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	comic_page.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	comic_title.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _on_continue_button_pressed() -> void:
	if showing_end_comic:
		return

	comic_title.text = ""
	mid_fight_comic.visible = false
	get_tree().paused = false
