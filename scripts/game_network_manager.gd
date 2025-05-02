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

var playersDead : int = 0

var startingMaterials : int = 100

### Client and host ###
@export var nextTurnBtn : Button
@export var ship : Ship
@export var builder : Builder
@export var map: Map
@export var camera : Camera
@export var inventory : Inventory

# Fighting
@export var fightUI : CanvasLayer

var isReady : bool = false:
    set(new_val):
        isReady = new_val
        if nextTurnBtn:
            if isReady:
                nextTurnBtn.text = "Cancel"
            else:
                nextTurnBtn.text = "Next Turn"

var fightTurn : int = 0

func _ready():
    if !Array(OS.get_cmdline_args()).has("editor"):
        Input.mouse_mode = Input.MOUSE_MODE_CONFINED
    builder.gameNetworkManager = self
    map.process_mode = Node.PROCESS_MODE_DISABLED
    map.visible = false
    fightUI.visible = false
    builder.active = false
    if Lobby.players.size() == 0:
        Lobby.players[0] = {"name": "Player"}
    
    player_ready.rpc_id(1, true)

func _process(delta: float) -> void:
    if nextTurnBtn.button_pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        nextTurnCounter += delta
        nextTurnBtn.get_node("ProgressBar").value = nextTurnCounter / nextTurnCounterFire
        if nextTurnCounter > nextTurnCounterFire:
            nextTurnCounter = 0
            next_turn()

var nextTurnCounter : float = 0
const nextTurnCounterFire : float = .5 #time in seconds after which skipping turn is confirmed

func next_turn_btn_up():
    nextTurnCounter = 0
    nextTurnBtn.get_node("ProgressBar").value = nextTurnCounter

# Invoked when player presses next turn button, everyone must be ready
func next_turn():
    isReady = !isReady
    player_ready.rpc_id(1, isReady)

@rpc("any_peer", "call_local", "reliable")
func player_ready(readiness: bool=true):
    if multiplayer.is_server():
        if readiness:
            playersReady += 1
        else:
            playersReady -= 1
        
        if playersReady + playersDead == Lobby.players.size(): #all players are ready
            if turn == 0:
                add_materials.rpc(startingMaterials)
            host_called_end_turn.rpc(gameState) #does cleanup and increments gameState
            playersReady = 0
            # Loading screen or something
            if gameState == GameState.MAP:
                map.host_position_planets()
                map.sync_planets.rpc(map.planets)
            # End loading
            host_called_next_turn.rpc(gameState)

@rpc("any_peer", "call_local", "reliable")
func host_called_end_turn(_gameState: GameState, _data: Dictionary={}):
    isReady = false
    nextTurnBtn.disabled = true
    gameState = _gameState
    camera.position = Vector2.ZERO
    # Previous gamestate ends
    match gameState:
        GameState.BUILDING:
            builder.active = false
            # set gameState to ACTION if planet is picked by random or to MAP if player can to pick starting planet
            gameState = GameState.ACTION
        
        GameState.ACTION:
            fightUI.visible = false
            fightUI.process_mode = Node.PROCESS_MODE_DISABLED
            gameState = GameState.MAP
        
        GameState.MAP:
            ship.process_mode = Node.PROCESS_MODE_INHERIT
            ship.visible = true
            map.process_mode = Node.PROCESS_MODE_DISABLED
            map.visible = false
            gameState = GameState.BUILDING
            map.playerPlanet = map.nextPlayerPlanet

@rpc("any_peer", "call_local", "reliable")
func host_called_next_turn(_gameState: GameState, _data: Dictionary={}):
    if turn == 0:
        gameState = GameState.BUILDING
    turn += 1
    match gameState:
        GameState.BUILDING:
            camera.change_param()
            builder.active = true
            
        GameState.ACTION:
            #pick random encounter - call host to give it, so its fair
            fightUI.visible = true
            fightUI.process_mode = Node.PROCESS_MODE_INHERIT
            
        
        GameState.MAP:
            camera.position = map.planetNodes[map.playerPlanet].position
            camera.change_param(Vector2(1400, 1800), .2, 1)
            ship.process_mode = Node.PROCESS_MODE_DISABLED
            ship.visible = false
            map.process_mode = Node.PROCESS_MODE_INHERIT
            map.visible = true
    
    nextTurnBtn.disabled = false
        
@rpc("authority", "call_local", "reliable")
func add_materials(amount: int):
    inventory.materials += amount 
