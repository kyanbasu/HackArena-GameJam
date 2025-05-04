extends Node2D
class_name Ship

@export var builder : Builder
@export var healthBar : TextureProgressBar
@export var systemsPanel : Container

@export var enemySubViewport : SubViewport

# Stacks of healthbars
var healthBarColors : Array = [
    Color("212123"), #empty
    Color("c2d368"),
    Color(.8, .1, .2),
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

# distributed energy to modules
var shields : int
var oxygen : int
var engines : int
var weapons : int

# Vector3i(pos.x, pos.y, rotation_degrees) -> {part: ShipModule, ui: Control}
@export var modules : Dictionary[Vector3i, Dictionary] = {}

@export var panelModule : PackedScene

func _ready() -> void:
    enemySubViewport.ship = self

func damage(amount: int, _position: Vector2i):
    _position = _position/G.TILE_SIZE
    if builder.occupiedSpace.has(_position): # don't damage anything if projectiles can't hit ship
        # Shield absorbing, doesnt do any damage if shield absorbs all
        if shields * 4 > amount:
            return
        amount -= shields*4
        
        # Chance for dodging
        var chance = log(engines+1) / log(100)
        #print("change to dodge ", chance)
        if chance > randf():
            return
        
        builder.occupiedSpace[_position].deal_damage(amount)
        total_damage += amount
        var vec = Vector3i(
            int(builder.occupiedSpace[_position].global_position.x),
            int(builder.occupiedSpace[_position].global_position.y),
            int(builder.occupiedSpace[_position].rotation_degrees)
            )
        if modules[vec].has("ui"):
            modules[vec].ui.get_node("bar").value = float(modules[vec].part.health) / modules[vec].part.maxHealth
        
        if modules[vec].part.health <= 0 and modules[vec].part.energy > 0:
            used_energy -= modules[vec].part.energy
            add_module_group_energy(modules[vec].part, -modules[vec].part.energy)
            modules[vec].part.energy = 0
        
        refresh_ui()



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
        part.update_icons()
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
                add_module_group_energy(modules[v].part, -1)
    refresh_ui()

func reset_all_energy():
    for v in modules.keys():
        if modules[v].part.energy > 0:
            modules[v].part.energy = 0
            used_energy -= modules[v].part.energy
            add_module_group_energy(modules[v].part, -modules[v].part.energy)
    builder.gameNetworkManager.enemyShip.targets = []
    refresh_ui()

func reset_weapons():
    for v in modules.keys():
        if modules[v].part.moduleType == ShipModule.ModuleType.WEAPON and modules[v].part.energy > 0:
            used_energy -= modules[v].part.energy
            add_module_group_energy(modules[v].part, -modules[v].part.energy)
            modules[v].part.energy = 0
            modules[v].part.target = Vector2i.MAX
    builder.gameNetworkManager.enemyShip.targets = []
    refresh_ui()

# Disposes entire energy for shields and engines
func do_reinforcements():
    reset_all_energy()
    for v in modules.keys():
        if used_energy == max_energy: return
        if modules[v].part.moduleType == ShipModule.ModuleType.WEAPON or modules[v].part.moduleType == ShipModule.ModuleType.SHIELD:
            modules[v].part.energy += modules[v].part.maxEnergy
            used_energy += modules[v].part.maxEnergy
            add_module_group_energy(modules[v].part, modules[v].part.maxEnergy)
    refresh_ui()

func create_panel_module(vec: Vector3i):
    var ins = panelModule.instantiate() as Control
    systemsPanel.add_child(ins)
    ins.gui_input.connect(panel_module_input.bind(vec))
    ins.mouse_exited.connect(panel_module_mouse_exited.bind(vec))
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

var lastModulatedPart = null
func modulate_part(part: ShipModule=null):
    if lastModulatedPart:
        lastModulatedPart.modulate = Color.WHITE
    if part != null:
        part.modulate = Color(.3,1,.3)
    lastModulatedPart = part    

func panel_module_mouse_exited(v: Vector3i):
    modules[v].part.modulate = Color.WHITE

func panel_module_input(event, v: Vector3i):
    modules[v].part.modulate = Color(.3,1,.3)
    if !builder.gameNetworkManager.isMyFightingTurn and !builder.active: return
    if modules[v].part.health <= 0: return
    if event is InputEventMouseButton and event.pressed:
        # increase used energy
        if event.button_index == MOUSE_BUTTON_LEFT and modules[v].part.energy < modules[v].part.maxEnergy and used_energy < max_energy:
            if modules[v].part.moduleType == ShipModule.ModuleType.WEAPON:
                if builder.gameNetworkManager.playerFighting == 0: return
                enemySubViewport.pickingTarget = modules[v].part # Selecting target for weapon
                Input.set_custom_mouse_cursor(G.targetingCursor)
            add_module_group_energy(modules[v].part, 1)
            modules[v].part.energy += 1
            used_energy += 1
            G.down.play()
        # decrease used energy
        elif event.button_index == MOUSE_BUTTON_RIGHT and modules[v].part.energy > 0:
            if modules[v].part.moduleType == ShipModule.ModuleType.WEAPON:
                enemySubViewport.pickingTarget = null
                Input.set_custom_mouse_cursor(G.defaultCursor)
            add_module_group_energy(modules[v].part, -1)
            modules[v].part.energy -= 1
            used_energy -= 1
            G.up.play()
        
        refresh_ui()

func add_module_group_energy(part: ShipModule, amount: int):
    if part.moduleType == ShipModule.ModuleType.WEAPON:
        weapons += amount
    elif part.moduleType == ShipModule.ModuleType.ENGINE:
        engines += amount
    elif part.moduleType == ShipModule.ModuleType.SHIELD:
        shields += amount
    elif part.moduleType == ShipModule.ModuleType.OXYGEN:
        oxygen += amount

func refresh_ui():
    if G.currencyNEnergy:
        G.currencyNEnergy.get_node("energy").text = str(max_energy - used_energy)

    var currHealth = max_health - total_damage
    @warning_ignore("integer_division")
    var barIndex = floor(currHealth / 50)
    
    currHealth = currHealth % 50
    
    if barIndex + 2 > healthBarColors.size():
        barIndex = healthBarColors.size()-2
        currHealth = 50
    
    healthBar.value = currHealth/50.0
    healthBar.tint_progress = healthBarColors[barIndex+1]
    healthBar.get_child(0).self_modulate = healthBarColors[barIndex]
