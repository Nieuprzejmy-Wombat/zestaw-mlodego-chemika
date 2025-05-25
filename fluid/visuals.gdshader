shader_type fog;

uniform float data[8*4*2*8*8*8*16*10];

float current(vec3 uvw, int sub) {
	int gx = int(uvw.x*4.0);
	int gy = int(uvw.y*2.0);
	int gz = int(uvw.z*1.0);
	int lx = int(uvw.x*4.0*8.0)%8;
	int ly = int(uvw.y*2.0*8.0)%8;
	int lz = int(uvw.z*1.0*8.0)%8;
	return data[
		gx*2*1*8*8*8*16*10
		+gy*1*8*8*8*16*10
		+gz*8*8*8*16*10
		+lx*8*8*16*10
		+ly*8*16*10
		+lz*16*10
		+sub];
}

void fog() {
	vec4 color_acc = vec4(0.0);
	// REMEMBER: NOT PHYSICALLY ACCURATE
	for (int i = 0; i<16; i++){
		color_acc += vec4(
			current(UVW, i*10+0),
			current(UVW, i*10+1),
			current(UVW, i*10+2),
			current(UVW, i*10+9));
	}
	ALBEDO = color_acc.rgb;
	DENSITY = color_acc.a;
}
