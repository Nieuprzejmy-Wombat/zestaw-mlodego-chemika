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



uint chunkOffset(uint pos) {
	return uint(floor((chunk_size+int(pos)-1)/chunk_size)+1);
}

float[fraction_size][10] getVoxel(uint chunkNeighbours[3][3][3], uint x, uint y, uint z){
	uint currentChunk = chunkNeighbours[chunkOffset(gl_LocalInvocationID.x+x)][chunkOffset(gl_LocalInvocationID.y+y)][chunkOffset(gl_LocalInvocationID.z+z)];
	if (currentChunk >= chunkDataBuffer.data.length()) {
		return defaultVoxelBuffer.data;
	}
	return chunkDataBuffer.data[currentChunk][(int(gl_LocalInvocationID.x+x)-1)%chunk_size][(int(gl_LocalInvocationID.y+y)-1)%chunk_size][(int(gl_LocalInvocationID.z+z)-1)%chunk_size];
}

void setVoxel(uint chunkNeighbours[3][3][3], uint x, uint y, uint z, float data[fraction_size][10]){
	uint currentChunk = chunkNeighbours[chunkOffset(gl_LocalInvocationID.x+x)][chunkOffset(gl_LocalInvocationID.y+y)][chunkOffset(gl_LocalInvocationID.z+z)];
	chunkDataBuffer.data[currentChunk][(int(gl_LocalInvocationID.x+x)-1)%chunk_size][(int(gl_LocalInvocationID.y+y)-1)%chunk_size][(int(gl_LocalInvocationID.z+z)-1)%chunk_size] = data;
}

float calculateMassMultiplier(vec3 point){
	float x = dot(normalize(point), massDirectionBuffer.data) * length(point);
	float y = 0;
	float currentMult = 1;
	for (uint i = 0; i<massCurveBuffer.data.length(); i++){
		y+=massCurveBuffer.data[i]*currentMult;
		currentMult*=x;
	}
	return y;
}

float calculateFractionMass(float fraction[10]){
	return fraction[9]*calculateMassMultiplier(vec3(fraction[0], fraction[1], fraction[2]));
}

float radius(float volume){
	return pow(volume*(3.0/4.0/3.14), 1.0/3.0);
}

float repel(float dist, float rs){
	return pressureMultiplierBuffer.data * pow(dist-rs, 2);
}

vec3 calculatePressure(uint chunkNeighbours[3][3][3], vec3 pos, float volume){
	vec3 acc = gravityBuffer.data;
	for (uint x = 0; x<3; x++){
		for (uint y = 0; y<3; y++){
			for (uint z = 0; z<3; z++){
				float currentVoxel[fraction_size][10] = getVoxel(chunkNeighbours, x, y, z);
				for (uint w = 0; w<fraction_size; w++){
					vec3 currentPosition = vec3(currentVoxel[w][3]+float(x)-1.0, currentVoxel[w][4]+float(y)-1.0, currentVoxel[w][5]+float(z)-1.0);
					float force = repel(distance(currentPosition, pos), radius(volume) + radius(currentVoxel[w][9]));
					force*=calculateFractionMass(currentVoxel[w]);
					acc += (currentPosition-pos) * (force/(float(fraction_size)*3.0*3.0*3.0 - 1));
				}
			}
		}
	}
	return acc;
}

void applyMovement(uint chunkNeighbours[3][3][3]) {
	float currentVoxel[fraction_size][10] = getVoxel(chunkNeighbours, 1, 1, 1);
	for(uint i = 0; i<fraction_size; i++){
		currentVoxel[i][3]+=currentVoxel[i][6]*timeBuffer.data;
		currentVoxel[i][4]+=currentVoxel[i][7]*timeBuffer.data;
		currentVoxel[i][5]+=currentVoxel[i][8]*timeBuffer.data;
	}
	setVoxel(chunkNeighbours, 1, 1, 1, currentVoxel);
}

void recalculateVelocities(uint chunkNeighbours[3][3][3]){
	float currentVoxel[fraction_size][10] = getVoxel(chunkNeighbours, 1, 1, 1);
	for (uint i=0; i<fraction_size; i++){
		vec3 fix = gravityBuffer.data;
		fix += calculatePressure(chunkNeighbours, vec3(currentVoxel[i][3], currentVoxel[i][4], currentVoxel[i][5]), currentVoxel[i][9]) * calculateFractionMass(currentVoxel[i]);
		// fix += TODO some alignment and stickyness forces here
		
		fix *= timeBuffer.data;
		currentVoxel[i][6] += fix.x;
		currentVoxel[i][7] += fix.y;
		currentVoxel[i][8] += fix.z;
	}
	setVoxel(chunkNeighbours, 1, 1, 1, currentVoxel);
}

uint swapFullness(uint chunkNeighbours[3][3][3], uint x, uint y, uint z, uint data){
	uint currentChunk = chunkNeighbours[chunkOffset(gl_LocalInvocationID.x+x)][chunkOffset(gl_LocalInvocationID.y+y)][chunkOffset(gl_LocalInvocationID.z+z)];
	return atomicExchange(fullnessBuffer.data[currentChunk][(int(gl_LocalInvocationID.x+x)-1)%chunk_size][(int(gl_LocalInvocationID.y+y)-1)%chunk_size][(int(gl_LocalInvocationID.z+z)-1)%chunk_size], data);
}


void main() {
	uint chunkNeighbours[3][3][3] = chunkNeighbourBuffer.data[gl_WorkGroupID.x*gl_NumWorkGroups.y*gl_NumWorkGroups.z + gl_WorkGroupID.y*gl_NumWorkGroups.z + gl_WorkGroupID.z];
	
	recalculateVelocities(chunkNeighbours);
	
	applyMovement(chunkNeighbours);

	float previousVoxel[fraction_size][10] = getVoxel(chunkNeighbours, 1, 1, 1);

	uint voxelCount = 0;
	float currentVoxel[fraction_size][10] = {{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0},{0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0}};

	for (uint i = 0; i < fraction_size; i++) {
		if (previousVoxel[i][9]!=0.0){
			bool simmilar = false;
			for (uint j = 0; j < voxelCount && !simmilar; j++){
				if (currentVoxel[j][0]==previousVoxel[i][0] && currentVoxel[j][1]==previousVoxel[i][1] && currentVoxel[j][2]==previousVoxel[i][2]) {
					if (dot(vec3(currentVoxel[j][6], currentVoxel[j][7], currentVoxel[j][8]), vec3(previousVoxel[i][6], previousVoxel[i][7], previousVoxel[i][8]))>=0.1) {
						currentVoxel[j][3]*=currentVoxel[j][9];
						currentVoxel[j][4]*=currentVoxel[j][9];
						currentVoxel[j][5]*=currentVoxel[j][9];
						currentVoxel[j][6]*=currentVoxel[j][9];
						currentVoxel[j][7]*=currentVoxel[j][9];
						currentVoxel[j][8]*=currentVoxel[j][9];
						
						previousVoxel[i][3]*=previousVoxel[i][9];
						previousVoxel[i][4]*=previousVoxel[i][9];
						previousVoxel[i][5]*=previousVoxel[i][9];
						previousVoxel[i][6]*=previousVoxel[i][9];
						previousVoxel[i][7]*=previousVoxel[i][9];
						previousVoxel[i][8]*=previousVoxel[i][9];
						
						currentVoxel[j][3]+=previousVoxel[i][3];
						currentVoxel[j][4]+=previousVoxel[i][4];
						currentVoxel[j][5]+=previousVoxel[i][5];
						currentVoxel[j][6]+=previousVoxel[i][6];
						currentVoxel[j][7]+=previousVoxel[i][7];
						currentVoxel[j][8]+=previousVoxel[i][8];
						
						currentVoxel[j][9]+=previousVoxel[i][9];
						
						currentVoxel[j][3]/=currentVoxel[j][9];
						currentVoxel[j][4]/=currentVoxel[j][9];
						currentVoxel[j][5]/=currentVoxel[j][9];
						currentVoxel[j][6]/=currentVoxel[j][9];
						currentVoxel[j][7]/=currentVoxel[j][9];
						currentVoxel[j][8]/=currentVoxel[j][9];
						
						simmilar = true;
					}
				}
			}
			if (!simmilar) {
				currentVoxel[voxelCount] = previousVoxel[i];
				voxelCount += 1;
			}
		}
	};
	
	setVoxel(chunkNeighbours, 1, 1, 1, currentVoxel);
	
	fullnessBuffer.data[chunkNeighbours[1][1][1]][gl_LocalInvocationID.x][gl_LocalInvocationID.y][gl_LocalInvocationID.z] = voxelCount;
	
	uint completeness = 0;
	
	for (uint i = 0; i < voxelCount; i++) {
		if (floor(currentVoxel[i][3])!=0 || floor(currentVoxel[i][4])!=0 || floor(currentVoxel[i][5])!=0){
			completeness = bitfieldInsert(completeness, uint(4294967295), int(i), 1);
		}
	}
	
	memoryBarrier();
	barrier();
	
	for (uint t=0; t<1024; t++){
		if (completeness != 0){
			for (uint i = 0; i < fraction_size; i++) {
				if (bitfieldExtract(completeness, int(i), 1) != 0){
					uint fullness = swapFullness(
						chunkNeighbours,
						uint(floor(currentVoxel[i][3]+1.0)),
						uint(floor(currentVoxel[i][4]+1.0)),
						uint(floor(currentVoxel[i][5]+1.0)),
						uint(fraction_size));
					if (fullness<fraction_size){
						float voxel[fraction_size][10];
						uint currentChunk = chunkNeighbours
							[chunkOffset(gl_LocalInvocationID.x+uint(floor(currentVoxel[i][3]+1.0)))]
							[chunkOffset(gl_LocalInvocationID.y+uint(floor(currentVoxel[i][4]+1.0)))]
							[chunkOffset(gl_LocalInvocationID.z+uint(floor(currentVoxel[i][5]+1.0)))];
						float copy[10] = {0.,0.,0.,0.,0.,0.,0.,0.,0.,0.};
						copy[0] = currentVoxel[i][0];
						copy[1] = currentVoxel[i][1];
						copy[2] = currentVoxel[i][2];
						copy[3] = currentVoxel[i][3];
						copy[4] = currentVoxel[i][4];
						copy[5] = currentVoxel[i][5];
						copy[6] = currentVoxel[i][6];
						copy[7] = currentVoxel[i][7];
						copy[8] = currentVoxel[i][8];
						copy[9] = currentVoxel[i][9]; // WHY DOESNT THIS LINE WORK!!!
						//for (uint  a = 0; a < 10; a++) {
							chunkDataBuffer.data[currentChunk]
							[(int(gl_LocalInvocationID.x+uint(floor(currentVoxel[i][3]+1.0)))-1) % chunk_size]
							[(int(gl_LocalInvocationID.y+uint(floor(currentVoxel[i][4]+1.0)))-1) % chunk_size]
							[(int(gl_LocalInvocationID.z+uint(floor(currentVoxel[i][5]+1.0)))-1) % chunk_size]
							[fullness] = copy;
						//}
						fullness+=1;
						swapFullness(chunkNeighbours, uint(floor(currentVoxel[i][3]+1.0)), uint(floor(currentVoxel[i][4]+1.0)), uint(floor(currentVoxel[i][5]+1.0)), fullness);
						completeness = bitfieldInsert(completeness, uint(0), int(i), 1);
					}
				}
			}
		}
	}
	
	memoryBarrier();
	barrier();
	
	if (fullnessBuffer.data[chunkNeighbours[1][1][1]][gl_LocalInvocationID.x][gl_LocalInvocationID.y][gl_LocalInvocationID.z]!=0) {
		activityBuffer.data[chunkNeighbours[1][1][1]]=true;
	}
}

