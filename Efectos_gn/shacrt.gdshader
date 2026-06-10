shader_type canvas_item;
render_mode unshaded; // Evita que las luces 2D del juego alteren el filtro

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(0.0, 1.0) = 0.1;
uniform float scanline_count : hint_range(10.0, 1080.0) = 300.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

// Función para curvar las coordenadas UV (Efecto de tubo CRT)
vec2 distort(vec2 uv) {
    vec2 delta = uv - 0.5;
    float delta2 = dot(delta, delta);
    float delta4 = delta2 * delta2;
    float delta_offset = delta2 * curvature + delta4 * (curvature * 0.5);
    return 0.5 + delta * (1.0 + delta_offset);
}

void fragment() {
    // 1. Aplicar distorsión de lente
    vec2 distorted_uv = distort(SCREEN_UV);
    
    // Cortar los píxeles que se salen de la pantalla curva usando un bloque estructural
    if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Bordes negros fuera del tubo CRT
    } else {
        // 2. Aberración Cromática (Separación de color RGB)
        vec2 shift = vec2(0.002, 0.0);
        float r = texture(SCREEN_TEXTURE, distorted_uv - shift).r;
        float g = texture(SCREEN_TEXTURE, distorted_uv).g;
        float b = texture(SCREEN_TEXTURE, distorted_uv + shift).b;
        vec3 color = vec3(r, g, b);
        
        // 3. Líneas de escaneo (Scanlines)
        float scanline = sin(distorted_uv.y * scanline_count * PI * 2.0);
        scanline = (scanline + 1.0) * 0.5; // Normalizar entre 0 y 1
        scanline = mix(1.0, scanline, scanline_opacity);
        color *= scanline;
        
        // 4. Viñeta (Oscurecer las esquinas)
        vec2 vignette_uv = distorted_uv * (1.0 - distorted_uv.yx);
        float vignette = vignette_uv.x * vignette_uv.y * 15.0;
        vignette = clamp(pow(vignette, vignette_opacity), 0.0, 1.0);
        color *= vignette;
        
        COLOR = vec4(color, 1.0);
    }
}
