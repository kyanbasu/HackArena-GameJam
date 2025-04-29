@tool
extends Node2D
class_name ShipModule

const TILE_SIZE = 32

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
                box.shape.size = Vector2(TILE_SIZE, TILE_SIZE)
                box.position = t * TILE_SIZE
                col_added.append(t)

static func queue_free_children(node: Node) -> void:
    for n in node.get_children():
        node.remove_child(n)
        n.queue_free()

func _draw():
    if Engine.is_editor_hint():
        for t in tiles:
            draw_rect(
                Rect2(TILE_SIZE*t.x - TILE_SIZE/2, TILE_SIZE*t.y - TILE_SIZE/2, TILE_SIZE, TILE_SIZE), 
                Color(0, 1, 0, 0.1))

var health;
var maxHealth = 2;

var energy;
var maxEnergy = 1;

func _ready() -> void:
    health = maxHealth;
    energy = maxEnergy;

func rotate_left() -> void:
    rotation -= PI/2
    for i in len(tiles):
        tiles[i] = Vector2i(tiles[i].y, -tiles[i].x)

func rotate_right() -> void:
    rotation += PI/2
    for i in len(tiles):
        tiles[i] = Vector2i(-tiles[i].y, tiles[i].x)

func _mouse_entered():
    if !get_parent().holdingElement or !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        get_parent().holdingElement = self

func _mouse_exited():
    if !get_parent().isHoldingElement and get_parent().holdingElement == self:
        get_parent().holdingElement = null
