shader_type canvas_item;

// Hintergrund im Carry-Queen-Stil: fast schwarze Platine mit Wabenraster,
// magentafarbenem Kern hinter der Scheibe und kaltem Schein hinter dem
// Bumper-Pad.  Alle Werte bleiben unter 1.0, damit der Glow-Filter nur die
// Neonlinien aufbluehen laesst und nicht den ganzen Tisch.

uniform vec2 rect_size = vec2(660.0, 960.0);
uniform vec3 base_color : source_color = vec3(0.018, 0.010, 0.032);
uniform vec3 hex_color : source_color = vec3(0.44, 0.11, 0.46);
uniform vec3 core_glow : source_color = vec3(0.30, 0.035, 0.28);
uniform vec3 top_glow : source_color = vec3(0.05, 0.15, 0.24);
uniform vec2 core_at = vec2(270.0, 640.0);
uniform vec2 top_at = vec2(270.0, 345.0);
uniform float hex_px = 34.0;

// Position im Tisch-Koordinatensystem.  Ueber VERTEX statt UV, damit der
// Shader unabhaengig davon funktioniert, an welchem Knotentyp er haengt.
varying vec2 field_pos;


void vertex() {
	field_pos = VERTEX;
}


// Liefert die Lage im Wabenraster: xy = Abstand zum Zellmittelpunkt,
// zw = Kennung der Zelle.
vec4 hex_cell(vec2 p) {
	vec2 s = vec2(1.0, 1.7320508);
	vec4 hC = floor(vec4(p, p - vec2(0.5, 1.0)) / s.xyxy) + 0.5;
	vec4 h = vec4(p - hC.xy * s, p - (hC.zw + vec2(0.5)) * s);
	vec4 res;
	if (dot(h.xy, h.xy) < dot(h.zw, h.zw)) {
		res = vec4(h.xy, hC.xy);
	} else {
		res = vec4(h.zw, hC.zw + vec2(0.5));
	}
	return res;
}


float hex_edge(vec2 p) {
	p = abs(p);
	return max(dot(p, vec2(0.5, 0.8660254)), p.x);
}


float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


void fragment() {
	vec2 px = field_pos;
	vec2 uv = px / rect_size;
	vec3 col = base_color;

	// Wabenraster mit einzelnen pulsierenden Zellen
	vec4 cell = hex_cell(px / hex_px);
	float edge = smoothstep(0.40, 0.50, hex_edge(cell.xy));
	float seed = hash21(cell.zw);
	float pulse = 0.5 + 0.5 * sin(TIME * 0.7 + seed * 24.0);
	col += hex_color * edge * (0.15 + 0.28 * pulse * step(0.70, seed));
	col += hex_color * 0.09 * step(0.92, seed) * (0.35 + 0.65 * pulse);

	// Magenta-Kern hinter der drehenden Scheibe.
	// Hinweis: smoothstep mit edge0 > edge1 ist in GLSL undefiniert und liefert
	// unter Vulkan 0 - deshalb immer aufsteigend rechnen und umkehren.
	float dc = length((px - core_at) / vec2(370.0, 340.0));
	col += core_glow * (1.0 - smoothstep(0.0, 1.0, dc));

	// kalter Schein hinter dem Bumper-Pad
	float dt = length((px - top_at) / vec2(260.0, 240.0));
	col += top_glow * (1.0 - smoothstep(0.0, 1.0, dt)) * 0.75;

	// feine Zeilenstruktur wie auf einem Stream
	col += vec3(0.09, 0.02, 0.13) * 0.05 * step(0.5, fract(px.y / 4.0));

	// Vignette
	float v = length((uv - vec2(0.5)) * vec2(1.15, 1.0));
	col *= mix(1.0, 0.45, smoothstep(0.34, 0.95, v));

	COLOR = vec4(col, 1.0);
}
