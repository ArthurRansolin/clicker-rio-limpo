
extends Control

const TRASH_SCENE: PackedScene = preload("res://Scenes/Trash.tscn")

var advance_pending: bool = false


func _ready() -> void:
	# Aguarda a interface calcular o tamanho dos controles.
	await get_tree().process_frame

	if GameManager.phase_trash_total <= 0:
		GameManager.phase_trash_total = (
			GameManager.get_trash_count_for_level(
				GameManager.current_level
			)
		)

	if not GameManager.game_updated.is_connected(update_ui):
		GameManager.game_updated.connect(update_ui)

	if not $ShopButton.pressed.is_connected(_on_shop_button_pressed):
		$ShopButton.pressed.connect(_on_shop_button_pressed)

	spawn_remaining_trash()
	update_ui()


func spawn_remaining_trash() -> void:
	# Remove os resíduos anteriores.
	for child in $RiverArea.get_children():
		child.queue_free()

	# Aguarda a remoção dos nós antigos.
	await get_tree().process_frame

	var total: int = GameManager.phase_trash_total
	var area_size: Vector2 = $RiverArea.size

	# Margens e distância mínima entre os resíduos.
	var margin: float = 12.0
	var min_distance: float = 70.0
	var positions: Array[Vector2] = []
	var max_attempts: int = 30

	for i in range(total):
		var trash_id: String = (
			"Fase_%d_Lixo_%d"
			% [GameManager.current_level, i]
		)

		# Não recria resíduos já coletados.
		if GameManager.collected_trash_ids.has(trash_id):
			continue

		var trash: TextureButton = TRASH_SCENE.instantiate()
		trash.name = "Trash_%d" % i
		trash.set_meta("trash_id", trash_id)
		trash.set_meta("coin_value", 5)

		# Define o tamanho do resíduo.
		trash.custom_minimum_size = Vector2(64, 64)
		trash.size = Vector2(64, 64)

		$RiverArea.add_child(trash)

		# Calcula os limites para manter o resíduo dentro do rio.
		var max_x: float = maxf(
			margin,
			area_size.x - trash.size.x - margin
		)
		var max_y: float = maxf(
			margin,
			area_size.y - trash.size.y - margin
		)

		var chosen_position: Vector2 = Vector2(margin, margin)

		# Procura uma posição aleatória que não fique muito próxima
		# das posições escolhidas anteriormente.
		for attempt in range(max_attempts):
			var candidate := Vector2(
				randf_range(margin, max_x),
				randf_range(margin, max_y)
			)

			var valid_position: bool = true

			for other_position in positions:
				if candidate.distance_to(other_position) < min_distance:
					valid_position = false
					break

			chosen_position = candidate

			if valid_position:
				break

		trash.position = chosen_position
		positions.append(chosen_position)

		# Conecta o clique à coleta do resíduo.
		trash.pressed.connect(
			_on_trash_pressed.bind(trash)
		)


func _on_trash_pressed(trash: TextureButton) -> void:
	if not is_instance_valid(trash):
		return

	var trash_id: String = str(
		trash.get_meta("trash_id", trash.name)
	)
	var base_value: int = int(
		trash.get_meta("coin_value", 5)
	)

	GameManager.collect_trash(trash_id, base_value)
	trash.queue_free()

	# Avança quando todos os resíduos forem coletados.
	if (
		GameManager.phase_trash_collected
		>= GameManager.phase_trash_total
		and not advance_pending
	):
		advance_pending = true
		call_deferred("_advance_to_next_level")


func _advance_to_next_level() -> void:
	if (
		GameManager.phase_trash_collected
		< GameManager.phase_trash_total
	):
		advance_pending = false
		return

	GameManager.advance_level()
	await spawn_remaining_trash()

	advance_pending = false
	update_ui()


func update_ui() -> void:
	$CoinLabel.text = "Moedas: " + str(GameManager.coins)

	$LevelLabel.text = (
		"Fase: " + str(GameManager.current_level)
	)

	var percentage: float = GameManager.get_clean_percentage()

	$CleanLabel.text = (
		"Rio limpo: " + str(roundi(percentage)) + "%"
	)

	$ProgressBar.value = percentage

	$ClickPowerLabel.text = (
		"Bônus por coleta: +"
		+ str(GameManager.get_collection_bonus())
		+ " | Multiplicador: "
		+ str(snappedf(GameManager.multiplier, 0.1))
		+ "x"
	)


func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
