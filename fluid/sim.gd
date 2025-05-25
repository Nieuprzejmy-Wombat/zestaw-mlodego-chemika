extends FogVolume
class_name FluidVolume

const chunk_size := 8
const fraction_size := 16

@onready var rd := RenderingServer.create_local_rendering_device()
@onready var shader := rd.shader_create_from_spirv(
	preload("res://fluid/shader.glsl")
	.get_spirv())

func create_float_buffer(default: float, length: int) -> RID:
	var packed := PackedFloat32Array()
	packed.resize(length)
	packed.fill(default)
	var bytes := packed.to_byte_array()
	return rd.storage_buffer_create(bytes.size(), bytes)

func floats_to_buffer(packed: PackedFloat32Array) -> RID:
	var bytes := packed.to_byte_array()
	return rd.storage_buffer_create(bytes.size(), bytes)

@export var dimensions := Vector3i(16,8,4)
@export var voxel_size := 0.02
@export var mass_curve := PackedFloat32Array([0.0])
@export var mass_direction := PackedFloat32Array([0.1, 0.2, 0.3])
@export var gravity := PackedFloat32Array([0.1, 0.2, 0.3])
@export var pressure_multiplier := PackedFloat32Array([1.0])

@onready var mass_curve_buffer := floats_to_buffer(mass_curve)
@onready var mass_direction_buffer := floats_to_buffer(mass_direction)
@onready var gravity_buffer := floats_to_buffer(gravity)
@onready var pressure_multiplier_buffer := floats_to_buffer(pressure_multiplier)
@onready var default_voxel_buffer := create_float_buffer(0.0, fraction_size*10)

var neighbourhood: RID
var chunk_data: RID
var activity_buffer: RID
var current_computation_width := 0
var fullness: RID

# use .call_deferred so that it doesn't conflict with _process
func reset(data: PackedFloat32Array) -> void:
	if activity_buffer.is_valid():
		rd.free_rid(activity_buffer)
	if neighbourhood.is_valid():
		rd.free_rid(neighbourhood)
	if chunk_data.is_valid():
		rd.free_rid(chunk_data)
	current_computation_width = dimensions.x*dimensions.y*dimensions.z
	var bytes := data.to_byte_array()
	chunk_data = rd.storage_buffer_create(bytes.size(), bytes)
	var raw_activity := PackedByteArray([0])
	raw_activity.resize(current_computation_width*4)
	raw_activity.fill(-1)
	activity_buffer = rd.storage_buffer_create(raw_activity.size(), raw_activity)
	var neighbourhood_data := PackedInt32Array()
	neighbourhood_data.resize(current_computation_width*3*3*3)
	for x in dimensions.x:
		for y in dimensions.y:
			for z in dimensions.z:
				for dx in 3:
					for dy in 3:
						for dz in 3:
							neighbourhood_data.append(
								wrapi(x+dx-1, 0, dimensions.x)*dimensions.y*dimensions.z
								+wrapi(y+dy-1, 0, dimensions.y)*dimensions.z
								+wrapi(z+dz-1, 0, dimensions.z))
	var neighbourhood_bytes := neighbourhood_data.to_byte_array()
	neighbourhood = rd.storage_buffer_create(
		neighbourhood_bytes.size(),
		neighbourhood_bytes)
	fullness = rd.storage_buffer_create(
		dimensions.x*dimensions.y*dimensions.z
		*chunk_size*chunk_size*chunk_size
		*4)

func process(delta: float) -> void:
	push_warning("haha")
	if (current_computation_width == 0):
		return
	var neighbourhood_uniform := RDUniform.new()
	neighbourhood_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	neighbourhood_uniform.binding = 0
	neighbourhood_uniform.add_id(neighbourhood)
	var chunk_data_uniform := RDUniform.new()
	chunk_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	chunk_data_uniform.binding = 1
	chunk_data_uniform.add_id(chunk_data)
	var activity_uniform := RDUniform.new()
	activity_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	activity_uniform.binding = 2
	activity_uniform.add_id(activity_buffer)
	var data_set := rd.uniform_set_create(
		[neighbourhood_uniform, chunk_data_uniform, activity_uniform],
		shader,
		0)
	
	var time_buffer := create_float_buffer(delta, 1)
	var time_uniform := RDUniform.new()
	time_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	time_uniform.binding = 0
	time_uniform.add_id(time_buffer)
	var mass_curve_uniform := RDUniform.new()
	mass_curve_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	mass_curve_uniform.binding = 1
	mass_curve_uniform.add_id(mass_curve_buffer)
	var mass_direction_uniform := RDUniform.new()
	mass_direction_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	mass_direction_uniform.binding = 2
	mass_direction_uniform.add_id(mass_direction_buffer)
	var gravity_uniform := RDUniform.new()
	gravity_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	gravity_uniform.binding = 3
	gravity_uniform.add_id(gravity_buffer)
	var pressure_multiplier_uniform := RDUniform.new()
	pressure_multiplier_uniform.uniform_type = \
		RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	pressure_multiplier_uniform.binding = 4
	pressure_multiplier_uniform.add_id(pressure_multiplier_buffer)
	var default_voxel_uniform := RDUniform.new()
	default_voxel_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	default_voxel_uniform.binding = 5
	default_voxel_uniform.add_id(default_voxel_buffer)
	var config_set := rd.uniform_set_create(
		[time_uniform, mass_curve_uniform, mass_direction_uniform,
		gravity_uniform, pressure_multiplier_uniform, default_voxel_uniform],
		shader,
		1)
	
	var fullness_uniform := RDUniform.new()
	fullness_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	fullness_uniform.binding = 0
	fullness_uniform.add_id(fullness)
	var tool_set := rd.uniform_set_create(
		[fullness_uniform],
		shader, 
		2)
	
	push_warning("aiai")
	rd.compute_list_end()
	print("uiui")
	var pipeline := rd.compute_pipeline_create(shader)
	print(pipeline.get_id())
	var compute_list := rd.compute_list_begin()
	print(compute_list)
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, data_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, config_set, 1)
	rd.compute_list_bind_uniform_set(compute_list, tool_set, 2)
	rd.compute_list_dispatch(compute_list, current_computation_width, 1, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
	
	var buffer_data := rd.buffer_get_data(chunk_data).to_float32_array()
	print(buffer_data)
	material.set_shader_parameter("data", buffer_data)
	
	rd.free_rid(time_buffer)
	
	rd.free_rid(tool_set)
	rd.free_rid(data_set)

func _process(delta: float) -> void:
	process(delta)
