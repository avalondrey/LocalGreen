extends Camera2D
class_name CameraController

# ─── Contrôle de la caméra pour la grille isométrique ────────────────
# Zoom avec molette, déplacement avec WASD/Flèches

var zoom_min := Vector2(0.5, 0.5)
var zoom_max := Vector2(2.0, 2.0)
var zoom_speed := 0.1
var pan_speed := 300.0

var target_zoom := Vector2(1.0, 1.0)
var target_offset := Vector2.ZERO

# ─── Initialisation ──────────────────────────────────────────────────
func _ready() -> void:
	position = Vector2(640, 360)
	smoothing_enabled = true
	smoothing_speed = 5.0
	print("📷 CameraController initialisé")

func _process(delta: float) -> void:
	# Déplacement fluide
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * pan_speed * delta

	# Zoom fluide
	zoom = zoom.lerp(target_zoom, delta * 5.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_out()

func _zoom_in() -> void:
	target_zoom = (target_zoom + Vector2(zoom_speed, zoom_speed)).clamp(zoom_min, zoom_max)

func _zoom_out() -> void:
	target_zoom = (target_zoom - Vector2(zoom_speed, zoom_speed)).clamp(zoom_min, zoom_max)
