extends Node
var active = false
var callback: JavaScriptObject
var window: JavaScriptObject
var current_game: Node
var current_level: Node
var last_json = ""
func _ready():
	if not OS.has_feature("web"): return
	active = JavaScriptBridge.eval("new URLSearchParams(location.search).get('studio') === '1'")
	if not active: return
	window = JavaScriptBridge.get_interface("window")
	callback = JavaScriptBridge.create_callback(receive)
	window.gioDeliver = callback
	JavaScriptBridge.eval("""
	window.gioToken = new URLSearchParams(location.search).get('token');
	window.gioParentOrigin = new URLSearchParams(location.search).get('parentOrigin');
	window.gioSend = (type, details={}) => parent.postMessage({type, token:window.gioToken, ...details},window.gioParentOrigin);
	addEventListener('message', e => {
	 if(e.source!==parent || e.origin!==window.gioParentOrigin || e.data?.token!==window.gioToken || e.data?.type!=='gio:level') return;
	 if(typeof e.data.json==='string' && e.data.json.length<=2000000) window.gioDeliver(e.data.json);
	});
	""")
func waiting(game: Node):
	current_game = game
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	send("gio:ready")
func send(type: String):
	if active: window.gioSend(type)
func receive(arguments: Array):
	var text = str(arguments[0])
	var result = preload("res://scripts/studio_import.gd").new().parse(text)
	if not result.errors.is_empty():
		send_error(result.errors)
		return
	last_json = text
	if is_instance_valid(current_game): current_game.queue_free()
	if is_instance_valid(current_level): current_level.queue_free()
	current_level = result.level
	add_child(current_level)
	var game = load("res://scenes/main.tscn").instantiate()
	game.level_override = current_level
	game.studio_test = true
	get_tree().root.add_child(game)
	current_game = game
	if not current_level.problems().is_empty(): send_error(current_level.problems())
	else: JavaScriptBridge.eval("window.gioSend('gio:loaded')") if active else pass_native()
func pass_native():
	pass
func send_error(errors):
	if active:
		window.gioError = JSON.stringify(errors)
		JavaScriptBridge.eval("window.gioSend('gio:error',{errors:JSON.parse(window.gioError)})")
func return_to_editor():
	if active: JavaScriptBridge.eval("window.gioSend('gio:return')")
