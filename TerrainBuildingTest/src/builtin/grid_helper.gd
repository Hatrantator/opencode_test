@tool
extends Object
class_name GridHelper

var grid_width: int
var grid_height: int
var grid_data: PackedFloat32Array
var tile_textures: Array[Texture2D]

## Example Call
#var grid := GridHelper.new()
#var biome_9x9 := grid.get_9x9_from_array(biomes_data, Vector2i(0,0), temperature_image.get_width(),temperature_image.get_height())
func get_9x9_from_array(center: Vector2i) -> Dictionary:
	var result := {}
	var offsets := [
		Vector2i( 0,  0), #center
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), #top row
		Vector2i(-1,  0),                  Vector2i(1,  0), #l/r
		Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1), #bot row
	]
	for offset in offsets:
		var pos :Vector2i = center + offset
		if pos.x < 0 or pos.y < 0 or pos.x >= grid_width or pos.y >= grid_height:
			result[pos] = null
			continue
		var idx := index_from_xy(pos.x, pos.y)
		result[pos] = grid_data[idx]
		#get_texture_for_cell(pos.x, pos.y)
	return result
	

func index_from_xy(x: int, y: int) -> int:
	return y * grid_width + x


##TODO: DualGridSystem
func get_neighbors(x: int, y: int) -> Dictionary:
	var center := int(grid_data[index_from_xy(x, y)])
	return {
		"c": center,
		"n": _get_cell(x, y - 1, center),
		"e": _get_cell(x + 1, y, center),
		"s": _get_cell(x, y + 1, center),
		"w": _get_cell(x - 1, y, center),
	}

func _get_cell(x: int, y: int, fallback: int) -> int:
	if x < 0 or y < 0 or x >= grid_width or y >= grid_height:
		return fallback
	return int(grid_data[index_from_xy(x, y)])

func get_neighbor_mask(x: int, y: int) -> int:
	var n := get_neighbors(x, y)
	var c = n["c"]
	var mask := 0
	if n["n"] == c: mask |= 1   # 0001
	if n["e"] == c: mask |= 2   # 0010
	if n["s"] == c: mask |= 4   # 0100
	if n["w"] == c: mask |= 8   # 1000
	return mask

func get_texture_for_cell(x: int, y: int) -> Texture2D:
	var mask := get_neighbor_mask(x, y)
	# 16 Varianten pro Biome (wie im TileSet)
	var biome_id := int(grid_data[index_from_xy(x, y)])
	var texture_index := biome_id * 16 + mask
	#print(texture_index)
	if texture_index < 0 or texture_index >= tile_textures.size():
		return null
	return tile_textures[texture_index]

func build_texture_array() -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	result.resize(grid_width * grid_height)

	for y in range(grid_height):
		for x in range(grid_width):
			result[index_from_xy(x, y)] = get_texture_for_cell(x, y)

	return result
