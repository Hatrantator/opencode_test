class_name WeatherSimulator
extends Node


@export var debug = false
@export var debug_speed = 0.0

## Weather parameters:
@export var forecast_texture: Texture2D# Texture to display the weather forecast
var forecast_progress: int = 0
# wind parameters
@export var weather_wind_speed: float = 0.02
@export var weather_wind_direction: Vector2 = Vector2(0.5, 0.5) # Direction in which the wind is blowing
# rain parameters
@export_range(0.0,1.0) var rain_amount: float = 0.0
@export var cloud_intensity: float = 0.25 # in percentage (0-1)
# Sun parameters
@export var sun_directional_light: DirectionalLight3D
@export var sun_intensity: float = 0.5 # in percentage (0-1)
@export var sun_max_intensity: float = 0.45 # in percentage (0-1)
@export var godray_color_day: Color = Color(1.0, 0.9, 0.6) # Warm color for daytime
@export var godray_color_night: Color = Color(0.5, 0.5, 0.5) # Cool color for nighttime
@export var godray_amount: float = 0.5 # Amount of godrays to cast

## Time parameters
@export var day_length: float = 480.0 # Length of a full day/night cycle in seconds
var time_of_day: float = 0.0 # 0.0 = midnight, 0.5 = noon, 1.0 = next midnight
@export var weather_change_interval: float = 120.0 # in seconds
@export var weather_change_duration: float = 10.0 # in seconds

## Helper
var rng = RandomNumberGenerator.new()
var shader_params: Dictionary = {}

func _ready() -> void:
	if debug:
		log_debug("Weather Simulator is ready!")
		day_length = day_length / debug_speed
		weather_change_interval = weather_change_interval / debug_speed

	if not sun_directional_light:
		log_debug("Sun directional light is not assigned!")

	update_forecast()
	#cast_storm(weather_change_interval, 0.85) # Start with a storm
#	cast_rain(true) # Start raining at the beginning
#	set_global_shader_param("cloud_intensity", cloud_intensity, 2.0)
#	set_global_shader_param("weather_wind_direction", Vector2(-1.0,-1.0), 8.0)


func _process(delta: float) -> void:
	# Update the time of day
	time_of_day += delta / day_length
	if time_of_day > 1.0:
		time_of_day -= 1.0 # Loop back to the start of the cycle
	%DayProgressBar.value = time_of_day

	var godray_color = godray_color_night.lerp(godray_color_day, abs(sin(time_of_day * PI)))
	
	# Calculate light intensity: peaks at 0.5, 0.0 at 0.0 and 1.0
	var light_intensity = max(0.0, sin(time_of_day * PI))

	# Calculate godray amount: peaks at 0.25 and 0.75, 0.0 at 0.0 and 0.5
	godray_amount = max(0.0, cos((time_of_day-.175) * 2.0 * PI * 2.0))
	var cloud_sun_diff: float
	if cloud_intensity < 0.95: cloud_sun_diff = cloud_intensity * godray_amount
	else: cloud_sun_diff = 1.0
	godray_amount = max(0.0, godray_amount - cloud_sun_diff)

	# Calculate the sun's rotation based on the time of day
	var godray_rotation_z = clamp(lerp(-90.0, 90.0, time_of_day), -40.0, 40.0)


	get_tree().call_group("SUN", "set_material_rotation", godray_rotation_z)
	get_tree().call_group('SUN', "set_color", godray_color)
	cast_godrays(godray_amount) # Godrays are more intense during the day
	sun_directional_light.light_energy = light_intensity * 0.45
	
	# Update the UI
	%SunProgressBar.value = sun_directional_light.light_energy
	%RayProgressBar.value = godray_amount
	%CloudProgressBar.value = cloud_intensity

func update_forecast() -> void:
	await get_tree().create_timer(0.1).timeout # Wait for the scene to load
	if not forecast_texture:
		log_debug("Forecast texture is not assigned!")
		return

	# Get the texture as an image
	await get_tree().process_frame
	var image = forecast_texture.get_image()

	# Read a pixel on the X-axis based on a normalized weather condition
	var x = int(forecast_progress * image.get_width() % image.get_width())
	var pixel_color = image.get_pixel(x, 0) # Read the pixel at (x, 0)

	log_debug("Forecast color at X=%d: %s" % [x, str(pixel_color)])
	rng.seed = hash(pixel_color.r)
	rng.randomize()
	pixel_color.r += rng.randf_range(-0.15,0.15)
	rng.seed = hash(pixel_color.g)
	rng.randomize()
	pixel_color.g += rng.randf_range(-0.15,0.15)
	rng.seed = hash(pixel_color.b)
	rng.randomize()
	pixel_color.b += rng.randf_range(-0.15,0.15)
	change_weather(pixel_color.r, pixel_color.g, pixel_color.b)

	# Log or use the pixel color
	#apply_forecast_color(pixel_color)

	# Schedule the next update
	forecast_progress += 1
	await get_tree().create_timer(weather_change_interval).timeout
	update_forecast()


# (r)ain, (g)louds, (b)reeze
func change_weather(r: float, g: float, b: float) -> void:
	log_debug("Changing weather: R: %s, G: %s, B: %s" % [r, g, b])

	if g >= 0.8 && b >= 0.8:
		# If the clouds are too dense, cast a storm
		cast_storm(weather_change_interval, g)
		return

	## Randomly change weather parameters


	rng.seed = hash(r)
	rng.randomize()
	var rain_chance = rng.randf_range(0.0, 1.0)

	cloud_intensity = g
	# rain only occurs if the cloud intensity is high enough
	if r > rain_chance && cloud_intensity > 0.35:
		cast_rain(true, cloud_intensity)
	
	#godray_amount -= cloud_sun_diff
	#cast_godrays(godray_amount) # Godrays are more intense when clouds are less dense

	# randomizing the breeze
	rng.seed = hash(b)
	rng.randomize()

	weather_wind_speed = clamp((weather_wind_speed+rng.randf_range(-0.03, 0.03)), 0.0, 0.1)

	if shader_params.has("weather_wind_direction"):
		weather_wind_direction = shader_params["weather_wind_direction"].rotated(rng.randf_range(-PI/8, PI/8))

	# set global shader parameters
	set_global_shader_param("cloud_intensity", cloud_intensity, weather_change_duration)
	set_global_shader_param("weather_wind_speed", weather_wind_speed, weather_change_duration)
	set_global_shader_param("weather_wind_direction", weather_wind_direction, weather_change_duration * 0.5)


	log_debug("Weather changed: Wind Speed: %s, Wind Direction: %s, Rain Chance: %s Cloud Intensity: %s" % [weather_wind_speed, weather_wind_direction, rain_chance, cloud_intensity])


func cast_storm(duration: float = weather_change_interval, intensity: float = 0.85) -> void:
	rng.seed = hash(forecast_progress)
	rng.randomize()
	# Set the weather to stormy conditions
	weather_wind_speed = rng.randf_range(0.08, 0.12)

	rain_amount = rng.randf_range(0.0, 1.0)
	cast_rain(true, rain_amount)
	cast_godrays(0.0) # Disable godrays during storm

	# Set global weather shader parameters for stormy weather
	set_global_shader_param("cloud_intensity", intensity, weather_change_duration)
	set_global_shader_param("weather_wind_speed", weather_wind_speed, weather_change_duration)
	set_global_shader_param("weather_wind_direction", weather_wind_direction)

	log_debug("Stormy weather: Wind Speed: %s, Wind Direction: %s, Rain Amount: %s" % [weather_wind_speed, weather_wind_direction, rain_amount])


	await get_tree().create_timer(duration).timeout
	update_forecast()


func cast_rain(_rain: bool, amount: float = 1.0) -> void:
	await get_tree().create_timer(0.1).timeout # Wait for the scene to load
	get_tree().call_group("RAIN", "set_emitting", _rain)
	get_tree().call_group("RAIN", "set_amount_ratio", amount)


func cast_godrays(amount: float = 1.0, height_offset_x: float = -90.0) -> void:
	get_tree().call_group("SUN", "set_amount_ratio", amount)
	#get_tree().call_group("SUN", "set_height_offset", height_offset_x)


func set_global_shader_param(param: String, value: Variant, time: float = 0.0) -> void:
	if not shader_params.has(param):
		shader_params[param] = ProjectSettings.get_setting("shader_globals/"+param).value

	if time > 0.0:
		var tween = get_tree().create_tween()
		var current_value = shader_params[param]
		log_debug("Current value: %s" % str(current_value))
		tween.tween_method(_shader_param_interpolator.bind(param), current_value, value, time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	else:
		RenderingServer.global_shader_parameter_set(param, value)
	shader_params[param] = value


func _shader_param_interpolator(value: Variant, param: String = "") -> void:
	RenderingServer.global_shader_parameter_set(param, value)


func log_debug(message: String, custom_name: String = "") -> void:
	if debug:
		var timestamp = Time.get_datetime_string_from_system()
		var log_name = custom_name if custom_name != "" else self.name
		var entry = "%s|%s|%s" % [log_name, timestamp, message]
		print(entry)
