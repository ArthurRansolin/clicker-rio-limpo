
extends Control

const TRASH_SCENE: PackedScene = preload("res://Scenes/Trash.tscn")
const TRASH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/lixo/caixa_papelao.svg"),
	preload("res://assets/lixo/casca_banana.svg"),
	preload("res://assets/lixo/engrenagem.svg"),
	preload("res://assets/lixo/garrafa_plastica.svg"),
	preload("res://assets/lixo/garrafa_vidro.svg"),
	preload("res://assets/lixo/lata.svg"),
	preload("res://assets/lixo/papel_amassado.svg"),
	preload("res://assets/lixo/pedra.svg"),
	preload("res://assets/lixo/pneu.svg"),
	preload("res://assets/lixo/saco_lixo.svg"),
]
const SCENARIO_TEXTURES: Array[Texture2D] = [
	preload("res://assets/cenarios/cenario_01_parque_urbano.svg"),
	preload("res://assets/cenarios/cenario_02_praia_poluida.svg"),
	preload("res://assets/cenarios/cenario_03_rio_industrial.svg"),
	preload("res://assets/cenarios/cenario_04_floresta_recuperada.svg"),
]

var advance_pending: bool = false
var timeout_pending: bool = false
var missed_click_feedback_time: float = 0.0
var low_time_animation_active: bool = false
var low_time_tween: Tween
var final_game_over: bool = false
var truck_action_timer: float = 0.0


func _process(delta: float) -> void:
	if advance_pending or timeout_pending or final_game_over:
		return

	missed_click_feedback_time = maxf(
		0.0,
		missed_click_feedback_time - delta
	)
	GameManager.phase_time_remaining = maxf(
		0.0,
		GameManager.phase_time_remaining - delta
	)
	_update_low_time_animation()
	update_timer_ui()
	_process_truck_auto_click(delta)

	if GameManager.phase_time_remaining <= 0.0:
		timeout_pending = true
		if GameManager.current_level >= GameManager.FINAL_LEVEL:
			_show_final_score()
		else:
			_restart_level_after_timeout()


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
	if not $RiverArea.gui_input.is_connected(_on_river_gui_input):
		$RiverArea.gui_input.connect(_on_river_gui_input)
	if not $Backgound.gui_input.is_connected(_on_river_gui_input):
		$Backgound.gui_input.connect(_on_river_gui_input)

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
		trash.texture_normal = TRASH_TEXTURES[
			randi_range(0, TRASH_TEXTURES.size() - 1)
		]
		trash.set_meta("trash_id", trash_id)
		trash.set_meta("coin_value", 5)
		trash.set_meta("clicks_done", 0)

		var max_clicks: int = 1 + floori(
			float(GameManager.current_level) / 2.0
		)
		var extra_click_chance: float = minf(
			float(GameManager.current_level) * 0.1,
			0.8
		)
		var required_clicks: int = 1

		if max_clicks > 1 and randf() < extra_click_chance:
			required_clicks = randi_range(2, max_clicks)

		trash.set_meta("required_clicks", required_clicks)
		trash.tooltip_text = "Cliques: 0/%d" % required_clicks

		# Define o tamanho do resíduo.
		trash.custom_minimum_size = Vector2(48, 48)
		trash.size = Vector2(48, 48)
		trash.pivot_offset = trash.size / 2.0

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
		if GameManager.current_level >= 8:
			trash.position.x = margin + (
				float(i) / float(maxi(total, 1))
			) * (max_x - margin)
		positions.append(trash.position)

		# Conecta o clique à coleta do resíduo.
		trash.pressed.connect(
			_on_trash_pressed.bind(trash)
		)
		if GameManager.current_level >= 8:
			_move_trash_right(trash, margin, max_x)


func _on_trash_pressed(trash: TextureButton) -> void:
	if (
		not is_instance_valid(trash)
		or trash.disabled
		or timeout_pending
		or advance_pending
	):
		return
	var hit_animation: Tween = _animate_trash_hit(trash)

	var trash_id: String = str(
		trash.get_meta("trash_id", trash.name)
	)
	var base_value: int = int(
		trash.get_meta("coin_value", 5)
	)
	var clicks_done: int = (
		int(trash.get_meta("clicks_done", 0))
		+ GameManager.get_click_strength()
	)
	var required_clicks: int = int(
		trash.get_meta("required_clicks", 1)
	)
	trash.set_meta("clicks_done", clicks_done)
	trash.tooltip_text = "Cliques: %d/%d" % [clicks_done, required_clicks]

	if clicks_done < required_clicks:
		return

	GameManager.collect_trash(trash_id, base_value)
	trash.disabled = true
	await hit_animation.finished
	if is_instance_valid(trash):
		trash.queue_free()

	# Avança quando todos os resíduos forem coletados.
	if (
		GameManager.phase_trash_collected
		>= GameManager.phase_trash_total
		and not advance_pending
	):
		advance_pending = true
		call_deferred("_advance_to_next_level")


func _animate_trash_hit(trash: TextureButton) -> Tween:
	if trash.has_meta("hit_tween"):
		var previous_tween: Tween = trash.get_meta("hit_tween")
		if previous_tween.is_running():
			previous_tween.kill()

	trash.rotation_degrees = 0.0
	trash.scale = Vector2.ONE
	var tween: Tween = trash.create_tween()
	trash.set_meta("hit_tween", tween)
	tween.tween_property(trash, "rotation_degrees", -10.0, 0.045)
	tween.tween_property(trash, "rotation_degrees", 10.0, 0.07)
	tween.tween_property(trash, "rotation_degrees", -6.0, 0.055)
	tween.tween_property(trash, "rotation_degrees", 0.0, 0.045)
	tween.parallel().tween_property(trash, "scale", Vector2(0.88, 0.88), 0.06)
	tween.tween_property(trash, "scale", Vector2.ONE, 0.12)
	return tween


func _advance_to_next_level() -> void:
	if (
		GameManager.phase_trash_collected
		< GameManager.phase_trash_total
	):
		advance_pending = false
		return

	if GameManager.current_level >= GameManager.FINAL_LEVEL:
		_show_final_score()
		return

	GameManager.advance_level()
	await spawn_remaining_trash()

	advance_pending = false
	update_ui()
	_highlight_level_change()


func _show_final_score() -> void:
	if final_game_over:
		return

	final_game_over = true
	timeout_pending = true
	var total_collected: int = GameManager.collected_trash_ids.size()
	$GameOverLayer/CenterContainer/FinalScorePanel/VBoxContainer/ScoreLabel.text = (
		"Pontuação final: %d resíduos coletados" % total_collected
	)
	$GameOverLayer/CenterContainer/FinalScorePanel/VBoxContainer/LevelReachedLabel.text = (
		"Fase alcançada: %d de %d"
		% [GameManager.current_level, GameManager.FINAL_LEVEL]
	)
	$GameOverLayer/CenterContainer/FinalScorePanel/VBoxContainer/CoinsLabel.text = (
		"Moedas acumuladas: %d" % GameManager.coins
	)
	$GameOverLayer/CenterContainer/FinalScorePanel/VBoxContainer/ErrorsLabel.text = (
		"Cliques errados: %d" % GameManager.missed_clicks_total
	)
	$GameOverLayer.visible = true


func _restart_level_after_timeout() -> void:
	missed_click_feedback_time = 0.0
	$TimerLabel.modulate = Color.WHITE
	$TimerLabel.text = "Tempo esgotado! Fase reiniciando..."
	await get_tree().create_timer(1.2).timeout
	GameManager.restart_current_level()
	await spawn_remaining_trash()
	timeout_pending = false
	update_ui()


func _move_trash_right(trash: TextureButton, left_x: float, right_x: float) -> void:
	while is_instance_valid(trash):
		var duration: float = randf_range(5.0, 9.0)
		var tween: Tween = create_tween()
		tween.tween_property(trash, "position:x", right_x, duration)
		await tween.finished
		if not is_instance_valid(trash):
			return
		trash.position.x = left_x


func _highlight_level_change() -> void:
	var level_label: Label = $LevelLabel
	level_label.pivot_offset = level_label.size / 2.0
	var tween: Tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(
		level_label,
		"modulate",
		Color(1.0, 0.78, 0.2),
		0.16
	)
	tween.parallel().tween_property(
		level_label,
		"scale",
		Vector2(1.25, 1.25),
		0.16
	)
	tween.tween_property(level_label, "modulate", Color.WHITE, 0.16)
	tween.parallel().tween_property(
		level_label,
		"scale",
		Vector2.ONE,
		0.16
	)


func _on_river_gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and not timeout_pending
		and not advance_pending
	):
		var penalty: float = GameManager.get_missed_click_penalty()
		GameManager.missed_clicks_total += 1
		GameManager.phase_time_remaining = maxf(
			0.0,
			GameManager.phase_time_remaining - penalty
		)
		missed_click_feedback_time = 1.2
		$TimerLabel.set_meta("last_missed_click_penalty", penalty)
		update_timer_ui()
		if GameManager.phase_time_remaining <= 0.0:
			timeout_pending = true
			if GameManager.current_level >= GameManager.FINAL_LEVEL:
				_show_final_score()
			else:
				_restart_level_after_timeout()


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
	update_timer_ui()
	_update_scenario_background()

	$ClickPowerLabel.text = (
		"Bônus por coleta: +"
		+ str(GameManager.get_collection_bonus())
		+ " | Multiplicador: "
		+ str(snappedf(GameManager.multiplier, 0.1))
		+ "x | Força: " + str(GameManager.get_click_strength())
	)


func _update_scenario_background() -> void:
	var scenario_index: int = floori(
		float(GameManager.current_level - 1) / 5.0
	) % SCENARIO_TEXTURES.size()
	$Backgound.texture = SCENARIO_TEXTURES[scenario_index]


func update_timer_ui() -> void:
	var seconds_left: int = ceili(GameManager.phase_time_remaining)

	if missed_click_feedback_time > 0.0:
		var penalty_text: String = "%.1f" % float(
			$TimerLabel.get_meta("last_missed_click_penalty", 3.0)
		)
		$TimerLabel.text = (
			"[color=#ff3333]Tempo: %d s (-%s s)[/color]"
			% [seconds_left, penalty_text]
		)
	elif GameManager.phase_time_remaining < 5.0:
		$TimerLabel.text = "Tempo: [color=#ff3333]%d s[/color]" % seconds_left
	else:
		$TimerLabel.text = "Tempo: %d s" % seconds_left


func _process_truck_auto_click(delta: float) -> void:
	if GameManager.truck_level <= 0 or GameManager.phase_time_remaining <= 0.0:
		return

	truck_action_timer += delta
	if truck_action_timer < GameManager.get_truck_interval():
		return

	truck_action_timer = 0.0
	var available_trash: Array[TextureButton] = []
	for child in $RiverArea.get_children():
		if child is TextureButton and not child.disabled:
			available_trash.append(child)

	if not available_trash.is_empty():
		var index: int = randi_range(0, available_trash.size() - 1)
		_on_trash_pressed(available_trash[index])


func _update_low_time_animation() -> void:
	if GameManager.phase_time_remaining <= 5.0:
		if low_time_animation_active:
			return
		low_time_animation_active = true
		$TimerLabel.pivot_offset = $TimerLabel.size / 2.0
		low_time_tween = create_tween()
		low_time_tween.set_loops()
		low_time_tween.tween_property(
			$TimerLabel,
			"scale",
			Vector2(1.15, 1.15),
			0.25
		)
		low_time_tween.tween_property(
			$TimerLabel,
			"scale",
			Vector2.ONE,
			0.25
		)
	elif low_time_animation_active:
		low_time_animation_active = false
		if is_instance_valid(low_time_tween) and low_time_tween.is_running():
			low_time_tween.kill()
		$TimerLabel.scale = Vector2.ONE


func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Shop.tscn")
