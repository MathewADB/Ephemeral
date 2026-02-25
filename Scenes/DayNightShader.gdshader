shader_type canvas_item;
uniform float night_factor;
uniform vec4 day_color;
uniform vec4 night_color;

void fragment() {
    vec4 color = mix(day_color, night_color, night_factor);
    COLOR = vec4(color.rgb, color.a * color.a); // use alpha for blending
}