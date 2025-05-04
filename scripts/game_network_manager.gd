extends Node2D
class_name GameNetworkManager

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

enum Action {
    FIGHT,
    MINING,
    RANDOM,
    SHOP
}

var currentAction : Action

var shopPlanet : int = 14

var turn : int = 0

var playersDead : int = 0

var startingMaterials : int = 100

var fightingPlayers : Dictionary = {}

### Client and host ###
@export var nextTurnBtn : Button
@export var ship : Ship
@export var enemyShip : EnemyShip
@export var builder : Builder
@export var map: Map
@export var camera : Camera
@export var inventory : Inventory
@export var actionPicker : CanvasLayer
@export var shop : CanvasLayer
@export var actionControl : PackedScene # action instance to spawn
@export var actionIcons : Dictionary[Action, Texture2D] = {}

# Fighting
@export var fightUI : CanvasLayer
@export var playerFighting : int = 0 # UID of peer that you are fighting, 0 if not fighting


var isMyFightingTurn : bool = false:
    set(new_val):
        isMyFightingTurn = new_val
        if nextTurnBtn:
            toggle_next_turn_btn(isMyFightingTurn)

var canNextTurn : bool = true:
    set(new_val):
        canNextTurn = new_val
        if nextTurnBtn:
            toggle_next_turn_btn(canNextTurn)

# If is ready for next turn, input disabled when is ready
var isReady : bool = false:
    set(new_val):
        isReady = new_val
        if nextTurnBtn:
            if isReady:
                nextTurnBtn.text = tr("CANCEL")
            else:
                nextTurnBtn.text = tr("NEXT_TURN")

var fightTurn : int = 0

var isDead := false

func _ready():
    if !Array(OS.get_cmdline_args()).has("editor"):
        Input.mouse_mode = Input.MOUSE_MODE_CONFINED
    elif multiplayer.get_peers().size() == 0:
        var err = Lobby.create_game()
        if err != OK:
            printerr("IF IN EDITOR- RUN ONLY ONE INSTANCE (or connect via main menu)")
    Lobby.player_disconnected.connect(player_disconnected_during_game)
    builder.gameNetworkManager = self
    map.process_mode = Node.PROCESS_MODE_DISABLED
    map.visible = false
    actionPicker.visible = false
    actionPicker.process_mode = Node.PROCESS_MODE_DISABLED
    fightUI.visible = false
    builder.active = false
    if Lobby.players.size() == 0:
        Lobby.players[0] = {"name": "Player"}
    
    player_ready.rpc_id(1, true)

func player_disconnected_during_game(peer_id):
    if !multiplayer.is_server(): return
    playersDead += 1
    if fightingPlayers.has(peer_id):
        send_data_to_enemy.rpc_id(fightingPlayers[peer_id], {"force_end": true})
        fightingPlayers.erase(peer_id)

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
# Changes fight turn if is fighting
func next_turn():
    G.down.play()
    if playerFighting != 0:
        var _data = {}
        var damages = {}
        for w in ship.modules.values():
            if w.part.moduleType == ShipModule.ModuleType.WEAPON and w.part.target != Vector2i.MAX:
                damages[w.part.target] = w.part.damage * w.part.energy
        _data.damages = damages
        send_data_to_enemy.rpc_id(playerFighting, _data)
        isMyFightingTurn = false
    else:
        isReady = !isReady
        player_ready.rpc_id(1, isReady)

@rpc("any_peer", "call_local", "reliable")
func player_ready(readiness: bool=true):
    if multiplayer.is_server() and Lobby.players.has(multiplayer.get_remote_sender_id()):
        if readiness:
            playersReady += 1
        else:
            playersReady -= 1
        if playersReady == Lobby.players.size(): #all players are ready
            if turn == 0:
                add_materials.rpc(startingMaterials)
                generate_bg.rpc(randi_range(-1000,1000))
                for i in Lobby.players.keys():
                    # Starting Planet
                    #var planet = randi_range(0, map.planetCount-1)
                    var planet = shopPlanet
                    host_called_end_turn.rpc_id(i, gameState, {"planet": planet})
                    Lobby.players[i].planet = planet
            else:
                host_called_end_turn.rpc(gameState) #does cleanup and increments gameState
            playersReady = 0
            ### Host only logic between turns
            # Loading screen or something
            if gameState == GameState.MAP:
                map.host_position_planets()
                map.sync_planets.rpc(map.planets)
            
            elif gameState == GameState.ACTION:
                fightingPlayers = {}
                var playersOnPlanet : Dictionary[int, Array] = {} # planetIndex: Array[peerUID]
                var playersAndActions : Dictionary[int, Array] = {}
                for p in Lobby.players.keys():
                    if !playersOnPlanet.has(Lobby.players[p].planet):
                        playersOnPlanet[Lobby.players[p].planet] = []
                    playersOnPlanet[Lobby.players[p].planet].push_back(p)
                
                if shopPlanet in playersOnPlanet.keys():
                    playersOnPlanet.erase(shopPlanet)
                
                for arr in playersOnPlanet.values():
                    arr.shuffle()
                    while arr.size() >= 2: # while, because there is rare chance that there are >=4 players on the same planet
                        var p1 = arr.pop_back()
                        var p2 = arr.pop_back()
                        init_fight.rpc_id(p1, p2)
                        init_fight.rpc_id(p2, p1)
                        playersAndActions[p1] = [Action.FIGHT]
                        playersAndActions[p2] = [Action.FIGHT]
                
                for p in Lobby.players.keys():
                    if !playersAndActions.has(p):
                        if Lobby.players[p].planet == shopPlanet:
                            playersAndActions[p] = [Action.SHOP, [Action.MINING, Action.RANDOM].pick_random()]
                        else:
                            playersAndActions[p] = [Action.MINING, Action.RANDOM]
                    send_available_actions.rpc_id(p, playersAndActions[p])
                        
                
            
            # End loading
            host_called_next_turn.rpc(gameState)

@rpc("any_peer", "call_local", "reliable")
func host_called_end_turn(_gameState: GameState, _data: Dictionary={}):
    isReady = false
    canNextTurn = false
    gameState = _gameState
    camera.position = Vector2.ZERO
    if turn == 0:
        gameState = GameState.MAP
        map.nextPlayerPlanet = _data.planet

    # Previous gamestate ends
    match gameState:
        GameState.BUILDING:
            builder.active = false
            # set gameState to ACTION if planet is picked by random or to MAP if player can to pick starting planet
            gameState = GameState.ACTION
        
        GameState.ACTION:
            shop.visible = false
            shop.process_mode = Node.PROCESS_MODE_DISABLED
            fightUI.visible = false
            fightUI.process_mode = Node.PROCESS_MODE_DISABLED
            actionPicker.visible = false
            actionPicker.process_mode = Node.PROCESS_MODE_DISABLED
            gameState = GameState.MAP
        
        GameState.MAP:
            G.target_bg_pitch = 1
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
    else:
        if ship.max_health - ship.total_damage <= 0 and !isDead:
            dead.rpc()
            isDead = true
    turn += 1
    
    match gameState:
        GameState.BUILDING:
            camera.change_param()
            builder.active = true
            canNextTurn = true
            
        GameState.ACTION:
            #pick random encounter - call host to give it, so its fair
            actionPicker.visible = true
            actionPicker.process_mode = Node.PROCESS_MODE_INHERIT
            
        
        GameState.MAP:
            G.target_bg_pitch = .8
            camera.position = map.planetNodes[map.playerPlanet].position
            camera.change_param(Vector2(1400, 1800), .2, 1)
            ship.process_mode = Node.PROCESS_MODE_DISABLED
            ship.visible = false
            map.process_mode = Node.PROCESS_MODE_INHERIT
            map.visible = true
            canNextTurn = true

### Host

@rpc("any_peer", "call_local", "reliable")
func flew_to_planet(index: int):
    if multiplayer.is_server() and Lobby.players.has(multiplayer.get_remote_sender_id()):
        Lobby.players[multiplayer.get_remote_sender_id()].planet = index

@rpc("any_peer", "call_local", "reliable")
func process_and_send_action(action: Action):
    if multiplayer.is_server() and Lobby.players.has(multiplayer.get_remote_sender_id()):
        var peer_id = multiplayer.get_remote_sender_id()
        var _data = {}
        match action:
            Action.SHOP:
                _data.shop_items = {}
                for i in range(randi_range(4,8)):
                    var item = tableShop.keys().pick_random()
                    if !_data.shop_items.has(item.resource_path):
                        _data.shop_items[item.resource_path] = {"price": tableShop[item]}
                        _data.shop_items[item.resource_path].amount = 1
                    else:
                        _data.shop_items[item.resource_path].amount += 1
            
            Action.MINING:
                _data.material = randi_range(20, 60)
            
            Action.RANDOM:
                _data = get_random_event_data()
        
        send_action_data.rpc_id(peer_id, _data)

func get_random_event_data() -> Dictionary:
    var _data = {"random": true}
    var encounter = [
        "pirate", "asteroid", "solar_flare", # negative
        "abandoned_ship", "abandoned_station", "quarry", "ship_in_need" # positive
    ].pick_random()
    
    _data.name = encounter
    match encounter:
        "pirate":
            _data.request = randi_range(30, 100) # requested material count
        "asteroid":
            _data.material = -randi_range(20, 40)
        
        "abandoned_ship":
            _data.material = randi_range(10, 50)
        "abandoned_station":
            _data.material = randi_range(30, 80)
            _data.reward = tableAbandonedStation.pick_random().resource_path
        "quarry":
            _data.material = randi_range(40, 80)
        "ship_in_need":
            _data.request = randi_range(20, 50)
            _data.reward = tableShipInNeed.pick_random().resource_path
    
    return _data

@rpc("any_peer", "call_local", "reliable")
func dead():
    playersDead += 1
    if multiplayer.is_server() and Lobby.players.has(multiplayer.get_remote_sender_id()):
        Lobby.players.erase(multiplayer.get_remote_sender_id())

### Host and client

@rpc("authority", "call_local", "reliable")
func init_fight(enemy_id):
    playerFighting = enemy_id
    
    # Sending ship to enemy
    #var parts: Dictionary[Vector3i, PackedScene] = {}
    var parts : Array = []
    for p in ship.modules.keys():
        #parts[p] = ship.modules[p].get_meta("packed_scene") #hopefully there isn't any bug
        parts.push_back(p.x)
        parts.push_back(p.y)
        parts.push_back(p.z)
        parts.push_back(ship.modules[p].part.get_meta("packed_scene").resource_path)
        
    send_enemy_ship.rpc_id(playerFighting, parts)

@rpc("any_peer", "call_remote", "reliable")
func send_enemy_ship(p: Array):
    var parts: Dictionary[Vector3i, String] = {}
    for i in range(0, p.size(), 4):
        parts[Vector3i(p[i], p[i+1], p[i+2])] = p[i+3]
    enemyShip.generate_ship(parts)
    
    # send systems data to let host decide who will start turn
    send_fight_data_to_host.rpc_id(1, {"max_energy": ship.max_energy, "enemy": playerFighting})

@rpc("any_peer", "call_local", "reliable")
func send_fight_data_to_host(_data: Dictionary):
    fightingPlayers[multiplayer.get_remote_sender_id()] = {}
    if _data.has("max_energy"):
        fightingPlayers[multiplayer.get_remote_sender_id()].max_energy = _data.max_energy
        #fightingPlayers[multiplayer.get_remote_sender_id()].enemy = _data.enemy
        
        if fightingPlayers.has(multiplayer.get_remote_sender_id()) and fightingPlayers.has(_data.enemy):
            var e1 = fightingPlayers[multiplayer.get_remote_sender_id()].max_energy
            var e2 = fightingPlayers[_data.enemy].max_energy
            if e1 > e2:
                send_data_to_enemy.rpc_id(multiplayer.get_remote_sender_id(), {"starting": true})
                send_data_to_enemy.rpc_id(_data.enemy, {"starting": false})
            elif e1 < e2:
                send_data_to_enemy.rpc_id(multiplayer.get_remote_sender_id(), {"starting": false})
                send_data_to_enemy.rpc_id(_data.enemy, {"starting": true})
            else:
                var r = randi() % 2 == 0
                send_data_to_enemy.rpc_id(multiplayer.get_remote_sender_id(), {"starting": r})
                send_data_to_enemy.rpc_id(_data.enemy, {"starting": !r})
        

@rpc("any_peer", "call_local", "reliable")
func send_data_to_enemy(_data: Dictionary):
    print(multiplayer.get_remote_sender_id())
    print(_data)
    if multiplayer.get_remote_sender_id() == 1:
        if _data.has("starting"):
            isMyFightingTurn = _data.starting
            if !_data.starting:
                ship.do_reinforcements()
            return
        if _data.has("force_end"):
            playerFighting = 0
            toggle_next_turn_btn(true)
            return
    
    if _data.has("end"):
        playerFighting = 0
        ship.reset_all_energy()
        toggle_next_turn_btn(true)
        return
    
    if _data.has("damages"):
        for d in _data.damages.keys():
            ship.damage(_data.damages[d], d)
    
    ship.reset_weapons()
    
    # is dead
    if ship.max_health - ship.total_damage <= 0:
        send_data_to_enemy.rpc_id(playerFighting, {"end": true})
        playerFighting = 0
        dead.rpc()
        isDead = true
        return
    
    # Enemy ended their turn so its mine now
    isMyFightingTurn = true
    fightTurn += 1

# Send available actions to pick, client specific
# additional _data parameter for small information about certain actions
@rpc("authority", "call_local", "reliable")
func send_available_actions(actions: Array, _data: Dictionary={}):
    for c in actionPicker.get_node("ActionsPanel").get_child(0).get_children():
        c.queue_free()
    actionPicker.get_node("TitlePanel/title").text = tr("ACTIONS")
    for a in actions:
        var act = actionControl.instantiate() as Button
        act.get_node("title").text = tr(Action.keys()[a])
        act.get_node("desc").text = tr(Action.keys()[a] + "_DESC")
        act.get_node("icon").texture = actionIcons[a]
        actionPicker.get_node("ActionsPanel").get_child(0).add_child(act)
        act.button_down.connect(pick_action.bind(a))

func pick_action(action: Action):
    G.click.play()
    for c in actionPicker.get_node("ActionsPanel").get_child(0).get_children():
        c.queue_free()
    process_and_send_action.rpc_id(1, action)

# More precise information about picked action, like items in the shop
@rpc("authority", "call_local", "reliable")
func send_action_data(_data: Dictionary):
    print(_data)
    # Random encounters
    if _data.has("random"):
        actionPicker.get_node("TitlePanel/title").text = tr("RANDOM." + _data.name.to_upper())
        
        match _data.name:
            "pirate":
                # Accept request
                var act = actionControl.instantiate() as Button
                act.get_node("title").text = tr("ACCEPT")
                #act.get_node("desc").text = tr("_DESC")
                #act.get_node("icon").texture = actionIcons[a]
                actionPicker.get_node("ActionsPanel").get_child(0).add_child(act)
                act.button_down.connect(pirate_after_decision.bind(true, _data.request))
                
                # Decline
                act = actionControl.instantiate() as Button
                act.get_node("title").text = tr("DECLINE")
                #act.get_node("desc").text = tr("_DESC")
                #act.get_node("icon").texture = actionIcons[a]
                actionPicker.get_node("ActionsPanel").get_child(0).add_child(act)
                act.button_down.connect(pirate_after_decision.bind(false))
            "asteroid":
                damage_random_part()
            "solar_flare":
                damage_random_part()
        
        if _data.name != "pirate":
            canNextTurn = true
    # Other actions
    else:
        if playerFighting:
            fightUI.visible = true
            fightUI.process_mode = Node.PROCESS_MODE_INHERIT
            actionPicker.visible = false
            return
        actionPicker.get_node("TitlePanel/title").text = tr("REWARDS")
        canNextTurn = true

    if _data.has("material"):
        inventory.materials += _data.material
        var act = actionControl.instantiate() as Button
        if _data.material > 0:
            act.get_node("title").text = tr("GOT_MATERIAL") % _data.material
        else:
            act.get_node("title").text = tr("LOST_MATERIAL") % -_data.material
        #act.get_node("desc").text = tr("_DESC")
        #act.get_node("icon").texture = actionIcons[a]
        actionPicker.get_node("ActionsPanel").get_child(0).add_child(act)
    if _data.has("reward"):
        inventory.add_module_from_path(_data.reward)
        var act = actionControl.instantiate() as Button
        
        act.get_node("title").text = tr("GOT_MODULE") % _data.reward.get_file().trim_suffix('.tscn').replace("_", " ")

        #act.get_node("desc").text = tr("_DESC")
        #act.get_node("icon").texture = actionIcons[a]
        actionPicker.get_node("ActionsPanel").get_child(0).add_child(act)
    
    # Shop
    if _data.has("shop_items"):
        actionPicker.visible = false
        shop.visible = true
        shop.process_mode = Node.PROCESS_MODE_INHERIT
        shop.set_items(_data.shop_items)

# called locally
func pirate_after_decision(accepted: bool, reward=0):
    canNextTurn = true
    for c in actionPicker.get_node("ActionsPanel").get_child(0).get_children():
        c.queue_free()
    
    if accepted:
        inventory.materials -= reward
        var act = actionControl.instantiate() as Button
        act.get_node("title").text = tr("LOST_MATERIAL") % reward
        #act.get_node("desc").text = tr("_DESC")
        #act.get_node("icon").texture = actionIcons[a]
        actionPicker.get_node("ActionsPanel").get_child(0).add_child(act)
    else:
        damage_random_part()

func damage_random_part():
    var m = ship.modules.values().pick_random().part as ShipModule
    ship.damage(randi_range(3,10), Vector2i(m.global_position-Vector2(16,16)))
    var modules = Inventory.get_name_from_file(m.get_meta("packed_scene"))
    var act = actionControl.instantiate() as Button
    act.get_node("title").text = tr("PART_DAMAGED") % modules
    #act.get_node("desc").text = tr("_DESC")
    #act.get_node("icon").texture = actionIcons[a]
    actionPicker.get_node("ActionsPanel").get_child(0).add_child(act)

@rpc("authority", "call_local", "reliable")
func add_materials(amount: int):
    inventory.materials += amount 

@rpc("authority", "call_local", "reliable")
func generate_bg(_seed: int):
    G._seed = _seed
    map.generate_background()



func toggle_next_turn_btn(enable: bool):
    nextTurnBtn.disabled = !enable

### Loot tables etc.

@export var tableShop : Dictionary[PackedScene, int]
@export var tableShipInNeed : Array[PackedScene]
@export var tableAbandonedStation : Array[PackedScene]
