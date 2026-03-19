class_name ConnectFourAI
extends RefCounted

const PlayerConfigScript = preload("res://scripts/core/player_config.gd")
const ConnectFourBoardScript = preload("res://scripts/core/connect_four_board.gd")

const SCORE_WIN = 100000000
const SCORE_LOSS = -100000000
const SCORE_INF = 1000000000

var _profiles = {
    PlayerConfigScript.Difficulty.EASY: {
        "depth": 3,
        "randomness": 0.35,
        "center_weight": 4.0,
        "three_weight": 60.0,
        "two_weight": 12.0,
        "block_three_weight": 90.0,
        "block_two_weight": 14.0,
    },
    PlayerConfigScript.Difficulty.MEDIUM: {
        "depth": 4,
        "randomness": 0.12,
        "center_weight": 6.0,
        "three_weight": 90.0,
        "two_weight": 18.0,
        "block_three_weight": 120.0,
        "block_two_weight": 20.0,
    },
    PlayerConfigScript.Difficulty.HARD: {
        "depth": 5,
        "randomness": 0.02,
        "center_weight": 8.0,
        "three_weight": 120.0,
        "two_weight": 24.0,
        "block_three_weight": 170.0,
        "block_two_weight": 28.0,
    },
}

var _rng = RandomNumberGenerator.new()

func _init() -> void:
    _rng.randomize()

func set_profile(difficulty: int, overrides: Dictionary) -> void:
    var base_profile: Dictionary = _profiles.get(difficulty, _profiles[PlayerConfigScript.Difficulty.MEDIUM]).duplicate(true)
    for key in overrides.keys():
        base_profile[key] = overrides[key]
    _profiles[difficulty] = base_profile

func choose_column(board, player_id: int, difficulty: int) -> int:
    var valid_columns: Array = board.get_valid_columns()
    if valid_columns.is_empty():
        return -1

    var ordered_columns = _ordered_columns(valid_columns)

    var immediate_win = _find_immediate_column(board, ordered_columns, player_id)
    if immediate_win != -1:
        return immediate_win

    var opponent_id = _opponent(player_id)
    var immediate_block = _find_immediate_column(board, ordered_columns, opponent_id)
    if immediate_block != -1:
        return immediate_block

    var profile: Dictionary = _profiles.get(difficulty, _profiles[PlayerConfigScript.Difficulty.MEDIUM])
    var search_depth = maxi(1, int(profile.get("depth", 4)))

    var scored_moves: Array = []
    for column in ordered_columns:
        var row = board.apply_move(column, player_id)
        var score = _minimax(board, search_depth - 1, -SCORE_INF, SCORE_INF, false, player_id, profile)
        board.undo_move(column, row)
        scored_moves.append({
            "column": column,
            "score": score,
        })

    scored_moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return int(a["score"]) > int(b["score"])
    )

    if scored_moves.size() == 1:
        return int(scored_moves[0]["column"])

    var randomness = clampf(float(profile.get("randomness", 0.0)), 0.0, 1.0)
    if _rng.randf() < randomness:
        var pool_size = mini(3, scored_moves.size())
        return int(scored_moves[_rng.randi_range(0, pool_size - 1)]["column"])

    return int(scored_moves[0]["column"])

func _find_immediate_column(board, columns: Array, player_id: int) -> int:
    for column in columns:
        var row = board.apply_move(column, player_id)
        if row == -1:
            continue

        var winner = board.get_winner()
        board.undo_move(column, row)
        if winner == player_id:
            return column

    return -1

func _minimax(board, depth: int, alpha: int, beta: int, maximizing: bool, ai_player_id: int, profile: Dictionary) -> int:
    var winner = board.get_winner()
    var opponent_id = _opponent(ai_player_id)

    if winner == ai_player_id:
        return SCORE_WIN + depth
    if winner == opponent_id:
        return SCORE_LOSS - depth
    if depth <= 0 or board.is_full():
        return _evaluate_board(board, ai_player_id, profile)

    var valid_columns = board.get_valid_columns()
    if valid_columns.is_empty():
        return 0

    var ordered_columns = _ordered_columns(valid_columns)

    if maximizing:
        var best_score = -SCORE_INF
        for column in ordered_columns:
            var row = board.apply_move(column, ai_player_id)
            var score = _minimax(board, depth - 1, alpha, beta, false, ai_player_id, profile)
            board.undo_move(column, row)

            best_score = maxi(best_score, score)
            alpha = maxi(alpha, best_score)
            if alpha >= beta:
                break

        return best_score

    var best_opponent_score = SCORE_INF
    for column in ordered_columns:
        var row = board.apply_move(column, opponent_id)
        var score = _minimax(board, depth - 1, alpha, beta, true, ai_player_id, profile)
        board.undo_move(column, row)

        best_opponent_score = mini(best_opponent_score, score)
        beta = mini(beta, best_opponent_score)
        if alpha >= beta:
            break

    return best_opponent_score

func _evaluate_board(board, ai_player_id: int, profile: Dictionary) -> int:
    var opponent_id = _opponent(ai_player_id)
    var score = 0.0

    var center_column = int(ConnectFourBoardScript.COLUMNS / 2)
    var center_weight = float(profile.get("center_weight", 6.0))
    for row in range(ConnectFourBoardScript.ROWS):
        var center_value = board.get_cell(row, center_column)
        if center_value == ai_player_id:
            score += center_weight
        elif center_value == opponent_id:
            score -= center_weight

    for row in range(ConnectFourBoardScript.ROWS):
        for column in range(ConnectFourBoardScript.COLUMNS - 3):
            var window = [
                board.get_cell(row, column),
                board.get_cell(row, column + 1),
                board.get_cell(row, column + 2),
                board.get_cell(row, column + 3),
            ]
            score += _score_window(window, ai_player_id, opponent_id, profile)

    for column in range(ConnectFourBoardScript.COLUMNS):
        for row in range(ConnectFourBoardScript.ROWS - 3):
            var window = [
                board.get_cell(row, column),
                board.get_cell(row + 1, column),
                board.get_cell(row + 2, column),
                board.get_cell(row + 3, column),
            ]
            score += _score_window(window, ai_player_id, opponent_id, profile)

    for row in range(ConnectFourBoardScript.ROWS - 3):
        for column in range(ConnectFourBoardScript.COLUMNS - 3):
            var down_window = [
                board.get_cell(row, column),
                board.get_cell(row + 1, column + 1),
                board.get_cell(row + 2, column + 2),
                board.get_cell(row + 3, column + 3),
            ]
            score += _score_window(down_window, ai_player_id, opponent_id, profile)

    for row in range(3, ConnectFourBoardScript.ROWS):
        for column in range(ConnectFourBoardScript.COLUMNS - 3):
            var up_window = [
                board.get_cell(row, column),
                board.get_cell(row - 1, column + 1),
                board.get_cell(row - 2, column + 2),
                board.get_cell(row - 3, column + 3),
            ]
            score += _score_window(up_window, ai_player_id, opponent_id, profile)

    return int(round(score))

func _score_window(window: Array, ai_player_id: int, opponent_id: int, profile: Dictionary) -> float:
    var ai_count = 0
    var opponent_count = 0
    var empty_count = 0

    for value in window:
        if value == ai_player_id:
            ai_count += 1
        elif value == opponent_id:
            opponent_count += 1
        else:
            empty_count += 1

    if ai_count == 4:
        return SCORE_WIN * 0.1
    if opponent_count == 4:
        return SCORE_LOSS * 0.1

    var window_score = 0.0
    if ai_count == 3 and empty_count == 1:
        window_score += float(profile.get("three_weight", 90.0))
    elif ai_count == 2 and empty_count == 2:
        window_score += float(profile.get("two_weight", 18.0))

    if opponent_count == 3 and empty_count == 1:
        window_score -= float(profile.get("block_three_weight", 120.0))
    elif opponent_count == 2 and empty_count == 2:
        window_score -= float(profile.get("block_two_weight", 20.0))

    return window_score

func _ordered_columns(columns: Array) -> Array:
    var ordered = columns.duplicate()
    var center = int(ConnectFourBoardScript.COLUMNS / 2)

    ordered.sort_custom(func(a: int, b: int) -> bool:
        var distance_a = abs(a - center)
        var distance_b = abs(b - center)
        if distance_a == distance_b:
            return a < b
        return distance_a < distance_b
    )

    return ordered

func _opponent(player_id: int) -> int:
    return 2 if player_id == 1 else 1
