extends Node2D
class_name EnemyShip

var max_energy : int
var health : int:
    set(nv):
        health = nv
        refresh_ui()
var shields : int:
    set(nv):
        shields = nv
        refresh_ui()

# Key: x,y - position, z - rotation
# Value: PackedScene of ShipModule
#@export var parts_list : Dictionary[Vector3i, PackedScene]

@export var healthBar : TextureProgressBar

# Stacks of healthbars
var healthBarColors : Array = [
    Color("212123"), #empty
    Color("c2d368"),
    Color(.8, .1, .2),
    Color(.2, .3, .8),
    Color(.8, .8, .1),
    Color(.9, .1, .9),
    Color(.6, .2, .9),
    Color(.2, .9, .9)
]

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

func refresh_ui():
    if has_node("../shields"):
        get_node("../shields").set_level(shields)
    
    var currHealth = health
    @warning_ignore("integer_division")
    var barIndex = floor(currHealth / 50)
    
    currHealth = currHealth % 50
    
    if barIndex + 2 > healthBarColors.size():
        barIndex = healthBarColors.size()-2
        currHealth = 50
    
    healthBar.value = currHealth/50.0
    healthBar.tint_progress = healthBarColors[barIndex+1]
    healthBar.get_child(0).self_modulate = healthBarColors[barIndex]
