extends Node3D
class_name InvasionManager

var castle_ladder_spots: Array[Dictionary] = []
var active_queue_spots: Array[Dictionary] = []

func _ready() -> void:
	var spots_parent = $LadderClimbingSpots
	if spots_parent:
		for child in spots_parent.get_children():
			if child is Marker3D:
				castle_ladder_spots.append({
					"marker": child,
					"is_claimed": false
				})
	else:
		push_error("InvasionManager: Could not find 'LadderClimbingSpots'. Check your node paths.")

func claim_closest_ladder_spot(requester_pos: Vector3) -> Marker3D:
	var closest_spot: Dictionary = {}
	var shortest_dist: float = INF
	
	for spot in castle_ladder_spots:
		if not spot["is_claimed"]:
			var dist = requester_pos.distance_squared_to(spot["marker"].global_position)
			if dist < shortest_dist:
				shortest_dist = dist
				closest_spot = spot
				
	if not closest_spot.is_empty():
		closest_spot["is_claimed"] = true
		return closest_spot["marker"]
		
	return null

func register_placed_ladder(ladder: Node3D, auto_claim_first_spot: bool = true) -> Marker3D:
	var queue_parent = ladder.get_node_or_null("Queue")
	var first_spot_marker: Marker3D = null
	
	if queue_parent:
		var spots = queue_parent.get_children()
		for i in range(spots.size()):
			var spot_node = spots[i]
			if spot_node is Marker3D:
				var is_claimed = (i == 0 and auto_claim_first_spot)
				if is_claimed:
					first_spot_marker = spot_node
					
				active_queue_spots.append({
					"marker": spot_node,
					"is_claimed": is_claimed
				})
				
	return first_spot_marker


func claim_closest_queue_spot(requester_pos: Vector3) -> Marker3D:
	var closest_spot: Dictionary = {}
	var shortest_dist: float = INF
	
	for spot in active_queue_spots:
		if is_instance_valid(spot["marker"]) and not spot["is_claimed"]:
			var dist = requester_pos.distance_squared_to(spot["marker"].global_position)
			if dist < shortest_dist:
				shortest_dist = dist
				closest_spot = spot
				
	if not closest_spot.is_empty():
		closest_spot["is_claimed"] = true
		return closest_spot["marker"]
		
	return null


func has_available_ladder_spots() -> bool:
	for spot in castle_ladder_spots:
		if not spot["is_claimed"]:
			return true
	return false

func release_claim(marker: Marker3D) -> void:
	if not is_instance_valid(marker):
		return
		
	for spot in castle_ladder_spots:
		if spot["marker"] == marker:
			spot["is_claimed"] = false
			return
			
	for spot in active_queue_spots:
		if spot["marker"] == marker:
			spot["is_claimed"] = false
			return

func _process(_delta: float) -> void:
	for i in range(active_queue_spots.size() - 1, -1, -1):
		var spot = active_queue_spots[i]
		if not is_instance_valid(spot["marker"]):
			active_queue_spots.remove_at(i)
