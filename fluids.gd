extends Resource
@export var locations: Dictionary


func lookup(location: Vector3) -> Fluid:
	return locations[location.snapped(Vector3(0.25, 0.25, 0.25))]
	
func spawn(location: Vector3, fluid: Fluid) -> void:
	locations[location.snapped(Vector3(0.25, 0.25, 0.25))] = fluid
