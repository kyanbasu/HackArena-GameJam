extends Node2D

# HOST ONLY
@export var playersReady : int = 0

enum GameState {
    FLYING,
    MAP,
    BUILDING,
    SHOP
}

var gameState : GameState = GameState.BUILDING

# Client and host
@export var nextTurnBtn : Button
@export var ship : Ship
@export var builder : Builder

var isReady : bool = false

func _ready():
    pass

# Invoked when player presses next turn button, everyone must be ready
func next_turn():
    isReady = !isReady
    player_ready.rpc(1, isReady)
    if isReady:
        nextTurnBtn.text = "Cancel"
    else:
        nextTurnBtn.text = "Next Turn"

@rpc("any_peer", "call_local", "reliable")
func player_ready(id, readiness: bool=true):
    if multiplayer.is_server():
        if readiness:
            playersReady += 1
        else:
            playersReady -= 1
        
        if playersReady == Lobby.players.size(): #all players are ready
            if gameState == GameState.BUILDING:
                toggle_builder.rpc(false)

@rpc("any_peer", "call_local", "reliable")
func toggle_builder(active: bool):
    builder.active = active
