extends Control

@onready var play_button: Button = $CenterContainer/MenuPanel/Content/PlayButton
@onready var credits_button: Button = $CenterContainer/MenuPanel/Content/CreditsButton
@onready var rules_button: Button = $CenterContainer/MenuPanel/Content/RulesButton
@onready var info_label: Label = $CenterContainer/MenuPanel/Content/InfoLabel
@onready var back_button: Button = $CenterContainer/MenuPanel/Content/BackButton


func _ready() -> void:
	for button in [play_button, credits_button, rules_button, back_button]:
		_style_button(button)
	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_show_credits)
	rules_button.pressed.connect(_show_rules)
	back_button.pressed.connect(_show_main_menu)


func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.42, 0.35, 1)
	normal.set_corner_radius_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.56, 0.44, 1)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.08, 0.32, 0.29, 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)


func _on_play_pressed() -> void:
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _show_credits() -> void:
	_show_info("CRÉDITOS", "Arthur Ransolin\nCarlos Ribeiro\nEduardo Assmann\nEduardo Bernal\nJulio César\nMateus Ribeiro\n.\nObrigado por ajudar a cuidar dos rios!")

func _show_rules() -> void:
	_show_info("REGRAS", "Clique nos resíduos para coletá-los e limpar o rio.\nCada fase tem um tempo limite. Cliques fora dos resíduos reduzem o tempo.\nUse as moedas na loja para comprar melhorias.")


func _show_info(title: String, message: String) -> void:
	$CenterContainer/MenuPanel/Content/Title.text = title
	info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	$CenterContainer/MenuPanel/Content/Subtitle.visible = false
	play_button.visible = false
	credits_button.visible = false
	rules_button.visible = false
	info_label.text = message
	info_label.visible = true
	back_button.visible = true


func _show_main_menu() -> void:
	$CenterContainer/MenuPanel/Content/Title.text = "RIO LIMPO"
	$CenterContainer/MenuPanel/Content/Subtitle.visible = true
	play_button.visible = true
	credits_button.visible = true
	rules_button.visible = true
	info_label.visible = false
	back_button.visible = false
