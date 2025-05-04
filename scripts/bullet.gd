extends AnimatedSprite2D

@export var explosion : PackedScene
@export var speed : int = 1000

var silent := false
var startPos : Vector2
var endPos : Vector2

var time : float = 0
var _time : float = 0

func init(_s: Vector2, _e: Vector2) -> void:
    startPos = _s
    endPos = _e + Vector2(G.TILE_SIZE, G.TILE_SIZE)/2
    time = G.distance(startPos, endPos) / speed
    z_index = 1000

var exp : AnimatedSprite2D

func _process(delta: float) -> void:
    if time != 0:
        global_position = lerp(startPos, endPos, _time/time)
        _time += delta
        if _time > time:
            time = INF
            if silent:
                visible = false
                await G.wait(10)
                end()
                return
            exp = explosion.instantiate()
            exp.global_position = endPos
            get_tree().root.add_child(exp)
            G.explosion.play()
            exp.z_index = 1000
            exp.play()
            exp.animation_finished.connect(end)
            await G.wait(10)
            end()
            
        
        
            

func end():
    if exp:
        exp.queue_free()
    queue_free()
        
