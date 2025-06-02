shader_type fog;

uniform float data[4*2*1*8*8*8*16*10];

float current(vec3 pos, int sub) {
    return data[
        int(pos.x/8.0)*2*1*8*8*8*16*10+
		int(pos.y/8.0)*1*8*8*8*16*10+
        int(pos.z/8.0)*8*8*8*16*10+
        (int(pos.x)%8)*8*8*16*10+
        (int(pos.y)%8)*8*16*10+
        (int(pos.z)%8)*16*10+
        int(sub)];
}

void fog() {
	vec4 color_acc = vec4(0.0);
	// REMEMBER: NOT PHYSICALLY ACCURATE
	vec3 uvw=vec3(UVW.x*8.0*4.0, UVW.y*8.0*2.0, UVW.z*8.0*1.0);
	for (int i = 0; i<16; i++){
		color_acc += vec4(
			current(uvw, i*10+0)*16.0,
			current(uvw, i*10+1),
			current(uvw, i*10+2),
			current(uvw, i*10+9))/16.0;
	}
	float a = 3.0;
	float b = 1000.0;
	float c = 7.0;
	//ALBEDO = color_acc.rgb/256.0;
	//DENSITY = c-pow((color_acc.a+a)/b, -1.0/3.0);
	DENSITY = 1.0;
	ALBEDO = UVW;
}