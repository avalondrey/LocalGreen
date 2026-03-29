extends Node2D
class_name DayNightCycle

# ─── Cycle jour/nuit avec overlay visuel ─────────────────────────────

# ─── Couleurs du ciel ────────────────────────────────────────────────
var sky_colors := {
        "dawn": Color(1.0, 0.85, 0.6, 0.15),
        "day": Color(0.0, 0.0, 0.0, 0.0),
        "dusk": Color(0.9, 0.5, 0.3, 0.2),
        "night": Color(0.05, 0.05, 0.2, 0.4)
}

var current_phase: String = "day"
var overlay: ColorRect
var stars: Array = []
var transition_speed: float = 0.5

# ─── Références ──────────────────────────────────────────────────────
@onready var game_manager: GameManager = get_parent().get_node_or_null("GameManager")

# ─── Initialisation ──────────────────────────────────────────────────
func _ready() -> void:
        print("🌙 DayNightCycle initialisé")
        _create_overlay()
        _create_stars()
        z_index = 1000

func _create_overlay() -> void:
        overlay = ColorRect.new()
        overlay.color = sky_colors["day"]
        overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(overlay)

func _create_stars() -> void:
        for i in range(15):
                var star = _create_star()
                star.position = Vector2(randf_range(50, 1230), randf_range(30, 200))
                star.modulate.a = 0.0
                add_child(star)
                stars.append(star)

func _create_star() -> Node2D:
        var star = Node2D.new()
        var sprite = Sprite2D.new()
        var size = randi_range(2, 5)
        var img = Image.create(size * 2, size * 2, false, Image.FORMAT_RGBA8)
        img.fill(Color.TRANSPARENT)
        Draw.circle(img, Vector2(size, size), float(size), Color(1.0, 1.0, 0.8))
        sprite.texture = ImageTexture.create_from_image(img)
        star.add_child(sprite)
        return star

# ─── Mise à jour ─────────────────────────────────────────────────────
func _process(delta: float) -> void:
        if not game_manager:
                return

        # Calculer la phase en fonction du timer du jour
        var day_progress = game_manager.day_timer / game_manager.day_duration

        var target_color: Color
        var target_stars_alpha: float

        if day_progress < 0.15:
                # Aube
                target_color = sky_colors["dawn"]
                target_stars_alpha = lerp(0.5, 0.0, day_progress / 0.15)
                current_phase = "dawn"
        elif day_progress < 0.65:
                # Jour
                target_color = sky_colors["day"]
                target_stars_alpha = 0.0
                current_phase = "day"
        elif day_progress < 0.8:
                # Crépuscule
                var t = (day_progress - 0.65) / 0.15
                target_color = sky_colors["day"].lerp(sky_colors["dusk"], t)
                target_stars_alpha = 0.0
                current_phase = "dusk"
        else:
                # Nuit
                var t = (day_progress - 0.8) / 0.2
                target_color = sky_colors["dusk"].lerp(sky_colors["night"], t)
                target_stars_alpha = t
                current_phase = "night"

        # Transition fluide
        overlay.color = overlay.color.lerp(target_color, transition_speed * delta)

        # Étoiles
        for star in stars:
                star.modulate.a = lerp(star.modulate.a, target_stars_alpha, transition_speed * delta)
                # Scintillement
                if current_phase == "night":
                        var twinkle = randf() * 0.3
                        star.modulate.a = clampf(star.modulate.a + twinkle, 0.0, target_stars_alpha)
