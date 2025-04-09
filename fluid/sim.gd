extends Node3D
class_name FluidSim

var chunks: Array[RDFluidChunk] = []
var neighbours_buffer: RID
var compute_width := 0
var data_mutex := Mutex.new()

var rd: RenderingDevice
var pipeline: RID
var shader: RID

@export var mass_curve: PackedFloat32Array
var mass_curve_buffer: RID

@export var mass_direction: PackedFloat32Array
var mass_direction_buffer: RID

@export var gravity: PackedFloat32Array
var gravity_buffer: RID

@export var pressure_multiplier: PackedFloat32Array
var pressure_multiplier_buffer: RID

var default_voxel_buffer: RID

@export var chunk_size := 1.0

func _ready() -> void:
	data_mutex.lock()
	rd = RenderingServer.create_local_rendering_device()
	mass_curve_buffer = rd.storage_buffer_create(
		mass_curve.to_byte_array().size(), mass_curve.to_byte_array())
	mass_direction_buffer = rd.storage_buffer_create(
		mass_direction.to_byte_array().size(), mass_direction.to_byte_array())
	gravity_buffer = rd.storage_buffer_create(
		gravity.to_byte_array().size(), gravity.to_byte_array())
	pressure_multiplier_buffer = rd.storage_buffer_create(
		pressure_multiplier.to_byte_array().size(), pressure_multiplier.to_byte_array())
	
	var shader_file := load("res://fluid/shader.glsl");
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader) # TODO fix the blockage here
	
	var default_voxel_arr := PackedFloat32Array()
	default_voxel_arr.resize(16*10)
	default_voxel_arr.fill(0)
	var default_voxel_data := default_voxel_arr.to_byte_array()
	default_voxel_buffer = rd.storage_buffer_create(
		default_voxel_data.size(), default_voxel_data)
	
	data_mutex.unlock()

func recalculate_neighbours() -> void:
	rd.free_rid(neighbours_buffer)
	var neighbours := PackedInt32Array()
	for chunk in chunks:
		if chunk.active:
			for x in [-1, 0, 1]:
				for y in [-1, 0, 1]:
					for z in [-1, 0, 1]:
						var pos = chunk.position + Vector3i(x, y, z)
						var idx := chunks.find_custom(
							func (c: RDFluidChunk):
								return c.position == pos)
						if idx<0:
							var data := PackedFloat32Array()
							data.resize(16*16*16*16*10)
							data.fill(0.0)
							var bytes := data.to_byte_array()
							var buffer := rd.storage_buffer_create(bytes.size(),
								bytes)
							var rd_chunk := RDFluidChunk.new()
							rd_chunk.data = buffer
							rd_chunk.position = pos
							rd_chunk.active = false
							idx = chunks.size()
							chunks.append(rd_chunk)
						neighbours.append(idx)
	var neighbours_bytes := neighbours.to_byte_array()
	neighbours_buffer = rd.storage_buffer_create(neighbours_bytes.size(),
		neighbours_bytes)

func reset_chunks(next_chunks: Array[FluidChunkSave]) -> void:
	data_mutex.lock()
	compute_width = next_chunks.size()
	for chunk in chunks:
		rd.free_rid(chunk.data)
	chunks = []
	for chunk in next_chunks:
		var bytes := chunk.data.to_byte_array()
		var buffer := rd.storage_buffer_create(bytes.size(), bytes)
		var rd_chunk := RDFluidChunk.new()
		rd_chunk.data = buffer
		rd_chunk.position = chunk.position
		rd_chunk.active = true
		chunks.append(rd_chunk)
	next_chunks = []
	recalculate_neighbours()
	data_mutex.unlock()

func _physics_process(delta: float) -> void:
	data_mutex.lock()
	
	if compute_width==0:
		data_mutex.unlock()
		return
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	var neighbours_uniform := RDUniform.new()
	neighbours_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	neighbours_uniform.binding = 0
	neighbours_uniform.add_id(neighbours_buffer)
	
	var data_uniform := RDUniform.new()
	data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	data_uniform.binding = 1
	for chunk in chunks:
		data_uniform.add_id(chunk.data)
	
	var activity_uniform := RDUniform.new()
	activity_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	data_uniform.binding = 2
	var activity_arr := PackedInt32Array()
	activity_arr.resize(compute_width)
	activity_arr.fill(true)
	var activity_data := activity_arr.to_byte_array()
	var activity_buffer := rd.storage_buffer_create(activity_data.size(), activity_data)
	data_uniform.add_id(activity_buffer)
	
	var input_set := rd.uniform_set_create(
		[neighbours_uniform, data_uniform, activity_uniform],
		shader, 0)
	rd.compute_list_bind_uniform_set(compute_list, input_set, 0)
	
	
	var time_uniform := RDUniform.new()
	time_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	time_uniform.binding = 0
	var time_data := PackedFloat32Array([delta]).to_byte_array()
	var time_buffer := rd.storage_buffer_create(time_data.size(), time_data)
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
	
	var param_set := rd.uniform_set_create(
		[time_uniform, mass_curve_uniform,mass_direction_uniform,
		gravity_uniform, pressure_multiplier_uniform, default_voxel_uniform],
		shader, 1)
	rd.compute_list_bind_uniform_set(compute_list, param_set, 1)
	
	
	var fullness_uniform := RDUniform.new()
	fullness_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	fullness_uniform.binding = 0
	var fullness_start_arr := PackedInt32Array()
	fullness_start_arr.resize(compute_width)
	fullness_start_arr.fill(0)
	var fullness_start_data := fullness_start_arr.to_byte_array()
	var fullness_buffer := rd.storage_buffer_create(
		fullness_start_data.size(), fullness_start_data)
	fullness_uniform.add_id(fullness_buffer)
	
	var output_set := rd.uniform_set_create([fullness_uniform], shader, 2)
	rd.compute_list_bind_uniform_set(compute_list, output_set, 2)
	
	rd.compute_list_dispatch(compute_list, compute_width, 1, 1)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()
	
	var activity := rd.buffer_get_data(activity_buffer).to_float32_array()
	var change := false
	for i in range(chunks.size()):
		if chunks[i].active != (activity[i]!=0):
			change = true
			chunks[i].active = activity[i]!=0
	if change:
		recalculate_neighbours()
	
	for volume in get_children():
		volume.queue_free()
	
	for chunk in chunks:
		if chunk.active:
			var volume := FogVolume.new()
			volume.size = Vector3(chunk_size, chunk_size, chunk_size)
			volume.material = ShaderMaterial.new()
			volume.material.shader = load("res://fluid/display.tres")
			volume.global_position = Vector3(chunk.position)
			add_child(volume)
	
	data_mutex.unlock()
