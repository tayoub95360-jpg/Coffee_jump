extends Node2D

@export var platform_scene: PackedScene = preload("res://scenes/platform.tscn")
@export var num_initial_platforms: int = 6
@export var vertical_gap: int = 120
@export var horizontal_range: int = 300
@export var player_path: NodePath

var platforms: Array = []
var player: Node2D

func _ready():
	player = get_node(player_path) if player_path != NodePath("") else null

	# Si pas assigné dans l'Inspector, essaye de trouver une instance nommée "Bean"
	if not player:
		var candidate := get_node_or_null("Bean")
		if candidate:
			player = candidate

	# Plateformes initiales (sous le joueur)
	var y := int(player.global_position.y) + 100
	for i in range(num_initial_platforms):
		spawn_platform(Vector2(randf_range(-horizontal_range, horizontal_range), y))
		y += vertical_gap

func _physics_process(_delta):
	if not player:
		return

	# Si le joueur approche de la plateforme la plus basse, génère plus loin en bas
	var lowest_y := get_lowest_platform_y()
	if player.global_position.y > (lowest_y - 300):
		spawn_platform(Vector2(randf_range(-horizontal_range, horizontal_range), lowest_y + vertical_gap))

	# Nettoyage: supprime les plateformes très au-dessus du joueur
	for p in platforms.duplicate():
		if p.global_position.y < player.global_position.y - 600:
			platforms.erase(p)
			p.queue_free()

func spawn_platform(pos: Vector2):
	var p = platform_scene.instantiate()
	add_child(p)
	p.global_position = pos

	# IMPORTANT: s'assurer que la collision n'est PAS One Way en mode café
	var shape := p.get_node_or_null("Body/CollisionShape2D")
	if shape and shape.one_way_collision:
		shape.one_way_collision = false

	platforms.append(p)

func get_lowest_platform_y() -> float:
	if platforms.is_empty():
		return player.global_position.y

	var lowest: float = platforms[0].global_position.y
	for p in platforms:
		if p.global_position.y > lowest:
			lowest = p.global_position.y
	return lowest
