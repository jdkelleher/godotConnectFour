class_name GameScreen
extends Control

const PlayerConfigScript = preload("res://scripts/core/player_config.gd")
const GameControllerScript = preload("res://scripts/core/game_controller.gd")
const ConnectFourAIScript = preload("res://scripts/ai/connect_four_ai.gd")

signal back_to_menu_requested()

@export_range(0.0, 2.0, 0.05) var ai_thinking_delay: float = 0.45

@export_range(1, 7, 1) var easy_depth: int = 3
@export_range(1, 7, 1) var medium_depth: int = 4
@export_range(1, 8, 1) var hard_depth: int = 5

@export_range(0.0, 1.0, 0.01) var easy_randomness: float = 0.35
@export_range(0.0, 1.0, 0.01) var medium_randomness: float = 0.12
@export_range(0.0, 1.0, 0.01) var hard_randomness: float = 0.02

@onready var _turn_label: Label = $LayoutMargin/Layout/Header/TurnLabel
@onready var _matchup_label: Label = $LayoutMargin/Layout/Header/MatchupLabel
@onready var _board_view: Control = $LayoutMargin/Layout/BoardContainer/BoardPadding/BoardView
@onready var _restart_button: Button = $LayoutMargin/Layout/Footer/RestartButton
@onready var _menu_button: Button = $LayoutMargin/Layout/Footer/MenuButton

@onready var _result_panel: PanelContainer = $ResultPanel
@onready var _result_title: Label = $ResultPanel/ResultMargin/ResultBody/ResultTitle
@onready var _result_detail: Label = $ResultPanel/ResultMargin/ResultBody/ResultDetail
@onready var _result_restart_button: Button = $ResultPanel/ResultMargin/ResultBody/ResultActions/ResultRestartButton
@onready var _result_menu_button: Button = $ResultPanel/ResultMargin/ResultBody/ResultActions/ResultMenuButton

var _controller = GameControllerScript.new()
var _ai = ConnectFourAIScript.new()
var _current_settings
var _ai_request_token = 0

func _ready() -> void:
    _result_panel.visible = false
    _board_view.set_board(_controller.board)
    _board_view.set_interactable(false)

    _configure_ai_profiles()
    _connect_ui_signals()
    _connect_controller_signals()

func start_match(settings) -> void:
    if not is_node_ready():
        await ready

    _ai_request_token += 1
    _current_settings = settings.duplicate_settings()

    _result_panel.visible = false
    _board_view.clear_winning_cells()
    _board_view.set_player_colors(
        _current_settings.get_player(1).disc_color,
        _current_settings.get_player(2).disc_color
    )
    _matchup_label.text = _current_settings.matchup_label()

    _controller.start_match(_current_settings)

func _connect_ui_signals() -> void:
    _board_view.column_selected.connect(_on_column_selected)
    _board_view.drop_animation_finished.connect(_on_drop_animation_finished)

    _restart_button.pressed.connect(_on_restart_pressed)
    _menu_button.pressed.connect(_on_menu_pressed)
    _result_restart_button.pressed.connect(_on_restart_pressed)
    _result_menu_button.pressed.connect(_on_menu_pressed)

func _connect_controller_signals() -> void:
    _controller.board_reset.connect(_on_board_reset)
    _controller.turn_changed.connect(_on_turn_changed)
    _controller.move_rejected.connect(_on_move_rejected)
    _controller.move_committed.connect(_on_move_committed)
    _controller.game_finished.connect(_on_game_finished)

func _configure_ai_profiles() -> void:
    _ai.set_profile(PlayerConfigScript.Difficulty.EASY, {
        "depth": easy_depth,
        "randomness": easy_randomness,
    })
    _ai.set_profile(PlayerConfigScript.Difficulty.MEDIUM, {
        "depth": medium_depth,
        "randomness": medium_randomness,
    })
    _ai.set_profile(PlayerConfigScript.Difficulty.HARD, {
        "depth": hard_depth,
        "randomness": hard_randomness,
    })

func _on_board_reset() -> void:
    _board_view.clear_winning_cells()
    _board_view.queue_redraw()

func _on_turn_changed(player_id: int, player_config) -> void:
    _turn_label.text = "%s Turn" % player_config.display_name
    _turn_label.modulate = player_config.disc_color

    if player_config.is_computer():
        _board_view.set_interactable(false)
        _queue_ai_turn(player_id)
    else:
        _board_view.set_interactable(_controller.can_accept_input())

func _queue_ai_turn(expected_player_id: int) -> void:
    _ai_request_token += 1
    var request_token = _ai_request_token

    _turn_label.text = "%s Thinking..." % _controller.get_active_player().display_name
    _turn_label.modulate = _controller.get_active_player().disc_color

    if ai_thinking_delay > 0.0:
        await get_tree().create_timer(ai_thinking_delay).timeout

    if request_token != _ai_request_token:
        return
    if _controller.is_game_over or _controller.input_locked:
        return
    if not _controller.is_current_player_computer():
        return
    if _controller.current_player_id != expected_player_id:
        return

    var active_player = _controller.get_active_player()
    var selected_column = _ai.choose_column(_controller.board, expected_player_id, active_player.difficulty)
    if selected_column == -1:
        var fallback_columns = _controller.board.get_valid_columns()
        if fallback_columns.is_empty():
            return
        selected_column = int(fallback_columns[0])

    _controller.request_move(selected_column)

func _on_move_rejected(_column: int, reason: String) -> void:
    if _controller.is_game_over:
        return

    _turn_label.text = reason
    _turn_label.modulate = Color(1.0, 0.93, 0.74)

func _on_move_committed(player_id: int, column: int, row: int) -> void:
    _board_view.set_interactable(false)
    _board_view.animate_drop(player_id, column, row)

func _on_drop_animation_finished() -> void:
    _controller.complete_move_animation()

func _on_game_finished(result_type: String, winner_id: int, winning_cells: Array) -> void:
    _ai_request_token += 1
    _board_view.set_interactable(false)
    _board_view.set_winning_cells(winning_cells)

    if result_type == "win":
        var winner = _current_settings.get_player(winner_id)
        _turn_label.text = "%s Wins!" % winner.display_name
        _turn_label.modulate = winner.disc_color
        _result_title.text = "%s Wins!" % winner.display_name
        _result_detail.text = "Connected four in a row."
    else:
        _turn_label.text = "Draw Game"
        _turn_label.modulate = Color(0.92, 0.95, 1.0)
        _result_title.text = "Draw Game"
        _result_detail.text = "The board is full with no winner."

    _show_result_panel()

func _show_result_panel() -> void:
    _result_panel.visible = true
    _result_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
    _result_panel.scale = Vector2(0.92, 0.92)
    _result_panel.pivot_offset = _result_panel.size * 0.5

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(_result_panel, "modulate:a", 1.0, 0.22)
    tween.tween_property(_result_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_column_selected(column: int) -> void:
    if _controller.is_current_player_computer():
        return
    _controller.request_move(column)

func _on_restart_pressed() -> void:
    if _current_settings == null:
        return
    start_match(_current_settings)

func _on_menu_pressed() -> void:
    _ai_request_token += 1
    back_to_menu_requested.emit()
