extends Camera2D

var isMiddleDown := false
var lastCameraPos := Vector2.ZERO
var lastMousePos := Vector2.ZERO

var smooth_zoom : float = 1
var target_zoom : float

const ZOOM_SPEED = 10

const CAMERA_BOUND := Vector2(600, 350)

func _ready() -> void:
    target_zoom = zoom.x

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        match event.button_index:
            MOUSE_BUTTON_WHEEL_DOWN:
                target_zoom -= 0.1
            MOUSE_BUTTON_WHEEL_UP:
                target_zoom += 0.1
            MOUSE_BUTTON_MIDDLE:
                if event.pressed:
                    lastCameraPos = position
                    lastMousePos = get_local_mouse_position()
                isMiddleDown = event.pressed
        target_zoom = clamp(target_zoom, 0.5, 5)
    if event is InputEventMouseMotion:
        if isMiddleDown:
            position = lastCameraPos - get_local_mouse_position() + lastMousePos
            position.x = clamp(position.x, -CAMERA_BOUND.x, CAMERA_BOUND.x)
            position.y = clamp(position.y, -CAMERA_BOUND.y, CAMERA_BOUND.y)

func _process(delta):
    smooth_zoom = lerp(smooth_zoom, target_zoom, ZOOM_SPEED * delta)
    if smooth_zoom != target_zoom:
        set_zoom(Vector2(smooth_zoom, smooth_zoom))
