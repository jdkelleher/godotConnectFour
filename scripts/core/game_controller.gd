class_name GameController
extends RefCounted

const ConnectFourBoardScript = preload("res://scripts/core/connect_four_board.gd")
const MatchSettingsScript = preload("res://scripts/core/match_settings.gd")

signal board_reset()
signal turn_changed(player_id: int, player_config)
signal move_rejected(column: int, reason: String)
signal move_committed(player_id: int, column: int, row: int)
signal game_finished(result_type: String, winner_id: int, winning_cells: Array)

var board = ConnectFourBoardScript.new()
var settings = MatchSettingsScript.new()
var current_player_id = 1
var is_game_over = false
var input_locked = false

var _pending_next_player_id = 1
var _pending_outcome: Dictionary = {}

func start_match(new_settings) -> void:
    settings = new_settings.duplicate_settings()
    board.reset()
    current_player_id = 1
    is_game_over = false
    input_locked = false
    _pending_next_player_id = 1
    _pending_outcome.clear()

    board_reset.emit()
    turn_changed.emit(current_player_id, get_active_player())

func request_move(column: int) -> bool:
    if is_game_over:
        move_rejected.emit(column, "The game is already over.")
        return false

    if input_locked:
        move_rejected.emit(column, "Wait for the current disc to finish dropping.")
        return false

    if not board.is_valid_column(column):
        move_rejected.emit(column, "That column is full.")
        return false

    var acting_player_id = current_player_id
    var row = board.apply_move(column, acting_player_id)
    if row == -1:
        move_rejected.emit(column, "Invalid move.")
        return false

    input_locked = true
    move_committed.emit(acting_player_id, column, row)

    var winning_line = board.get_winning_line()
    if not winning_line.is_empty():
        is_game_over = true
        _pending_outcome = {
            "result": "win",
            "winner": acting_player_id,
            "cells": winning_line.get("cells", []),
        }
    elif board.is_full():
        is_game_over = true
        _pending_outcome = {
            "result": "draw",
            "winner": 0,
            "cells": [],
        }
    else:
        _pending_outcome.clear()
        _pending_next_player_id = 2 if acting_player_id == 1 else 1

    return true

func complete_move_animation() -> void:
    if not input_locked:
        return

    input_locked = false

    if is_game_over:
        var result_type = String(_pending_outcome.get("result", "draw"))
        var winner_id = int(_pending_outcome.get("winner", 0))
        var winning_cells: Array = _pending_outcome.get("cells", [])
        game_finished.emit(result_type, winner_id, winning_cells)
        return

    current_player_id = _pending_next_player_id
    turn_changed.emit(current_player_id, get_active_player())

func get_active_player():
    return settings.get_player(current_player_id)

func is_current_player_computer() -> bool:
    return get_active_player().is_computer()

func can_accept_input() -> bool:
    return not is_game_over and not input_locked
