extends CharacterBody2D

# --- Réglages de déplacement (tweakables dans l’Inspector) ---
@export var max_speed: float = 220.0          # vitesse horizontale max
@export var accel_ground: float = 10.0        # inertie au sol (plus réactif)
@export var accel_air: float = 7.0            # inertie en l’air (un poil plus “mou”)
@export var damp_ground: float = 12.0         # ralenti si on lâche les touches (sol)
@export var damp_air: float = 6.0             # ralenti si on lâche les touches (air)

@export var gravity: float = 380.0            # gravité faible -> chute lente
@export var terminal_velocity: float = 230.0  # vitesse limite de chute (IMPORTANT)
@export var ground_slide_speed: float = 60.0  # vitesse verticale quand on “colle” au sol
@export var floor_snap: float = 8.0           # aide à rester collé aux plateformes

@export var death_y: float = 4000.0           # sécurité: trop bas -> reset (MVP)

func _ready() -> void:
	# Caméra
	var cam := $Camera2D
	if cam:
		cam.make_current()
	# “Colle” légèrement aux plateformes pour bien glisser dessus
	floor_snap_length = floor_snap

func _physics_process(delta: float) -> void:
	# --- Entrée utilisateur ---
	var dir := 0.0
	if Input.is_action_pressed("move_left"):
		dir -= 1.0
	if Input.is_action_pressed("move_right"):
		dir += 1.0

	# --- Cible horizontale + inertie (différente sol / air) ---
	var target_speed := dir * max_speed
	var accel := accel_ground if is_on_floor() else accel_air
	velocity.x = lerp(velocity.x, target_speed, accel * delta)

	# Si aucune entrée → amortissement (différent sol / air) pour stopper doucement
	if absf(dir) < 0.01:
		var damp := damp_ground if is_on_floor() else damp_air
		velocity.x = lerp(velocity.x, 0.0, damp * delta)

	# --- Gravité douce + vitesse de chute limitée ---
	velocity.y += gravity * delta
	if velocity.y > terminal_velocity:
		velocity.y = terminal_velocity

	# Pas de rebond : si on est “sur le sol”, on garde une petite descente
	if is_on_floor() and velocity.y > ground_slide_speed:
		velocity.y = ground_slide_speed

	# Déplacement physique
	move_and_slide()
