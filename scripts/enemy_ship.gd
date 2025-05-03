extends Node2D
class_name EnemyShip

var max_energy : int

# Key: x,y - position, z - rotation
# Value: PackedScene of ShipModule
#@export var parts_list : Dictionary[Vector3i, PackedScene]

@export var targetSelectionTex : Texture2D
var targets : Array[Vector2i]:
    set(new_val):
        targets = new_val
        queue_redraw()

func _draw() -> void:
    for t in targets:
        draw_texture_rect(targetSelectionTex, 
                        Rect2(t, Vector2i(G.TILE_SIZE,G.TILE_SIZE)),
                        false
        )

#func _ready() -> void:
    #for v in parts_list:
        #var part = parts_list[v].instantiate() as ShipModule
        #add_child(part)
        #part.z_index = -10
        #part.position = Vector2(v.x, v.y)
        #part.rotation_degrees = v.z

func clear_children():
    for c in get_children():
        c.queue_free()

func generate_ship(parts : Dictionary[Vector3i, String]):
    clear_children()
    for v in parts:
        var part = load(parts[v]).instantiate() as ShipModule
        add_child(part)
        part.z_index = -10
        part.position = Vector2(v.x, v.y)
        part.rotation_degrees = v.z
