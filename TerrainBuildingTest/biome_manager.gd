extends Node

enum Temperature {COLD,TEMPERATE,HOT}
enum Humidity {DRY,MEDIUM,WET}
enum Biome {
	OCEAN,
	TUNDRA,
	TAIGA,
	SNOWY_FOREST,
	GRASSLAND,
	FOREST,
	RAINFOREST,
	DESERT,
	SAVANNA,
	TROPICAL_RAINFOREST,
	ALPINE,
	SNOW,
	GLACIER
}

func get_temperature(value: float) -> Temperature:
	if value < 0.33: return Temperature.COLD
	elif value < 0.66: return Temperature.TEMPERATE
	else: return Temperature.HOT
func get_humidity(value: float) -> Humidity:
	if value < 0.33: return Humidity.DRY
	elif value < 0.66: return Humidity.MEDIUM
	else: return Humidity.WET

func get_biome(temperature_value: float, humidity_value: float, altitude: float) -> Biome:
	# Altitude overrides
	if altitude < 0.25: return Biome.OCEAN
	if altitude > 0.9: return Biome.GLACIER
	if altitude > 0.75: return Biome.SNOW
	if altitude > 0.6: return Biome.ALPINE

	var temp: Temperature = get_temperature(temperature_value)
	var hum: Humidity = get_humidity(humidity_value)
	match temp:
		Temperature.COLD:
			match hum:
				Humidity.DRY: return Biome.TUNDRA
				Humidity.MEDIUM: return Biome.TAIGA
				Humidity.WET: return Biome.SNOWY_FOREST
		Temperature.TEMPERATE:
			match hum:
				Humidity.DRY: return Biome.GRASSLAND
				Humidity.MEDIUM: return Biome.FOREST
				Humidity.WET: return Biome.RAINFOREST
		Temperature.HOT:
			match hum:
				Humidity.DRY: return Biome.DESERT
				Humidity.MEDIUM: return Biome.SAVANNA
				Humidity.WET: return Biome.TROPICAL_RAINFOREST
	return Biome.GRASSLAND # Fallback (should never happen)
