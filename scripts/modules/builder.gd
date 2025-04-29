extends Node2D

class_name Builder

@export var parts : Array[PackedScene]

@export var active := false
@export var debugOccupied := false

const TILE_SIZE = 32

# dictionary of ShipModule in matrix [x][y] representing if tile is occupied or not
@export var occupiedSpace := {}
var lastPartPositionRotation : Vector3

@export var buildableSpace := {}

@export var overlapping : Array[Vector2i]

func _draw() -> void:
    if debugOccupied:
        for x in occupiedSpace.keys():
            for y in occupiedSpace[x].keys():
                draw_rect(
                Rect2(TILE_SIZE*x-2, TILE_SIZE*y-2, TILE_SIZE+4, TILE_SIZE+4), 
                Color(1, 0, 0, 0.5), false, 6)
#@export var modules : Dictionary[int, ShipModule]

var holdingElement : ShipModule
var isHoldingElement := false

func _ready() -> void:
    for x in range(-4,5):
        for y in range(-4,5):
            if !buildableSpace.has(x):
                buildableSpace[x] = {}
            buildableSpace[x][y] = true
    var p = parts[1].instantiate()
    add_child(p)
    place_part(p, Vector2(500, 200))
    
    p = parts[1].instantiate()
    add_child(p)
    place_part(p, Vector2(0, 200))
    
    p = parts[0].instantiate()
    add_child(p)
    place_part(p, Vector2(-200, 200))
    
    p = parts[0].instantiate()
    add_child(p)
    place_part(p, Vector2(-200, 0))

func _input(event: InputEvent) -> void:
    if !active: return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if holdingElement: #started moving part
                pickup_part(holdingElement)
                isHoldingElement = true
        else:
            if holdingElement and isHoldingElement: #ended moving part
                place_part(holdingElement, get_global_mouse_position())
            isHoldingElement = false
    
    if holdingElement and isHoldingElement:
        if Input.is_action_just_pressed("left"):
            holdingElement.rotate_left()
        elif Input.is_action_just_pressed("right"):
            holdingElement.rotate_right()

func _process(delta: float) -> void:
    if !active: return
    overlapping = []
    if holdingElement and isHoldingElement:
        holdingElement.global_position = lerp(holdingElement.global_position, get_global_mouse_position(), delta*10*clamp(distance(holdingElement.global_position, get_global_mouse_position())/1000, 1, 10))
        overlapping = get_overlap(holdingElement, get_global_mouse_position())
        
    
    queue_redraw()

func any_overlap(part: ShipModule, _position: Vector2) -> bool:
    for t in part.tiles:
        var x = t.x + int(floor(_position.x/part.TILE_SIZE))
        var y = t.y + int(floor(_position.y/part.TILE_SIZE))
        if (occupiedSpace.has(x) and occupiedSpace[x].has(y)) or (!buildableSpace.has(x) or !buildableSpace[x].has(y)):
            return true
    return false

func get_overlap(part: ShipModule, _position: Vector2) -> Array[Vector2i]:
    var _o : Array[Vector2i] = []
    for t in part.tiles:
        var x = t.x + int(floor(_position.x/part.TILE_SIZE))
        var y = t.y + int(floor(_position.y/part.TILE_SIZE))
        if (occupiedSpace.has(x) and occupiedSpace[x].has(y)) or (!buildableSpace.has(x) or !buildableSpace[x].has(y)):
            _o.append(t)
    return _o

# position will be rounded to grid
func pickup_part(part: ShipModule):
    lastPartPositionRotation = Vector3(part.global_position.x, part.global_position.y, part.rotation)
    for t in part.tiles:
        var x = t.x + int(floor(part.global_position.x/part.TILE_SIZE))
        var y = t.y + int(floor(part.global_position.y/part.TILE_SIZE))
        if occupiedSpace.has(x) and occupiedSpace[x].has(y):
            occupiedSpace[x].erase(y)
            if occupiedSpace[x].is_empty():
                occupiedSpace.erase(x)

# position will be rounded to grid
func place_part(part: ShipModule, _position: Vector2, _rotation: float=-1):
    if _rotation != -1:
        while (int(abs(part.rotation - _rotation)*180/PI))%360 > 10:
            part.rotate_left()
    part.global_position = Vector2(
        floor(_position.x/part.TILE_SIZE)*part.TILE_SIZE + part.TILE_SIZE - part.TILE_SIZE/2,
        floor(_position.y/part.TILE_SIZE)*part.TILE_SIZE + part.TILE_SIZE - part.TILE_SIZE/2
    )
    #check for collisions
    if any_overlap(part, _position):
        var new_pos = Vector2(lastPartPositionRotation.x, lastPartPositionRotation.y)
        if new_pos == _position:
            return
        place_part(part, new_pos, lastPartPositionRotation.z)
        return
    #reserve space
    for t in part.tiles:
        var x = t.x + int(floor(part.global_position.x/part.TILE_SIZE))
        var y = t.y + int(floor(part.global_position.y/part.TILE_SIZE))
        if !occupiedSpace.has(x):
            occupiedSpace[x] = {y: part}
        else:
            occupiedSpace[x][y] = part

func distance(v1: Vector2, v2: Vector2) -> float:
    return sqrt((v1.x + v2.x)**2 + (v1.y + v2.y)**2);
