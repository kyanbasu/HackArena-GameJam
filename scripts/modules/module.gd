@tool
extends Node2D
class_name ShipModule

@export var isRotateable : bool = true

@export var tiles : Array[Vector2i]:
    set(new_tiles):
        tiles = new_tiles.duplicate() #duplicate fixes unique array problem
        if Engine.is_editor_hint(): # Tiles selection visualisation
            queue_redraw()
            
            if !get_node_or_null("boundingBox"):
                printerr("Please create boundingBox StaticBody2D as the children of module, and connect mouse_entered and mouse_exited signals to module")
                return
            
            $boundingBox.collision_layer = 128 #layer and mask 8 is selectable
            $boundingBox.collision_mask = 128
            $boundingBox.input_pickable = true
            
            # remove all children of bounding box to then redo every for tiles
            queue_free_children($boundingBox)
            var col_added : Array[Vector2i] = []
            for t in tiles:
                if t in col_added: continue
                var box = CollisionShape2D.new()
                $boundingBox.add_child(box)
                box.owner = self
                box.name = "%s,%s" % [t.x, t.y]
                box.shape = RectangleShape2D.new()
                box.shape.size = Vector2(G.TILE_SIZE, G.TILE_SIZE)
                box.position = t * G.TILE_SIZE
                col_added.append(t)

static func queue_free_children(node: Node) -> void:
    for n in node.get_children():
        node.remove_child(n)
        n.queue_free()

func _draw():
    if Engine.is_editor_hint():
        for t in tiles:
            @warning_ignore("integer_division")
            draw_rect(
                Rect2(G.TILE_SIZE*t.x - G.TILE_SIZE/2, G.TILE_SIZE*t.y - G.TILE_SIZE/2, G.TILE_SIZE, G.TILE_SIZE), 
                Color(0, 1, 0, 0.1)
            )

var health;
var maxHealth = 2;

var energy;
var maxEnergy = 1;

func _ready() -> void:
    health = maxHealth;
    energy = maxEnergy;

func rotate_left() -> void:
    if !isRotateable: return
    rotation -= PI/2
    for i in len(tiles):
        tiles[i] = Vector2i(tiles[i].y, -tiles[i].x)

func rotate_right() -> void:
    if !isRotateable: return
    rotation += PI/2
    for i in len(tiles):
        tiles[i] = Vector2i(-tiles[i].y, tiles[i].x)

func _mouse_entered():
    if !get_parent().selectedModule or !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        get_parent().selectedModule = self

func _mouse_exited():
    if !get_parent().isHoldingModule and get_parent().selectedModule == self:
        get_parent().selectedModule = null
