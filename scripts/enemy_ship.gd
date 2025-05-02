extends Node2D
class_name EnemyShip

# Key: x,y - position, z - rotation
# Value: PackedScene of ShipModule
@export var parts_list : Dictionary[Vector3i, PackedScene]

@export var targetSelectionTex : Texture2D
var targets : Array[Vector2i]:
    set(new_val):
        targets = new_val
        queue_redraw()

func _draw() -> void:
    for t in targets:
        draw_texture_rect(targetSelectionTex, 
                        Rect2(t - Vector2i(G.TILE_SIZE,G.TILE_SIZE)/2, Vector2i(G.TILE_SIZE,G.TILE_SIZE)),
                        false
        )

func _ready() -> void:
    for v in parts_list:
        var part = parts_list[v].instantiate() as ShipModule
        add_child(part)
        part.z_index = -10
        part.position = Vector2(v.x, v.y)
        part.rotation_degrees = v.z
