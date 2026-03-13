extends Control

@onready var comic_page = $ComicPage
@onready var continue_button = $ContinueButton

var comic_image = preload("res://comic.png")

func _ready():
	visible = true
	comic_page.texture = comic_image
	continue_button.pressed.connect(_on_continue_button_pressed)

func _on_continue_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
