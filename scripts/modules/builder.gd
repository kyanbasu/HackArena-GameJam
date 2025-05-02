extends Node2D

class_name Builder

@export var inventory : Inventory

@export var placementGrid : Node2D
@export var spaceGrid : Node2D
@export var BG : TextureRect

@export var active := false:
    set(new_val):
        active = new_val
        if BG:
            BG.visible = new_val
        if spaceGrid:
            spaceGrid.queue_redraw()
        if inventory:
            inventory.visible = new_val
@export var debugOccupied := false

# dictionary of ShipModule in Vector2i(x,y) representing if tile is occupied or not
@export var occupiedSpace : Dictionary[Vector2i, ShipModule] = {}
var lastPartPositionRotation : Vector3

@export var buildableSpace : Dictionary[Vector2i, bool] = {}

@export var overlapping : Array[Vector2i]

var gameNetworkManager

func _draw() -> void:
    if debugOccupied:
        for v in occupiedSpace.keys():
            draw_rect(
            Rect2(G.TILE_SIZE*v.x-2, G.TILE_SIZE*v.y-2, G.TILE_SIZE+4, G.TILE_SIZE+4), 
            Color(1, 0, 0, 0.5), false, 6)
#@export var modules : Dictionary[int, ShipModule]

var selectedModule : ShipModule
var isHoldingModule := false

var ship : Ship

func _ready() -> void:
    ship = get_parent()
    placementGrid.builder = self
    spaceGrid.builder = self
    if inventory: inventory.builder = self
    
    for x in range(-5,6):
        for y in range(-4,5):
            buildableSpace[Vector2i(x,y)] = true

func _input(event: InputEvent) -> void:
    if !active or gameNetworkManager.isReady: return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if selectedModule: #started moving part
                pickup_part(selectedModule)
                
        else:
            if selectedModule and isHoldingModule: #ended moving part
                place_part(selectedModule, get_global_mouse_position())
            isHoldingModule = false
            selectedModule = null
            placementGrid.queue_redraw()
            queue_redraw()
    
    if selectedModule and isHoldingModule and selectedModule.isRotateable:
        if Input.is_action_just_pressed("left"):
            selectedModule.rotate_left()
        elif Input.is_action_just_pressed("right"):
            selectedModule.rotate_right()

func _process(delta: float) -> void:
    if !active or gameNetworkManager.isReady: return
    overlapping = []
    if selectedModule and isHoldingModule:
        selectedModule.global_position = lerp(selectedModule.global_position, get_global_mouse_position(), delta*10*clamp(G.distance(selectedModule.global_position, get_global_mouse_position())/1000, 1, 10))
        overlapping = get_overlap(selectedModule, get_global_mouse_position())
        
        placementGrid.queue_redraw()
        queue_redraw()

func any_overlap(part: ShipModule, pos: Vector2) -> bool:
    for t in part.tiles:
        var chk = t + world_to_grid(pos)
        if occupiedSpace.has(chk) or !buildableSpace.has(chk):
            return true
    return false

func world_to_grid(pos: Vector2) -> Vector2i:
    return Vector2i(floor(pos.x/G.TILE_SIZE), floor(pos.y/G.TILE_SIZE))

func get_overlap(part: ShipModule, pos: Vector2) -> Array[Vector2i]:
    var _o : Array[Vector2i] = []
    for t in part.tiles:
        var chk = t + world_to_grid(pos)
        if occupiedSpace.has(chk) or !buildableSpace.has(chk):
            _o.append(t)
    return _o

# returns if any other module is near this module
func is_part_adjacent(part: ShipModule) -> bool:
    for t in part.tiles:
        if is_part_adjacent_check_one(part, t + Vector2i(1, 0)):
            return true
        if is_part_adjacent_check_one(part, t + Vector2i(-1, 0)):
            return true
        if is_part_adjacent_check_one(part, t + Vector2i(0, 1)):
            return true
        if is_part_adjacent_check_one(part, t + Vector2i(0, -1)):
            return true
    return false

func is_part_adjacent_check_one(part: ShipModule, offset: Vector2i) -> bool:
    var chk = Vector2i(part.global_position/G.TILE_SIZE - Vector2(.5,.5)) + offset
    if occupiedSpace.has(chk) and occupiedSpace[chk] != part:
        return true
    return false

# position will be rounded to grid
func pickup_part(part: ShipModule):
    selectedModule.z_index = 10
    lastPartPositionRotation = Vector3(part.global_position.x, part.global_position.y, part.rotation)
    for t in part.tiles:
        var chk = t + Vector2i(part.global_position/G.TILE_SIZE - Vector2(.5,.5))
        if occupiedSpace.has(chk):
            occupiedSpace.erase(chk)
    inventory.add_module(part)
    if flood_occupied() != occupiedSpace.size():
        var new_pos = Vector2(lastPartPositionRotation.x, lastPartPositionRotation.y)
        place_part(part, new_pos, lastPartPositionRotation.z)
        return
    ship.changed_ship_module(part, false)
    isHoldingModule = true

const FOUR_SIDES : Array[Vector2i] = [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]
func flood_occupied() -> int:
    if occupiedSpace.size() == 0: return 0
    var floodedOccupied : Dictionary[Vector2i, bool] = {}
    var checkQueue : Array[Vector2i] = [occupiedSpace.keys()[0]]
    
    while checkQueue.size() > 0:
        for s in FOUR_SIDES:
            var chk = checkQueue[0] + s
            if occupiedSpace.has(chk) and !floodedOccupied.has(chk):
                checkQueue.append(chk)
        floodedOccupied[checkQueue.pop_front()] = true
    return floodedOccupied.size()
    

# position will be rounded to grid
func place_part(part: ShipModule, _position: Vector2, _rotation: float=-1):
    selectedModule.z_index = 0
    if inventory.isMouseOver:
        part.queue_free()
        return
    if _rotation != -1:
        while (int(abs(part.rotation - _rotation)*180/PI))%360 > 10:
            part.rotate_left()
    @warning_ignore("integer_division")
    part.global_position = Vector2(
        floor(_position.x/G.TILE_SIZE)*G.TILE_SIZE + G.TILE_SIZE - G.TILE_SIZE/2,
        floor(_position.y/G.TILE_SIZE)*G.TILE_SIZE + G.TILE_SIZE - G.TILE_SIZE/2
    )
    #check for collisions and if any part is adjacent or it is the first part
    if any_overlap(part, _position) or (!is_part_adjacent(part) and occupiedSpace.size() > 0):
        if lastPartPositionRotation == Vector3.INF:
            part.queue_free()
            return
        var new_pos = Vector2(lastPartPositionRotation.x, lastPartPositionRotation.y)
        if new_pos == _position:
            return
        place_part(part, new_pos, lastPartPositionRotation.z)
        return
    #reserve space
    for t in part.tiles:
        var v = t + Vector2i(part.global_position/G.TILE_SIZE - Vector2(.5,.5))
        occupiedSpace[v] = part
    ship.changed_ship_module(part, true)
    inventory.add_module(part, -1)
