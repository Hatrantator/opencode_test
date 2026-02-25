
// Global uniforms for cloud shadows
global uniform float we_wind_speed; // Speed of cloud scrolling and Vertex wind
global uniform vec2 we_wind_direction; // Direction of the wind
global uniform sampler2D we_cloud_map : hint_default_black, repeat_enable;
global uniform float cloud_intensity; // Intensity of the cloud shadows

uniform vec2 smoothed_wind_direction = vec2(0.0, 0.0);
uniform float smoothed_wind_speed = 0.5;
// Add a smoothing factor (lower values = smoother transitions)
const float SMOOTHING_FACTOR = 0.1;

vec2 get_wind_uv_vertex(vec2 node_pos_worldxy, vec2 uv) {
    vec2 wind_uv = vec2(sin(node_pos_worldxy.x + TIME * 1.25 + uv.y) * ( 1.0 - uv.y) * (weather_wind_speed * 3.0), cos(node_pos_worldxy.y + TIME * 0.45 + uv.y) * ( 1.0 - uv.y) * (weather_wind_speed * 3.0 - 0.05));
    return wind_uv;
}


vec2 get_smoothed_wind_direction(vec2 current_direction) {
    // Smoothly interpolate the wind direction
    return mix(smoothed_wind_direction, current_direction, SMOOTHING_FACTOR);
}

float get_smoothed_wind_speed(float current_speed) {
    // Smoothly interpolate the wind speed
    return mix(smoothed_wind_speed, current_speed, SMOOTHING_FACTOR);
}

// Returns the texture value for a given world position in a 2D texture map + movement
float get_cloud_fragment_grid_map(vec3 world_vertex) {
//Calculate world_vertex like this to get the correct position in the world
//vec3 world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
//vec2 node_pos_worldxy = NODE_POSITION_WORLD.xz;
	vec2 texture_position = (world_vertex.xz)/float(textureSize(cloud_texture,0).x) + 0.5;
    vec2 scroll_movement_wind = weather_wind_direction * weather_wind_speed * TIME * 0.1;

    // Smooth the wind direction and speed
    vec2 smooth_direction = get_smoothed_wind_direction(weather_wind_direction);
    float smooth_speed = get_smoothed_wind_speed(weather_wind_speed);

    // Calculate the scrolling movement based on smoothed values
    vec2 scroll_movement = smooth_direction * smooth_speed * TIME * 0.1;

    float cloud_fragment = texture(cloud_texture, texture_position + scroll_movement_wind).r;
    return cloud_fragment;
}