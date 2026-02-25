# Agent Guidelines for GDShaderLib

This is a Godot 4.6 project with GDScript and custom shaders. It is a shader library plugin for Godot with terrain generation, compute shaders, and world building tools.

## Project Structure

```
gd-shader-lib/
├── addons/                    # Godot editor plugins
│   ├── gd_shader_lib/         # Main shader library plugin
│   │   ├── dock/              # Editor dock UI
│   │   ├── shaders/           # Shader library
│   │   └── builtin/           # Utility scripts
│   ├── good_old_scape/        # Terrain painting plugin
│   ├── compute_shader_plus/   # Compute shader utilities
│   └── NormalMap/             # Normal map generator
├── src/                       # Game/World source code
│   ├── Player/                # Player controller, state machine
│   ├── World/                 # World generation, terrain
│   ├── Environment/           # Environment objects
│   ├── VFX/                  # Visual effects
│   ├── UI/                   # UI components
│   └── Resources/Shader/      # Shader resources
├── TerrainBuildingTest/       # Terrain building demo/test project
│   ├── src/
│   │   ├── classes/           # Terrain classes (marching cubes, world manager)
│   │   ├── resources/         # Biome and foliage resources
│   │   └── builtin/           # Utility scripts
│   ├── DynamicTexture/        # Dynamic texture components
│   └── TEST/                  # Test scenes
├── NewGoodOldScape/          # New terrain system experiments
└── project.godot             # Godot project config
```

---

## Build, Lint, and Test Commands

### Running the Project

- **Open with Godot 4.6+**: Open `project.godot` in Godot Editor
- **Run in editor**: Press F5 or click the Play button

### Testing

- **No formal test framework** exists in this project
- To test code, run the project in Godot editor and interact with the scene
- For shader testing, use the shader preview in the inspector or run the game

### Linting

- **Godot Editor** provides built-in linting via the script editor
- Enable in: Editor Settings > Editor > External Editor > Show Warnings
- VSCode with `godotTools` extension provides additional linting

### Godot Version

- Target: **Godot 4.6** (configured in `project.godot`)
- Some compute shader features limited to versions <= 4.2 (see `compute_helper.gd`)

---

## Code Style Guidelines

### General Principles

- Use **type hints** on all functions and variables when possible
- Keep functions small and focused
- Use `const` for values that never change
- Use `@tool` for editor-only scripts

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `StateMachine`, `ComputeHelper` |
| Functions | snake_case | `get_height()`, `update_chunks()` |
| Variables | snake_case | `chunks`, `initial_state` |
| Constants | SCREAMING_SNAKE | `COLLISION`, `MAX_CHUNKS` |
| Signals | snake_case | `signal transitioned` |
| Enum values | PascalCase | `State.IDLE`, `Biome.OCEAN` |
| Enum names | PascalCase | `Temperature`, `Humidity` |
| File names | snake_case | `world_gen.gd`, `heightmap.gd` |
| Shader uniforms | snake_case | `albedo_texture_1`, `use_normal` |

### Annotations

```gdscript
@tool                          # Editor-only script
@export                        # Expose to inspector
@export_category("Name")       # Group inspector properties
@export_group("Name")          # Group inspector properties
@onready                       # Initialize after node ready
@rpc                           # Multiplayer remote calls
@static                        # Static method/variable
```

### Type Annotations

```gdscript
# Variable types
var image: Image
var chunks: Array = []
var uniform_set_dirty := true  # Infer type from right side

# Function signatures
func get_height(x: int, z: int) -> int:
func _ready() -> void:
static func create(shader_path: String) -> ComputeHelper:
```

### Imports and Preloads

```gdscript
# Preload scenes and resources
const COLLISION = preload("res://src/World/WorldGen/PlaneGen/collision_chunk.tscn")

# Load dynamically
var shader_file: RDShaderFile = load(shader_path)
```

### Control Flow

- Use early returns when possible
- Prefer `for` loops over `while` when iterating
- Use `match` (switch) for multiple conditions

```gdscript
if not image:
    push_error("Heightmap image is not set")
    return

# Good: match for multiple conditions
match state.name:
    "idle": pass
    "run": pass
```

### Error Handling

```gdscript
# Push error (fatal)
push_error("Heightmap image is not set")

# Push warning (non-fatal)
push_warning("Deprecated method used")

# Print for debugging
print("Created chunks: %d" % create.size())
print_rich("[color=green]Message[/color]")
```

### Comments

- Use `##` for documentation comments on functions
- Use `#` for inline comments explaining complex logic
- Comment out code with `#` (not removed)

```gdscript
## Returns the height at the given world position.
func get_height(x: int, z: int) -> int:
    if r_cache.is_empty():
        print("NO HEIGHT CACHE")
        return 0  # Return 0 if the cache is not initialized
```

### Class Definition Patterns

```gdscript
# Register as global class
class_name ComputeHelper
extends Object

# Enums (placed at class level)
enum Temperature {COLD, TEMPERATE, HOT}
enum Biome {OCEAN, TUNDRA, FOREST, DESERT}

# Inner classes
class MyInnerClass:
    pass
```

### Signals

```gdscript
# Define signal
signal transitioned(state_name)

# Emit signal
emit_signal("transitioned", state.name)

# Or shorthand
transitioned.emit(state.name)
```

### Shaders

#### Shader Files (`.gdshader`)

```glsl
shader_type spatial;

render_mode cull_disabled, depth_draw_opaque;

// Includes
#include "res://src/Resources/Shader/custom_light.gdshaderinc"

// Constants
#define TOP_BOTTOM_COLOR

// Uniforms with hints
uniform vec4 albedo : source_color = vec4(1.0f);
uniform sampler2D albedo_texture : hint_default_black;
uniform bool use_normal = false;
uniform int cuts : hint_range(1, 8) = 3;
```

#### Shader Includes (`.gdshaderinc`)

```glsl
// @name Basic
// @category Other
// @type Spatial
// @description Basic Operations needed wherever

vec3 hash33(vec3 p) {
    p = fract(p * 0.4567);
    return fract(p);
}
```

#### Common Shader Patterns

- `shader_type spatial` - For 3D materials
- `shader_type canvas_item` - For 2D materials
- `shader_type compute` - For compute shaders
- Use `varying` to pass data between vertex/fragment/light
- Use `instance` keyword for instance-specific data

### File Organization

- One class per file
- File name should match class name
- Group related files in directories
- Use Godot's folder color customization in `project.godot`

### Editor Configuration

- `.editorconfig` enforces UTF-8 charset
- Project uses Godot 4.6 with Mobile rendering tier
- Physics: Jolt Physics (3D)
- Default window: 1920x1080

### Common Patterns in This Codebase

1. **State Machine**: Nodes in `src/Player/StateMachine/` implement a State pattern
2. **World Generation**: Chunk-based system in `src/World/WorldGen/PlaneGen/`
3. **Compute Shaders**: Use `ComputeHelper` class from `addons/compute_shader_plus/`
4. **Editor Plugins**: Use `@tool` and `EditorPlugin` base class
5. **TerrainBuildingTest**: Separate demo project for terrain building with marching cubes (`src/classes/marching_cube_*.gd`), biome system (`biome_manager.gd`), and foliage resources
