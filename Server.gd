extends Node

const MAX_SESSIONS := 10
const ALPHA := "abcdefghijklmnopqrstuvwxyz"

var peer: WebSocketServer = null

# dictionary of string:array
var sessions := {}

var players := {}


func _ready():
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	
	peer = WebSocketServer.new()
	if OS.has_environment("GD_PRIVATE_KEY") and OS.has_environment("GD_CERT"):
		var key_path := OS.get_environment("GD_PRIVATE_KEY")
		var crt_path := OS.get_environment("GD_CERT")
		var key := CryptoKey.new()
		key.load(key_path)
		var crt := X509Certificate.new()
		crt.load(crt_path)
		
		peer.private_key = key
		peer.ssl_certificate = crt
	peer.listen(5555, PoolStringArray(["ludus"]), true)
	get_tree().set_network_peer(peer)
	get_tree().connect("server_disconnected", self, "_on_close_network")


remote func create_session():
	print("create_session")
	var id := get_tree().get_rpc_sender_id()
	if sessions.size() < MAX_SESSIONS:
		var session_name := _generate_session_name()
		if session_name != "":
			sessions[session_name] = [id]
			players[id] = session_name
			rpc_id(id, "respond_create_session", session_name)
			return
	rpc_id(id, "no_available_sessions")


remote func join_session(name: String):
	var id := get_tree().get_rpc_sender_id()
	for s in sessions:
		if s == name:
			sessions[s].append(id)
			players[id] = s
			rpc_id(id, "respond_join_session")
			
			for p in sessions[s]:
				for p2 in sessions[s]:
					if p2 != p:
						rpc_id(p, "send_info", p2)
			return
	rpc_id(id, "invalid_session_name")


remote func send_points(points: int):
	var id := get_tree().get_rpc_sender_id()
	assert(id in players)
	var session_name: String = players[id]
	for p in sessions[session_name]:
		if p != id:
			rpc_id(p, "send_points", id, points)


remote func show_points():
	print("show points")
	var id := get_tree().get_rpc_sender_id()
	assert(id in players)
	var session_name: String = players[id]
	for p in sessions[session_name]:
		if p != id:
			rpc_id(p, "show_points")


remote func start_timer():
	var id := get_tree().get_rpc_sender_id()
	assert(id in players)
	var session_name: String = players[id]
	for p in sessions[session_name]:
		if p != id:
			rpc_id(p, "start_timer")


remote func end_timer():
	var id := get_tree().get_rpc_sender_id()
	assert(id in players)
	var session_name: String = players[id]
	for p in sessions[session_name]:
		if p != id:
			rpc_id(p, "end_timer")


func _on_peer_connected(id: int):
	print("%d connected" % id)


func _on_peer_disconnected(id: int):
	print("%d disconnected" % id)
	if id in players:
		var session: String = players[id]
		for p in sessions[session]:
			if p != id:
				rpc_id(p, "player_disconnected", id)
		sessions[session].erase(id)
		if sessions[session].size() == 0:
			sessions.erase(session)
		players.erase(id)


func _on_close_network():
	print("closing network")


func _generate_session_name() -> String:
	for tries in range(20):
		var session_name := ""
		for i in range(3):
			var c := ALPHA[randi() % 26]
			session_name += c
		if not session_name in sessions:
			return session_name
	return ""
