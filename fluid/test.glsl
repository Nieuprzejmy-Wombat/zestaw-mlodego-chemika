#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;



layout(set = 0, binding = 0, std430) readonly restrict buffer ChunkNeighbourBuffer {
	uint data[][3][3][3];
} chunkNeighbourBuffer;

layout(set = 0, binding = 1, std430) restrict buffer ChunkDataBuffer {
	float data[][16][16][16][16][10];
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
	float data[16][10];
} defaultVoxelBuffer;


layout(set = 2, binding = 0, std430) restrict buffer FullnessBuffer {
	uint data[][16][16][16];
} fullnessBuffer;



void main(){
	
}
