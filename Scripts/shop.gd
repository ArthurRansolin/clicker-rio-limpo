extends Control

const BUTTONS := ["HandsButton", "BinButton", "TruckButton", "RecyclingButton", "ClickStrengthButton", "BackButton"]

@onready var coin_label: Label = $CenterContainer/ShopPanel/VBoxContainer/CoinLabel
@onready var hands_button: Button = $CenterContainer/ShopPanel/VBoxContainer/HandsButton
@onready var bin_button: Button = $CenterContainer/ShopPanel/VBoxContainer/BinButton
@onready var truck_button: Button = $CenterContainer/ShopPanel/VBoxContainer/TruckButton
@onready var recycling_button: Button = $CenterContainer/ShopPanel/VBoxContainer/RecyclingButton
@onready var click_strength_button: Button = $CenterContainer/ShopPanel/VBoxContainer/ClickStrengthButton

func _ready() -> void:
	for button_name in BUTTONS:
		_style_button($CenterContainer/ShopPanel/VBoxContainer.get_node(button_name), button_name == "BackButton")

	$CenterContainer/ShopPanel/VBoxContainer/HandsButton.pressed.connect(_on_hands_pressed)
	$CenterContainer/ShopPanel/VBoxContainer/BinButton.pressed.connect(_on_bin_pressed)
	$CenterContainer/ShopPanel/VBoxContainer/TruckButton.pressed.connect(_on_truck_pressed)
	$CenterContainer/ShopPanel/VBoxContainer/RecyclingButton.pressed.connect(_on_recycling_pressed)
	$CenterContainer/ShopPanel/VBoxContainer/ClickStrengthButton.pressed.connect(_on_click_strength_pressed)
	$CenterContainer/ShopPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

	if not GameManager.game_updated.is_connected(update_shop):
		GameManager.game_updated.connect(update_shop)
	update_shop()


func _style_button(button: Button, is_back: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.42, 0.35, 1) if not is_back else Color(0.25, 0.37, 0.32, 1)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 9
	normal.content_margin_bottom = 9

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.56, 0.44, 1) if not is_back else Color(0.34, 0.48, 0.4, 1)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.08, 0.32, 0.29, 1)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.36, 0.43, 0.39, 0.72)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.972, 0.951, 0.927, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.79, 0.72, 1))
	button.add_theme_font_size_override("font_size", 16 if not is_back else 18)
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT if not is_back else HORIZONTAL_ALIGNMENT_CENTER


func update_shop() -> void:
	coin_label.text = "Moedas disponíveis: " + str(GameManager.coins)
	var hands_effect := "Erro tira " + str(snappedf(GameManager.get_missed_click_penalty(), 0.1)) + " s | +" + str(GameManager.hands_bonus) + " moeda/coleta"
	if GameManager.hands_level >= 4:
		hands_button.text = "Mãos rápidas - MAX\n" + hands_effect
	else:
		hands_button.text = "Mãos rápidas - Nível " + str(GameManager.hands_level) + "\n" + hands_effect + " | Custo: " + str(GameManager.hands_cost)

	var bin_effect := "-" + str(mini(GameManager.bin_level, 5)) + " resíduos/fase, +" + str(mini(GameManager.bin_level * 2, 10)) + " s"
	if GameManager.bin_level >= 5:
		bin_button.text = "Lixeira maior - MAX\n" + bin_effect
	else:
		bin_button.text = "Lixeira maior - Nível " + str(GameManager.bin_level) + "\n" + bin_effect + " | Custo: " + str(GameManager.bin_cost)

	var truck_effect := "Clique automático a cada " + str(snappedf(GameManager.get_truck_interval(), 0.1)) + " s | +" + str(GameManager.truck_level * GameManager.truck_income) + " moedas/s"
	if GameManager.truck_level >= 10:
		truck_button.text = "Caminhão de limpeza - MAX\n" + truck_effect
	else:
		truck_button.text = "Caminhão de limpeza - Nível " + str(GameManager.truck_level) + "\n" + truck_effect + " | Custo: " + str(GameManager.truck_cost)

	var recycling_effect := "+10% moedas e +2 s a cada " + str(GameManager.get_recycling_collection_interval()) + " resíduos"
	if GameManager.recycling_level >= 4:
		recycling_button.text = "Reciclagem - MAX\n" + recycling_effect
	else:
		recycling_button.text = "Reciclagem - Nível " + str(GameManager.recycling_level) + "\n" + recycling_effect + " | Custo: " + str(GameManager.recycling_cost)

	var click_effect := "+1 progresso por clique | Força atual: " + str(GameManager.get_click_strength())
	if GameManager.click_strength_level >= GameManager.MAX_CLICK_STRENGTH_LEVEL:
		click_strength_button.text = "Força do clique - MAX\n" + click_effect
	else:
		click_strength_button.text = "Força do clique - Nível " + str(GameManager.click_strength_level) + "\n" + click_effect + " | Custo: " + str(GameManager.click_strength_cost)

	hands_button.disabled = GameManager.coins < GameManager.hands_cost or GameManager.hands_level >= 4
	bin_button.disabled = GameManager.coins < GameManager.bin_cost or GameManager.bin_level >= 5
	truck_button.disabled = GameManager.coins < GameManager.truck_cost or GameManager.truck_level >= 10
	recycling_button.disabled = GameManager.coins < GameManager.recycling_cost or GameManager.recycling_level >= 4
	click_strength_button.disabled = (
		GameManager.coins < GameManager.click_strength_cost
		or GameManager.click_strength_level >= GameManager.MAX_CLICK_STRENGTH_LEVEL
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
