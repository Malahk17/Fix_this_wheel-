extends Control;

var create_button: Button;
var join_button: Button;
var lineEdit: LineEdit;
var nickname: String = '';

func _ready() -> void:
	create_button = $MarginContainer/VBoxContainer/CreateRoomButton;
	join_button = $MarginContainer/VBoxContainer/JoinRoomButton;
	lineEdit = $MarginContainer/VBoxContainer/LineEdit;
	
	create_button.disabled = true;
	join_button.disabled = true;
	
	create_button.connect("pressed", self, "_on_create_button_pressed");
	join_button.connect("pressed", self, "_on_join_button_pressed");
	lineEdit.connect("text_changed", self, "_on_text_changed");

func _on_create_button_pressed() -> void:
	if nickname != '':
		Network.create_server(nickname);
		_goto_waitingRoom();

func _on_join_button_pressed() -> void:
	if nickname != '':
		Network.connect_to_server(nickname);
		_goto_waitingRoom();

func _on_text_changed(new_text) -> void:
	nickname = new_text;
	
	if nickname == '':
		create_button.disabled = true;
		join_button.disabled = true;
	else:
		create_button.disabled = false;
		join_button.disabled = false;

func _goto_waitingRoom() -> void:
	Global.goto_scene("res://WaitingRoom.tscn");
