extends Node

const TILE_SIZE : int = 32


func distance(v1: Vector2, v2: Vector2) -> float:
    return sqrt((v1.x - v2.x)**2 + (v1.y - v2.y)**2);
