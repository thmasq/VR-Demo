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

func register_placed_ladder(ladder: Node3D, placer_slime: Node3D) -> Marker3D:
	var queue_parent = ladder.get_node_or_null("Queue")
	var first_spot_marker: Marker3D = null
	
	if queue_parent:
		var spots = queue_parent.get_children()
		for i in range(spots.size()):
			var spot_node = spots[i]
			if spot_node is Marker3D:
				var occupant = null
				
				if i == 0 and is_instance_valid(placer_slime):
					first_spot_marker = spot_node
					occupant = placer_slime
					
				active_queue_spots.append({
					"marker": spot_node,
					"ladder": ladder,
					"index": i,
					"occupant": occupant
				})
				
	return first_spot_marker

func claim_closest_queue_spot(requester: Node3D) -> Marker3D:
	var closest_spot: Dictionary = {}
	var shortest_dist: float = INF
	
	for spot in active_queue_spots:
		if is_instance_valid(spot["marker"]) and spot["occupant"] == null:
			var dist = requester.global_position.distance_squared_to(spot["marker"].global_position)
			if dist < shortest_dist:
				shortest_dist = dist
				closest_spot = spot
				
	if not closest_spot.is_empty():
		closest_spot["occupant"] = requester
		return closest_spot["marker"]
		
	return null


func compact_ladder_queue(ladder: Node3D) -> void:
	var ladder_spots = []
	for spot in active_queue_spots:
		if spot.get("ladder") == ladder:
			ladder_spots.append(spot)
			
	ladder_spots.sort_custom(func(a, b): return a["index"] < b["index"])
	
	for i in range(ladder_spots.size() - 1):
		if ladder_spots[i]["occupant"] == null:
			for j in range(i + 1, ladder_spots.size()):
				if is_instance_valid(ladder_spots[j]["occupant"]):
					var slime = ladder_spots[j]["occupant"]
					
					if not slime.is_inside_tree() or slime.is_queued_for_deletion():
						continue 
					
					ladder_spots[i]["occupant"] = slime
					ladder_spots[j]["occupant"] = null
					
					if slime.has_method("advance_to_spot"):
						slime.advance_to_spot(ladder_spots[i]["marker"])
					break

func release_claim(marker: Marker3D) -> void:
	if not is_instance_valid(marker): return
		
	for spot in castle_ladder_spots:
		if spot["marker"] == marker:
			spot["is_claimed"] = false
			return
			
	for spot in active_queue_spots:
		if spot["marker"] == marker:
			spot["occupant"] = null
			
			if is_instance_valid(spot.get("ladder")):
				compact_ladder_queue(spot["ladder"])
			return

func has_available_ladder_spots() -> bool:
	for spot in castle_ladder_spots:
		if not spot["is_claimed"]:
			return true
	return false
