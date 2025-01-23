extends Resource
class_name MaterialProperty

@export var direction: Vector3
@export var function_curve: Curve
@export var input_scale: float
@export var offset: float = -0.5

func apply(point:Vector3) -> float:
	var raw := point.dot(direction)*point.length()
	return function_curve.sample(raw*input_scale+offset)
