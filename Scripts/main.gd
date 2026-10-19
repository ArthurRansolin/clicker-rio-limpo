
extends Control


func _ready() -> void:
	# Define quantos resíduos existem no cenário na primeira abertura.
	if GameManager.total_trash == 0:
		GameManager.total_trash = $RiverArea.get_child_count()

	# Conecta cada resíduo ao sistema de coleta.
	for trash in $RiverArea.get_children():
		if not trash is TextureButton:
			continue

		var trash_id: String = str(trash.name)

		# Resíduos já coletados não reaparecem ao voltar da loja.
		if GameManager.collected_trash_ids.has(trash_id):
			trash.queue_free()
			continue

		trash.pressed.connect(_on_trash_pressed.bind(trash))

	# Atualiza a tela quando as moedas ou melhorias mudarem.
	if not GameManager.game_updated.is_connected(update_ui):
		GameManager.game_updated.connect(update_ui)

	$ShopButton.pressed.connect(_on_shop_button_pressed)

	update_ui()


func _on_trash_pressed(trash: TextureButton) -> void:
	if not is_instance_valid(trash):
		return

	var trash_id: String = str(trash.name)
	var base_value: int = int(trash.get_meta("coin_value", 5))

	GameManager.collect_trash(trash_id, base_value)

	# Remove o resíduo visualmente do cenário.
	trash.queue_free()


func update_ui() -> void:
	$CoinLabel.text = "Moedas: " + str(GameManager.coins)

	var percentage: float = GameManager.get_clean_percentage()
	$CleanLabel.text = "Rio limpo: " + str(roundi(percentage)) + "%"

	$ProgressBar.value = percentage

	$ClickPowerLabel.text = (
        "Bônus por coleta: +"
		+ str(GameManager.get_collection_bonus())
		+ " | Multiplicador: "
		+ str(snappedf(GameManager.multiplier, 0.1))
		+ "x"
	)

	if percentage >= 100.0:
		$CleanLabel.text = "Rio recuperado: 100%!"


func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
