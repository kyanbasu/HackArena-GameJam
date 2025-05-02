extends Camera2D
class_name Camera

var isMiddleDown := false
var lastCameraPos := Vector2.ZERO
var lastMousePos := Vector2.ZERO

var smooth_zoom : float = 1
var target_zoom : float

var min_zoom : float = 1
var max_zoom : float = 1

var camera_bound := Vector2(600, 350)

const ZOOM_SPEED = 10

var inventory : Inventory

@export var subViewport : SubViewport

func _ready() -> void:
    lastCameraPos = position
    target_zoom = zoom.x
    change_param()

func change_param(_camera_bound: Vector2=Vector2(600, 350), _min_zoom: float=1, _max_zoom: float = 1):
    camera_bound = _camera_bound
    min_zoom = _min_zoom
    max_zoom = _max_zoom
    
    position.x = clamp(position.x, -camera_bound.x, camera_bound.x)
    position.y = clamp(position.y, -camera_bound.y, camera_bound.y)
    target_zoom = clamp(target_zoom, min_zoom, max_zoom)


func _input(event: InputEvent) -> void:
    if inventory.isMouseOver or subViewport.isMouseOver: return
    if event is InputEventMouseButton:
        match event.button_index:
            MOUSE_BUTTON_WHEEL_DOWN:
                target_zoom -= 0.1
            MOUSE_BUTTON_WHEEL_UP:
                target_zoom += 0.1
            MOUSE_BUTTON_MIDDLE:
                if event.double_click:
                    position = Vector2.ZERO
                if event.pressed:
                    lastCameraPos = position
                    lastMousePos = get_local_mouse_position()
                isMiddleDown = event.pressed
        target_zoom = clamp(target_zoom, min_zoom, max_zoom)
    if event is InputEventMouseMotion:
        if isMiddleDown:
            position = lastCameraPos - get_local_mouse_position() + lastMousePos
            position.x = clamp(position.x, -camera_bound.x, camera_bound.x)
            position.y = clamp(position.y, -camera_bound.y, camera_bound.y)

func _process(delta):
    smooth_zoom = lerp(smooth_zoom, target_zoom, ZOOM_SPEED * delta)
    if smooth_zoom != target_zoom:
        set_zoom(Vector2(smooth_zoom, smooth_zoom))
