
extends Node

signal game_updated

# Recursos do jogador
var coins: int = 0
var multiplier: float = 1.0

# Melhorias de coleta
var hands_level: int = 0
var bin_level: int = 0
var truck_level: int = 0
var recycling_level: int = 0

# Custos iniciais
var hands_cost: int = 50
var bin_cost: int = 150
var truck_cost: int = 300
var recycling_cost: int = 500

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


func get_clean_percentage() -> float:
	if total_trash <= 0:
		return 0.0

	return minf(
		float(collected_trash_ids.size()) / float(total_trash) * 100.0,
		100.0
	)


func collect_trash(trash_id: String, base_value: int) -> void:
	if collected_trash_ids.has(trash_id):
		return

	coins += get_collection_value(base_value)
	collected_trash_ids.append(trash_id)

	game_updated.emit()


func buy_hands() -> bool:
	if coins < hands_cost:
		return false

	coins -= hands_cost
	hands_level += 1
	hands_cost = roundi(hands_cost * 1.5)

	game_updated.emit()
	return true


func buy_bin() -> bool:
	if coins < bin_cost:
		return false

	coins -= bin_cost
	bin_level += 1
	bin_cost = roundi(bin_cost * 1.6)

	game_updated.emit()
	return true


func buy_truck() -> bool:
	if coins < truck_cost:
		return false

	coins -= truck_cost
	truck_level += 1
	truck_cost = roundi(truck_cost * 1.7)

	game_updated.emit()
	return true


func buy_recycling() -> bool:
	if coins < recycling_cost:
		return false

	coins -= recycling_cost
	recycling_level += 1
	multiplier += 0.1
	recycling_cost = roundi(recycling_cost * 1.8)

	game_updated.emit()
	return true
