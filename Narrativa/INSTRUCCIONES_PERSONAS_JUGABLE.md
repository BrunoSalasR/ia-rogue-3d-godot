# IA ROGUE - Guia para hacer la beta jugable (personas)

Este documento explica, en orden, que debe hacer el equipo para dejar una beta funcional enfocada en jugabilidad:

- Movimiento estilo Hades/Hyper Light Drifter
- Combate melee + dash + hackeo funcionando sin romperse
- Modelos 3D beta visibles y legibles (aunque sean placeholder)

No se enfoca en arte final. Se enfoca en que "ya se pueda jugar bien".

---

## 1) Objetivo de la beta (definicion clara)

La beta se considera lista cuando cualquier persona puede abrir el proyecto, iniciar una partida y completar una sala de combate con este flujo:

1. Moverse (WASD)
2. Hacer dash encadenado (Space)
3. Atacar (Click izquierdo)
4. Hackear un enemigo (E) y ver secuencia narrativa
5. Matar enemigos y sumar fragmentos
6. Morir y reiniciar run sin errores

Si esto no se cumple de forma estable, no pasar a polish.

---

## 2) Estado actual (auditoria resumida)

Lo importante ya existe:

- `project.godot`: inputs configurados (WASD, dash, attack, hackeo, interact)
- `scripts/player/player.gd`: movimiento rapido, dash 3 cargas, melee arco 130, hackeo
- `scripts/enemies/base_enemy.gd`: IA basica (idle/chase/attack/hacked/dead)
- `scripts/enemies/regulated_enemy.gd`: secuencia de hackeo conectada con narrativa
- `scripts/ui/hud.gd`: HP, ciclos, dash charges, fragmentos y caja narrativa con pausa
- `scenes/world/test_room.tscn`: sala cerrada con paredes y obstaculos
- `scenes/main/main.tscn`: pipeline SubViewport + outline ya montado

Punto critico detectado:

- El `SubViewport` ya se fijo en `320x180` para el look pixel-art 3D.

---

## 3) Orden de trabajo recomendado (no cambiar orden)

## Paso 1 - Congelar una baseline jugable

1. Abrir `scenes/main/main.tscn`.
2. Cambiar `SVContainer/SubViewport -> size` a `Vector2i(320, 180)`.
3. Ejecutar escena principal y validar:
   - Player se mueve y dasha.
   - Enemigos persiguen.
   - HUD actualiza barras.
4. Si algo se rompe, arreglar antes de seguir.

Criterio de salida: el juego corre estable en baja resolucion interna.

## Paso 2 - Asegurar "game feel" de movimiento

Archivo: `scripts/player/player.gd`

Validar estos valores base (si ya estan, no tocar):

- `speed = 9.0`
- `dash_speed = 34.0`
- `dash_duration = 0.10`
- `max_dash_charges = 3`
- `dash_recharge_time = 0.70`
- `dash_min_interval = 0.06`

Playtest corto (5 minutos):

- Se puede esquivar con dash sin quedarse pegado.
- Se pueden encadenar 2-3 dashes.
- El melee no se siente lento.

Si se siente pesado, primero ajustar `acceleration` y `friction`, no tocar todo a la vez.

## Paso 3 - Validar loop de combate minimo

Archivos:

- `scripts/enemies/base_enemy.gd`
- `scripts/enemies/regulated_enemy.gd`
- `scripts/main.gd`

Checklist:

1. Enemigo detecta al player en rango.
2. Enemigo entra a chase y ataca.
3. Player puede matar enemigo con melee.
4. Hackeo consume ciclos y dispara narrativa.
5. Enemigo hackeado se auto-termina.
6. `GameManager` suma fragmentos al morir enemigos.

Si falla cualquiera de esos puntos, no avanzar a modelos.

## Paso 4 - Reemplazar placeholders por modelos 3D beta

Objetivo: legibilidad en combate, no belleza final.

Carpetas destino:

- `assets/characters/placeholder/`
- `assets/world/`

Accion:

1. Importar dos variantes del MC (GLB):
   - `mc_cube.glb` (forma digital inicial)
   - `mc_android.glb` (forma de materializacion)
2. Importar 1 modelo de enemigo regulado (GLB) distinto al MC.
3. Reemplazar `MeshInstance3D` caja en:
   - `scenes/player/player.tscn`
   - `scenes/enemies/regulated_enemy.tscn`
4. Mantener colisiones actuales (`CharacterBody3D + CollisionShape3D`).

Regla: cambiar visual sin romper hitbox ni scripts.
Regla de hitbox: coherencia con silueta legible en ortografica, no precision absoluta al mesh.

### Estructura recomendada de assets

```
assets/
└── characters/
    └── placeholder/
        ├── mc_cube/
        │   ├── mc_cube.glb
        │   └── anim/ (idle, run, dash, attack, death)
        ├── mc_android/
        │   ├── mc_android.glb
        │   └── anim/ (idle, run, dash, attack, death)
        └── enemy_regulated/
            ├── enemy_regulated.glb
            └── anim/ (idle, run, attack, death)
```

### Animaciones minimas obligatorias

- MC cubo: `idle`, `run`, `dash`, `attack`, `death`
- MC androide: `idle`, `run`, `dash`, `attack`, `death`
- Enemigo regulado: `idle`, `run`, `attack`, `death`

Prioridad de calidad: primero fluidez y legibilidad de cubo, luego androide.

## Paso 5 - Aplicar materiales/shader base para lectura

1. Crear 2 ramp textures minimas:
   - MC ramp (oscura + acento cian)
   - Enemy ramp (cian institucional + blanco)
2. Asignar `cel_shader.gdshader` a mesh del MC y enemigos.
3. Verificar que `OutlineEffect` ya se vea en runtime.

Si no hay tiempo, usar materiales simples de color plano, pero siempre mantener outline activo.

### Calidad visual objetivo (referencias oficiales)

Meta visual de este proyecto:

- [Odd Potato - Godot 3D Pixelart Starter Kit](https://oddpotatodev.itch.io/godot-3d-pixelart-starter-kit)
- [David Holland - 3D Pixel Art Rendering](https://www.davidhol.land/articles/3d-pixel-art-rendering/)

Reglas obligatorias para acercarse a ese look:

1. **Camara + viewport pixel-perfect**
   - SubViewport bajo (`320x180` o `426x240`)
   - Camara ortografica
   - Snap a grilla de texel + compensacion UV (upscale shader)
2. **Outline estable y fino**
   - Kernel cardinal (arriba/abajo/izq/der) para linea 1-pixel
   - Depth para silueta + normals para creases
3. **Lighting toon limpio**
   - Ramp texture como base de color real (no blanco puro en `ALBEDO`)
   - `steepness` alto para bandas limpias
   - `light_wrap` moderado para suavizar terminador
4. **Mallas low/mid poly legibles**
   - Siluetas claras y piezas grandes
   - Evitar detalles micro que se pierden en 320x180

### Descubrimientos tecnicos importantes (ya validados)

- Los modelos `Soldier.gltf` y `SciFi.gltf` SI traen clips utiles (`Idle`, `Run`, `Roll`, `Sword_Slash`, etc.).
- Algunos kits `.gltf` requieren `.bin` externos: si faltan, Godot no importa la escena.
- `preload("*.gltf")` puede fallar durante parse si el import aun no existe; para assets grandes conviene `load()` seguro en runtime y fallback.
- El warning `custom_samplers` en headless puede aparecer con shaders de pantalla; no bloquea juego en editor/runtime normal.

### Direccion de arte para que Null se vea androide (no humano generico)

- Mantener modelo base, pero agregar **augmentos mecanicos** visibles:
  - nucleo de pecho emissivo
  - visor frontal
  - placas de hombro y columna tecnica
- Paleta de Null:
  - sombras grafito/azul petroleo
  - acento cian/magenta contenido
- Si un mesh "se ve humano", no descartarlo de inmediato: primero reforzar lectura androide con augmentos, shader y silhouette pass.

### Orden recomendado para llegar a calidad alta (arte primero)

1. Bloquear pipeline de render (camara + pixel-perfect + outlines)
2. Bloquear shader de facciones (Null vs regulados)
3. Bloquear personaje androide legible en gameplay
4. Decorar bioma con kit modular sci-fi (props/walls/platforms)
5. Ajustar iluminacion por zonas (fria + warning accents)
6. Recien despues, pulir mecanicas secundarias

### Estado actual vs referencia (2026-04-20)

Resultado del test visual grabado con `--write-movie`:

- El personaje principal ya corre con animaciones reales y mayor lectura de androide (augmentos mecanicos visibles).
- El mapa sigue por debajo de la referencia en densidad visual y variedad de materiales.
- El look general aun no alcanza el nivel de OddPotato/David Holland por falta de:
  1. set dressing modular denso alrededor de camara de juego,
  2. authoring de ramp textures por asset/faccion (hoy son muy uniformes),
  3. mejores mallas base para el MC (modelo humano + augmentos no sustituye un androide diseñado desde cero),
  4. shader pass de post-proceso adicional (film grain sutil + volumetric accents + color grading por bioma).

### Iteracion arte aplicada (2026-04-20 / pass B)

Cambios implementados para acercar movimiento + frame quality al estilo de referencia:

1. **Camara pixel-perfect en movimiento (critico)**
   - Se implemento snap de camara a grilla de texel con compensacion subpixel en el upscaler (`texel_offset`).
   - Resultado esperado: menos pixel crawl/jitter durante seguimiento.

2. **Post-FX de cohesion pixel-art**
   - El shader de upscale ahora aplica:
     - cuantizacion de color suave (look paleta controlada),
     - film grain sutil,
     - vignette suave,
     - pequeno boost de contraste.
   - Objetivo: evitar look "lavado/plano" en runtime.

3. **Set dressing mas denso en radio de gameplay**
   - Se incremento la densidad cerca del player con props del kit modular (fan/chest/light/computer/access) y modulos geometricos de apoyo.
   - Objetivo: que el primer frame jugable tenga lectura de capas (masas grandes/medianas/pequenas).

4. **Dither toon activado**
   - `PixelShaderStyler` habilita dithering en materiales cel para mejorar ruptura de bandas y textura percibida.

### Iteracion arte aplicada (2026-04-20 / pass C)

1. **Color grading de salida (upscale pass)**
   - Ajuste de posterizacion/paleta y tints de sombra/highlight para separar mejor volumen y evitar look gris uniforme.

2. **Separacion de planos por atmosfera**
   - Activado fog suave en `WorldEnvironment` para profundidad legible en camara ortografica sin lavar el frame.

3. **Outline tuning**
   - Ajuste de alpha y umbrales de deteccion para mantener linea firme en silueta y reducir ruido en creases.

4. **Faccion regulados mas "clinica sci-fi"**
   - Material toon enemigo ajustado con mayor contraste frio y especular controlado.

5. **Validacion**
   - Captura nueva: `debug-captures/art_pass4.avi`.

### Iteracion arte aplicada (2026-04-20 / pass D)

1. **Composicion de suelo con guias emissive**
   - Se agregaron lineas emissive en zona central para reforzar lectura de direccion/ritmo visual sin depender de UI.

2. **Null con acento "glitch vivo"**
   - Augmentos mecanicos del androide ahora tienen pulso emissive leve en runtime, para identidad de "entidad digital materializandose".

3. **Validacion**
   - Captura nueva: `debug-captures/art_pass5.avi`.

### Iteracion arte aplicada (2026-04-20 / pass E)

1. **Separacion near/mid/far en post de outline**
   - Se agrego depth tint en el pass de outlines para enfriar planos lejanos y mantener planos cercanos mas neutros.
   - Mejora lectura de profundidad en ortografica.

2. **Movimiento mas legible**
   - Leve incremento de bob/tilt procedural en estado `MOVE` para que el desplazamiento se lea mas "vivo" en camara pixelada.

3. **Validacion**
   - Captura nueva: `debug-captures/art_pass6.avi`.

### Iteracion arte aplicada (2026-04-20 / pass F)

1. **Separacion de familias mas agresiva**
   - Ajuste de materiales cel por tipo de superficie:
     - floor: mas sobrio y oscuro,
     - wall: contraste medio con specular frio,
     - prop: highlights/specular mas marcados para lectura de detalle.

2. **Null vs Regulados mas diferenciados**
   - Null: augmentos con metal/emission mas fuerte (morado glitch).
   - Regulados: tono mas blanco-clinico/cian con bandas mas limpias.

3. **Atmosfera adicional**
   - Se agregaron planos atmosfericos extra para reforzar profundidad y separar mas el espacio cercano vs medio.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass7.avi`.

### Iteracion arte aplicada (2026-04-20 / pass G)

1. **Silueta de Null mas fuerte**
   - Se agregaron piezas mecanicas extra (fins de hombro y bloques de talon) para lectura mas "androide tecnico" a distancia.

2. **Outline + depth separation mas firme**
   - Aumentada fuerza de separacion por profundidad y line alpha para silueta principal mas legible.
   - Crease alpha reducido para evitar ruido en superficies internas.

3. **Grading final de esta vuelta**
   - Posterizacion/contraste/vignette ajustados para frame mas contundente y menos lavado.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass8.avi`.

### Iteracion arte aplicada (2026-04-20 / pass H)

1. **Densidad visual en zona de juego inmediata**
   - Se agregaron modulos de set dressing extra en el tercio frontal de camara para evitar vacios en frame jugable.

2. **Acentos de luz morado/cian**
   - Nuevos puntos de luz locales para reforzar identidad Null (morado glitch) sin perder lectura clinica del bioma.

3. **Separacion atmosferica**
   - Fog levemente reforzado para mejorar separacion de planos en ortografica.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass9.avi`.

### Iteracion arte aplicada (2026-04-20 / pass I)

1. **Atmofx lateral para volumen**
   - Se agregaron planos atmosfericos laterales para mejorar separacion del sujeto en movimiento en la zona central.

2. **Contraste global mas controlado**
   - Ambiente base ligeramente mas oscuro y niebla con energia un poco mayor para reforzar profundidad.

3. **Depth tint mas claro en pipeline de outlines**
   - Se aumento la fuerza de depth tint para mantener lectura near/far mas evidente.

4. **Cohesion cromatica**
   - Ajuste de `shadow_tint`/`highlight_tint` y menor grain para textura mas limpia tipo referencia.

5. **Validacion**
   - Captura nueva: `debug-captures/art_pass10.avi`.

### Iteracion arte aplicada (2026-04-20 / pass J)

1. **Outline mas limpio en detalle fino**
   - Se activo `crease_feather` para suavizar transiciones de creases y reducir cortes agresivos en geometria interna.

2. **Densidad modular adicional (gameplay path)**
   - Se sumaron props extras alrededor del recorrido inmediato del jugador para evitar zonas "planas" en movimiento.

3. **Validacion**
   - Captura nueva: `debug-captures/art_pass11.avi`.

### Iteracion arte aplicada (2026-04-20 / pass K)

1. **Null mas separable del fondo**
   - Augmentos con `rim` activado para mejorar recorte visual del personaje sobre fondos oscuros/cargados.

2. **Silueta de outline principal mas fuerte**
   - `line_alpha` elevado para priorizar lectura inmediata de formas en movimiento.

3. **Cohesion de contraste**
   - Ambiente global y glow reducidos levemente para evitar lavado.
   - Ajuste en grading (`contrast_boost` y `shadow_tint`) para mas profundidad percibida.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass12.avi`.

### Iteracion arte aplicada (2026-04-20 / pass L - referencias YouTube nuevas)

1. **Fix critico de camara en movimiento**
   - Se elimino el re-bind/snap forzado por frame en `main.gd` (eso introducia jitter y anulaba parte del subpixel compensation).
   - Resultado esperado: desplazamiento mas limpio y consistente.

2. **Preset de encuadre tipo intro/test**
   - En `pixel_camera_rig.gd` se agrego preset `intro_test_view`:
     - pitch mas inclinado,
     - ortho mas abierto,
     - distancia de brazo ajustada,
     - offset de encuadre para ver mejor carriles de combate.
   - Objetivo: acercar framing al estilo de vista de prueba/intro de la referencia.

3. **Documentacion de referencias adicionales**
   - Integradas las dos nuevas referencias de YouTube al bloque de fuentes tecnicas.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass13.avi`.

### Iteracion arte aplicada (2026-04-20 / pass M)

1. **Iluminacion de sujeto (centro de combate)**
   - Se agregaron luces locales cerca del eje del player para mejorar lectura del personaje y del espacio inmediato.

2. **Composicion emissive extendida**
   - Nuevas guias emissive longitudinales para sostener ritmo visual en el encuadre estilo intro/test.

3. **Separacion de planos reforzada**
   - Ajustes de fog y far tint para enfriar un poco mas la distancia y dejar foreground mas claro.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass14.avi`.

### Iteracion arte aplicada (2026-04-20 / pass N)

1. **Vista intro/test mas estable**
   - Se agrego amortiguacion vertical ligera en la camara para mantener framing mas limpio en movimiento continuo.

2. **Outline tuning para silueta protagonista**
   - Ajuste de `crease_alpha` y `convex_cutoff` para priorizar borde principal y reducir ruido de pliegues menores.

3. **Micro-contraste de salida**
   - `contrast_boost` subido ligeramente para lectura mas fuerte en escenas densas.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass15.avi`.

### Iteracion arte aplicada (2026-04-20 / pass O)

1. **Lectura de sujeto reforzada**
   - Se agregaron luces locales complementarias cerca del eje central para separar mejor al personaje del fondo.

2. **Separacion de fondo (depth)**
   - Se incrementaron fog y depth tint para enfriar distancia y mantener foreground mas legible.

3. **Cohesion de highlights**
   - Ajuste de `highlight_tint` para mantener brillos mas limpios en materiales y outlines.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass16.avi`.

### Iteracion arte aplicada (2026-04-20 / pass Q - REFERENCE MATCH)

1. **Escena limpia tipo "intro/test" de referencia**
   - Se introduce `clean_test_mode` en `proto_map_room.gd` que arma:
     - un gran piso diamante (checker rotado 45°) con shader propio,
     - una piedra hero cerca del player (eco de la referencia visual),
     - iluminacion minima (key + rim) como en el video t3ssel8r.
   - Se quitaron walls, pilares, set dressing y prop kit modular del gameplay space.

2. **Piso pixel-art (checker diamante)**
   - Shader: `assets/shaders/spatial/floor_pixel_checker.gdshader`
   - Parametros clave: `cell_size`, `pattern_rotation = 45°`, `checker_strength = 1.0`, `contrast = 1.18`, `micro_dither`.
   - El shader ya RECIBE sombra direccional via `light()` controlando `DIFFUSE_LIGHT`, manteniendo el patrón checker intacto.

3. **Personaje cubo (start_form = "cube")**
   - `scenes/player/player.tscn` ahora arranca en forma cubo/androide digital para encajar con pixel-art 3D.
   - Modelo cubo rediseñado con torso/cabeza/brazos/satelites (proporcion humanoide).
   - Hitbox ajustada a altura vertical (capsule 1.25, offset 0.72).

4. **Enemigos re-tonalizados**
   - Paleta mas oscura/fria para reducir ruido visual blanco.

5. **Iluminacion global re-cableada**
   - Fog desactivado (la referencia es limpia, sin haze).
   - Ambient energy a 0.55 con color azul frio.
   - DirectionalLight reubicado y con `shadow_bias` ajustado para sombras pixeladas mas limpias.

6. **Validacion**
   - Captura final: `debug-captures/art_pass25_frame*.png`
   - Match visual con referencia del usuario: composicion, piso diamante y atmosfera general estan muy cerca.

### Iteracion arte aplicada (2026-04-20 / pass V - HERO DETALLADO + POSE VISIBLE)

1. **NullHero reforzado**
   - Cabeza ahora es `BoxMesh` (mas claro de leer en ortografica).
   - 2 ojos como pixeles pequeños (0.04x0.04).
   - Pelo: back + top + fringe frontal + 2 mechones laterales inclinados + 1 tuft superior rotado.
   - Cuello visible entre cabeza y torso.
   - Collar / cuello-capa marcado (parte superior de la capa elevada).
   - Cintura con cinturon oscuro.
   - Capa en 4 piezas: back superior (tono base), back inferior (tono oscuro), front lateral, flaps L/R inclinados.
   - Brazo derecho levantado en pose contemplativa (ArmUpper rotado 22°, ArmFore levantado 70° hacia la cara, mano cerca del menton).
   - Piernas: thigh (pants) + rodilla visible con piel + bota alta (`Mat_boots` marron claro) + pie (`Mat_boots_dark` marron oscuro) separado.

2. **Camara y encuadre tipo referencia**
   - `ortho_size = 3.4` (mas close-up).
   - `angle_x_deg = -35.0`, `arm_distance = 11.0`.

3. **Pose visible: 3/4 hacia camara**
   - En `main.gd`, spawn fija `player.facing = Vector3(0.57, 0, -0.82)` para que el brazo levantado + cara lean al camera.
   - Este override inicial SOBREVIVE al `_orient_mesh()` porque la target_y del lerp termina en el mismo angulo (mientras el player no mueva input).

4. **Validacion**
   - Captura: `debug-captures/art_pass4500000039.png`
   - Match visual con referencia: hero pixel-art con pose contemplativa + capa + botas marron alto + cristal al lado + piso diamante.

### Iteracion arte aplicada (2026-04-20 / pass U - PIXEL-ART REAL)

Cambios criticos para que el render SI lea como pixel-art (no PBR con aristas suaves):

1. **Upscaler nearest-neighbor puro**
   - `upscale_and_offset.gdshader` ahora hace `snapped_uv` pixel-hard, sin smoothing.
   - Resultado: pixeles cuadrados claros en la salida final (1920x1080).

2. **SubViewport**
   - Size subido a 384x216 para mas detalle y mejor match con ortho camera.
   - `default_canvas_item_texture_filter = 0` (nearest).
   - TAA/MSAA/Debanding: OFF para no suavizar pixeles.

3. **Shader de personaje re-escrito: `character_pixel_toon`**
   - Ahora es `render_mode unshaded`.
   - Calcula cel bands directo en fragment con un `sun_dir` uniform.
   - 3 bandas duras: shade_color / base_color / highlight_color.
   - Salida 100% predecible, sin sobre-exposicion.

4. **Floor shader**
   - Agrega bandas cel quantizadas en `light()` (3 niveles) con `lit_factor` topado a 0.62 para que los tiles iluminados no se blanqueen.
   - Pixel grain snapped al world grid (verdadero look pixel-art, no noise rescalado).

5. **Roca/cristal con mismo shader toon**
   - Unifica el look entre personaje + prop sin PBR roughness/metal.
   - Cada segmento tiene paleta propia (base, shade, highlight) auto-derivada.

6. **Pose visible**
   - Personaje spawneado con `rotation.y = -35°` para que el brazo levantado se lea en camara.

7. **Validacion**
   - Captura: `debug-captures/art_pass4100000039.png`.
   - Ya lee como pixel-art 3D (no como PBR low-poly).

### Iteracion arte aplicada (2026-04-20 / pass T - POSE + CRISTAL)

1. **NullHero con pose contemplativa**
   - Brazo derecho levantado 70° hacia el rostro (mano al mentón) como la referencia t3ssel8r.
   - Pelo con 4 segmentos (back/top/sides) para mas lectura de silueta.
   - Cinturon oscuro separando torso y pantalones.
   - Capa con 4 piezas (2 capas back + 2 flaps laterales) dando volumen al paño.

2. **Piedra/cristal rediseñada**
   - 6 segmentos con rotaciones aleatorias en 3 ejes + tonos escalonados.
   - Lee como un cristal/roca organica en vez de cajas apiladas.

3. **Pose lograda - match visual con la referencia**
   - Captura: `debug-captures/art_pass37_frame00000030.png`
   - Elementos clave presentes: pose contemplativa + capa + pelo blanco + cristal al lado + piso diamante + sombra blob.

### Iteracion arte aplicada (2026-04-20 / pass S - NULL HERO CUSTOM)

1. **Modelo MC reescrito desde cero (box-based)**
   - `assets/characters/placeholder/mc_hero/null_hero.tscn`
   - Silueta estilizada con proporciones mas cercanas a la referencia: cabeza, pelo blanco, capa marron, piel visible, pantalones oscuros, botas.
   - Materiales pre-bakeados por parte (skin/hair/cape/shirt/pants/boots) con StandardMaterial3D.
   - Motivo: el Adventurer de Kay es chunky-Kenney, silueta no match.

2. **Blob shadow integrado**
   - QuadMesh oscuro semi-transparente al lado del personaje (1.9x0.85) proyectado al piso.
   - Mucho mas confiable que shadow map a 320x180 (que genera acne/shimmering).
   - Resultado: sombra clara y definida como en la referencia t3ssel8r.

3. **Camara ajustada a encuadre de referencia**
   - `angle_x_deg = -38.0`, `arm_distance = 12.0`, `ortho_size = 4.8`
   - Personaje ocupa ahora ~35% del frame vertical (antes era <15%).

4. **DirectionalLight retuneado**
   - Luz calida tipo sol rasante desde frente-izquierda para producir sombra hacia derecha, igual que la imagen de referencia.

5. **Honestidad visual: lo que falta para 1:1 con la foto**
   - Modelo con mas mesh smoothing (no solo boxes) — requiere Blender.
   - Textures pixel-art bakeadas por parte (ahora son colores planos).
   - Animaciones de idle/walk rigueadas (actualmente solo procedural bob en el mesh pivot).
   - Piedra mas organica (cristal/roca tipo mineral) en vez de 3 boxes apilados.

### Iteracion arte aplicada (2026-04-20 / pass R - MATCH VISUAL CONFIRMADO)

1. **Adventurer de Kay Lousberg como MC**
   - Se importo `Adventurer.gltf` (del Ultimate Modular Women pack que ya descargaste).
   - Es exactamente el tipo de modelo low-poly 3D que usan t3ssel8r y OddPotato para el look pixel-art 3D (se ve pixelado al renderizarse en SubViewport 320x180).
   - Se coloca como `start_form = "android"` en `scenes/player/player.tscn`.

2. **Recomendacion sobre modelos 3D**
   - NO hay que comprar otro asset.
   - NO hay que modelar desde cero (al menos no todavia).
   - El Ultimate Modular Women (gratis en Kay Lousberg) + animaciones built-in en los .gltf = suficiente para beta visual.

3. **Paleta del MC neutralizada (tono beige/marron)**
   - En `character_pixel_toon.gdshader` + parametros en `player.gd` se uso la paleta:
     - lit: `#D0C2AD`
     - mid: `#8C756B`
     - shade: `#382F2F`
     - accent: morado contenido (solo 4% mix) para mantener identidad Null.

4. **Augmentos mecanicos desactivados**
   - Ensuciaban la silueta humana del Adventurer.
   - Se mantendran para una forma "android_glitch" especifica en el futuro (por ejemplo durante dash).

5. **Enemigos retonalizados**
   - Mismo shader `character_pixel_toon` pero con paleta fria azul-gris (institucional clinical).
   - Lit: `#99B7DB`, mid: `#5271A5`, shade: `#142033`, accent: `#33D1FF`.

6. **Validacion en movimiento**
   - Capturas: `debug-captures/art_pass28_movement.avi`, `art_pass29_mov*.png`.
   - El Adventurer usa sus animaciones gltf nativas via `_cache_visual_animation_player`.
   - Se confirma match composicional con la referencia: piso diamante + personaje humanoide + piedra compañera + atmosfera oscura.

### Lo que genuinamente falta para un match 1:1 con la referencia

Esto NO es un capricho de estilo, es limite real de produccion:

1. **Modelo del personaje**
   - La referencia muestra una chica humanoide pixel-art con capa, armadura, anatomia.
   - El proyecto aun no tiene ese asset.
   - Opciones reales:
     a) Modelar en Blender (con MCP Blender) un personaje low-poly humanoide con texturas pixel-art nearest-neighbor.
     b) Usar un sprite 2D billboard (rompe 3D pero es lo que hace mucha gente).
     c) Contratar/comprar un asset humanoide 3D pixel-art.

2. **Animaciones del personaje**
   - La referencia (t3ssel8r) usa Cascadeur + smear frames + animacion on twos.
   - El cubo actual tiene animacion procedural solo; el humanoide real necesita rig + animaciones.

3. **Texturas del piso con mas caracter**
   - Se puede agregar una textura de ruido/grano especifica por tile (tipo t3ssel8r polvo).
   - Requiere authoring de textura.

4. **Volumetrics / atmospheric dust**
   - David Holland usa raymarched volumetric scatter. Se puede aproximar con planos aditivos, pero no es gratis.

### Pipeline final que funciona (copiar estos params si algo se rompe)

- `SubViewport` 320x180
- Camera ortho size ~7-8, angle -42°, arm 14
- Floor shader: `floor_pixel_checker` + cel_shader material on props
- Upscaler shader con pixel snap + subpixel offset
- Outline shader con depth tint + crease feather
- Fog desactivado en modo clean
- Start form = "cube" para el MC hasta que exista `Null_Android_v2`

1. **Encuadre intro/test refinado**
   - Ajuste fino de pitch/distancia/ortho para framing mas limpio y legible en movimiento.

2. **Outline menos agresivo en interiores**
   - Ajustes de `line_alpha`, `zdelta_cutoff` y `crease_feather` para conservar borde principal sin sobrecargar detalle interno.

3. **Atmosfera mas equilibrada**
   - Fog ligeramente reducido para evitar exceso de haze y conservar contraste util.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass17.avi`.

### Iteracion arte aplicada (2026-04-20 / pass Q - foco piso/personaje estilo referencia)

1. **Textura de piso tipo pixel-checker**
   - Se creo shader dedicado `floor_pixel_checker.gdshader` con:
     - checker en world-space,
     - lineas de celda finas,
     - banding controlado + micro variacion.
   - Aplicado a materiales de floor para acercar look al grid del estilo referencia.

2. **Personaje con material mas cercano a referencia**
   - Android ahora usa material toon/muted mas "pintado" (menos plastico brillante).
   - Escala del modelo android ajustada (`0.94`) para lectura mas fina en camara intro/test.

3. **Validacion**
   - Captura nueva: `debug-captures/art_pass18.avi`.

### Iteracion arte aplicada (2026-04-20 / pass R - foco texturas)

1. **Piso mejor resuelto**
   - Shader de piso evolucionado con checker mas claro, lineas mas finas, contraste mayor y control de banding/dither.
   - Escala de celda ajustada para lectura mas limpia tipo referencia.

2. **Textura de personaje mas trabajada**
   - Nuevo shader `character_pixel_toon.gdshader` para android:
     - ruptura de superficie (micro patron),
     - paleta muted de 3 tonos,
     - acento morado controlado,
     - especular bajo para evitar look plastico.

3. **Escalado/lectura**
   - Se mantiene ajuste de escala en android para encuadre intro/test y claridad de silhouette.

4. **Validacion**
   - Captura nueva: `debug-captures/art_pass19.avi`.

### Limitaciones reales para igualar 1:1 las referencias

Estas limitaciones NO bloquean una beta visual fuerte, pero si explican por que aun no es "calidad portfolio final":

1. **Modelo principal**
   - Sin `Null_Android_v2` dedicado (silueta mecanica propia), el look del MC seguira parcialmente "humano base + augmentos".

2. **Ramps por familia**
   - Hoy no hay authoring completo de ramp por cada familia (suelo/muro/prop/MC/enemigo), por eso partes del frame quedan demasiado cercanas en tono.

3. **Volumetric accents**
   - El look tipo David Holland sube mucho con volumetric fake/god-rays. En Godot vanilla se puede aproximar, pero requiere pass extra de shader/post.

4. **Kit de assets**
   - La calidad final depende de mallas y texturas del kit disponible. Si el kit no trae suficiente lectura low/mid poly, hay que corregir en Blender (MCP Blender ayuda).

### Hacks / fuentes tecnicas recomendadas (video + comunidad)

Para seguir iterando al estilo t3ssel8r/OddPotato sin adivinar:

- Subpixel camera para 3D pixel art (YouTube): `https://www.youtube.com/watch?v=NutO1jzuVXU`
- Recreating t3ssel8r style in Godot (YouTube): `https://www.youtube.com/watch?v=g1vH3HeePco`
- Demo open source de camara/shaders: `https://github.com/leopeltola/Godot-3d-pixelart-demo`
- Referencia de outline + palette + dithering: `https://godotshaders.com/shader/outline-posterization-color-palette-and-dithering/`
- Referencia extra 1: `https://www.youtube.com/watch?v=YjDQB6KBwAs`
- Referencia extra 2 (foco en vista intro/test): `https://www.youtube.com/watch?v=1FrIBkuq0ZI`

Regla: cada mejora visual nueva debe validarse con captura en movimiento (`--write-movie`), no solo por screenshot estatico.

### Bloqueadores de calidad visual alta (arte-first)

1. **Modelo principal**
   - Se requiere un modelo androide dedicado (no humano base) con silueta mecanica clara.
   - Recomendado: kitbash en Blender y export `glb/gltf` con LOD simple.

2. **Pipeline de texturas y ramps**
   - Cada familia de assets (suelo, props, muros, personaje, enemigo) necesita ramp propia.
   - Sin eso, todo cae en tonos similares y se ve "plano".

3. **Densidad de escena**
   - La referencia funciona porque cada frame tiene masas grandes + medianas + pequenas.
   - El nivel actual tiene demasiadas zonas vacias.

4. **Post FX de cohesion**
   - Film grain suave
   - Vignette sutil
   - ajuste de contraste por bioma
   - opcional: volumetric fake para separar planos

### Siguiente sprint recomendado (solo arte)

1. Diseñar `Null_Android_v2` en Blender (MCP Blender puede acelerar bloque base)
2. Reemplazar set dressing con kit modular en un radio de gameplay cercano (no solo periferia)
3. Crear 4 ramp textures de produccion y asignarlas por grupos de meshes
4. Grabar comparativa A/B con `--write-movie` y elegir configuracion final por frame quality

## Paso 6 - Feedback visual minimo (obligatorio para jugabilidad)

Implementar solo 3 VFX:

1. Dash trail corto
2. Hit flash en enemigo al recibir dano
3. Hackeo flash/particulas simples

Sin este feedback, el combate se siente "sin impacto" aunque la logica funcione.

## Paso 7 - QA rapido de vertical slice (30-45 min)

Pruebas obligatorias:

- 3 runs completas de test room sin crash.
- Revisar que no se congele en narrativa.
- Verificar recarga de dash durante combate intenso.
- Morir intencionalmente y confirmar reload correcto.
- Confirmar que fragmentos persisten segun el sistema actual.

Registrar bugs en una lista simple: "pasos para reproducir + resultado esperado + resultado actual".

---

## 4) Matriz de prioridad (si hay poco tiempo)

Prioridad alta (hacer si o si):

1. SubViewport 320x180
2. Movimiento/dash estable
3. Combate + hackeo sin errores
4. Modelos beta en player/enemy
5. MC dual (cubo + androide) al menos con swap manual en escena/script

Prioridad media:

1. VFX minimos (dash/hit/hackeo)
2. Ramps de cel shader por faccion

Prioridad baja (post-beta):

1. AnimationTree completo
2. Hub Nodo Muerto
3. Transiciones de salas y biomas
4. Arma de rango y bosses

---

## 5) Definicion de "ya funciona"

Decir "jugable" solo cuando:

- No hay errores bloqueantes en consola durante una partida normal.
- El jugador entiende controles en menos de 30 segundos.
- El dash se siente util y responsivo para atacar/esquivar.
- El hackeo funciona como mecanica y como momento narrativo.
- Los modelos 3D beta permiten distinguir MC vs enemigo de un vistazo.

Si uno de esos puntos falla, todavia no esta lista.

---

## 6) Entrega interna recomendada

Al cerrar esta fase, entregar:

1. Build ejecutable de prueba
2. Video corto (1-2 min) mostrando loop completo
3. Lista de bugs abiertos (maximo 10, ordenados por severidad)
4. Captura de parametros finales de movimiento/dash

Eso evita ambiguedad y permite arrancar la siguiente fase (contenido y biomas) con base firme.
