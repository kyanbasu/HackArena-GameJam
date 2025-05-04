@tool
extends Node2D
class_name ShipModule

enum ModuleType {
    EMPTY,
    COCKPIT,
    ENGINE,
    SHIELD,
    WEAPON,
    GENERATOR,
    OXYGEN
}

@export var moduleType: ModuleType = ModuleType.EMPTY

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

@export var isRotateable : bool = true

# Total health of module
@export var maxHealth = 2;
var health;

# Total energy used by module
@export var maxEnergy : int = 0;
var energy : int = 0:
    set(nv):
        energy = nv
        if battery:
            battery.value = batTexOff + nv * 0.15

@export var batteryOffset : Vector2i = Vector2i(1,0)

func _ready() -> void:
    health = maxHealth;
    
    #Randomize floor tiles
    if has_node("floor"):
        var tex = get_node("floor").get("texture").duplicate()
        tex.region = Rect2(Vector2(tex.region.size.x * randi_range(0,4), 0), tex.region.size)
        get_node("floor").set("texture", tex)

func rotate_left() -> void:
    if !isRotateable: return
    rotation -= PI/2
    rotation_degrees = int(rotation_degrees) % 360
    for i in len(tiles):
        tiles[i] = Vector2i(tiles[i].y, -tiles[i].x)

func rotate_right() -> void:
    if !isRotateable: return
    rotation += PI/2
    rotation_degrees = int(rotation_degrees) % 360
    for i in len(tiles):
        tiles[i] = Vector2i(-tiles[i].y, tiles[i].x)

func deal_damage(amount: int) -> void:
    if health - amount < 0:
        health = 0
        return
    health -= amount

func _mouse_entered():
    if !get_parent().selectedModule or !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        get_parent().selectedModule = self

func _mouse_exited():
    if !get_parent().isHoldingModule and get_parent().selectedModule == self:
        get_parent().selectedModule = null


var icon : Node2D = null
var battery : TextureProgressBar = null
var batTexOff : float = 0

func update_icons():
    if moduleType == ModuleType.EMPTY: return
    if !icon:
        icon = load("res://prefabs/ui/module_icon.tscn").instantiate()
        add_child(icon)
        var off : Vector2
        match moduleType:
            ModuleType.COCKPIT:
                off = Vector2(0,0)
            ModuleType.SHIELD:
                off = Vector2(32,0)
            ModuleType.OXYGEN:
                off = Vector2(64,0)
            ModuleType.WEAPON:
                off = Vector2(96,0)
            ModuleType.ENGINE:
                off = Vector2(128,0)
            ModuleType.GENERATOR:
                off = Vector2(160,0)
        
        var tex = icon.get("texture").duplicate()
        tex.region = Rect2(off, Vector2(32,32))
        icon.set("texture", tex)
        
    if !battery and maxEnergy > 0 and maxEnergy <= 5:
        battery = load("res://prefabs/ui/battery_icon.tscn").instantiate()
        add_child(battery)
        var off : Vector2
        match maxEnergy:
            1:
                off = Vector2(0,0)
                batTexOff = 0.37
            2:
                off = Vector2(32,0)
                batTexOff = 0.3
            3:
                off = Vector2(0,32)
                batTexOff = 0.21
            4:
                off = Vector2(32,32)
                batTexOff = 0.15
            5:
                off = Vector2(0,64)
                batTexOff = 0.06

        # under
        var tex = battery.get("texture_under").duplicate()
        tex.region = Rect2(off, Vector2(32,32))
        battery.set("texture_under", tex)
        
        # overlay
        tex = battery.get("texture_progress").duplicate()
        tex.region = Rect2(off, Vector2(32,32))
        battery.set("texture_progress", tex)
        battery.position = batteryOffset * G.TILE_SIZE - Vector2i(battery.size/2)
