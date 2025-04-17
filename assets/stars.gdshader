shader_type sky;


uniform float star_intensity: hint_range(0., 0.2) = 0.08;
uniform float layer_scale: hint_range(0., 60.) = 20.;
uniform float layer_scale_step: hint_range(0., 40.) = 10.;
uniform int layers_count: hint_range(0, 12) = 3;


// Voronoi method credit:
// The MIT License
// Copyright © 2013 Inigo Quilez
// https://www.shadertoy.com/view/ldl3Dl

vec3 hash(vec3 x) {
	x = vec3(dot(x, vec3(127.1,311.7, 74.7)),
			 dot(x, vec3(269.5,183.3,246.1)),
			 dot(x, vec3(113.5,271.9,124.6)));
	return fract(sin(x) * 43758.5453123);
}

vec2 voronoi(in vec3 x){
	vec3 p = floor(x);
	vec3 f = fract(x);
	
	float res = 100.;
	float id = 0.;
	
	for (float k = -1.; k <= 1.; k += 1.) {
		for (float j = -1.; j <= 1.; j += 1.) {
			for (float i = -1.; i <= 1.; i += 1.) {
				vec3 b = vec3(i, j, k);
				vec3 r = vec3(b) - f + hash(p + b);
				float d = dot(r, r);
				if (d < res) {
					res = d;
					id = dot(p + b, vec3(0., 57., 113.));
				}
		    }
		}
	}
	
	return vec2(sqrt(res), id);
}

void sky() {
	COLOR = vec3(0, 0, 0);
	
	for (int i = 0; i < layers_count; i++) {
		vec3 pos = EYEDIR * (layer_scale + float(i) * layer_scale_step);
		vec2 layer = voronoi(pos);
		
		vec3 rand = hash(vec3(layer.y));
		
		float star = smoothstep(star_intensity, 0., layer.x);
		
		vec3 star_color = star * vec3(1.0, 1.0, 1.0);
		
		COLOR += star_color;
	}
}