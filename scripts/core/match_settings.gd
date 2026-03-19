class_name MatchSettings
extends RefCounted

const PlayerConfigScript = preload("res://scripts/core/player_config.gd")

var players: Array = []

func _init(player_one = null, player_two = null) -> void:
    if player_one == null:
        player_one = PlayerConfigScript.new()
        player_one.slot_index = 1
        player_one.display_name = "Player 1"
    if player_two == null:
        player_two = PlayerConfigScript.new()
        player_two.slot_index = 2
        player_two.display_name = "Player 2"
    players = [player_one, player_two]

func get_player(player_id: int):
    var index = clampi(player_id - 1, 0, 1)
    return players[index]

func set_player(player_id: int, config) -> void:
    var index = clampi(player_id - 1, 0, 1)
    players[index] = config

func duplicate_settings():
    return get_script().new(players[0].duplicate_config(), players[1].duplicate_config())

func matchup_label() -> String:
    var left = "%s (%s)" % [
        players[0].display_name,
        PlayerConfigScript.player_type_label(players[0].player_type),
    ]
    var right = "%s (%s)" % [
        players[1].display_name,
        PlayerConfigScript.player_type_label(players[1].player_type),
    ]

    if players[0].is_computer():
        left += " - %s" % PlayerConfigScript.difficulty_label(players[0].difficulty)
    if players[1].is_computer():
        right += " - %s" % PlayerConfigScript.difficulty_label(players[1].difficulty)

    return "%s vs %s" % [left, right]
