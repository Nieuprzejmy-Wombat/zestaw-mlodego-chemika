extends MaterialSampler
class_name MaterialGroup

@export var materials: Array[MaterialType]
@export var name: String

func sample(pos: Vector3) -> float:
	var sum:= 0.0
	for material in materials:
		sum+=material.sample(pos)
	return sum
