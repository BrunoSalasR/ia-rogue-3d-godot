# IA ROGUE - Guia maestra del pipeline visual y tecnico

Este documento consolida TODO lo aprendido durante la iteracion del pipeline pixel-art 3D. Cualquiera que entre al proyecto debe leer esto primero. No reescribir shaders ni cambiar parametros clave sin entender lo que sigue.

---

## 1. Meta visual (no negociable)

Replicar el look de:
- t3ssel8r (canal YouTube)
- David Holland: https://www.davidhol.land/articles/3d-pixel-art-rendering/
- OddPotato Godot 3D Pixelart Starter Kit
- Foto de referencia principal del usuario: personaje pixel-art con capa marron, piedra gris, piso en diamante, sombra marcada.

Criterios de exito por frame:
1. Los pixeles de salida son **cuadrados y nitidos** (nearest-neighbor puro).
2. La iluminacion en superficies tiene **bandas cel duras**, no gradientes suaves.
3. Hay **silueta clara** del personaje (outline o contraste fuerte con fondo).
4. Hay **sombra proyectada** visible del personaje sobre el piso.
5. Composicion limpia: pocos elementos, buena legibilidad.

---

## 2. Pipeline de render (validado y estable)

```
Scene 3D → SubViewport 384x216 (nearest filter) → SubViewportContainer con upscale shader → Screen 1920x1080
```

### 2.1 SubViewport (en `scenes/main/main.tscn`)

Parametros que NO se pueden tocar sin romper el look pixel-art:

```
size = Vector2i(384, 216)
render_target_update_mode = 4 (always)
default_canvas_item_texture_filter = 0 (nearest)
msaa_3d = 0
use_taa = false
use_debanding = false
screen_space_aa = 0
positional_shadow_atlas_size = 2048
```

Cualquier filtro/AA/TAA suaviza pixeles y mata el look.

### 2.2 Upscaler (`assets/shaders/canvas_item/upscale_and_offset.gdshader`)

Shader pixel-perfect con:
- `snapped_uv` hard nearest sampling (NO sharp_sample con smoothing).
- `texel_offset` para subpixel compensation (recibe el error de snap de la camara).
- Posterizacion suave de color, film grain leve, vignette, contrast boost.

Uniforms importantes:
- `contrast_boost = 1.10`
- `vignette_strength = 0.22`
- `shadow_tint`, `highlight_tint` para color grading separado por luminancia.

### 2.3 Camara pixel-perfect (`scripts/camera/pixel_camera_rig.gd`)

Intro/test preset activo (validado para el look foto):
- `angle_x_deg = -35.0`
- `arm_distance = 11.0`
- `ortho_size = 3.4`
- `intro_test_view = true`

Implementa:
- Seguimiento suave con lerp + amortiguacion vertical.
- Snap a grilla de texel (`snappedf(pos.x, pixel_size)`).
- Compensacion subpixel via `texel_offset` al shader de upscale.

**Nunca forzar re-snap en `_process` de main.gd** (probado y rompe movimiento).

### 2.4 Iluminacion global (`scenes/main/main.tscn`)

```
WorldEnvironment:
  background_color = Color(0.05, 0.06, 0.09)
  ambient_light_energy = 0.55
  ambient_light_color = Color(0.24, 0.28, 0.34)
  glow_intensity = 0.08
  glow_bloom = 0.03
  fog_enabled = false  (el haze mata el contraste)

DirectionalLight3D:
  light_energy = 1.5
  shadow_enabled = true
  shadow_bias = 0.06
  shadow_normal_bias = 0.8
  shadow_opacity = 0.85
```

---

## 3. Shaders clave

### 3.1 `floor_pixel_checker.gdshader`

- Patron diamante (checker rotado 45°).
- `cell_size = 1.95`, `line_width = 0.03`, `pattern_rotation = 0.785`.
- Grain cuantizado al world grid (`pixel_grid_size = 0.08`) → pixel-art real, no noise rescalado.
- `light()` hace cel bands cuantizadas a 3 niveles con `lit_factor` topado a 0.62 para no blanquear los tiles iluminados.
- `shadow_darkness = 0.30` para que las zonas en sombra se lean oscuras.

### 3.2 `character_pixel_toon.gdshader`

- `render_mode unshaded`: calcula cel bands DIRECTO en fragment con `sun_dir` uniform.
- 3 bandas duras: `shade_color`, `base_color`, `highlight_color`.
- No depende de `light()` de Godot (evita sobre-exposicion en boxes).
- Se aplica a personaje + props importantes (roca, etc) para unificar lenguaje visual.

### 3.3 `outlines.gdshader`

- Screen-space edge detection por depth + normals.
- Tint por profundidad (`near_tint` / `far_tint`) para separar planos.
- `crease_feather = 0.06` para creases suaves.
- `line_alpha = 0.83` (silueta clara sin dominar).

---

## 4. Personaje (NullHero)

### 4.1 Estado actual (pass X en adelante)

Model: **`Adventurer.gltf`** de Kay Lousberg Ultimate Modular Women pack.
- Path: `assets/characters/placeholder/mc_adventurer/Adventurer.gltf`
- glTF self-contained (texture + bin + animations embedded).
- Animaciones incluidas: Idle, Run, Roll, Sword_Slash, etc.
- Scale runtime: 0.85.
- Orientation offset en `_orient_mesh`: 0 (Adventurer ya tiene face en +Z de default).
- Filter: `BaseMaterial3D.TEXTURE_FILTER_NEAREST` forzado en runtime via `_force_nearest_texture_filter`.

El NullHero con capsules/spheres (passes W) se abandono porque faltaba detalle anatomico real para acercarse a referencia t3ssel8r. El enfoque correcto es: **usar un modelo 3D low-poly con textura pixel-art bakeada** y NO sobreescribir sus materiales con shader cel monocromo.

Si necesitas volver a la forma digital (cubo), el `null_cube.tscn` sigue disponible para `start_form = "cube"`.

En runtime, el `character_pixel_toon` shader se aplica recursivamente a cada MeshInstance3D y extrae el color base del StandardMaterial3D original. Se preserva la paleta mientras se logra el look pixel-art.

Piezas actuales:
- Head (box), HairBack/Top/Fringe/LockL/LockR/Tuft, 2 Eyes (pixels).
- Neck, Torso, Collar (capa cuello), Belt.
- Cape: back + back_lower (tono oscuro) + front lateral + flaps L/R.
- Brazos: upper + fore + hand por lado. Brazo derecho levantado en pose contemplativa.
- Piernas: thigh (pants) + knee skin + boot tall (marron claro) + boot foot (marron oscuro).
- BlobShadow: QuadMesh 1.9x0.85 horizontal oscuro semi-transparente.

### 4.2 Limitacion actual (lo que el usuario pide corregir)

Box-based es legible pero lee MUY "cubico" cerca. La referencia tiene siluetas mas organicas. Plan:

### 4.3 Plan hacia meta visual (siguiente fase)

Fase A: boxes con paleta bakeada → lee pixel-art pero blocky. [HECHO]

Fase B: **reemplazar boxes por primitivas curvas** [HECHO - pass W]
- Cabeza y pelo dome → SphereMesh
- Mechones → SphereMesh pequeños rotados (no capsulas, mas claro en pixel-art)
- Cuello, torso, brazos, piernas → CapsuleMesh
- Hombros, rodillas, manos, pies → SphereMesh
- Cinturon, collar → CylinderMesh
- Capa (back, flaps) → PrismMesh (trapezoidal, mas organica que box)
- Ojos → SphereMesh minusculos
- Resultado: silueta organica, sombra cel se distribuye suavemente, listo para UV mapping.

Fase C: UV mapping preparado para **texturizar con pixel-art real** (pintar en Aseprite 128x128 por parte, aplicar nearest filter).

Fase D: Rig + animaciones procedurales/keyframed para idle, walk, dash, attack.

---

## 5. Mapa / escena (clean stage)

`scripts/world/proto_map_room.gd` con `clean_test_mode = true`:
- Un gran piso (180x180 unidades) con `floor_pixel_checker`.
- Invisible walls boundingbox.
- Una hero rock (6 piezas con `character_pixel_toon`, rotaciones no alineadas) como companion visual.
- 2 soft pillars distantes para romper horizonte.
- 2 spawn points de enemigos (lejos de la camara inicial).

Modo "legacy" (clutter completo) queda como fallback pero inactivo por defecto.

---

## 6. Comando CLI para iteracion visual

```
"C:\Users\bruni\OneDrive\Desktop\Apps\Godot 4.6.2\Godot_v4.6.2-stable_win64.exe" \
  --path "<ruta proyecto>" \
  --write-movie "debug-captures\art_passXX.png" \
  --fixed-fps 60 --quit-after 40 \
  -- --skip-intro
```

- `--skip-intro` evita la narrativa inicial.
- `--auto-demo` hace que el player se mueva solo (para validar animacion).
- Sin los dos, el player queda en pose inicial (ideal para capturas de referencia).

Output: PNGs `art_passXX00000039.png` (el ultimo frame estable).

---

## 7. Modelos 3D disponibles

### 7.1 Kay Lousberg - Ultimate Modular Women (GRATIS, ya descargado)

Path: `C:\Users\bruni\OneDrive\Desktop\Programming Brunich\Friends\3D models\Characters 3d model aniamtions\Ultimate Modular Women - April 2022-.../Individual Characters\glTF\`

Personajes disponibles:
- Adventurer, Casual, Formal, Medieval, Punk, SciFi, Soldier, Suit, Witch, Worker
- Cada uno ~3MB con geometria + animaciones (Idle, Run, Roll, Attack, etc) embebidas.

Evaluacion real:
- Son **low-poly 3D chibi style** (tipo Kenney).
- Al renderizarse a 384x216 con cel shader + outlines, se ven MUY decente pixel-art.
- Problema: proporciones chibi no matchean al 100% la referencia esbelta.
- Veredicto: utiles como enemigos / NPCs secundarios, no como MC principal.

### 7.2 OddPotato Godot 3D Pixelart Starter Kit (COMPRADO)

Path: `C:\Users\bruni\OneDrive\Desktop\Programming Brunich\Friends\PIXELART Shaders\`

No trae modelos 3D (solo base primitivos de Godot). Trae:
- cel_shader + cel_shader.gdshaderinc con ramps dithering
- foliage_cel_shader (para pasto)
- outline shader (screen-space depth/normals)
- upscale_and_offset (pixel-perfect camera shader)
- pixel_perfect_scaler.gd

Los shaders de este kit son esencialmente los mismos que tenemos en el proyecto (mismo autor probablemente). Migracion ya esta hecha.

Util extra a futuro: `foliage_cel_shader` + texture atlas 4-variantes de pasto para bioma "natural".

---

## 8. MCPs configurados (.cursor/mcp.json)

- `godot` (@coding-solo/godot-mcp): control del editor, run proyecto, captura output debug.
- `blender` (ahujasid/blender-mcp): modelar en Blender desde Cursor. **USAR CUANDO haga falta saltar a Fase B de modelado organico.**

---

## 9. Cosas que NO funcionaron (no volver a intentar)

1. **SubViewport a 320x180**: muy bajo, el personaje queda a <60 pixeles y se pierde detalle.
2. **`sharp_sample` smoothing en upscaler**: hace que los pixeles se vean suaves, pierde el look.
3. **`fog_enabled = true` con densidad media**: mata contraste en vista clean.
4. **Re-snap de camara cada frame en main.gd `_process`**: anula subpixel compensation, introduce jitter.
5. **StandardMaterial3D PBR en personaje**: genera gradientes que no leen pixel-art.
6. **`toon_light` del cel_shader aplicado al piso**: reemplaza el patron checker con el ramp color.
7. **`shadow_darkness = 0.55` con multiplicacion**: efecto sombra muy leve. Correcto: usar `mix(shade, lit, ATTENUATION)` direct.
8. **Augmentos mecanicos flotantes en MC humano**: ensucian la silueta. Solo aplicarlos a forma cubo/digital de Null, no al hero humanoide.

---

## 10. Plan de trabajo (roadmap actualizado)

### Hitos arte

- [x] Pass A-I: pipeline pixel-art fundamental (camara, upscale, cel shader).
- [x] Pass J-L: outline tuning + density + intro framing.
- [x] Pass M-P: grading + pose intro-test.
- [x] Pass Q-T: clean stage diamond floor + NullHero box-based.
- [x] Pass U: pixel-art real (nearest upscaler + unshaded toon + quantized floor).
- [x] Pass V: hero detallado con pelo, ojos, botas altas, pose contemplativa visible.
- [x] Pass W: mesh organico (capsules/spheres/prisms) → ya no se ve como cubos.
- [x] Pass W.1 (fix): head orientation correcta + cara con ojos/nariz/boca + 4 bandas cel.
- [x] Pass X (PIVOTE REAL): volver a `Adventurer.gltf` de Kay Lousberg.
      - Null hero custom con capsules era insuficiente (sin detalle anatomico real).
      - Adventurer tiene: sombrero, rostro, camisa, mochila, cinturon, shorts, rodillas, botas altas, todo con textures pixel-art bakeadas y animaciones built-in.
      - Orientacion: offset 0 en `_orient_mesh` (el Adventurer ya tiene cara en +Z).
      - Idle → cara a camara. W → espalda a camara.
      - `_force_nearest_texture_filter`: duplica materials del gltf y aplica NEAREST.
      - SubViewport bajado a `256x144` para pixels de salida mas grandes.
      - Upscale shader con posterizacion a 18 pasos por canal + saturation boost → paleta pixel-art discreta.
- [ ] Pass X: UV mapping preparado + textura pixel-art por parte.
- [ ] Pass Y: rig + animaciones keyframed para idle/walk/dash/attack.
- [ ] Pass Z: integrar blaster glitch negro/morado (pedido original).

### Hitos mecanicas (despues del arte)

- [ ] Movimiento + dash stable al 100%.
- [ ] Combate melee con feedback visual (hit flash, hit freeze).
- [ ] Hackeo + narrativa.
- [ ] Sistema de fragmentos persistente.
- [ ] Biomas / transiciones.

---

## 11. Comandos frecuentes

```
# Validar look estatico (pose inicial)
godot --write-movie debug-captures/artN.png --quit-after 40 -- --skip-intro

# Validar en movimiento (auto-demo)
godot --write-movie debug-captures/artN.avi --quit-after 240 -- --skip-intro --auto-demo

# Import assets nuevos (.gltf) - forzar import cache
godot --headless --editor  (matar despues de ~5s)
```

---

## 12. Archivos criticos

- `scenes/main/main.tscn` - escena root, SubViewport + HUD + shaders.
- `scenes/player/player.tscn` - player + hitboxes + forma inicial.
- `scripts/player/player.gd` - logica y aplicacion de shader al modelo.
- `scripts/world/proto_map_room.gd` - clean stage.
- `scripts/camera/pixel_camera_rig.gd` - camara pixel-perfect con intro_test preset.
- `scripts/main.gd` - spawn player + pose inicial contemplativa.
- `assets/shaders/spatial/character_pixel_toon.gdshader` - hero + roca.
- `assets/shaders/spatial/floor_pixel_checker.gdshader` - piso diamante.
- `assets/shaders/spatial/outlines.gdshader` - edge detection.
- `assets/shaders/canvas_item/upscale_and_offset.gdshader` - upscaler final.
- `assets/characters/placeholder/mc_hero/null_hero.tscn` - modelo MC actual.

---

## 13. Identidad del MC (Null)

Dualidad narrativa:
- **Forma cubo/digital**: glitch morado, silueta cubica, mecanica. (`null_cube.tscn`)
- **Forma humano/fisica**: aventurero con capa marron, pelo blanco, botas altas. (`null_hero.tscn`) [ACTIVA]

`start_form = "android"` en `player.tscn` activa la forma humana.

El switch entre formas se hace via `_apply_visual_form()` en `player.gd`. Se puede invocar durante dash o hackeo para efecto narrativo.

---

## 14. Referencia de parametros "golden"

Si algo se rompe visualmente, restaurar estos valores:

```
# scripts/camera/pixel_camera_rig.gd (intro_test_view)
angle_x_deg = -35.0
arm_distance = 11.0
ortho_size = 3.4

# scenes/main/main.tscn (Environment)
ambient_light_energy = 0.55
fog_enabled = false
DirectionalLight.light_energy = 1.5
shadow_bias = 0.06

# floor_pixel_checker shader params
cell_size = 1.95
contrast = 1.18
pattern_rotation = 0.7854
shadow_darkness = 0.30
pixel_grid_size = 0.08

# character_pixel_toon shader params
sun_dir = Vector3(-0.7, 0.7, 0.5)
# 4 bandas hard en fragment:
#   lit < 0.35 → shade_color
#   lit < 0.55 → mix(shade, base, 0.55)
#   lit < 0.78 → base_color
#   else       → highlight_color
# shade = base.darkened(0.58), highlight = base.lightened(0.22)
# Skip conversion si luma(base) < 0.18 (ojos, boca) o material transparente (blob shadow).

# upscale_and_offset
contrast_boost = 1.10
vignette_strength = 0.22
```

---

Fin.
