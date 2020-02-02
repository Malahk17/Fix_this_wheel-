extends Node;

signal boss_change(new_boss);
signal trade;
signal deal(id, dealer);
signal done(dealer);

const DEFAULT_IP: String = '127.0.0.1';
const DEFAULT_PORT: int = 34573;
const MAX_PLAYERS: int = 3;

var peer_id: int;

var players: Dictionary = {};

var server: bool;

var keys: Array = [];
var k_ind: int;
var boss: int;

func _ready() -> void:
	# Server has always to exists
	players[1] = {};

func create_server(nickname: String) -> void:
	var peer = NetworkedMultiplayerENet.new();
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS);
	get_tree().set_network_peer(peer);
	
	get_tree().multiplayer.connect('network_peer_connected', self, 'peer_connected');
	get_tree().multiplayer.connect('network_peer_disconnected', self, 'peer_disconnected');
	get_tree().multiplayer.connect("network_peer_packet", self, "_on_packet_received");
	
	server = true;
	
	players[1]['name'] = nickname;
	peer_id = 1;

func connect_to_server(nickname: String) -> void:
	var peer = NetworkedMultiplayerENet.new();
	peer.create_client(DEFAULT_IP, DEFAULT_PORT);
	get_tree().set_network_peer(peer);
	
	get_tree().multiplayer.connect('network_peer_connected', self, 'peer_connected');
	get_tree().multiplayer.connect('network_peer_disconnected', self, 'peer_disconnected');
	get_tree().multiplayer.connect("network_peer_packet", self, "_on_packet_received");
	get_tree().multiplayer.connect("server_disconnected", self, "_on_server_disconnected");
	
	peer_id = get_tree().get_network_unique_id();
	players[peer_id] = {};
	players[peer_id]['name'] = nickname;

func peer_connected(net_id: int) -> void:
	players[net_id] = {};
	get_tree().multiplayer.send_bytes(to_json(players[peer_id]).to_ascii());

func peer_disconnected(id: int) -> void:
	get_tree().quit();

func _on_server_disconnected() -> void:
	get_tree().quit();

func _on_packet_received(id: int, packet: PoolByteArray) -> void:
	var message: Dictionary = parse_json(packet.get_string_from_ascii());
	
	if message.has('name'):
		players[id]['name'] = message['name'];
	elif message.has('set-game'):
		for k in keys:
			players[k]['gold'] = 10;
			players[k]['bet'] = 0;
		
		keys = players.keys();
		boss = message['set-game']['boss'];
		k_ind = keys.find(boss);
		Global.goto_scene("res://GamingTable.tscn");
	elif message.has('next'):
		for k in keys:
			players[k] = {};
			players[k]['gold'] = message['next'][k]['gold'] + 10;
			players[k]['bet'] = 0;
		
		boss = message['next']['boss'];
#		get_tree().get_root().get_node('GamingTable')._on_bossChange(boss);
		Network.emit_signal("boss_change", boss);
	elif message.has("trade"):
		Network.emit_signal("trade");
	elif message.has('deal'):
		Network.emit_signal('deal', id, message['deal']);
	elif message.has('done'):
		Network.emit_signal('done', message['done']);

func send_to_game():
	var command: Dictionary = {};
	
	keys = players.keys();
	k_ind = 0;
	boss = keys[k_ind];
	
	for k in keys:
		players[k]['gold'] = 10;
		players[k]['bet'] = 0;
	
	command['set-game'] = {};
	command['set-game']['boss'] = boss;
	
	get_tree().multiplayer.send_bytes(to_json(command).to_ascii());
