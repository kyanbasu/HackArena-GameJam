extends Node2D

@export var builder : Builder

func _draw() -> void:
    if builder.holdingElement and builder.isHoldingElement:
        for t in builder.holdingElement.tiles:
            draw_rect(
                Rect2(
                    floor(get_global_mouse_position().x/builder.holdingElement.TILE_SIZE)*builder.holdingElement.TILE_SIZE + builder.holdingElement.TILE_SIZE*t.x, 
                    floor(get_global_mouse_position().y/builder.holdingElement.TILE_SIZE)*builder.holdingElement.TILE_SIZE + builder.holdingElement.TILE_SIZE*t.y, 
                    builder.holdingElement.TILE_SIZE, builder.holdingElement.TILE_SIZE), 
                Color.WHITE
            )

func _process(_delta: float) -> void:
    if builder.overlapping:
        material.set_shader_parameter("Color", Color(1, 0, 0, 0.4))
    else:
        material.set_shader_parameter("Color", Color(0, 1, 0, 0.4))
    queue_redraw()
