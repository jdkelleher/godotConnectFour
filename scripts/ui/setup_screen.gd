class_name SetupScreen
extends Control

const PlayerConfigScript = preload("res://scripts/core/player_config.gd")
const MatchSettingsScript = preload("res://scripts/core/match_settings.gd")

signal start_match_requested(settings)

@export var player_one_color: Color = Color("#fb7185")
@export var player_two_color: Color = Color("#22d3ee")
@export var default_player_one_type: int = PlayerConfigScript.PlayerType.HUMAN
@export var default_player_two_type: int = PlayerConfigScript.PlayerType.COMPUTER
@export var default_player_one_difficulty: int = PlayerConfigScript.Difficulty.MEDIUM
@export var default_player_two_difficulty: int = PlayerConfigScript.Difficulty.MEDIUM

@onready var _start_button: Button = $ContentMargin/Content/StartButton
@onready var _header_labels: Array = [
    $ContentMargin/Content/PlayersRow/Player1Card/CardBody/HeaderLabel,
    $ContentMargin/Content/PlayersRow/Player2Card/CardBody/HeaderLabel,
]
@onready var _type_options: Array = [
    $ContentMargin/Content/PlayersRow/Player1Card/CardBody/TypeOption,
    $ContentMargin/Content/PlayersRow/Player2Card/CardBody/TypeOption,
]
@onready var _difficulty_labels: Array = [
    $ContentMargin/Content/PlayersRow/Player1Card/CardBody/DifficultyLabel,
    $ContentMargin/Content/PlayersRow/Player2Card/CardBody/DifficultyLabel,
]
@onready var _difficulty_options: Array = [
    $ContentMargin/Content/PlayersRow/Player1Card/CardBody/DifficultyOption,
    $ContentMargin/Content/PlayersRow/Player2Card/CardBody/DifficultyOption,
]

var _last_difficulty: Array = [
    PlayerConfigScript.Difficulty.MEDIUM,
    PlayerConfigScript.Difficulty.MEDIUM,
]

func _ready() -> void:
    (_header_labels[0] as Label).modulate = player_one_color
    (_header_labels[1] as Label).modulate = player_two_color

    _populate_type_options()
    _populate_difficulty_options()

    _last_difficulty[0] = default_player_one_difficulty
    _last_difficulty[1] = default_player_two_difficulty

    _connect_signals()
    _apply_defaults()

func _connect_signals() -> void:
    _start_button.pressed.connect(_on_start_pressed)

    for slot in range(2):
        (_type_options[slot] as OptionButton).item_selected.connect(_on_type_selected.bind(slot))
        (_difficulty_options[slot] as OptionButton).item_selected.connect(_on_difficulty_selected.bind(slot))

func _populate_type_options() -> void:
    for type_option in _type_options:
        var option = type_option as OptionButton
        option.clear()
        option.add_item("Human", PlayerConfigScript.PlayerType.HUMAN)
        option.add_item("Computer", PlayerConfigScript.PlayerType.COMPUTER)

func _populate_difficulty_options() -> void:
    for difficulty_option in _difficulty_options:
        var option = difficulty_option as OptionButton
        option.clear()
        option.add_item("Easy", PlayerConfigScript.Difficulty.EASY)
        option.add_item("Medium", PlayerConfigScript.Difficulty.MEDIUM)
        option.add_item("Hard", PlayerConfigScript.Difficulty.HARD)

func _apply_defaults() -> void:
    _select_id(_type_options[0] as OptionButton, default_player_one_type)
    _select_id(_type_options[1] as OptionButton, default_player_two_type)
    _select_id(_difficulty_options[0] as OptionButton, default_player_one_difficulty)
    _select_id(_difficulty_options[1] as OptionButton, default_player_two_difficulty)

    _sync_slot_ui(0)
    _sync_slot_ui(1)

func _on_type_selected(_item_index: int, slot: int) -> void:
    _sync_slot_ui(slot)

func _on_difficulty_selected(_item_index: int, slot: int) -> void:
    _last_difficulty[slot] = (_difficulty_options[slot] as OptionButton).get_selected_id()

func _sync_slot_ui(slot: int) -> void:
    var type_id = (_type_options[slot] as OptionButton).get_selected_id()
    var show_difficulty = type_id == PlayerConfigScript.PlayerType.COMPUTER

    (_difficulty_labels[slot] as Label).visible = show_difficulty
    (_difficulty_options[slot] as OptionButton).visible = show_difficulty

    if show_difficulty:
        _select_id(_difficulty_options[slot] as OptionButton, _last_difficulty[slot])

func _on_start_pressed() -> void:
    var player_one = _build_player_config(0)
    var player_two = _build_player_config(1)
    start_match_requested.emit(MatchSettingsScript.new(player_one, player_two))

func _build_player_config(slot: int):
    var config = PlayerConfigScript.new()
    config.slot_index = slot + 1
    config.display_name = "Player %d" % (slot + 1)
    config.player_type = (_type_options[slot] as OptionButton).get_selected_id()
    config.disc_color = player_one_color if slot == 0 else player_two_color

    if config.player_type == PlayerConfigScript.PlayerType.COMPUTER:
        config.difficulty = (_difficulty_options[slot] as OptionButton).get_selected_id()
        _last_difficulty[slot] = config.difficulty
    else:
        config.difficulty = _last_difficulty[slot]

    return config

func _select_id(option: OptionButton, value: int) -> void:
    for item_index in range(option.item_count):
        if option.get_item_id(item_index) == value:
            option.select(item_index)
            return

    option.select(0)
