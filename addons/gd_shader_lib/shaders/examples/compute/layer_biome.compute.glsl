#[compute]
#version 450
layout(local_size_x = 1, local_size_y = 1) in;
// Temperature
const int TEMP_COLD       = 0;
const int TEMP_TEMPERATE  = 1;
const int TEMP_HOT        = 2;
// Humidity
const int HUM_DRY     = 0;
const int HUM_MEDIUM  = 1;
const int HUM_WET     = 2;
// Biome colors (RGBA, linear)
const vec4 COLOR_OCEAN               = vec4(0.0, 0.25, 0.6, 1.0);
const vec4 COLOR_TUNDRA              = vec4(0.7, 0.8, 0.7, 1.0);
const vec4 COLOR_TAIGA               = vec4(0.3, 0.5, 0.3, 1.0);
const vec4 COLOR_SNOWY_FOREST        = vec4(0.8, 0.9, 0.9, 1.0);
const vec4 COLOR_GRASSLAND           = vec4(0.4, 0.7, 0.2, 1.0);
const vec4 COLOR_FOREST              = vec4(0.1, 0.5, 0.1, 1.0);
const vec4 COLOR_RAINFOREST          = vec4(0.0, 0.4, 0.2, 1.0);
const vec4 COLOR_DESERT              = vec4(0.9, 0.8, 0.4, 1.0);
const vec4 COLOR_SAVANNA             = vec4(0.7, 0.7, 0.3, 1.0);
const vec4 COLOR_TROPICAL_RAINFOREST = vec4(0.0, 0.6, 0.3, 1.0);
const vec4 COLOR_ALPINE              = vec4(0.5, 0.5, 0.5, 1.0);
const vec4 COLOR_SNOW                = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 COLOR_GLACIER             = vec4(0.85, 0.95, 1.0, 1.0);
// Biomes
const float BIOME_OCEAN                = 0;
const float BIOME_TUNDRA               = 1;
const float BIOME_TAIGA                = 2;
const float BIOME_SNOWY_FOREST         = 3;
const float BIOME_GRASSLAND            = 4;
const float BIOME_FOREST               = 5;
const float BIOME_RAINFOREST           = 6;
const float BIOME_DESERT               = 7;
const float BIOME_SAVANNA              = 8;
const float BIOME_TROPICAL_RAINFOREST  = 9;
const float BIOME_ALPINE               = 10;
const float BIOME_SNOW                 = 11;
const float BIOME_GLACIER              = 12;
//Struct
struct BiomesData {
	float biome;
};
// Uniforms
layout(set = 0, binding = 0, rgba8) uniform readonly image2D temperatureInTexture;
layout(set = 0, binding = 1, rgba8) uniform readonly image2D humidityInTexture;
layout(set = 0, binding = 2, rgba8) uniform readonly image2D heightInTexture;
layout(set = 0, binding = 3, rgba8) uniform readonly image2D biomeInTexture;
layout(set = 0, binding = 4, rgba32f) uniform writeonly restrict image2D biomeOutTexture;
layout(set = 0, binding = 5) writeonly buffer biomesBuffer {
	BiomesData[] data;
};

int get_temperature(float value) {
	if (value < 0.33) return TEMP_COLD;
	else if (value < 0.66) return TEMP_TEMPERATE;
	else return TEMP_HOT;
}
int get_humidity(float value) {
	if (value < 0.33) return HUM_DRY;
	else if (value < 0.66) return HUM_MEDIUM;
	else return HUM_WET;
}
vec4 get_biome_color(float temperature_value, float humidity_value, float altitude) {
	// Altitude overrides (early exit)
	if (altitude < 0.25) return COLOR_OCEAN;
	if (altitude > 0.9) return COLOR_GLACIER;
	if (altitude > 0.75) return COLOR_SNOW;
	if (altitude > 0.6) return COLOR_ALPINE;

	int temp = get_temperature(temperature_value);
	int hum  = get_humidity(humidity_value);

	// Temperature × Humidity matrix
	if (temp == TEMP_COLD) {
		if (hum == HUM_DRY) return COLOR_TUNDRA;
		else if (hum == HUM_MEDIUM) return COLOR_TAIGA;
		else return COLOR_SNOWY_FOREST;
	}
	else if (temp == TEMP_TEMPERATE) {
		if (hum == HUM_DRY) return COLOR_GRASSLAND;
		else if (hum == HUM_MEDIUM) return COLOR_FOREST;
		else return COLOR_RAINFOREST;
	}
	else {
		if (hum == HUM_DRY) return COLOR_DESERT;
		else if (hum == HUM_MEDIUM) return COLOR_SAVANNA;
		else return COLOR_TROPICAL_RAINFOREST;
	} //TEMP_HOT
}
float get_biome(float temperature_value, float humidity_value, float altitude) {
	// Altitude overrides (early exit)
	if (altitude < 0.25) return BIOME_OCEAN;
	if (altitude > 0.9) return BIOME_GLACIER;
	if (altitude > 0.75) return BIOME_SNOW;
	if (altitude > 0.6) return BIOME_ALPINE;

	int temp = get_temperature(temperature_value);
	int hum  = get_humidity(humidity_value);

	// Temperature × Humidity matrix
	if (temp == TEMP_COLD) {
		if (hum == HUM_DRY) return BIOME_TUNDRA;
		else if (hum == HUM_MEDIUM) return BIOME_TAIGA;
		else return BIOME_SNOWY_FOREST;
	}
	else if (temp == TEMP_TEMPERATE) {
		if (hum == HUM_DRY) return BIOME_GRASSLAND;
		else if (hum == HUM_MEDIUM) return BIOME_FOREST;
		else return BIOME_RAINFOREST;
	}
	else {
		if (hum == HUM_DRY) return BIOME_DESERT;
		else if (hum == HUM_MEDIUM) return BIOME_SAVANNA;
		else return BIOME_TROPICAL_RAINFOREST;
	} // TEMP_HOT 
}

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	float temperature = imageLoad(temperatureInTexture, uv).r; //reading Image
	float humidity = imageLoad(humidityInTexture, uv).r; //reading Image
	float height = imageLoad(heightInTexture, uv).r; //reading Image
	//imageStore(biomeOutTexture, uv, vec4(temperature, humidity, height, 1.0)); //writing Image
	vec4 biomeColor = get_biome_color(temperature, humidity, height);
	float biomeId = get_biome(temperature, humidity, height);
	imageStore(biomeOutTexture, uv, biomeColor); //writing Image

	int width = imageSize(biomeOutTexture).x;
	uint index = uint(uv.y * width + uv.x);
	data[index].biome = biomeId;
}
