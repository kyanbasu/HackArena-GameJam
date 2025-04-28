extends Node2D

@export var builder : Node2D

func _draw() -> void:
    if builder.holdingElement and builder.isHoldingPlaceButton:
        for t in builder.holdingElement.tiles:
            draw_rect(
                Rect2(
                    floor(get_global_mouse_position().x/builder.holdingElement.TILE_SIZE)*builder.holdingElement.TILE_SIZE + builder.holdingElement.TILE_SIZE*t.x, 
                    floor(get_global_mouse_position().y/builder.holdingElement.TILE_SIZE)*builder.holdingElement.TILE_SIZE + builder.holdingElement.TILE_SIZE*t.y, 
                    builder.holdingElement.TILE_SIZE, builder.holdingElement.TILE_SIZE), 
                Color(0, 1, 0, 0.1)
            )

func _process(delta: float) -> void:
    queue_redraw()
