extends Node2D

var builder : Builder

func _draw() -> void:
    if builder.active:
        for v in builder.buildableSpace.keys():
            var col = Color(1,1,0,0.2)
            draw_rect(
                Rect2(
                    builder.TILE_SIZE*v.x, 
                    builder.TILE_SIZE*v.y,
                    builder.TILE_SIZE, builder.TILE_SIZE), 
                col
            )
