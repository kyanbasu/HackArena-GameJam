extends Node

@export var connectionMenu : CanvasLayer
@export var lobbyMenu : CanvasLayer
@export var gameScene : PackedScene


func _ready() -> void:
    connectionMenu.get_node("ip").text = Lobby.defaultIp
    connectionMenu.get_node("port").text = str(Lobby.localPort)
    connectionMenu.get_node("name").text = NameGenerator.get_random_name()
    
    Lobby.player_connected.connect(player_connected)
    Lobby.player_disconnected.connect(player_disconnected)
    
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)

func regenerate_name():
    connectionMenu.get_node("name").text = NameGenerator.get_random_name()

func player_connected(peer_id, player_info):
    refresh_player_list()
    
func player_disconnected(peer_id):
    refresh_player_list()

func _on_host_pressed() -> void:
    connectionMenu.get_node("host").disabled = true
    connectionMenu.get_node("connect").disabled = true
    Lobby.localPort = int(connectionMenu.get_node("port").text)
    Lobby.player_info.name = connectionMenu.get_node("name").text
    var err = Lobby.create_game()
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
    Lobby.player_info.name = connectionMenu.get_node("name").text
    var err = Lobby.join_game(connectionMenu.get_node("ip").text, int(connectionMenu.get_node("port").text))
    if err != OK:

        return


func _on_connected_ok():
    connectionMenu.visible = false
    lobbyMenu.visible = true
    lobbyMenu.get_node("start").disabled = true

func _on_connected_fail():
    printerr("Error joining session")
    connectionMenu.get_node("host").disabled = false
    connectionMenu.get_node("connect").disabled = false

func _host_start_game() -> void:
    Lobby.isInGame = true
    Lobby._load_scene.rpc(gameScene.resource_path)

func refresh_player_list():
    $playerList.text = "Player List\n"
    var names : Array[String]
    for p in Lobby.players.values():
        names.append(p.name)
    names.sort()
    for n in names:
        $playerList.text += "%s\n" % n

func text_edit_input():
    connectionMenu.get_node("name").text = connectionMenu.get_node("name").text.strip_escapes()
    connectionMenu.get_node("ip").text = connectionMenu.get_node("ip").text.strip_escapes().replace(" ", "")
    connectionMenu.get_node("port").text = connectionMenu.get_node("port").text.strip_escapes().replace(" ", "")
