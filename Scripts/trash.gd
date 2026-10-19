extends TextureButton

@export var coin_value: int = 5


func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	GameManager.coins += coin_value
	queue_free()
