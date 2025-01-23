extends MaterialSampler
class_name MaterialType

@export var name: String
@export var texture: Texture3D

func sample(pos: Vector3) -> float:
	return texture.get_data()[pos.z].get_pixel(pos.x, pos.y).a
