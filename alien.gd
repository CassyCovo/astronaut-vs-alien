extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D

@export var tex_idle: Texture2D
@export var tex_hit: Texture2D
@export var tex_block: Texture2D
@export var tex_super: Texture2D

var state := "idle"

func _ready():
	set_state("idle")

func set_state(new_state: String):
	state = new_state
	match state:
		"idle":
			sprite.texture = tex_idle
		"hit":
			sprite.texture = tex_hit
		"block":
			sprite.texture = tex_block
		"super":
			sprite.texture = tex_super
