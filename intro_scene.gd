extends Control

@onready var crawl_text = $RichTextLabel
@onready var continue_button = $ContinueButton

var full_text := """Year 2347.

Humanity has entered a new era of deep space exploration. Astronaut explorers travel across the galaxy searching for new worlds and valuable resources.

[Astronaut Name] is currently on a solo expedition, charting unknown regions far from Earth.

During the journey, the ship detects a powerful energy signal coming from a distant planet known as [Planet Name].

Believing the signal may lead to a rare and valuable resource known as [Crystal Name], the astronaut decides to investigate.

Unaware that something on the planet is already waiting..."""

var char_index := 0
var typing_speed := 0.03
var finished := false

func _ready():
	crawl_text.text = ""
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_button_pressed)
	type_text()

func type_text() -> void:
	while char_index < full_text.length():
		crawl_text.text += full_text[char_index]
		char_index += 1
		await get_tree().create_timer(typing_speed).timeout

	finished = true
	continue_button.visible = true
	blink_continue()

func blink_continue():
	while finished:
		continue_button.visible = !continue_button.visible
		await get_tree().create_timer(0.6).timeout

func _on_continue_button_pressed():
	if finished:
		get_tree().change_scene_to_file("res://comic_scene.tscn")
