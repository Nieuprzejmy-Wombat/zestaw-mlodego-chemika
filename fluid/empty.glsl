#[compute]
#version 430

const uint chunk_size = 8;
const uint fraction_size = 16;

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;



layout(set = 0, binding = 0, std430) readonly restrict buffer ChunkNeighbourBuffer {
	uint data[][3][3][3];
} chunkNeighbourBuffer;

layout(set = 0, binding = 1, std430) restrict buffer ChunkDataBuffer {
	float data[][chunk_size][chunk_size][chunk_size][fraction_size][10];
} chunkDataBuffer;

layout(set = 0, binding = 2, std430) writeonly restrict buffer ActivityBuffer {
	bool data[];
} activityBuffer;


layout(set = 1, binding = 0, std430) readonly restrict buffer TimeBuffer {
	float data;
} timeBuffer;

layout(set = 1, binding = 1, std430) readonly restrict buffer MassCurveBuffer {
	float data[];
} massCurveBuffer;

layout(set = 1, binding = 2, std430) readonly restrict buffer MassDirectionBuffer {
	vec3 data;
} massDirectionBuffer;

layout(set = 1, binding = 3, std430) readonly restrict buffer GravityBuffer {
	vec3 data;
} gravityBuffer;

layout(set = 1, binding = 4, std430) readonly restrict buffer PressureMultiplierBuffer {
	float data;
} pressureMultiplierBuffer;

layout(set = 1, binding = 5, std430) readonly restrict buffer DefaultVoxelBuffer {
	float data[fraction_size][10];
} defaultVoxelBuffer;


layout(set = 2, binding = 0, std430) restrict buffer FullnessBuffer {
	uint data[][chunk_size][chunk_size][chunk_size];
} fullnessBuffer;

void main() {
}

