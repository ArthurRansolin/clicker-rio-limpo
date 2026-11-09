
extends Node

signal game_updated

const FINAL_LEVEL: int = 10

# Sistema de fases
var current_level: int = 1
var phase_trash_total: int = 0
var phase_trash_collected: int = 0
var phase_time_remaining: float = 60.0

# Recursos do jogador
var coins: int = 0
var multiplier: float = 1.0
var missed_clicks_total: int = 0

# Melhorias de coleta
var hands_level: int = 0
var bin_level: int = 0
var truck_level: int = 0
var recycling_level: int = 0
var click_strength_level: int = 0

# Custos iniciais
var hands_cost: int = 50
var bin_cost: int = 150
var truck_cost: int = 300
var recycling_cost: int = 500
var click_strength_cost: int = 200

# Valores das melhorias
var hands_bonus: int = 1
var bin_bonus: int = 5
var truck_income: int = 5

# Progresso do cenário
var total_trash: int = 0
var collected_trash_ids: Array[String] = []

# Produção automática
var production_timer: float = 0.0


func _process(delta: float) -> void:
	production_timer += delta

	if production_timer >= 1.0:
		production_timer -= 1.0

		if truck_level > 0:
			coins += roundi(truck_level * truck_income * multiplier)
			game_updated.emit()


func get_collection_bonus() -> int:
	return (hands_level * hands_bonus) + (bin_level * bin_bonus)


func get_collection_value(base_value: int) -> int:
	return roundi((base_value + get_collection_bonus()) * multiplier)


func get_missed_click_penalty() -> float:
	return maxf(1.0, 3.0 - float(hands_level) * 0.5)


func get_truck_interval() -> float:
	if truck_level <= 0:
		return 6.0
	return maxf(1.5, 6.0 - float(truck_level - 1) * 0.5)


func get_recycling_collection_interval() -> int:
	return maxi(2, 6 - recycling_level)


func get_clean_percentage() -> float:
	if phase_trash_total <= 0:
		return 0.0

	return minf(
		float(phase_trash_collected)
		/ float(phase_trash_total) * 100.0,
		100.0
	)




func collect_trash(trash_id: String, base_value: int) -> void:
	if collected_trash_ids.has(trash_id):
		return

	coins += get_collection_value(base_value)
	collected_trash_ids.append(trash_id)
	phase_trash_collected += 1

	if (
		recycling_level > 0
		and phase_trash_collected % get_recycling_collection_interval() == 0
	):
		phase_time_remaining = minf(
			phase_time_remaining + 2.0,
			get_time_limit_for_level(current_level) + 10.0
		)

	game_updated.emit()


func buy_hands() -> bool:
	if coins < hands_cost or hands_level >= 4:
		return false

	coins -= hands_cost
	hands_level += 1
	hands_cost = roundi(hands_cost * 1.5)

	game_updated.emit()
	return true


func buy_bin() -> bool:
	if coins < bin_cost or bin_level >= 5:
		return false

	coins -= bin_cost
	bin_level += 1
	bin_cost = roundi(bin_cost * 1.6)

	game_updated.emit()
	return true


func buy_truck() -> bool:
	if coins < truck_cost or truck_level >= 10:
		return false

	coins -= truck_cost
	truck_level += 1
	truck_cost = roundi(truck_cost * 1.7)

	game_updated.emit()
	return true


func buy_recycling() -> bool:
	if coins < recycling_cost or recycling_level >= 4:
		return false

	coins -= recycling_cost
	recycling_level += 1
	multiplier += 0.1
	recycling_cost = roundi(recycling_cost * 1.8)

	game_updated.emit()
	return true


func buy_click_strength() -> bool:
	if coins < click_strength_cost:
		return false

	coins -= click_strength_cost
	click_strength_level += 1
	click_strength_cost = roundi(click_strength_cost * 1.8)
	game_updated.emit()
	return true


func get_click_strength() -> int:
	return 1 + click_strength_level

func get_trash_count_for_level(level: int) -> int:
	var extra_difficulty: int = floori(
		float(level - 1) / 10.0
	) * 10

	var base_count: int = 8 + ((level - 1) * 2) + extra_difficulty
	return maxi(6, base_count - mini(bin_level, 5))


func advance_level() -> void:
	current_level += 1
	phase_trash_collected = 0
	phase_trash_total = get_trash_count_for_level(current_level)
	phase_time_remaining = get_time_limit_for_level(current_level)

	game_updated.emit()


func get_time_limit_for_level(level: int) -> float:
	var seconds_per_level: float = 28.0 / float(FINAL_LEVEL - 1)
	var level_time: float = maxf(
		32.0,
		60.0 - float(level - 1) * seconds_per_level
	)
	return level_time + minf(float(bin_level) * 2.0, 10.0)


func restart_current_level() -> void:
	var level_prefix: String = "Fase_%d_Lixo_" % current_level
	var remaining_ids: Array[String] = []

	for trash_id in collected_trash_ids:
		if not trash_id.begins_with(level_prefix):
			remaining_ids.append(trash_id)

	collected_trash_ids = remaining_ids
	phase_trash_collected = 0
	phase_time_remaining = get_time_limit_for_level(current_level)
	game_updated.emit()
