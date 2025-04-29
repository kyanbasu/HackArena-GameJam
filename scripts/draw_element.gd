extends Node2D

@export var builder : Builder

func _draw() -> void:
    if builder.holdingElement and builder.isHoldingElement:
        for t in builder.holdingElement.tiles:
            var col = Color(0,1,0,0.5)
            if builder.overlapping.has(t):
                col = Color(1,0,0,0.5)
                
            draw_rect(
                Rect2(
                    floor(get_global_mouse_position().x/builder.holdingElement.TILE_SIZE)*builder.holdingElement.TILE_SIZE + builder.holdingElement.TILE_SIZE*t.x, 
                    floor(get_global_mouse_position().y/builder.holdingElement.TILE_SIZE)*builder.holdingElement.TILE_SIZE + builder.holdingElement.TILE_SIZE*t.y, 
                    builder.holdingElement.TILE_SIZE, builder.holdingElement.TILE_SIZE), 
                col
            )

func _process(_delta: float) -> void:
    queue_redraw()
