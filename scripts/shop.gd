extends CanvasLayer

@export var inventory : Inventory
@export var container : Container
@export var shopItem : PackedScene

@export var repairPriceLabel : Label
var repairPrice : int = 0:
    set(nv):
        repairPrice = nv
        if repairPriceLabel:
            repairPriceLabel.text = str(repairPrice)

var items : Dictionary = {}

func set_items(_items: Dictionary):
    for c in container.get_children():
        c.queue_free()
    
    container.visible = true
    items = _items
    
    for item in items.keys():
        var ins = shopItem.instantiate() as Button
        ins.get_node("name").text = item.get_file().trim_suffix('.tscn').replace("_", " ")
        ins.get_node("price").text = str(items[item].price)
        ins.button_down.connect(buy_item.bind(item))
        items[item].node = ins
        container.add_child(ins)
    
    repairPrice = inventory.builder.ship.get_repair_price()

func buy_item(path: String):
    if items.has(path) and inventory.materials >= items[path].price and items[path].amount > 0:
        inventory.add_module_from_path(path)
        inventory.materials -= items[path].price
        items[path].amount -= 1
        if items[path].amount == 0:
            items[path].node.disabled = true


func _on_repair_btn_button_down() -> void:
    inventory.builder.ship.repair()
    repairPrice = inventory.builder.ship.get_repair_price()


func _on_shop_btn_button_down() -> void:
    container.visible = true
    inventory.visible = false


func _on_inventory_btn_button_down() -> void:
    container.visible = false
    inventory.visible = true
