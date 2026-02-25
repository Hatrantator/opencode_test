// @name Fresnel Modifier
// @category Fragment
// @type Spatial
// @description Returns Fresnel for 3D Objects either as ALBEDO or as EMISSION

//Fresnel Include for Fragments and Emission
uniform float fresnelAmount : hint_range(-2.0, 10.0) =  0.5;
uniform float fresnelStrength : hint_range(-2.0, 10.0) =  0.5;
uniform float fresnelBlend : hint_range(-1.0,1.0) = 1.0; // @deprecated
uniform vec4 fresnelColor : source_color = vec4(0.58,0.65,0.33,1.0);

float fresnel(float amount, vec3 normal, vec3 view) {
// @call float fresnelBasic = fresnel(fresnelAmount, NORMAL, VIEW);
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}
vec3 fresnelGlow(float amount, float strength, vec3 color, vec3 normal, vec3 view){
// @call vec3 fresnelEmission = fresnelGlow(fresnelAmount,fresnelStrength,fresnelColor.rgb, NORMAL, VIEW);
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * strength;
}

//TODO: this is for usage in a foliage shader
vec4 apply_fresnel_modifier(vec3 normal, vec3 viewDir, vec4 baseColor) {
    float fresnelFactor = pow(1.0 - abs(dot(normalize(normal), normalize(viewDir))), fresnelStrength);
    fresnelFactor = clamp(fresnelFactor * fresnelBlend, 0.0, 1.0);
    vec4 fresnelEffect = fresnelColor * fresnelFactor;
    return mix(baseColor, fresnelEffect, fresnelFactor);
}
vec3 emit_fresnel_color(vec3 normal, vec3 viewDir, vec3 baseColor) {
    float rateColor = clamp(baseColor.r, 0.0, 1.0);
    float fresnel = pow(1.0 - clamp(dot(normal, viewDir), 0.0, 1.0), 3.0);
    float fresnelRate = clamp(rateColor,0.1,1.0);
    vec3 fresColor = baseColor * (1.0 - fresnelStrength);
    fresColor += fresnelColor.rgb * fresnel * fresnelRate;
    return fresColor;
}