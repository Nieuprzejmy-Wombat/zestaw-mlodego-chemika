extends Resource
@export var locations: Dictionary
enum FluidType {NONE, WATER}

func lookup(location: Vector3) -> FluidType:
	var res: FluidType = locations.find_key(location)
	return res if res else FluidType.NONE
	
func spawn(location: Vector3, fluid: FluidType) -> void:
	locations[location] = fluid
