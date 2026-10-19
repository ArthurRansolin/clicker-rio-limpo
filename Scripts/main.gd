extends Control

var coins = 0
var click_power = 1
var upgrade_cost = 10
var autoclick_power = 0
var autoclick_cost = 50


func _ready():
	$AutoClickTimer.start()
	update_ui()


func _on_click_button_pressed():
	coins += click_power
	update_ui()


func _on_upgrade_button_pressed():
	if coins >= upgrade_cost:
		coins -= upgrade_cost
		click_power += 1
		upgrade_cost += 10
		
		update_ui()


func update_ui():
	$CoinLabel.text = "🪙 Moedas: " + str(GameManager.coins)
	$ClickPowerLabel.text = "Poder por clique: " + str(click_power)
	
	$Shop/UpgradeCostLabel.text = "Custo: " + str(upgrade_cost)
	
	$Shop/AutoClickLabel.text = "Autoclick: +" + str(autoclick_power) + " moeda/s"
	$Shop/AutoClickButton.text = "Comprar Autoclick - " + str(autoclick_cost)
	
	$Shop/UpgradeButton.disabled = coins < upgrade_cost
	$Shop/AutoClickButton.disabled = coins < autoclick_cost


func _on_auto_click_timer_timeout() -> void:
	coins += autoclick_power
	update_ui()


func _on_auto_click_button_pressed() -> void:
	if coins >= autoclick_cost:
		coins -= autoclick_cost
		autoclick_power += 1
		update_ui()
