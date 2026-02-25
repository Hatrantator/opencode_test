global uniform sampler2D ground_mask : hint_default_black, repeat_disable;//, filter_nearest;
global uniform float ground_mask_bw_threshold;
uniform bool use_greyscale = true;
uniform vec3 secondary_albedo: source_color = vec3(1.0,0.5,0.5);
uniform vec3 tertiary_albedo: source_color = vec3(0.5,1.0,0.5);
uniform vec3 quarternary_albedo: source_color = vec3(0.5,0.5,1.0);

vec3 get_top_albedo(float vertex_y, vec3 top_color, vec3 side_color) {
    if (abs(vertex_y - 0.5) < 0.01) {
        // Close enough to top face
        return top_color;
    } else {
        return side_color;
    }
}

vec3 get_albedo(vec3 world_vertex, vec3 color) {
    vec2 texture_position = (world_vertex.xz + 0.5)/float(textureSize(ground_mask,0).x * 2);
    if (use_greyscale){
        float mask = texture(ground_mask, texture_position).r;
        if (mask >= ground_mask_bw_threshold) {
            return color;
        } else {
            return secondary_albedo;
        }
    } else {
        vec3 rgb_mask = texture(ground_mask, texture_position).rgb;
        if (rgb_mask.r > rgb_mask.b && rgb_mask.r > rgb_mask.g) {
            return secondary_albedo;
        } else if (rgb_mask.g > rgb_mask.r && rgb_mask.g > rgb_mask.b) {
            return tertiary_albedo;
        } else if (rgb_mask.b > rgb_mask.r && rgb_mask.b > rgb_mask.g) {
            return quarternary_albedo;
        } else if (rgb_mask == vec3(0.0,0.0,0.0)) {
            return color;
        }
    }
	
}

float get_alpha(vec3 world_vertex, float alpha) {
    vec2 texture_position = (world_vertex.xz + 0.5)/float(textureSize(ground_mask,0).x * 2);
    float mask = texture(ground_mask, texture_position).r;
    //return alpha;
    if (mask <= ground_mask_bw_threshold) {
        return 0.0;
    } else {
        return alpha;
    }
}

