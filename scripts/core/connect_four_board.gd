class_name ConnectFourBoard
extends RefCounted

const COLUMNS = 7
const ROWS = 6
const EMPTY = 0

var _grid: Array = []

func _init() -> void:
    reset()

func reset() -> void:
    _grid.clear()
    for row in range(ROWS):
        var row_data: Array = []
        row_data.resize(COLUMNS)
        row_data.fill(EMPTY)
        _grid.append(row_data)

func duplicate_board() -> ConnectFourBoard:
    var copy = get_script().new()
    for row in range(ROWS):
        for column in range(COLUMNS):
            copy._grid[row][column] = _grid[row][column]
    return copy

func get_cell(row: int, column: int) -> int:
    if not _is_inside(column, row):
        return EMPTY
    return int(_grid[row][column])

func set_cell(row: int, column: int, value: int) -> void:
    if _is_inside(column, row):
        _grid[row][column] = value

func next_open_row(column: int) -> int:
    if column < 0 or column >= COLUMNS:
        return -1
    for row in range(ROWS - 1, -1, -1):
        if int(_grid[row][column]) == EMPTY:
            return row
    return -1

func is_valid_column(column: int) -> bool:
    return next_open_row(column) != -1

func is_column_full(column: int) -> bool:
    return next_open_row(column) == -1

func apply_move(column: int, player_id: int) -> int:
    if player_id <= EMPTY:
        return -1
    var row = next_open_row(column)
    if row == -1:
        return -1
    _grid[row][column] = player_id
    return row

func undo_move(column: int, row: int) -> void:
    if _is_inside(column, row):
        _grid[row][column] = EMPTY

func get_valid_columns() -> Array:
    var valid_columns: Array = []
    for column in range(COLUMNS):
        if is_valid_column(column):
            valid_columns.append(column)
    return valid_columns

func is_full() -> bool:
    for column in range(COLUMNS):
        if is_valid_column(column):
            return false
    return true

func get_winner() -> int:
    var winning_line = get_winning_line()
    if winning_line.is_empty():
        return EMPTY
    return int(winning_line["player"])

func get_winning_line() -> Dictionary:
    var directions = [
        Vector2i(1, 0),
        Vector2i(0, 1),
        Vector2i(1, 1),
        Vector2i(1, -1),
    ]

    for row in range(ROWS):
        for column in range(COLUMNS):
            var player = int(_grid[row][column])
            if player == EMPTY:
                continue

            for direction in directions:
                var cells: Array = [Vector2i(column, row)]
                var complete = true
                for offset in range(1, 4):
                    var next_column = column + direction.x * offset
                    var next_row = row + direction.y * offset
                    if not _is_inside(next_column, next_row):
                        complete = false
                        break
                    if int(_grid[next_row][next_column]) != player:
                        complete = false
                        break
                    cells.append(Vector2i(next_column, next_row))

                if complete:
                    return {
                        "player": player,
                        "cells": cells,
                    }

    return {}

func to_matrix_copy() -> Array:
    var copy: Array = []
    for row in range(ROWS):
        copy.append((_grid[row] as Array).duplicate())
    return copy

func _is_inside(column: int, row: int) -> bool:
    return column >= 0 and column < COLUMNS and row >= 0 and row < ROWS
