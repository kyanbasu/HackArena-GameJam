extends Node2D

var builder : Builder

func _draw() -> void:
    if builder.active:
        for v in builder.buildableSpace.keys():
            var col = Color(1,1,0,0.2)
            draw_rect(
                Rect2(
                    G.TILE_SIZE*v.x, 
                    G.TILE_SIZE*v.y,
                    G.TILE_SIZE, G.TILE_SIZE), 
                col
            )
