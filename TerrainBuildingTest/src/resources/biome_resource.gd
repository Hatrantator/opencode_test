@tool
extends Resource
class_name BiomeResource

#@export_enum("COLD","TEMPERATE","HOT") var Temperature = 1
#@export_enum("DRY","MEDIUM","WET") var Humidity = 1
@export_enum(
	"OCEAN",
	"TUNDRA",
	"TAIGA",
	"SNOWY_FOREST",
	"GRASSLAND",
	"FOREST",
	"RAINFOREST",
	"DESERT",
	"SAVANNA",
	"TROPICAL_RAINFOREST",
	"ALPINE",
	"SNOW",
	"GLACIER"
) var biome_category: int = 4
