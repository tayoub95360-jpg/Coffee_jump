extends Node2D

@export var platform_scene : PackedScene = preload("res://scenes/platform.tscn")
@export var num_initial_platforms : int = 5
@export var vertical_gap : int = 120
@export var horizontal_range : int = 300
@export var player_node_path : NodePath

var platforms : Array = []
var player : Node2D = null

func _ready():
	if player_node_path != NodePath(""):
		player = get_node(player_node_path)
	else:
		push_error("Aucun joueur assigné à player_node_path !")
		return

	var y = 0
	for i in range(num_initial_platforms):
		spawn_platform(Vector2(randf_range(-horizontal_range, horizontal_range), y))
		y -= vertical_gap

func _physics_process(_delta):
	if not player:
		return

	# Génération de nouvelles plateformes si le joueur monte
	var highest_platform_y = get_highest_platform_y()
	if player.global_position.y < highest_platform_y + 300:
		spawn_platform(Vector2(randf_range(-horizontal_range, horizontal_range), highest_platform_y - vertical_gap))

	# Supprimer les plateformes trop basses
	for p in platforms.duplicate():
		if p.global_position.y > player.global_position.y + 400:
			platforms.erase(p)
			p.queue_free()

func spawn_platform(pos : Vector2):
	var p = platform_scene.instantiate()
	add_child(p)
	p.global_position = pos
	platforms.append(p)

func get_highest_platform_y() -> float:
	var highest = 0
	for p in platforms:
		if p.global_position.y < highest:
			highest = p.global_position.y
	return highest
