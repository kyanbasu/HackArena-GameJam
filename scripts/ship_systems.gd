extends Node2D
class_name Ship

@export var builder : Builder

# main systems
var max_health : int
var total_damage : int #is just negative health, real health is max_health-damage

var max_energy : int
var energy : int

# distributing energy to modules
var max_shield : int
var shield : int

var max_oxygen : int
var oxygen : int

var max_thrusters : int
var thrusters : int

var max_weapons : int
var weapons : int


func damage(amount: int, _position: Vector2i):
    if builder.occupiedSpace.has(_position): # don't damage anything if projectiles can't hit ship
        builder.occupiedSpace[_position].damage(amount)
        total_damage += amount
