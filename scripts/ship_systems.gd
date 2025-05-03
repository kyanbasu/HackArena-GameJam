extends Node2D
class_name Ship

@export var builder : Builder
@export var healthBar : ProgressBar
@export var systemsPanel : Container

# Stacks of healthbars
var healthBarColors : Array = [
    Color("#212123"), #empty
    Color(.8, .2, .2),
    Color(.3, .8, .2),
    Color(.2, .3, .8),
    Color(.8, .8, .1),
    Color(.9, .1, .9),
    Color(.6, .2, .9),
    Color(.2, .9, .9)
]

# main systems
var max_health : int
var total_damage : int #is just negative health, real health is max_health-damage

var max_energy : int
var used_energy : int

# distributing energy to modules
var max_shield : int
var shield : int

var max_oxygen : int
var oxygen : int

var max_engines : int
var thrusters : int

var max_weapons : int
var weapons : int

# Vector3i(pos.x, pos.y, rotation_degrees) -> {part: ShipModule, ui: Control}
@export var modules : Dictionary[Vector3i, Dictionary] = {}

@export var panelModule : PackedScene

func damage(amount: int, _position: Vector2i):
    if builder.occupiedSpace.has(_position): # don't damage anything if projectiles can't hit ship
        builder.occupiedSpace[_position].damage(amount)
        total_damage += amount
        
        refresh_health_bar()

func refresh_health_bar():
    var currHealth = max_health - total_damage
    @warning_ignore("integer_division")
    var barIndex = floor(currHealth / 50)
    
    currHealth = currHealth % 50
    
    if barIndex + 2 > healthBarColors.size():
        barIndex = healthBarColors.size()-2
        currHealth = 50
    
    healthBar.value = currHealth/50.0
    healthBar.get("theme_override_styles/fill").bg_color = healthBarColors[barIndex+1]
    healthBar.get_child(0).self_modulate = healthBarColors[barIndex]

func changed_ship_module(part: ShipModule, added: bool):
    var mult = 1 # adds or removes from max systems
    var vec = Vector3i(
            int(part.global_position.x),
            int(part.global_position.y),
            int(part.rotation_degrees)
            )
    if added:
        if !modules.has(vec):
            modules[vec] = {}
        modules[vec].part = part
        if part.moduleType != ShipModule.ModuleType.EMPTY:
            create_panel_module(vec)
    else:
        if modules[vec].has("ui"):
            modules[vec].ui.queue_free()
        modules.erase(vec)
        mult = -1
    
    max_health += part.maxHealth * mult
    
    match part.moduleType:
        part.ModuleType.COCKPIT: #cockpit increases max_energy (generates energy)
            max_energy -= part.maxEnergy * mult
    
    if max_energy < 0: return #what
    while max_energy < used_energy:
        for v in modules.keys():
            if modules[v].part.energy > 0:
                modules[v].part.energy -= 1
                used_energy -= 1
    refresh_health_bar()
    refresh_ui()

func create_panel_module(vec: Vector3i):
    var ins = panelModule.instantiate() as Control
    systemsPanel.add_child(ins)
    ins.gui_input.connect(panel_module_input.bind(vec))
    systemsPanel.move_child(systemsPanel.get_node("moduleEnd"), -1) # set it to be at the end
    
    var tex = ins.get_node("icon").get("texture").duplicate()
    match modules[vec].part.moduleType:
        ShipModule.ModuleType.COCKPIT:
            tex.region = Rect2(0, 0, 16, 16)
        ShipModule.ModuleType.SHIELD:
            tex.region = Rect2(16, 0, 16, 16)
        ShipModule.ModuleType.ENGINE:
            tex.region = Rect2(32, 0, 16, 16)
        ShipModule.ModuleType.GENERATOR:
            tex.region = Rect2(48, 0, 16, 16)
        ShipModule.ModuleType.OXYGEN:
            tex.region = Rect2(0, 16, 16, 16)
        ShipModule.ModuleType.WEAPON:
            tex.region = Rect2(16, 16, 16, 16)
    
    ins.get_node("icon").set("texture", tex)
    
    modules[vec].ui = ins

# to use, if some modules are in group
func get_part_with_the_same_part(type) -> Vector3i:
    for v in modules.keys():
        if modules[v].part.ModuleType == type:
            return v
    return Vector3i.MAX

func panel_module_input(event, v: Vector3i):
    if event is InputEventMouseButton and event.pressed:
        # increase used energy
        if event.button_index == MOUSE_BUTTON_LEFT and modules[v].part.energy < modules[v].part.maxEnergy and used_energy < max_energy:
            modules[v].part.energy += 1
            used_energy += 1
        # decrease used energy
        elif event.button_index == MOUSE_BUTTON_RIGHT and modules[v].part.energy > 0:
            modules[v].part.energy -= 1
            used_energy -= 1
        
        refresh_ui()
        

func refresh_ui():
    if G.currencyNEnergy:
        G.currencyNEnergy.get_node("energy").text = str(max_energy - used_energy)
