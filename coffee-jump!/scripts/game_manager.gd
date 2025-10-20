extends Node

@onready var SugarMode: PackedScene = preload("res://scenes/sugar_mode.tscn")
@onready var CoffeeMode: PackedScene = preload("res://scenes/coffee_mode.tscn")

var current_mode: String = "sugar"
var sugar_mode_node: Node = null
var coffee_mode_node: Node = null
var is_transitioning: bool = false
var last_sugar_pos: Vector2 = Vector2.ZERO
var last_coffee_pos: Vector2 = Vector2.ZERO
var first_coffee: bool = true

func _ready() -> void:
	load_mode("sugar")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_mode") and not is_transitioning:
		var next := "coffee" if current_mode == "sugar" else "sugar"
		transition_to(next)

func load_mode(mode: String) -> void:
	# instancie si besoin, montre le mode demandé, cache l’autre
	if mode == "sugar":
		if sugar_mode_node == null:
			sugar_mode_node = SugarMode.instantiate()
			add_child(sugar_mode_node)
		sugar_mode_node.visible = true
		sugar_mode_node.process_mode = Node.PROCESS_MODE_INHERIT
		if coffee_mode_node:
			coffee_mode_node.visible = false
			coffee_mode_node.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		if coffee_mode_node == null:
			coffee_mode_node = CoffeeMode.instantiate()
			add_child(coffee_mode_node)
		coffee_mode_node.visible = true
		coffee_mode_node.process_mode = Node.PROCESS_MODE_INHERIT
		if sugar_mode_node:
			sugar_mode_node.visible = false
			sugar_mode_node.process_mode = Node.PROCESS_MODE_DISABLED

	current_mode = mode

func transition_to(next_mode: String) -> void:
	is_transitioning = true
	var current_node := (sugar_mode_node if current_mode == "sugar" else coffee_mode_node)

	# 1) Geler le mode courant et mémoriser la position du joueur
	if current_node:
		current_node.process_mode = Node.PROCESS_MODE_DISABLED
		var player := get_player(current_node, current_mode)
		if player:
			if current_mode == "sugar":
				last_sugar_pos = player.global_position
			else:
				last_coffee_pos = player.global_position

	# 2) Pause 1s (mode courant figé)
	await get_tree().create_timer(0.3).timeout

	# 3) Charger/afficher le prochain mode mais figé pendant 1s
	if next_mode == "sugar":
		if sugar_mode_node == null:
			sugar_mode_node = SugarMode.instantiate()
			add_child(sugar_mode_node)
		# placer le joueur si on a déjà une position (sinon, spawn par défaut)
		var sugar_player := get_player(sugar_mode_node, "sugar")
		if sugar_player and last_sugar_pos != Vector2.ZERO:
			sugar_player.global_position = last_sugar_pos

		sugar_mode_node.visible = true
		focus_mode_camera(sugar_mode_node)
		sugar_mode_node.process_mode = Node.PROCESS_MODE_DISABLED
		if coffee_mode_node:
			coffee_mode_node.visible = false

		await get_tree().create_timer(0.5).timeout
		sugar_mode_node.process_mode = Node.PROCESS_MODE_INHERIT

	else: # next_mode == "coffee"
		if coffee_mode_node == null:
			coffee_mode_node = CoffeeMode.instantiate()
			add_child(coffee_mode_node)
		var coffee_player := get_player(coffee_mode_node, "coffee")
		if coffee_player:
			if first_coffee or last_coffee_pos == Vector2.ZERO:
				coffee_player.global_position = Vector2(0, -200) # position initiale
			else:
				coffee_player.global_position = last_coffee_pos

		coffee_mode_node.visible = true
		focus_mode_camera(coffee_mode_node)
		coffee_mode_node.process_mode = Node.PROCESS_MODE_DISABLED
		if sugar_mode_node:
			sugar_mode_node.visible = false

		await get_tree().create_timer(0.5).timeout
		coffee_mode_node.process_mode = Node.PROCESS_MODE_INHERIT
		first_coffee = false

	current_mode = next_mode
	is_transitioning = false

func get_player(mode_node: Node, mode_name: String) -> Node2D:
	# Convention: dans sugar_mode.tscn le joueur s’appelle "Sugar", dans coffee_mode.tscn "Bean"
	var path := ("Sugar" if mode_name == "sugar" else "Bean")
	return mode_node.get_node_or_null(path) as Node2D

func find_camera(node: Node) -> Camera2D:
	for c in node.get_children():
		if c is Camera2D:
			return c
		var found := find_camera(c)
		if found:
			return found
	return null

func focus_mode_camera(mode_node: Node) -> void:
	var cam := find_camera(mode_node)
	if cam:
		cam.make_current()
