shader_type canvas_item;

// Controles desde el Inspector
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float curvature : hint_range(0.0, 10.0) = 2.0;
uniform float scanline_count : hint_range(0.0, 1080.0) = 300.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 1.2;
uniform float aberration_amount : hint_range(0.0, 0.1) = 0.002;

// --- APARTADO FULL SCREEN ---
// Esta función intercepta los vértices del ColorRect y los expande
// al tamaño completo del viewport actual del juego de forma obligatoria.
void vertex() {
    // Si el nodo está dentro de un CanvasLayer, esto estira los bordes
    // mapeando los vértices directo a las coordenadas de la pantalla (-1 a 1)
    VERTEX = (VERTEX * 2.0) - 1.0;
}

// Función para curvar las coordenadas UV y simular el tubo CRT
vec2 curve_uv(vec2 uv) {
    vec2 delta = uv - 0.5;
    float dist = dot(delta, delta);
    return uv + delta * dist * (curvature / 10.0);
}

void fragment() {
    // 1. Aplicar curvatura de pantalla
    vec2 curved_uv = curve_uv(SCREEN_UV);
    
    // Cortar los bordes negros si la curvatura se sale de la pantalla
    if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
        discard;
    }
    
    // 2. Aberración Cromática (Separación de color R y B)
    float r = texture(SCREEN_TEXTURE, vec2(curved_uv.x + aberration_amount, curved_uv.y)).r;
    float g = texture(SCREEN_TEXTURE, curved_uv).g;
    float b = texture(SCREEN_TEXTURE, vec2(curved_uv.x - aberration_amount, curved_uv.y)).b;
    vec4 text_color = vec4(r, g, b, 1.0);
    
    // 3. Scanlines (Líneas horizontales)
    float scanline = sin(curved_uv.y * scanline_count * PI * 2.0);
    scanline = (scanline + 1.0) / 2.0; // Normalizar entre 0 y 1
    scanline = mix(1.0, scanline, scanline_opacity);
    text_color.rgb *= scanline;
    
    // 4. Viñeta (Oscurecer las esquinas)
    vec2 vignette_uv = curved_uv * (1.0 - curved_uv.yx);
    float vignette = vignette_uv.x * vignette_uv.y * 15.0;
    vignette = clamp(pow(vignette, vignette_intensity), 0.0, 1.0);
    text_color.rgb *= vignette;
    
    COLOR = text_color;
}