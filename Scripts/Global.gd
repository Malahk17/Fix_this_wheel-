extends Node

var current_scene: Node = null;

func _ready():
	var root: Viewport = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1);

func goto_scene(path: String) -> void:
	call_deferred('_deferred_goto_scene', path);

func _deferred_goto_scene(path: String) -> void:
	current_scene.free();
	
	current_scene = ResourceLoader.load(path).instance();
	get_tree().get_root().add_child(current_scene);
	get_tree().set_current_scene(current_scene);
