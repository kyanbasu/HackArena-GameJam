extends CanvasLayer

class_name Inventory

var builder: Builder

var materials : int = 0 #same as money, scrap

@export var uiModulesContainer : Container
@export var uiModule : PackedScene

# module and its amount, if amount is 0 delete it(?) or will it stay as if you have unlocked it(?)
@export var modules : Dictionary[PackedScene, int] = {}
@export var ui_modules : Dictionary[PackedScene, UIModule] = {}

var isMouseOver := false

func _ready() -> void:
    builder.gameNetworkManager.camera.inventory = self # d-_-b cool
    for m in modules.keys():
        create_ui_module(m)

func create_ui_module(part: PackedScene):
    var ui_mod = uiModule.instantiate() as UIModule
    ui_modules[part] = ui_mod
    ui_mod.part = part
    ui_mod.inventory = self
    ui_mod.module_amount = modules[part]
    ui_mod.mouse_filter = Control.MOUSE_FILTER_PASS
    ui_mod.module_name = get_name_from_file(part)
    uiModulesContainer.add_child(ui_mod)

static func get_name_from_file(scene: PackedScene):
    return scene.resource_path.get_file().trim_suffix('.tscn').replace("_", " ")

func update_ui_module(part: PackedScene):
    if ui_modules.has(part):
        ui_modules[part].module_amount = modules[part]
    else:
        create_ui_module(part)
        
func add_module(part: ShipModule, amount: int=1) -> bool:
    if part.has_meta("packed_scene"):
        var s = part.get_meta("packed_scene", PackedScene) #getting PackedScene from instance
        if modules.has(s):
            if modules[s] + amount < 0: return false
            modules[s] += amount
        else:
            if amount <= 0: return false
            modules[s] = amount
        
        update_ui_module(s)
    return true

#takes ShipModule with meta packed_scene as argument
func remove_module(part: ShipModule) -> void:
    if part.has_meta("packed_scene"):
        var s = part.get_meta("packed_scene", PackedScene) #getting PackedScene from instance
        remove_module_scene(s)

#takes PackedScene as argument
func remove_module_scene(part: PackedScene) -> Error:
    if modules.has(part) and modules[part] > 0:
        modules[part] -= 1
        update_ui_module(part)
        return OK
    else:
        print("what? you dont have this module")
        return ERR_PRINTER_ON_FIRE

func get_module(part: PackedScene) -> ShipModule:
    if builder.active and !builder.gameNetworkManager.isReady and modules.has(part) and modules[part] > 0:
        update_ui_module(part)
        var p = part.instantiate() as ShipModule
        p.set_meta("packed_scene", part)
        p.z_index = 10
        builder.selectedModule = p
        builder.isHoldingModule = true
        builder.lastPartPositionRotation = Vector3.INF
        p.global_position = builder.get_global_mouse_position()
        builder.add_child(p)
    return null

func _on_mouse_entered() -> void:
    isMouseOver = true


func _on_mouse_exited() -> void:
    isMouseOver = false
