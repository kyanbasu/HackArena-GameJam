extends Button

var scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

func _on_button_down() -> void:
    if scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT:
        scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        text = "canvas_items"
    else:
        scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
        text = "viewport"
    get_tree().root.content_scale_mode = scale_mode
