extends Node

var peer: WebSocketServer = null

var sessions := {
	"abc": [],
	"def": [],
	"ghi": [],
	"jkl": [],
	"mno": []
}

var players := {}


func _ready():
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	
	peer = WebSocketServer.new()
	peer.listen(5555, PoolStringArray(["ludus"]), true)
	get_tree().set_network_peer(peer)
	get_tree().connect("server_disconnected", self, "_on_close_network")


remote func create_session():
	print("create_session")
	var id := get_tree().get_rpc_sender_id()
	for s in sessions:
		if sessions[s].size() == 0:
			sessions[s].append(id)
			players[id] = s
			rpc_id(id, "respond_create_session", s)
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
		players.erase(id)


func _on_close_network():
	print("closing network")
