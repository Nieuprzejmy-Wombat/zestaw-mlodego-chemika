extends Resource
class_name RecipeInput

@export var ammount := 1
@export var shape: MaterialShape = null
@export var simillarity: float
@export var purity := 0.5
@export var material: MaterialSampler

func sample(pos: Vector3, s: MaterialShape) -> bool:
	return material.sample(pos)>purity and (shape.rough or s.rough) and shape.size.distance_to(s.size)<simillarity
