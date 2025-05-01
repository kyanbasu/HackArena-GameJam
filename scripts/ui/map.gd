extends Node2D
class_name Map

# planetName: {
#   planet: { position: Vector2 },
#   orbit: { rotation: Vector2, offset: Vector2, radius: int }
# }
var planets : Dictionary[String, Dictionary] = {}

# data contains every planet position, orbit, icon and (?)name
func position_planets(data: Dictionary) -> void:
    pass

func _ready() -> void:
    for i in range(30):
        var rot = Vector2(randf_range(.9, 1.1), randf_range(.9, 1.1))
        var rad = (i*2+1) * 20 + 80
        var off = Vector2.ZERO #Vector2(randi_range(-20, 20), randi_range(-20, 20))
        
        planets[str(i)] = {
            "planet": {
                "position": Vector2(randf_range(-1,1), randf_range(-1,1)) * rot * rad
            },
            "orbit": {
                "rotation": rot,
                "radius": rad,
                "offset": off
            }
        }
    
    queue_redraw()

func _draw() -> void:
    var i : float = 0
    for p in planets.values():
        draw_set_transform(p.orbit.offset, 0, p.orbit.rotation)
        draw_circle(Vector2.ZERO, p.orbit.radius, Color.from_hsv(i / planets.size() / 1.33, 1, 1, .25), false, 2)
        draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
        draw_circle(p.planet.position, 30, Color.RED)
        i += 1
    
