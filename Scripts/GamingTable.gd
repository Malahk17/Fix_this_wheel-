extends Control;

var completed_trades: int = 0;
var phase: Dictionary = {};

var c_selectable: Color = Color('ff8764');
var c_done: Color = Color('a0240e');
var c_passive: Color = Color('d85638');

onready var next_phase: Button = $VBoxContainer/CenterContainer2/Button;

onready var player_card1: Control = $VBoxContainer/GridContainer/PlayerCard1;
onready var player_card2: Control = $VBoxContainer/GridContainer/PlayerCard2;
onready var player_card3: Control = $VBoxContainer/GridContainer/PlayerCard3;
onready var player_card4: Control = $VBoxContainer/GridContainer/PlayerCard4;

func _ready() -> void:
	Network.connect("boss_change", self, "_on_bossChange");
	Network.connect("trade", self, "_on_trade_requested");
	Network.connect("deal", self, "_on_deal_concluded");
	Network.connect("done", self, "_on_done");
	
	next_phase.connect("pressed", self, "_on_nextPhase");
	next_phase.visible = false;
	
	$TradeDialog.connect("confirmed", self, "_make_deal");
	
	player_card1.set_color(c_passive);
	player_card2.set_color(c_passive);
	player_card3.set_color(c_passive);
	player_card4.set_color(c_passive);
	
	player_card1.set_name(Network.players[1]['name']);
	player_card2.set_name(Network.players[Network.keys[1]]['name']);
	player_card3.set_name(Network.players[Network.keys[2]]['name']);
	player_card4.set_name(Network.players[Network.keys[3]]['name']);
	
	if Network.boss == Network.peer_id:
		_update_gold();
		_on_bossChange(Network.boss);
	else:
		_mask_gold();

func _update_gold() -> void:
	$VBoxContainer/CenterContainer/Label.text = Network.players[Network.peer_id]['name'] + "\n" + Network.players[Network.peer_id]['gold'] + " gold";
	player_card1.set_gold(Network.players[1]['gold']);
	player_card1.set_bet(Network.players[1]['bet']);
	player_card2.set_gold(Network.players[Network.keys[1]]['gold']);
	player_card2.set_bet(Network.players[Network.keys[1]]['bet']);
	player_card3.set_gold(Network.players[Network.keys[2]]['gold']);
	player_card3.set_bet(Network.players[Network.keys[2]]['bet']);
	player_card4.set_gold(Network.players[Network.keys[3]]['gold']);
	player_card4.set_bet(Network.players[Network.keys[3]]['bet']);

func _mask_gold() -> void:
	player_card1.mask_gold();
	player_card1.mask_bet();
	player_card2.mask_gold();
	player_card2.mask_bet();
	player_card3.mask_gold();
	player_card3.mask_bet();
	player_card4.mask_gold();
	player_card4.mask_bet();
	
	player_card1.set_color(c_passive);
	player_card2.set_color(c_passive);
	player_card3.set_color(c_passive);
	player_card4.set_color(c_passive);

func _on_bossChange(new_boss) -> void:
	if Network.peer_id == new_boss:
		$BossDialog.popup();
		next_phase.visible = true;
		next_phase.disabled = true;
		
		player_card1.get_node("ReferenceRect").connect("gui_input", self, "_on_player1_click");
		player_card2.get_node("ReferenceRect").connect("gui_input", self, "_on_player2_click");
		player_card3.get_node("ReferenceRect").connect("gui_input", self, "_on_player3_click");
		player_card4.get_node("ReferenceRect").connect("gui_input", self, "_on_player4_click");
		
		player_card1.set_color(c_selectable);
		player_card2.set_color(c_selectable);
		player_card3.set_color(c_selectable);
		player_card4.set_color(c_selectable);
	else:
		player_card1.set_color(c_passive);
		player_card2.set_color(c_passive);
		player_card3.set_color(c_passive);
		player_card4.set_color(c_passive);

func _on_nextPhase() -> void:
	var bets: int = 0;
	for k in Network.keys:
		if Network.players[k]['bet'] > 0:
			bets = bets + 1;
	
	var win_lose: int;
	if bets >= 3:
		win_lose = 3;
	else:
		win_lose = -3;
	Network.players[Network.peer_id]['gold'] = Network.players[Network.peer_id]['gold'] + win_lose;
	
	phase['next'] = {};
	for k in Network.keys:
		phase['next'][k] = {};
		phase['next'][k]['gold'] = Network.players[k]['gold'];
	
	Network.k_ind = Network.k_ind + 1;
	if Network.k_ind > 3:
		Network.k_ind = 0;
	
	phase['next']['boss'] = Network.keys[Network.k_ind];
	
	get_tree().multiplayer.send_bytes(to_json(phase).to_ascii());
	
	_mask_gold();
	next_phase.visible = false;
	next_phase.disabled = true;

func _on_trade_requested() -> void:
	$TradeDialog/SpinBox.max_value = Network.players[Network.peer_id]['gold'];
	$TradeDialog.popup();

func _make_deal() -> void:
	var response: Dictionary = {};
	response['deal'] = $TradeDialog/SpinBox.value;
	if get_tree().multiplayer.is_network_server():
		_on_deal_concluded(1, response['deal']);
	else:
		get_tree().multiplayer.send_bytes(to_json(response).to_ascii(), Network.boss);

func _on_deal_concluded(trader: int, gold_given: int) -> void:
	Network.players[trader]['gold'] = Network.players[trader]['gold'] - gold_given;
	Network.players[trader]['bet'] = gold_given;
	$PopupDialog.hide();
	_update_gold();
	
	var broadcast: Dictionary = {};
	broadcast['done'] = trader;
	match Network.keys.find(trader):
		0:
			player_card1.get_node("ReferenceRect").disconnect("gui_input", self, "_on_player1_click");
			player_card1.set_color(c_done);
		1:
			player_card2.get_node("ReferenceRect").disconnect("gui_input", self, "_on_player2_click");
			player_card2.set_color(c_done);
		2:
			player_card3.get_node("ReferenceRect").disconnect("gui_input", self, "_on_player3_click");
			player_card3.set_color(c_done);
		3:
			player_card4.get_node("ReferenceRect").disconnect("gui_input", self, "_on_player4_click");
			player_card4.set_color(c_done);
	get_tree().multiplayer.send_bytes(to_json(broadcast).to_ascii());
	
	completed_trades = completed_trades + 1;
	if completed_trades == 4:
		next_phase.disabled = false;

func _on_done(id: int) -> void:
	match Network.keys.find(id):
		0:
			player_card1.set_color(c_done);
		1:
			player_card2.set_color(c_done);
		2:
			player_card3.set_color(c_done);
		3:
			player_card4.set_color(c_done);

func _on_player1_click(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		if Network.keys.find(Network.peer_id) == 0:
			_on_trade_requested();
		else:
			var trade: Dictionary = {};
			trade['trade'] = Network.peer_id;
			get_tree().multiplayer.send_bytes(to_json(trade).to_ascii(), Network.keys[0]);
			$PopupDialog.popup();

func _on_player2_click(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		if Network.keys.find(Network.peer_id) == 1:
			_on_trade_requested();
		else:
			var trade: Dictionary = {};
			trade['trade'] = Network.peer_id;
			get_tree().multiplayer.send_bytes(to_json(trade).to_ascii(), Network.keys[1]);
			$PopupDialog.popup();

func _on_player3_click(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		if Network.keys.find(Network.peer_id) == 2:
			_on_trade_requested();
		else:
			var trade: Dictionary = {};
			trade['trade'] = Network.peer_id;
			get_tree().multiplayer.send_bytes(to_json(trade).to_ascii(), Network.keys[2]);
			$PopupDialog.popup();

func _on_player4_click(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		if Network.keys.find(Network.peer_id) == 3:
			_on_trade_requested();
		else:
			var trade: Dictionary = {};
			trade['trade'] = Network.peer_id;
			get_tree().multiplayer.send_bytes(to_json(trade).to_ascii(), Network.keys[3]);
			$PopupDialog.popup();
