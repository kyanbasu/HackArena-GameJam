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
    if builder.selectedModule and builder.isHoldingModule:
        for t in builder.selectedModule.tiles:
            var col = Color(0,1,0,0.5)
            if builder.overlapping.has(t):
                col = Color(1,0,0,0.5)
                
            draw_rect(
                Rect2(
                    floor(get_global_mouse_position().x/builder.TILE_SIZE)*builder.TILE_SIZE + builder.TILE_SIZE*t.x, 
                    floor(get_global_mouse_position().y/builder.TILE_SIZE)*builder.TILE_SIZE + builder.TILE_SIZE*t.y, 
                    builder.TILE_SIZE, builder.TILE_SIZE), 
                col
            )

func _process(_delta: float) -> void:
    queue_redraw()
