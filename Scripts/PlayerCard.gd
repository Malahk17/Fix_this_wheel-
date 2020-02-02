extends Control

onready var color_rect: ColorRect = $ColorRect;
onready var name_label: Label = $VBoxContainer/CenterContainer/Name;
onready var gold_label: Label = $VBoxContainer/HBoxContainer/CenterContainer/Gold;
onready var bet_label: Label = $VBoxContainer/HBoxContainer/CenterContainer2/Bet;

func _ready():
	pass

func set_color(color: Color) -> void:
	color_rect.color = color;

func set_name(player_name: String) -> void:
	name_label.set_text(player_name);

func set_gold(gold: int) -> void:
	gold_label.set_text(str(gold));

func set_bet(bet: int) -> void:
	bet_label.set_text(str(bet));

func mask_gold() -> void:
	gold_label.set_text('-');

func mask_bet() -> void:
	bet_label.set_text('-');
