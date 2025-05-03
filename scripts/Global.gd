extends Node

const TILE_SIZE : int = 32

var currencyNEnergy : Control

var defaultCursor : Texture2D
var targetingCursor : Texture2D

func _ready() -> void:
    defaultCursor = load("res://art/ui/Cursor.ase")
    targetingCursor = load("res://art/ui/Attack_Icon.ase")
    
    if Array(OS.get_cmdline_args()).has("editor"): return
    get_tree().root.mode = Window.MODE_MAXIMIZED

func distance(v1: Vector2, v2: Vector2) -> float:
    return sqrt((v1.x - v2.x)**2 + (v1.y - v2.y)**2);
