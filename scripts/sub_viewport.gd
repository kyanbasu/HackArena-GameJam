extends SubViewport

@export var target : Node2D
@export var enemyShip : EnemyShip
var ship : Ship

# Contains reference to weapon
var pickingTarget : ShipModule = null

@export var extensionIndicator : TextureRect

var subViewportContainer : SubViewportContainer

var isMiddleDown := false
var lastCameraPos := Vector2.ZERO
var lastMousePos := Vector2.ZERO

var smoothZoom : float = 1
var targetZoom : float

var minZoom : float = .5
var maxZoom : float = 3

var cameraBound := Vector2(600, 350)

const ZOOM_SPEED = 10
const SIZE_SPEED = 10

var camera : Camera2D

var isMouseOver := false

var targetSize : Vector2
var smoothSize : Vector2 = Vector2.ZERO

const COLLAPSED_SIZE : Vector2 = Vector2(20, 360)
const EXTENDED_SIZE : Vector2 = Vector2(640-140, 360)

func _ready() -> void:
    camera = $Camera
    subViewportContainer = get_parent()
    world_2d = get_tree().root.world_2d
    camera.position = target.position
    lastCameraPos = camera.position
    targetZoom = camera.zoom.x
    targetSize = COLLAPSED_SIZE
    subViewportContainer.size = targetSize
    extensionIndicator.position = Vector2(targetSize.x, targetSize.y/2) - extensionIndicator.size/2


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                if event.pressed and pickingTarget:
                    var selectedPos = Vector2i(floor(enemyShip.get_local_mouse_position()/G.TILE_SIZE)*G.TILE_SIZE)
                    pickingTarget.target = selectedPos
                    pickingTarget = null
                    Input.set_custom_mouse_cursor(G.defaultCursor)
                    enemyShip.targets = []
                    for p in ship.modules.values():
                        if p.part.moduleType == ShipModule.ModuleType.WEAPON and p.part.target != Vector2i.MAX:
                            enemyShip.targets.append(p.part.target)
                        
            # Camera
            MOUSE_BUTTON_WHEEL_DOWN:
                targetZoom -= 0.1
            MOUSE_BUTTON_WHEEL_UP:
                targetZoom += 0.1
            MOUSE_BUTTON_MIDDLE:
                if event.double_click:
                    camera.position = target.position
                if event.pressed:
                    lastCameraPos = camera.position
                    lastMousePos = subViewportContainer.get_local_mouse_position()
                isMiddleDown = event.pressed
        targetZoom = clamp(targetZoom, minZoom, maxZoom)
    if event is InputEventMouseMotion:
        if isMiddleDown:
            camera.position = lastCameraPos - subViewportContainer.get_local_mouse_position() + lastMousePos
            camera.position.x = clamp(camera.position.x, target.position.x - cameraBound.x, target.position.x + cameraBound.x)
            camera.position.y = clamp(camera.position.y, target.position.y - cameraBound.y, target.position.y + cameraBound.y)


func _process(delta):
    #smoothZoom = lerp(smoothZoom, targetZoom, ZOOM_SPEED * delta)
    #if smoothZoom != targetZoom:
        #camera.set_zoom(Vector2(smoothZoom, smoothZoom))
    
    smoothSize = lerp(smoothSize, targetSize, SIZE_SPEED * delta)
    if smoothSize != targetSize:
        size = Vector2i(smoothSize)
        subViewportContainer.size = size
        extensionIndicator.position = Vector2(0, smoothSize.y/2) - extensionIndicator.size/2
        subViewportContainer.position.x = 640 - smoothSize.x
    
        
    
        
func _on_mouse_entered() -> void:
    isMouseOver = true
    #size.x = int(get_tree().root.get_viewport().size.x * 0.8)
    targetSize = EXTENDED_SIZE
    extensionIndicator.flip_v = true


func _on_mouse_exited() -> void:
    isMouseOver = false
    targetSize = COLLAPSED_SIZE
    extensionIndicator.flip_v = false
    #print(get_tree().root.get_viewport().size)
    #size.x = int(get_tree().root.get_viewport().size.x * 0.05)
