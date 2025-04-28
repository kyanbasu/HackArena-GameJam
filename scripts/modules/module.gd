@tool
extends Node2D
class_name ShipModule

const TILE_SIZE = 32

# Tiles selection visualisation
@export var tiles : Array[Vector2i]:
    set(new_tiles):
        tiles = new_tiles
        if Engine.is_editor_hint():
            queue_redraw()
            
            if !get_node_or_null("boundingBox"):
                printerr("Please create boundingBox StaticBody2D as the children of module, and connect mouse_entered and mouse_exited signals to module")
                return
            
            $boundingBox.collision_layer = 128 #layer and mask 8 is selectable
            $boundingBox.collision_mask = 128
            $boundingBox.input_pickable = true
            
            # remove all children of bounding box to then redo every for tiles
            queue_free_children($boundingBox)
            for t in tiles:
                var box = CollisionShape2D.new()
                $boundingBox.add_child(box)
                box.owner = self
                box.shape = RectangleShape2D.new()
                box.shape.size = Vector2(TILE_SIZE, TILE_SIZE)
                box.position = t * TILE_SIZE

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
    pass

func rotate_right() -> void:
    pass

func _mouse_entered():
    if !get_parent().holdingElement or !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        get_parent().holdingElement = self

func _mouse_exited():
    if !get_parent().isHoldingElement and get_parent().holdingElement == self:
        get_parent().holdingElement = null
