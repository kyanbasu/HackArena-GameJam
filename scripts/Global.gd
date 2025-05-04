extends Node

const TILE_SIZE : int = 32

var currencyNEnergy : Control

var defaultCursor : Texture2D
var targetingCursor : Texture2D

var _seed : int = 0

@onready var down: AudioStreamPlayer = $down
@onready var up: AudioStreamPlayer = $up
@onready var picked: AudioStreamPlayer = $picked
@onready var placed: AudioStreamPlayer = $placed
@onready var ambient: AudioStreamPlayer = $ambient
@onready var music: AudioStreamPlayer = $music
@onready var death: AudioStreamPlayer = $death
@onready var explosion: AudioStreamPlayer = $explosion
@onready var click: AudioStreamPlayer = $click

var target_bg_pitch : float = 1

func _ready() -> void:
    TranslationServer.set_locale("en")
    defaultCursor = load("res://art/ui/Cursor.ase")
    targetingCursor = load("res://art/ui/Attack_Icon.ase")
    
    if Array(OS.get_cmdline_args()).has("editor"): return
    get_tree().root.mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func _process(delta: float) -> void:
    if target_bg_pitch != music.pitch_scale:
        music.pitch_scale = lerp(music.pitch_scale, target_bg_pitch, delta*6)
        ambient.pitch_scale = music.pitch_scale

func distance(v1: Vector2, v2: Vector2) -> float:
    return sqrt((v1.x - v2.x)**2 + (v1.y - v2.y)**2);

func wait(seconds: float) -> void:
  await get_tree().create_timer(seconds).timeout
