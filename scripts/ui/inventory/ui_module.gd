extends Panel

class_name UIModule

@export var part : PackedScene
var inventory : Inventory

var module_amount : int:
    set(new_value):
        module_amount = new_value
        $amount.text = "x%s" % new_value

var module_name : String:
    set(new_value):
        module_name = new_value
        $name.text = new_value

var module_desc : String:
    set(new_value):
        module_desc = new_value
        $desc.text = new_value

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
        inventory.get_module(part)
