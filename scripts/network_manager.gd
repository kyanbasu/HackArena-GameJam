extends Node

var localPlayer

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

var localPort : int = 4444
var localIp : String

const defaultIp : String = "127.0.0.1"
const MAX_CONNECTIONS = 20

@export var playersNode : Node2D

var isInGame := false

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players : Dictionary[int, Dictionary] = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info : Dictionary = {"name": "Player"}

var players_loaded = 0

func _ready() -> void:
    if OS.has_feature("windows"):
        if OS.has_environment("COMPUTERNAME"):
            localIp =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),IP.TYPE_IPV4)
    
    #print(localIp, ":", localPort)
    
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

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


func _on_player_disconnected(id):
    print("player disconnected %s %s" % [id, players[id].name])
    players.erase(id)
    player_disconnected.emit(id)


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
