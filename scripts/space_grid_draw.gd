extends Node2D

@export var builder : Builder

func _draw() -> void:
    for x in builder.buildableSpace.keys():
        for y in builder.buildableSpace[x].keys():
            var col = Color(1,1,0,0.2)
            draw_rect(
                Rect2(
                    builder.TILE_SIZE*x, 
                    builder.TILE_SIZE*y, 
                    builder.TILE_SIZE, builder.TILE_SIZE), 
                col
            )

func _process(_delta: float) -> void:
    queue_redraw()
