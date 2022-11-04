#version 450
#include "/defines.glsl"

layout (isolines, equal_spacing) in;

in tessVsData {
	float pointImportance;
} tessOut[];

out vsData {
	float pointImportance;
	vec2 prev;
	vec2 next;
	vec4 left;
	vec4 right;
} vsOut;

patch in vec4 pp0;
patch in vec4 pp3;
patch in int totalPoints;
patch in float imp_p0;
patch in float imp_p3;
patch in float t_value;


// Magic lens
uniform float lineWidth;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 inverseModelViewProjectionMatrix;

uniform vec2 delayedLensPosition;
uniform float actionStart;
uniform float actionEnd;
uniform float time;
uniform vec2 viewportSize;


// Ease in quad from defines.glsl, used in disp()
float easeInOut(float t) {
	if(t < 0.5f){
		return 2*t*t; 
	}else{
		return -1+(4-2*t)*t;
	}
};


#include "/lens.glsl"


// Catmull rom, (TODO currently not used)
vec4 catmull(vec4 p0, vec4 p1, vec4 p2, vec4 p3, float u ){

	float alpha = 1.0;
    float tension = 0.0;
    
    float t01 = pow(distance(p0, p1), alpha);
	float t12 = pow(distance(p1, p2), alpha);
	float t23 = pow(distance(p2, p3), alpha);

	vec2 m1 = (1.0f - tension) *
    	(p2.xy - p1.xy + t12 * ((p1.xy - p0.xy) / t01 - (p2.xy - p0.xy) / (t01 + t12)));
	vec2 m2 = (1.0f - tension) *
    	(p2.xy - p1.xy + t12 * ((p3.xy - p2.xy) / t23 - (p3.xy - p1.xy) / (t12 + t23)));
    
	vec2 a = 2.0f * (p1.xy - p2.xy) + m1 + m2;
	vec2 b = -3.0f * (p1.xy - p2.xy)  - m1 - m1 - m2;
	vec2 c = m1;
	vec2 d = p1.xy;

	vec2 new_pos =  (a * u * u * u) + (b * u * u) + (c * u) + (d);

	return vec4(new_pos, 0, 1);

}

// Constructs the left and right vertex of current position based on prev and next
void constructLeftRightVertex(vec4 prev_pos, vec4 pos, vec4 next_pos){
	float fragmentLineWidth = length(modelViewProjectionMatrix*vec4(0.0f, 0.0f, 0.0f, 1.0f) - modelViewProjectionMatrix*(vec4(lineWidth, 0.0f, 0.0f, 1.0f)));
		
	float aspectRatio = viewportSize.x/viewportSize.y;
	fragmentLineWidth *= aspectRatio;	

	vec2 v0 = normalize( pos.xy - prev_pos.xy);
	vec2 v1 = normalize( next_pos.xy - pos.xy);

	vec2 n0 = vec2( -v0.y, v0.x);
	vec2 n1 = vec2( -v1.y, v1.x);

	vec2 miter_a = normalize(n0 + n1);

	float an1 = dot(miter_a, n1);
	if(an1==0) an1 = 1;
	float length_a = (fragmentLineWidth*0.25) / an1;

	vec4 left = vec4( (pos.xy + length_a * miter_a ), 0, 1);
	vec4 right = vec4( (pos.xy - length_a * miter_a ), 0, 1);

	vsOut.left = left;
	vsOut.right = right;
}




void main(){
	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;

	vec4 p0 = pp0;
	vec4 p1 = gl_in[0].gl_Position;
	vec4 p2 = gl_in[1].gl_Position;
	vec4 p3 = pp3;



	// du: delimiter, t0, t1, t2 (previous, current, next) t-values 
	int vertexIndex = int(round(u * totalPoints)); 
	float du = 1.0f/totalPoints;
	float t0 = u-du;
	float t1 = u;
	float t2 = u+du;

	// Importance is interpolated

	float imp_p1 = tessOut[0].pointImportance;
	float imp_p2 = tessOut[1].pointImportance;

	float vertexImportance = mix(imp_p1, imp_p2, t1);
	vsOut.pointImportance = vertexImportance;


	vec4 prev_pos, pos, next_pos;
	float prev_imp, next_imp;

	// Handle edge cases where points are the same
	if(p0 == p1) p0 += vec4(0.000001f, 0, 0 ,0);
	if(p2 == p3) p3 += vec4(0.000001f, 0, 0 ,0);

	// Current Position
	pos = mix(p1, p2, t1);

	// Edge cases when a patch ends and starts 
	if(vertexIndex == 0){
		prev_pos = mix(p0, p1, 1.0f - du);
		prev_imp = mix(imp_p0, imp_p1, 1.0f - du);  

		next_pos = mix(p1, p2, t2);
		next_imp = mix(imp_p1, imp_p2, t2);

	} else if (vertexIndex == totalPoints){
		prev_pos = mix(p1, p2, t0);
		prev_imp = mix(imp_p1, imp_p2, t0);

		next_pos = mix(p2, p3, 0.0f + du);
		next_imp = mix(imp_p2, imp_p3, 0.0f + du);

	} else {
		prev_pos = mix(p1, p2, t0);
		prev_imp = mix(imp_p1, imp_p2, t0);

		next_pos = mix(p1, p2, t2);
		next_imp = mix(imp_p1, imp_p2, t2);
	}

	// Displacments 
	pos = displace(pos, vertexImportance);
	prev_pos = displace(prev_pos, prev_imp);
	next_pos = displace(next_pos, next_imp);

	vsOut.prev = prev_pos.xy;
	vsOut.next = next_pos.xy;

	constructLeftRightVertex(prev_pos, pos, next_pos);

	gl_Position = pos;
}