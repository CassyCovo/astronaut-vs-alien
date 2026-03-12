extends Control

@onready var comic_page = $ComicPage
@onready var continue_button = $ContinueButton

var pages = [
	preload("res://supermove_dummy.png"),
	preload("res://hit_dummy.png"),
	preload("res://block_dummy.png")
]

var current_page := 0

func _ready():
	comic_page.texture = pages[current_page]
	continue_button.pressed.connect(_on_continue_button_pressed)

func _on_continue_button_pressed():
	current_page += 1

	if current_page < pages.size():
		comic_page.texture = pages[current_page]
	else:
		get_tree().change_scene_to_file("res://main.tscn")
