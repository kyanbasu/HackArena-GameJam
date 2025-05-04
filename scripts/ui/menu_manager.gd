extends Node

@export var gameScene : PackedScene

func _ready() -> void:
    get_node("../connectionJoin").get_node("ip").text = Lobby.defaultIp
    get_node("../connectionCommon").get_node("port").text = str(Lobby.localPort)
    get_node("../connectionCommon").get_node("name").text = NameGenerator.get_random_name()
    
    Lobby.player_connected.connect(player_connected)
    Lobby.player_disconnected.connect(player_disconnected)
    
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)

func regenerate_name():
    get_node("../connectionCommon").get_node("name").text = NameGenerator.get_random_name()

func player_connected(_peer_id, _player_info):
    refresh_player_list()
    
func player_disconnected(_peer_id):
    refresh_player_list()

func _on_host_pressed() -> void:
    get_node("../connectionHost").get_node("host").disabled = true
    Lobby.localPort = int(get_node("../connectionCommon").get_node("port").text)
    Lobby.player_info.name = get_node("../connectionCommon").get_node("name").text
    var err = Lobby.create_game()
    if err != OK:
        printerr("Error creating session")
        get_node("../connectionHost").get_node("host").disabled = false
        return
    get_node("../connectionCommon").visible = false
    get_node("../connectionHost").visible = false
    get_node("../lobby").visible = true
    get_node("../lobby").get_node("start").disabled = false
    
func _on_join_pressed() -> void:
    get_node("../connectionHost").get_node("host").disabled = true
    Lobby.player_info.name = get_node("../connectionCommon").get_node("name").text
    var err = Lobby.join_game(get_node("../connectionJoin").get_node("ip").text, int(get_node("../connectionCommon").get_node("port").text))
    if err != OK:
        return


func _on_connected_ok():
    get_node("../connectionCommon").visible = false
    get_node("../connectionJoin").visible = false
    get_node("../lobby").visible = true
    get_node("../lobby").get_node("start").disabled = true

func _on_connected_fail():
    printerr("Error joining session")
    get_node("../connectionHost").get_node("host").disabled = false

func _host_start_game() -> void:
    Lobby.isInGame = true
    Lobby._load_scene.rpc(gameScene.resource_path)

func refresh_player_list():
    $playerList.text = "Player List\n"
    var names : Array[String]
    for i in Lobby.players.keys():
        var prefix = "%s"
        if i == 1:
            prefix = "[Host] " + prefix
        if i == multiplayer.multiplayer_peer.get_unique_id():
            prefix = "[You] " + prefix
        names.append(prefix % Lobby.players[i].name)
    names.sort()
    for n in names:
        $playerList.text += "%s\n" % n

func text_edit_input():
    get_node("../connectionCommon").get_node("name").text = get_node("../connectionCommon").get_node("name").text.strip_escapes()
    get_node("../connectionJoin").get_node("ip").text = get_node("../connectionJoin").get_node("ip").text.strip_escapes().replace(" ", "")
    get_node("../connectionCommon").get_node("port").text = get_node("../connectionCommon").get_node("port").text.strip_escapes().replace(" ", "")


func _on_menu_host_button_down() -> void:
    get_node("../connectionCommon").visible = true
    get_node("../connectionHost").visible = true
    get_node("../mainMenu").visible = false


func _on_menu_join_button_down() -> void:
    get_node("../connectionCommon").visible = true
    get_node("../connectionJoin").visible = true
    get_node("../mainMenu").visible = false


func _on_menu_options_button_down() -> void:
    get_node("../mainMenu").visible = false
    get_node("../options").visible = true


func _on_menu_quit_button_down() -> void:
    get_tree().quit()


func _on_back_button_down() -> void:
    if multiplayer.has_multiplayer_peer():
        multiplayer.multiplayer_peer.close()
    get_node("../connectionHost").get_node("host").disabled = false
    get_node("../connectionCommon").visible = false
    get_node("../connectionJoin").visible = false
    get_node("../connectionHost").visible = false
    get_node("../lobby").visible = false
    get_node("../options").visible = false
    get_node("../mainMenu").visible = true
    $playerList.text = ""


func _on_language_item_selected(index: int) -> void:
    match index:
        0:
            TranslationServer.set_locale("en")
        1:
            TranslationServer.set_locale("pl")
        2:
            TranslationServer.set_locale("ru")
