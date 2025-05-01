extends Node2D
class_name Map

# planetIndex: {
#   planet: { position: Vector2, node: Node2D },
#   orbit: { rotation: Vector2, offset: Vector2, radius: int }
# }
var planets : Dictionary[int, Dictionary] = {}

@export var planet : PackedScene

@export var playerPlanet : int = 0
@export var playerRange : int = 300
@export var nextPlayerPlanet : int

var planetCount = 30

#contains clickable planets node references
var planetNodes : Dictionary[int, Button] = {}

# data contains every planet position, orbit, icon and (?)name
func host_position_planets() -> void:
    if planets.size() == 0:
        init.rpc()
    else:
        for p in planets.values():
            var rot = p.orbit.rotation
            var rad = p.orbit.radius
            var planet_rot = randf_range(0, TAU)
            var new_planet_pos = Vector2(rot.x * cos(planet_rot), rot.y * sin(planet_rot))*rad
            
            p.planet.position = new_planet_pos

@rpc("authority", "call_local", "reliable")
func init():
    # Make sure planetNodes dict is clear
    for p in planetNodes.values():
        p.queue_free()
    planetNodes = {}
    
    for i in range(planetCount):
        var pl = planet.instantiate()
        pl.button_down.connect(select_planet.bind(i))
        planetNodes[i] = pl
        add_child(pl)
    nextPlayerPlanet = randi_range(0, planetCount-1)
    playerPlanet = nextPlayerPlanet
    if multiplayer.is_server():
        init_server()

func select_planet(index: int):
    if G.distance(planetNodes[index].position, planetNodes[playerPlanet].position) > playerRange:
        planetNodes[index].release_focus()
        planetNodes[nextPlayerPlanet].grab_focus()
        return
    nextPlayerPlanet = index

func init_server():
    for i in range(planetCount):
        var rot = Vector2(randf_range(.9, 1.1), randf_range(.9, 1.1))
        var rad = (i*2+1) * 20 + 200
        #var off = Vector2.ZERO #Vector2(randi_range(-20, 20), randi_range(-20, 20))
        
        var planet_rot = randf_range(0, TAU)
        var planet_pos = Vector2(rot.x * cos(planet_rot), rot.y * sin(planet_rot))*rad
        while dist_to_closest_planet(planet_pos, i) < 60: # Adjust positions if planets are too close
            planet_rot = randf_range(0, TAU)
            planet_pos = Vector2(rot.x * cos(planet_rot), rot.y * sin(planet_rot))*rad
        
        planets[i] = {
            "planet": {
                "position": planet_pos,
            },
            "orbit": {
                "rotation": rot,
                "radius": rad,
                #"offset": off,
            }
        }

func dist_to_closest_planet(pos: Vector2, index: int) -> float:
    var minimum = INF
    for i in range(max(index-3, 0), index):
        var d = G.distance(pos, planets[i].planet.position)
        if d < minimum:
            minimum = d
    return minimum

@rpc("authority", "call_local", "reliable")
func sync_planets(_planets : Dictionary):
    planets = _planets
    for i in planets.keys():
        planetNodes[i].position = planets[i].planet.position - planetNodes[i].size/2
    queue_redraw()

func _draw() -> void:
    var i : float = 0
    for p in planets.values():
        # Orbits
        draw_set_transform(Vector2.ZERO, 0, p.orbit.rotation)
        draw_circle(Vector2.ZERO, p.orbit.radius, Color.from_hsv(i / planets.size() / 1.33, 1, 1, .2), false, 2)
        # Temporary planet circles
        #draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
        #draw_circle(p.planet.position, 10, Color.RED)
        i += 1
    
    # Sun
    draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
    draw_circle(Vector2.ZERO, 100, Color(1, 1, 0, 1))
    
    # Selected planet and fly range
    draw_circle(planetNodes[playerPlanet].position + planetNodes[playerPlanet].size/2, 30, Color(0, 1, 0, .8), false, 6)
    draw_circle(planetNodes[playerPlanet].position + planetNodes[playerPlanet].size/2, playerRange, Color(.5, .5, .5, .8), false, 4)
