extends SubViewport

@export var target : Node2D

var subViewportContainer : SubViewportContainer

var isMouseOver := false

func _ready() -> void:
    subViewportContainer = get_parent()
    world_2d = get_tree().root.world_2d
    size = Vector2i(subViewportContainer.size)
    subViewportContainer.size = size
    $Camera.position = target.position


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
    #print(event)
    pass

func _on_mouse_entered() -> void:
    isMouseOver = true
    #size.x = int(get_tree().root.get_viewport().size.x * 0.8)


func _on_mouse_exited() -> void:
    isMouseOver = false
    #print(get_tree().root.get_viewport().size)
    #size.x = int(get_tree().root.get_viewport().size.x * 0.05)
