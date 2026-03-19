class_name PlayerConfig
extends RefCounted

enum PlayerType { HUMAN, COMPUTER }
enum Difficulty { EASY, MEDIUM, HARD }

var slot_index: int = 1
var display_name: String = "Player"
var player_type: int = PlayerType.HUMAN
var disc_color: Color = Color(1.0, 1.0, 1.0)
var difficulty: int = Difficulty.MEDIUM

func is_computer() -> bool:
    return player_type == PlayerType.COMPUTER

func duplicate_config() -> PlayerConfig:
    var copy = get_script().new()
    copy.slot_index = slot_index
    copy.display_name = display_name
    copy.player_type = player_type
    copy.disc_color = disc_color
    copy.difficulty = difficulty
    return copy

static func player_type_label(player_type_value: int) -> String:
    if player_type_value == PlayerType.COMPUTER:
        return "Computer"
    return "Human"

static func difficulty_label(difficulty_value: int) -> String:
    match difficulty_value:
        Difficulty.EASY:
            return "Easy"
        Difficulty.HARD:
            return "Hard"
        _:
            return "Medium"
