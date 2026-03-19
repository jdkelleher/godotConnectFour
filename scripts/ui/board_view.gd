class_name BoardView
extends Control

const ConnectFourBoardScript = preload("res://scripts/core/connect_four_board.gd")

signal column_selected(column: int)
signal drop_animation_finished()

@export var base_cell_size: float = 92.0
@export var drop_duration: float = 0.34
@export var board_color: Color = Color("#1d4ed8")
@export var board_shadow_color: Color = Color(0.02, 0.06, 0.18, 0.45)
@export var hole_color: Color = Color("#0b1733")
@export var hover_color: Color = Color(1.0, 1.0, 1.0, 0.3)
@export var winning_outline_color: Color = Color("#fde047")

var _board
var _hovered_column = -1
var _interactable = true
var _player_colors = {
    1: Color("#fb7185"),
    2: Color("#22d3ee"),
}
var _winning_lookup: Dictionary = {}
var _falling_disc: Dictionary = {}
var _fall_tween: Tween

func _ready() -> void:
    custom_minimum_size = Vector2(560.0, 460.0)
    mouse_exited.connect(_on_mouse_exited)

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()

func set_board(board) -> void:
    _board = board
    queue_redraw()

func set_interactable(value: bool) -> void:
    _interactable = value
    if not value and _hovered_column != -1:
        _hovered_column = -1
    queue_redraw()

func set_player_colors(player_one: Color, player_two: Color) -> void:
    _player_colors[1] = player_one
    _player_colors[2] = player_two
    queue_redraw()

func set_winning_cells(cells: Array) -> void:
    _winning_lookup.clear()
    for cell in cells:
        if cell is Vector2i:
            var key = _cell_key(cell.x, cell.y)
            _winning_lookup[key] = true
    queue_redraw()

func clear_winning_cells() -> void:
    _winning_lookup.clear()
    queue_redraw()

func animate_drop(player_id: int, column: int, row: int) -> void:
    if _fall_tween != null and _fall_tween.is_running():
        _fall_tween.kill()

    var layout = _layout()
    var start_y = float(layout["board_top"]) - float(layout["cell"]) * 0.8
    var target_y = _row_center_y(row, layout)
    var center_x = _column_center_x(column, layout)

    _falling_disc = {
        "player_id": player_id,
        "column": column,
        "row": row,
        "x": center_x,
        "y": start_y,
    }

    var board_distance = max(float(layout["cell"]) * float(ConnectFourBoardScript.ROWS), 1.0)
    var duration_scale = clampf(abs(target_y - start_y) / board_distance, 0.55, 1.2)
    var duration = max(drop_duration * duration_scale, 0.12)

    _fall_tween = create_tween()
    _fall_tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
    _fall_tween.tween_method(_set_falling_disc_y, start_y, target_y, duration)
    _fall_tween.finished.connect(_on_drop_tween_finished)

    queue_redraw()

func _set_falling_disc_y(value: float) -> void:
    if _falling_disc.is_empty():
        return
    _falling_disc["y"] = value
    queue_redraw()

func _on_drop_tween_finished() -> void:
    _falling_disc.clear()
    queue_redraw()
    drop_animation_finished.emit()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _refresh_hover((event as InputEventMouseMotion).position)
        return

    if event is InputEventMouseButton:
        var click = event as InputEventMouseButton
        if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
            var column = _column_from_position(click.position)
            if _can_select_column(column):
                column_selected.emit(column)

func _on_mouse_exited() -> void:
    if _hovered_column != -1:
        _hovered_column = -1
        queue_redraw()

func _refresh_hover(position: Vector2) -> void:
    if not _interactable or _board == null or not _falling_disc.is_empty():
        if _hovered_column != -1:
            _hovered_column = -1
            queue_redraw()
        return

    var next_column = _column_from_position(position)
    if next_column != -1 and _board.is_column_full(next_column):
        next_column = -1

    if next_column != _hovered_column:
        _hovered_column = next_column
        queue_redraw()

func _can_select_column(column: int) -> bool:
    return _interactable and _board != null and _falling_disc.is_empty() and column >= 0 and not _board.is_column_full(column)

func _column_from_position(position: Vector2) -> int:
    var layout = _layout()
    var board_left = float(layout["board_left"])
    var board_top = float(layout["board_top"])
    var board_width = float(layout["board_width"])
    var board_height = float(layout["board_height"])
    var hover_height = float(layout["hover_height"])
    var cell = float(layout["cell"])

    if position.x < board_left or position.x > board_left + board_width:
        return -1
    if position.y < board_top - hover_height or position.y > board_top + board_height:
        return -1

    var column = int(floor((position.x - board_left) / cell))
    if column < 0 or column >= ConnectFourBoardScript.COLUMNS:
        return -1

    return column

func _draw() -> void:
    if _board == null:
        return

    var layout = _layout()
    _draw_hover_marker(layout)
    _draw_board(layout)
    _draw_static_discs(layout)
    _draw_falling_disc(layout)

func _draw_hover_marker(layout: Dictionary) -> void:
    if _hovered_column == -1 or not _interactable:
        return

    var center = Vector2(
        _column_center_x(_hovered_column, layout),
        float(layout["board_top"]) - float(layout["cell"]) * 0.45
    )
    var radius = float(layout["cell"]) * 0.33
    draw_circle(center, radius, hover_color)

func _draw_board(layout: Dictionary) -> void:
    var board_rect = Rect2(
        Vector2(float(layout["board_left"]), float(layout["board_top"])),
        Vector2(float(layout["board_width"]), float(layout["board_height"]))
    )
    var shadow_rect = board_rect
    shadow_rect.position += Vector2(0.0, 10.0)

    draw_rect(shadow_rect, board_shadow_color, true)
    draw_rect(board_rect, board_color, true)

    var hole_radius = float(layout["cell"]) * 0.38
    for row in range(ConnectFourBoardScript.ROWS):
        for column in range(ConnectFourBoardScript.COLUMNS):
            var center = Vector2(_column_center_x(column, layout), _row_center_y(row, layout))
            draw_circle(center, hole_radius, hole_color)

func _draw_static_discs(layout: Dictionary) -> void:
    var disc_radius = float(layout["cell"]) * 0.32
    for row in range(ConnectFourBoardScript.ROWS):
        for column in range(ConnectFourBoardScript.COLUMNS):
            if not _falling_disc.is_empty() and int(_falling_disc["column"]) == column and int(_falling_disc["row"]) == row:
                continue

            var player_id = _board.get_cell(row, column)
            if player_id == ConnectFourBoardScript.EMPTY:
                continue

            var center = Vector2(_column_center_x(column, layout), _row_center_y(row, layout))
            draw_circle(center, disc_radius, _player_colors.get(player_id, Color.WHITE))

            if _winning_lookup.has(_cell_key(column, row)):
                draw_arc(center, disc_radius + 4.0, 0.0, TAU, 48, winning_outline_color, 4.0)

func _draw_falling_disc(layout: Dictionary) -> void:
    if _falling_disc.is_empty():
        return

    var disc_radius = float(layout["cell"]) * 0.32
    var center = Vector2(float(_falling_disc["x"]), float(_falling_disc["y"]))
    var player_id = int(_falling_disc["player_id"])
    draw_circle(center, disc_radius, _player_colors.get(player_id, Color.WHITE))

func _layout() -> Dictionary:
    var margin = 24.0
    var available_width = max(size.x - margin * 2.0, 260.0)
    var available_height = max(size.y - margin * 2.0, 220.0)

    var max_cell_from_width = floor(available_width / float(ConnectFourBoardScript.COLUMNS))
    var max_cell_from_height = floor(available_height / float(ConnectFourBoardScript.ROWS + 1))
    var cell = min(base_cell_size, max_cell_from_width, max_cell_from_height)
    cell = max(cell, 36.0)

    var hover_height = cell * 0.9
    var board_width = cell * float(ConnectFourBoardScript.COLUMNS)
    var board_height = cell * float(ConnectFourBoardScript.ROWS)

    var board_left = (size.x - board_width) * 0.5
    var board_top = (size.y - (board_height + hover_height)) * 0.5 + hover_height

    return {
        "cell": cell,
        "hover_height": hover_height,
        "board_left": board_left,
        "board_top": board_top,
        "board_width": board_width,
        "board_height": board_height,
    }

func _column_center_x(column: int, layout: Dictionary) -> float:
    return float(layout["board_left"]) + float(layout["cell"]) * (float(column) + 0.5)

func _row_center_y(row: int, layout: Dictionary) -> float:
    return float(layout["board_top"]) + float(layout["cell"]) * (float(row) + 0.5)

func _cell_key(column: int, row: int) -> String:
    return "%d:%d" % [column, row]
