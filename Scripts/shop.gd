extends Node2D


func _ready() -> void:
	$VBoxContainer/HandsButton.pressed.connect(_on_hands_pressed)
	$VBoxContainer/BinButton.pressed.connect(_on_bin_pressed)
	$VBoxContainer/TruckButton.pressed.connect(_on_truck_pressed)
	$VBoxContainer/RecyclingButton.pressed.connect(_on_recycling_pressed)
	$VBoxContainer/ClickStrengthButton.pressed.connect(_on_click_strength_pressed)
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
		+ "\nErro tira "
		+ str(snappedf(GameManager.get_missed_click_penalty(), 0.1))
		+ " s | +" + str(GameManager.hands_bonus)
		+ " moeda/coleta | Custo: "
		+ str(GameManager.hands_cost)
	)

	$VBoxContainer/BinButton.text = (
		"Lixeira maior - Nível " + str(GameManager.bin_level)
		+ "\n-" + str(mini(GameManager.bin_level, 5))
		+ " resíduos/fase, +" + str(mini(GameManager.bin_level * 2, 10))
		+ " s | Custo: "
		+ str(GameManager.bin_cost)
	)

	$VBoxContainer/TruckButton.text = (
		"Caminhão de limpeza - Nível " + str(GameManager.truck_level)
		+ "\nClique automático a cada "
		+ str(snappedf(GameManager.get_truck_interval(), 0.1))
		+ " s | +" + str(GameManager.truck_level * GameManager.truck_income)
		+ " moedas/s | Custo: "
		+ str(GameManager.truck_cost)
	)

	$VBoxContainer/RecyclingButton.text = (
		"Reciclagem - Nível " + str(GameManager.recycling_level)
		+ "\n+10% moedas e +2 s a cada "
		+ str(GameManager.get_recycling_collection_interval())
		+ " resíduos | Custo: "
		+ str(GameManager.recycling_cost)
	)

	$VBoxContainer/HandsButton.disabled = (
		GameManager.coins < GameManager.hands_cost
		or GameManager.hands_level >= 4
	)
	$VBoxContainer/BinButton.disabled = (
		GameManager.coins < GameManager.bin_cost
		or GameManager.bin_level >= 5
	)
	$VBoxContainer/TruckButton.disabled = (
		GameManager.coins < GameManager.truck_cost
		or GameManager.truck_level >= 10
	)
	$VBoxContainer/RecyclingButton.disabled = (
		GameManager.coins < GameManager.recycling_cost
		or GameManager.recycling_level >= 4
	)

	$VBoxContainer/ClickStrengthButton.text = (
		"Força do clique - Nível " + str(GameManager.click_strength_level)
		+ "\n+1 progresso por clique | Força atual: "
		+ str(GameManager.get_click_strength())
		+ " | Custo: " + str(GameManager.click_strength_cost)
	)
	$VBoxContainer/ClickStrengthButton.disabled = (
		GameManager.coins < GameManager.click_strength_cost
	)


func _on_hands_pressed() -> void:
	GameManager.buy_hands()


func _on_bin_pressed() -> void:
	GameManager.buy_bin()


func _on_truck_pressed() -> void:
	GameManager.buy_truck()


func _on_recycling_pressed() -> void:
	GameManager.buy_recycling()


func _on_click_strength_pressed() -> void:
	GameManager.buy_click_strength()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")