extends Node2D

### CONTROL HOST ONLY, but client have access to read ###
@export var playersReady : int = 0

# GameState contains all states that are relevant to all players at the same time
enum GameState {
    BUILDING, # Building ship
    ACTION, # Performing actions: encounters, fighting, extracting resources, shopping
    MAP, # Picking planet to travel to
    #SHOP #is at the time assigned to be ACTION, not every player needs to be in shop
}

# Host dictates gameState
var gameState : GameState = GameState.BUILDING

var turn : int = 0

### Client and host ###
@export var nextTurnBtn : Button
@export var ship : Ship
@export var builder : Builder
@export var map: Map

var isReady : bool = false

var fightTurn : int = 0

func _ready():
    map.process_mode = Node.PROCESS_MODE_DISABLED
    map.visible = false
    if Lobby.players.size() == 0:
        Lobby.players[0] = {"name": "Player"}

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
            host_called_next_turn(gameState)
            playersReady = 0

@rpc("any_peer", "call_local", "reliable")
func host_called_next_turn(_gameState: GameState, _data: Dictionary={}):
    nextTurnBtn.text = "Next Turn"
    gameState = _gameState
    # Previous gamestate ends
    match gameState:
        GameState.BUILDING:
            builder.active = false
            # set gameState to ACTION if planet is picked by random or to MAP if player can to pick starting planet
            gameState = GameState.MAP
        
        GameState.ACTION:
            pass
        
        GameState.MAP:
            ship.process_mode = Node.PROCESS_MODE_INHERIT
            ship.visible = true
            map.process_mode = Node.PROCESS_MODE_DISABLED
            map.visible = false
        
    # New gamestate starts
    match gameState:
        GameState.BUILDING:
            builder.active = true
            
        GameState.ACTION:
            #pick random encounter - call host to give it, so its fair
            pass
        
        GameState.MAP:
            ship.process_mode = Node.PROCESS_MODE_DISABLED
            ship.visible = false
            map.process_mode = Node.PROCESS_MODE_INHERIT
            map.visible = true
        
        
