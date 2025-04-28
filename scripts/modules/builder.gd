extends Node2D


@export var active := false
@export var debugOccupied := false

const TILE_SIZE = 128

# dictionary of ShipModule in matrix [x][y] representing if tile is occupied or not
@export var occupiedSpace := {}
var lastPartPosition : Vector2

func _draw() -> void:
    if debugOccupied:
        for x in occupiedSpace.keys():
            for y in occupiedSpace[x].keys():
                draw_rect(
                Rect2(TILE_SIZE*x-2, TILE_SIZE*y-2, TILE_SIZE+4, TILE_SIZE+4), 
                Color(1, 0, 0, 0.5), false, 6)
#@export var modules : Dictionary[int, ShipModule]

var holdingElement : ShipModule
var isHoldingPlaceButton := false

func _input(event: InputEvent) -> void:
    if !active: return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if holdingElement: #started moving part
                pickup_part(holdingElement)
            isHoldingPlaceButton = true
        else:
            if holdingElement: #ended moving part
                place_part(holdingElement, get_global_mouse_position())
            isHoldingPlaceButton = false

func _process(delta: float) -> void:
    if !active: return
    if holdingElement and isHoldingPlaceButton:
        holdingElement.global_position = lerp(holdingElement.global_position, get_global_mouse_position(), delta*10*clamp(distance(holdingElement.global_position, get_global_mouse_position())/1000, 1, 10))
    
    queue_redraw()

# position will be rounded to grid
func pickup_part(part: ShipModule):
    lastPartPosition = part.global_position
    for t in part.tiles:
        var x = t.x + int(floor(part.global_position.x/part.TILE_SIZE))
        var y = t.y + int(floor(part.global_position.y/part.TILE_SIZE))
        if occupiedSpace.has(x) and occupiedSpace[x].has(y):
            occupiedSpace[x].erase(y)
            if occupiedSpace[x].is_empty():
                occupiedSpace.erase(x)

# position will be rounded to grid
func place_part(part: ShipModule, position: Vector2):
    part.global_position = Vector2(
        floor(position.x/part.TILE_SIZE)*part.TILE_SIZE + part.TILE_SIZE - part.TILE_SIZE/2,
        floor(position.y/part.TILE_SIZE)*part.TILE_SIZE + part.TILE_SIZE - part.TILE_SIZE/2
    )
    #check for collisions
    for t in part.tiles:
        var x = t.x + int(floor(part.global_position.x/part.TILE_SIZE))
        var y = t.y + int(floor(part.global_position.y/part.TILE_SIZE))
        if occupiedSpace.has(x) and occupiedSpace[x].has(y): #collision appeared
            place_part(part, lastPartPosition)
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
