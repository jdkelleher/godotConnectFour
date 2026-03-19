extends Control

const SETUP_SCENE = preload("res://scenes/setup/setup_screen.tscn")
const GAME_SCENE = preload("res://scenes/game/game_screen.tscn")

@onready var _screen_root: Control = $ScreenRoot

func _ready() -> void:
    _show_setup()

func _show_setup() -> void:
    _clear_screen()

    var setup_screen = SETUP_SCENE.instantiate()
    _screen_root.add_child(setup_screen)
    setup_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    setup_screen.start_match_requested.connect(_on_start_match_requested)

func _show_game(settings) -> void:
    _clear_screen()

    var game_screen = GAME_SCENE.instantiate()
    _screen_root.add_child(game_screen)
    game_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    game_screen.back_to_menu_requested.connect(_on_back_to_menu_requested)
    game_screen.start_match(settings)

func _clear_screen() -> void:
    for child in _screen_root.get_children():
        child.queue_free()

func _on_start_match_requested(settings) -> void:
    _show_game(settings)

func _on_back_to_menu_requested() -> void:
    _show_setup()
