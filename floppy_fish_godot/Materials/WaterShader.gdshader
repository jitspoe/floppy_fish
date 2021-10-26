shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


varying flat vec3 normal;
float displace(vec3 v, float t) {
	float b1 = v.x * 3.0 + v.z * 0.5 + t;
	float b2 = v.x * 1.2 + v.z * 1.6 + t;
	return v.y + 0.05 * sin(b1) + 0.05 * sin(b2);
}

void vertex() {
	VERTEX.y = displace(VERTEX, TIME);
	normal = -normalize( cross( vec3(0.5, displace(VERTEX + vec3(0.5, 0, 0), TIME) - VERTEX.y, 0), vec3(0, displace(VERTEX + vec3(0, 0, 0.5), TIME) - VERTEX.y, 0.5) ) );
	normal = (MODELVIEW_MATRIX * vec4(normal, 0)).xyz;
}
/*
void vertex() {
	//UV=UV*uv1_scale.xy+uv1_offset.xy;
	//VERTEX.y += sin(VERTEX.x * 3.0 + VERTEX.z * 0.5 + TIME) * 0.1 + sin(VERTEX.x * 1.2 + VERTEX.z * 1.6 + TIME) * 0.1;
	float b1 = VERTEX.x * 3.0 + VERTEX.z * 0.5 + TIME;
	float b2 = VERTEX.x * 1.2 + VERTEX.z * 1.6 + TIME;
	float gx = 0.05 * 3.0 * cos(b1) + 0.05 * 1.2 * cos(b2);
	float gz = 0.05 * 0.5 * cos(b1) + 0.05 * 1.6 * cos(b2);
	VERTEX.y += 0.05 * sin(b1) + 0.05 * sin(b2);
	NORMAL = -normalize(cross(vec3(1, gx, 0), vec3(0, gz, 1)));
}
*/



void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = clamp(UV.y * 5.0, 0.0, 1.0);
	NORMAL = normal;
}
