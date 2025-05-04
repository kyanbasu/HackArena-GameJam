extends Node2D

@export var shields : Array[Node2D]

func set_level(level: int=0):
    for s in shields:
        s.visible = false
        
    if level > 0:
        shields[min(level, shields.size())].visible = true
