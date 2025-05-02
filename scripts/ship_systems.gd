extends Node2D
class_name Ship

@export var builder : Builder

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

@export var modules : Dictionary[Vector3i, ShipModule] = {}

func damage(amount: int, _position: Vector2i):
    if builder.occupiedSpace.has(_position): # don't damage anything if projectiles can't hit ship
        builder.occupiedSpace[_position].damage(amount)
        total_damage += amount

func changed_ship_module(part: ShipModule, added: bool):
    var mult = 1 # adds or removes from max systems
    if added:
        modules[Vector3i(part.global_position.x, part.global_position.y, part.rotation_degrees)] = part
    else:
        modules.erase(Vector3i(part.global_position.x, part.global_position.y, part.rotation_degrees))
        mult = -1
    
    max_health += part.maxHealth * mult
    
    match part.moduleType:
        part.ModuleType.COCKPIT:
            max_energy += part.maxEnergy * mult
        part.ModuleType.GENERATOR:
            max_energy += part.maxEnergy * mult
        
        part.ModuleType.ENGINE:
            max_engines += part.maxEnergy * mult
        part.ModuleType.SHIELD:
            max_shield += part.maxEnergy * mult
        part.ModuleType.WEAPON:
            max_weapons += part.maxEnergy * mult
            
    
