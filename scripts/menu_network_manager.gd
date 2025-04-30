extends Node

var localPlayer

@export var connectionMenu : CanvasLayer
@export var lobbyMenu : CanvasLayer

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

var localPort : int = 4444
var localIp : String

const defaultIp : String = "127.0.0.1"
const MAX_CONNECTIONS = 20

@export var playersNode : Node2D

@export var gameScene : PackedScene

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

var players_loaded = 0

func _ready() -> void:
    
    if OS.has_feature("windows"):
        if OS.has_environment("COMPUTERNAME"):
            localIp =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),IP.TYPE_IPV4)
    
    #print(localIp, ":", localPort)
    connectionMenu.get_node("ip").text = defaultIp
    connectionMenu.get_node("port").text = str(localPort)
    
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_host_pressed() -> void:
    connectionMenu.get_node("host").disabled = true
    connectionMenu.get_node("connect").disabled = true
    localPort = int(connectionMenu.get_node("port").text)
    player_info.name = connectionMenu.get_node("name").text
    var err = create_game()
    if err != OK:
        printerr("Error creating session")
        connectionMenu.get_node("host").disabled = false
        connectionMenu.get_node("connect").disabled = false
        return
    connectionMenu.visible = false
    lobbyMenu.visible = true
    lobbyMenu.get_node("start").disabled = false
    
func _on_join_pressed() -> void:
    connectionMenu.get_node("host").disabled = true
    connectionMenu.get_node("connect").disabled = true
    player_info.name = connectionMenu.get_node("name").text
    var err = join_game(connectionMenu.get_node("ip").text, int(connectionMenu.get_node("port").text))
    if err != OK:
        printerr("Error joining session")
        connectionMenu.get_node("host").disabled = false
        connectionMenu.get_node("connect").disabled = false
        return
    connectionMenu.visible = false
    lobbyMenu.visible = true
    lobbyMenu.get_node("start").disabled = true

func _host_start_game() -> void:
    _load_scene.rpc(gameScene.resource_path)

@rpc("call_local", "reliable")
func _load_scene(scene: String) -> void:
    get_tree().change_scene_to_file(scene)

func _on_connect_pressed() -> void:
    pass

func join_game(address = "", port = 4444) -> Error:
    if address.is_empty():
        address = defaultIp
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(address, port)
    if error:
        return error
    multiplayer.multiplayer_peer = peer
    return OK


func create_game() -> Error:
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(localPort, MAX_CONNECTIONS)
    if error:
        return error
    multiplayer.multiplayer_peer = peer

    players[1] = player_info
    player_connected.emit(1, player_info)
    refresh_player_list()
    
    return OK


func remove_multiplayer_peer():
    multiplayer.multiplayer_peer = null
    players.clear()


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
    if multiplayer.is_server():
        players_loaded += 1
        if players_loaded == players.size():
            $/root/Game.start_game()
            players_loaded = 0


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
    _register_player.rpc_id(id, player_info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
    var new_player_id = multiplayer.get_remote_sender_id()
    
    players[new_player_id] = new_player_info
    player_connected.emit(new_player_id, new_player_info)
    
    if multiplayer.is_server():
        print("[Host] New player connected: %s %s" % [new_player_id, new_player_info.name])
    else:
        print("[Client] New player connected: %s %s" % [new_player_id, new_player_info.name])
    
    refresh_player_list()


func _on_player_disconnected(id):
    print("player disconnected %s %s" % [id, players[id].name])
    players.erase(id)
    player_disconnected.emit(id)
    
    refresh_player_list()


func _on_connected_ok():
    var peer_id = multiplayer.get_unique_id()
    players[peer_id] = player_info
    player_connected.emit(peer_id, player_info)


func _on_connected_fail():
    multiplayer.multiplayer_peer = null


func _on_server_disconnected():
    multiplayer.multiplayer_peer = null
    players.clear()
    server_disconnected.emit()

func refresh_player_list():
    $playerList.text = "Player List\n"
    var names : Array[String]
    for p in players.values():
        names.append(p.name)
    names.sort()
    for n in names:
        $playerList.text += "%s\n" % n
