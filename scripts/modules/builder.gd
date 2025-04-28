extends Node2D


@export var active = false

var holdingElement : ShipModule
var isHoldingPlaceButton := false

func _input(event: InputEvent) -> void:
    if !active: return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            print("pressed")
            isHoldingPlaceButton = true
        else:
            print("released")
            if holdingElement:
                holdingElement.global_position = Vector2(
                    floor(get_global_mouse_position().x/holdingElement.TILE_SIZE)*holdingElement.TILE_SIZE + holdingElement.TILE_SIZE - holdingElement.TILE_SIZE/2,
                    floor(get_global_mouse_position().y/holdingElement.TILE_SIZE)*holdingElement.TILE_SIZE + holdingElement.TILE_SIZE - holdingElement.TILE_SIZE/2
                )
            isHoldingPlaceButton = false

func _process(delta: float) -> void:
    if !active: return
    if holdingElement and isHoldingPlaceButton:
        holdingElement.global_position = lerp(holdingElement.global_position, get_global_mouse_position(), delta*10*clamp(distance(holdingElement.global_position, get_global_mouse_position())/1000, 1, 10))
        queue_redraw()
        
func distance(v1: Vector2, v2: Vector2) -> float:
    return sqrt((v1.x + v2.x)**2 + (v1.y + v2.y)**2);
