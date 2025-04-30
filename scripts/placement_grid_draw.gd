extends Node2D

var builder : Builder

func _draw() -> void:
    if builder.active and builder.selectedModule and builder.isHoldingModule:
        for t in builder.selectedModule.tiles:
            var col = Color(0,1,0,0.5)
            if builder.overlapping.has(t):
                col = Color(1,0,0,0.5)
                
            draw_rect(
                Rect2(
                    floor(get_global_mouse_position().x/G.TILE_SIZE)*G.TILE_SIZE + G.TILE_SIZE*t.x, 
                    floor(get_global_mouse_position().y/G.TILE_SIZE)*G.TILE_SIZE + G.TILE_SIZE*t.y, 
                    G.TILE_SIZE, G.TILE_SIZE), 
                col
            )
