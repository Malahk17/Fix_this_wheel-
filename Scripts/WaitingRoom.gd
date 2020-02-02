extends Control;

var startGame: Button;

var p1: ColorRect;
var p1Label: Label;
var p2: ColorRect;
var p2Label: Label;
var p3: ColorRect;
var p3Label: Label;

func _ready():
	startGame = $VBoxContainer/VSplitContainer/Button;
	p1 = $VBoxContainer/PanelContainer/VBoxContainer/P1;
	p1Label = $VBoxContainer/PanelContainer/VBoxContainer/P1/Label;
	p2 = $VBoxContainer/PanelContainer/VBoxContainer/P2;
	p2Label = $VBoxContainer/PanelContainer/VBoxContainer/P2/Label;
	p3 = $VBoxContainer/PanelContainer/VBoxContainer/P3;
	p3Label = $VBoxContainer/PanelContainer/VBoxContainer/P3/Label;
	
	if get_tree().is_network_server():
		startGame.disabled = true;
		startGame.connect("pressed", self, "_on_startGame_pressed");
	else:
		startGame.visible = false;

func _process(delta) -> void:
	p1.visible = false;
	p2.visible = false;
	p3.visible = false;
	
	if Network.players[1].has('name'):
		$VBoxContainer/CenterContainer/Label.text = Network.players[1].name + "'s room:";
	
	var i: int = 1;
	for k in Network.players.keys():
		if k != 1 and Network.players[k].has('name'):
			match i:
				1:
					p1Label.text = Network.players[k]['name'];
					p1.visible = true;
				2:
					p2Label.text = Network.players[k]['name'];
					p2.visible = true;
				3:
					p3Label.text = Network.players[k]['name'];
					p3.visible = true;
			i = i + 1;
	if i == 4:
		startGame.disabled = false;

func _on_startGame_pressed() -> void:
	Global.goto_scene("res://GamingTable.tscn");
	Network.send_to_game();
