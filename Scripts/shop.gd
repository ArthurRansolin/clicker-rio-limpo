
extends Control


func _ready() -> void:
	$VBoxContainer/HandsButton.pressed.connect(_on_hands_pressed)
	$VBoxContainer/BinButton.pressed.connect(_on_bin_pressed)
	$VBoxContainer/TruckButton.pressed.connect(_on_truck_pressed)
	$VBoxContainer/RecyclingButton.pressed.connect(_on_recycling_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

	if not GameManager.game_updated.is_connected(update_shop):
		GameManager.game_updated.connect(update_shop)

	update_shop()


func update_shop() -> void:
	$VBoxContainer/CoinLabel.text = (
		"Moedas disponíveis: " + str(GameManager.coins)
	)

	$VBoxContainer/HandsButton.text = (
		"Mãos rápidas - Nível " + str(GameManager.hands_level)
		+ "\n+" + str(GameManager.hands_bonus)
		+ " moeda por coleta | Custo: "
		+ str(GameManager.hands_cost)
	)

	$VBoxContainer/BinButton.text = (
		"Lixeira maior - Nível " + str(GameManager.bin_level)
		+ "\n+" + str(GameManager.bin_bonus)
		+ " moedas por coleta | Custo: "
		+ str(GameManager.bin_cost)
	)

	$VBoxContainer/TruckButton.text = (
		"Caminhão de limpeza - Nível " + str(GameManager.truck_level)
		+ "\n+" + str(GameManager.truck_income)
		+ " moedas/s por nível | Custo: "
		+ str(GameManager.truck_cost)
	)

	$VBoxContainer/RecyclingButton.text = (
		"Reciclagem - Nível " + str(GameManager.recycling_level)
		+ "\n+10% no ganho de moedas por nível | Custo: "
		+ str(GameManager.recycling_cost)
	)

	$VBoxContainer/HandsButton.disabled = (
		GameManager.coins < GameManager.hands_cost
	)

	$VBoxContainer/BinButton.disabled = (
		GameManager.coins < GameManager.bin_cost
	)

	$VBoxContainer/TruckButton.disabled = (
		GameManager.coins < GameManager.truck_cost
	)

	$VBoxContainer/RecyclingButton.disabled = (
		GameManager.coins < GameManager.recycling_cost
	)


func _on_hands_pressed() -> void:
	GameManager.buy_hands()


func _on_bin_pressed() -> void:
	GameManager.buy_bin()


func _on_truck_pressed() -> void:
	GameManager.buy_truck()


func _on_recycling_pressed() -> void:
	GameManager.buy_recycling()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
