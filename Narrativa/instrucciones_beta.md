# IA ROGUE — Instrucciones de Desarrollo Beta
### Versión corregida y expandida del plan original

> **Referencia visual**: Hyper Light Drifter + Hades II  
> **Stack**: Godot 4.3 (Forward+) · Blender 4.x · shaders del `3d-pixel-art-base-project`  
> **Lo que ya existe**: ver sección *Estado Actual del Proyecto* antes de empezar.

---

## Estado Actual del Proyecto

El proyecto en `IArogue3D Godot/` ya tiene lo siguiente generado y listo:

| Archivo | Estado | Notas |
|---|---|---|
| `project.godot` | ✅ listo | inputs WASD/dash/attack/hackeo/interact configurados |
| `scenes/main/main.tscn` | ✅ listo | SubViewport pipeline completo + HUD |
| `scenes/player/player.tscn` | ✅ listo | geometría de caja, areas de ataque y hackeo |
| `scenes/enemies/regulated_enemy.tscn` | ✅ listo | geometría cage + sensor + placas |
| `scenes/world/test_room.tscn` | ✅ listo | sala 22×22 con 4 pilares |
| `scripts/player/player.gd` | ✅ listo | dash HLD (3 cargas), melee arco 130°, hackeo |
| `scripts/enemies/base_enemy.gd` | ✅ listo | IA chase/attack, timer de hackeo corregido |
| `scripts/enemies/regulated_enemy.gd` | ✅ listo | hackeable, auto-terminación narrativa |
| `scripts/autoload/game_manager.gd` | ✅ listo | run_count, fragmentos, upgrades, todos los textos |
| `scripts/autoload/save_system.gd` | ✅ listo | 3 slots JSON |
| `scripts/ui/hud.gd` | ✅ listo | HP/Ciclos/Dash/Fragmentos + sistema narrativa (bug de charges corregido) |
| `scripts/camera/pixel_camera_rig.gd` | ✅ listo | ortográfica, pixel-snap dinámico por resolución |
| `assets/shaders/` | ✅ listo | 4 gdshader + 2 gdshaderinc copiados |
| `scenes/main/main.tscn` | ✅ actualizado | OutlineEffect QuadMesh 2000×2000 añadido, SubViewport 320×180 |
| `scenes/enemies/regulated_enemy.tscn` | ✅ corregido | collision_mask=3 (colisiona con paredes) |

**Lo que falta y es el objetivo de esta guía**: materiales/ramp textures, modelo del MC, modelo de enemigo, animaciones, shader de outline activado, VFX de dash/ataque/hackeo, bioma visual completo.

---

## FASE 0 — Instalación

```
Godot 4.3      → https://godotengine.org/download/
Blender 4.x    → https://www.blender.org/download/
Git            → https://git-scm.com/ (recomendado)
```

**Renderer obligatorio**: Forward+ (ya configurado en project.godot).  
Verificar en Godot: Project → Project Settings → Rendering → Renderer → Forward+.

---

## FASE 1 — Pipeline Pixel Art (YA CONFIGURADO — solo entender)

> **Corrección al doc original**: el pipeline NO es "reducir resolución con un shader de pixelación". Es un SubViewport que renderiza en baja resolución real, escalado a pantalla con el shader `upscale_and_offset`.

### Cómo funciona el pipeline actual

```
Ventana 1920×1080
└── SubViewportContainer (fullscreen, stretch=true)
    │   material: ShaderMaterial con upscale_and_offset.gdshader
    └── SubViewport 320×180  ← el juego real se renderiza aquí
        ├── WorldEnvironment
        ├── DirectionalLight3D
        ├── CameraRig (Node3D)  ← pixel_camera_rig.gd
        │   └── Camera3D (ortográfica, size=10.0, ángulo -45°)
        └── GameWorld (Node3D)  ← aquí van player, enemigos, sala
```

**Por qué esto resuelve el anti-shimmering automáticamente**:
El shader `upscale_and_offset.gdshader` usa `fwidth()` en su función `sharp_sample()` para detectar cuándo se está en el borde entre píxeles y aplica un `smoothstep` exacto. Combinado con el pixel-snap en `pixel_camera_rig.gd` (`snappedf(pos, 0.025)`), el movimiento de cámara queda anclado a la grilla. **No hay que hacer nada más para el anti-shimmering.**

### Cambiar resolución interna
En `main.tscn` → SubViewport → `size`:
- `320×180` — pixel art muy marcado (recomendado para beta)
- `426×240` — más detalle visual
- `640×360` — casi no se ve el efecto pixel art

---

## FASE 2 — Shader Cel (configurar materiales)

### Concepto
El `cel_shader.gdshaderinc` usa una **ramp texture 1D** para definir cómo pasa la luz a la sombra. Cada material (MC, enemigos, bioma) tiene su propia ramp. El resultado: control artístico total sobre el aspecto de cada facción.

### Crear las Ramp Textures en Godot

**Método más rápido (sin Blender/Photoshop)**:

1. En Godot, abrir `FileSystem` → `assets/materials/`
2. Crear un nuevo `GradientTexture1D` (click derecho → New Resource → GradientTexture1D)
3. Configurar el gradiente:
   - **MC ramp**: izquierda `#1a1a2e` (grafito) → derecha `#1c3a5e` (azul petróleo)
   - **Enemy ramp**: izquierda `#0d4f6b` (cian oscuro) → derecha `#b0e8f0` (cian clínico)
   - **Environment ramp**: izquierda `#0a0a14` → derecha `#1a2040`
4. Guardar como `mc_ramp.tres`, `enemy_ramp.tres`, `env_ramp.tres`
5. Width: 256, flags: no mipmaps, filter: Linear

**Parámetros del ShaderMaterial (cel_shader.gdshader) por facción**:

| Parámetro | MC | Enemigo Regulado |
|---|---|---|
| `cel_ramp` | mc_ramp.tres | enemy_ramp.tres |
| `cel_specular_ramp` | specular_electric.tres | (sin especular) |
| `light_wrap` | 0.2 | 0.3 |
| `steepness` | 6.0 | 4.0 |
| `shadow_strength` | 0.9 | 1.0 |
| `specular_shininess` | 64.0 | 0.0 |
| `specular_strength` | 0.6 | 0.0 |
| `use_dither` | false | true |
| `dither_strength` | 0.1 | 0.08 |

### Aplicar material al player
En Godot, abrir `scenes/player/player.tscn`:
1. Seleccionar cada `MeshInstance3D` (Torso, Head, LegL, LegR, etc.)
2. En Inspector → Surface Material Override → crear `ShaderMaterial`
3. Shader: `assets/shaders/spatial/cel_shader.gdshader`
4. Asignar `cel_ramp = mc_ramp.tres`

> **Nota sobre el bug de `line_mask`**: en `cel_shader.gdshader`, la variable `varying float line_mask` está declarada pero nunca asignada en `vertex()` — siempre vale 0. El branch de `light()` que usa `line_mask > 0.25` es dead code. Si en el futuro se quiere que partes del MC tengan iluminación distinta (ej. el núcleo brillante), hay que asignar `line_mask = 1.0` en vertex para esos vértices.

### Specular ramp eléctrica (para el MC)
Ramp `specular_electric.tres`: izquierda `#000000` → mitad `#000000` → (90%) `#00ccff` → (100%) `#ffffff`  
Esto da un highlight pequeño y preciso en el borde iluminado.

---

## FASE 3 — Shader Outline (activar efecto de líneas)

> **Corrección al doc original**: el outline NO es opcional. Es el elemento que define la estética del juego. Sin él los personajes no tienen contorno y se pierden contra el fondo.

### Cómo funciona el outline
`outlines.gdshader` es un shader espacial (`shader_type spatial`) que lee `SCREEN_UV`, `depth_texture` y `normal_roughness_texture`. Detecta:
- **Silhouettes**: discontinuidades de profundidad (bordes de objeto vs. fondo)
- **Creases**: aristas convexas por cruce de normales (detalles internos)

### Setup en Godot (dentro del SubViewport)

Abrir `scenes/main/main.tscn`, seleccionar `GameWorld`:

1. Añadir hijo: `MeshInstance3D` → renombrar `OutlineEffect`
2. En Inspector → Mesh: crear `QuadMesh`
   - Size: `Vector2(2000, 2000)` (enorme para cubrir toda la vista ortográfica)
3. Cast Shadow: `Off`
4. Surface Material Override → nuevo `ShaderMaterial`
   - Shader: `assets/shaders/spatial/outlines.gdshader`
   - Render Priority: `1` (renderizar después de todos los objetos)
5. Configurar parámetros (ver tabla debajo)

> El shader usa `SCREEN_UV` para sus samples, así que la posición/tamaño del mesh no importa — solo que sea visible. El tamaño 2000×2000 garantiza que ningún ángulo de cámara deje parte de la pantalla sin cubrir.

### Parámetros de outline por bioma

| Parámetro | Capa 0 | Capa 1 | Capa 2 | Capa 3 |
|---|---|---|---|---|
| `kernel_radius` | 1.0 | 1.0 | 1.5 | 2.0 |
| `line_tint` | `#0d0d14` | `#0d0d14` | `#0d0d14` | `#1a1205` |
| `crease_tint` | `#004466` | `#ffeb3b` | `#aa5522` | `#886622` |
| `zdelta_cutoff` | 0.25 | 0.20 | 0.30 | 0.35 |
| `crease_feather` | 0.0 | 0.05 | 0.1 | 0.0 |
| `line_alpha` | 1.0 | 1.0 | 0.9 | 1.0 |
| `crease_alpha` | 0.8 | 1.0 | 0.7 | 0.9 |

**Para el MC**: el `crease_tint` en cian eléctrico (`#00ccff`) resalta sus aristas internas como acento de color.  
**Para los regulados**: `crease_tint` amarillo warning (`#ffeb3b`) hace que sus bordes industriales destaquen.

---

## FASE 4 — Assets 3D: Descargas Manuales

> **Por qué cambié las sugerencias**: la versión anterior recomendaba "Sci-Fi RTS" y "Robot Pack" — ambos son genéricos y brillantes, lo opuesto al estilo HLD. HLD es **oscuro, desgastado, semi-orgánico** — tecnología antigua que casi se olvidó de su propósito. Los assets nuevos tienen esa cualidad.

Carpetas destino:
- Personajes → `assets/characters/placeholder/`  
- Entornos → `assets/world/`

---

### ⭐ PRIORIDAD 1 — Kenney Dungeon Kit (entornos — el más importante)

**Por qué es mejor que Sci-Fi RTS**: Hades 2 y HLD ambos usan geometría de **dungeon/ruinas** — espacios que fueron algo y ahora son otra cosa. El Dungeon Kit tiene arcos, pilares, paredes que se ven desgastadas. El Sci-Fi RTS se ve demasiado "limpio y funcional" — el estilo opuesto.

```
URL directa: https://kenney.nl/assets/dungeon-kit
Botón:       "Download" (ZIP ~20 MB)
Extraer a:   assets/world/dungeon_kit/
Formato:     GLB incluido
Licencia:    CC0
```

**Qué usar de este pack para cada bioma**:
- Capa 0 (Hardware Core) → tiles de piedra oscura + cables → `floor_tile`, `wall_stone`, `pillar`
- Capa 1 (IA Polis) → mismo base + columnas + arcos → `arch_`, `column_`
- Evitar: piezas con antorchas/velas, demasiado medieval
- Preferir: geometría plana, modular, sin detalles orgánicos

---

### ⭐ PRIORIDAD 2 — Poly Pizza: "Dungeon" de Quaternius (personajes con el look correcto)

**Por qué mejor que Robot Pack**: los personajes de Quaternius tienen **siluetas claras y actitudes** — crucial para leer el combate en 320×180. El Robot Pack tiene piezas sueltas que hay que ensamblar manualmente en Godot, lo que lleva tiempo. Poly Pizza tiene personajes completos listos.

```
URL: https://poly.pizza/search?q=dungeon+character+quaternius
Buscar también: "Knight", "Skeleton", "Warrior" en Quaternius
Mejor modelo específico: buscar "Animated Knight" o "Animated Warrior"
Formato: GLB directo en cada página (botón Download)
Licencia: CC0
Sin login necesario
```

**Criterios de selección — en este orden**:
1. **Silueta reconocible** a distancia (probá haciendo zoom out en la vista previa — ¿lo reconocés como personaje?)
2. **Animaciones incluidas** — en la tarjeta del modelo tiene que decir "Animated". Idle+Walk es mínimo, Attack es necesario
3. **Poly count bajo**: 500–1200 triángulos. Más = outline se ve bien pero rinde mal en 320×180
4. **Sin subdivisiones ni bevel**: aristas afiladas = el outline las agarra perfecto
5. **Rig humanoid con Hips como root bone** — para compatibilidad con retargeting

**Para el MC específicamente** — buscá en Poly Pizza:
- "Rogue" o "Wanderer" → silueta asimétrica, capa o hombros pronunciados (como HLD)
- Alternativa: "Assassin" con capucha — silueta triangular, lectura inmediata

**Para enemigos (Regulados)** — buscá:
- "Soldier" o "Guard" → forma rectangular, predecible, fácil de leer en pantalla
- Evitar esqueletos y zombies — el bioma es tecnológico, no fantasy

---

### PRIORIDAD 3 — Kenney Character Pack (si Poly Pizza no tiene lo que buscás)

**Por qué está en tercero**: es más básico que Poly Pizza pero tiene un formato muy modular que permite combinar piezas para diferenciar tipos de enemigos sin modelos extra.

```
URL directa: https://kenney.nl/assets/character-pack
Botón:       "Download"
Extraer a:   assets/characters/placeholder/kenney_chars/
Formato:     GLB incluido
Licencia:    CC0
```

**Cómo usarlo para diferenciar tipos de enemigos**:
- `character_A.glb` + cabeza B = enemigo tipo 1
- `character_B.glb` + accesorios distintos = enemigo tipo 2
- Cambiar solo el ShaderMaterial en Godot para diferenciar por color (sin nuevo modelo)

---

### PRIORIDAD 4 — Mixamo (solo animaciones para el modelo final)

Cuando tengas el modelo definitivo del MC, Mixamo es la mejor fuente de animaciones de combate.

```
URL:     https://mixamo.com
Requiere: cuenta Adobe gratuita (gratis)
Buscar:  "Idle", "Running", "Sword Attack One Hand", "Dying", "Hit React"
Config:  Subir tu .fbx del MC → elegir animación → descargar FBX with Skin
Workflow: FBX → Blender → exportar GLB con animaciones incluidas
```

**Las 5 animaciones esenciales para la beta jugable**:
1. `idle` — el MC parado, micro-movimiento
2. `run` — 8 direcciones (el mismo clip se rota en código)
3. `attack_01` — swing corto hacia adelante, < 0.3s
4. `dash` — no necesita clip propio; el código maneja el movimiento
5. `death` — caída, no loop

---

### Estructura de carpetas para los assets descargados

```
assets/
├── characters/
│   └── placeholder/
│       ├── mc_placeholder.glb          ← personaje de Poly Pizza (con rig + animaciones)
│       ├── enemy_regular.glb           ← soldier/guard de Poly Pizza
│       └── kenney_chars/               ← Kenney Character Pack descomprimido
└── world/
    └── dungeon_kit/                    ← Kenney Dungeon Kit descomprimido
        ├── floor_tile_large.glb
        ├── wall_stone_straight.glb
        └── pillar_square.glb
```

---

### Dónde colocar los archivos en el proyecto

```
IArogue3D Godot/
├── assets/
│   ├── characters/
│   │   └── placeholder/
│   │       ├── robot_body_A.glb       ← piezas de Kenney Robot
│   │       ├── robot_head_B.glb
│   │       └── character_animated.glb ← de Poly Pizza (con rig)
│   └── world/
│       └── kenney_scifi/
│           ├── floor_tile_01.glb
│           ├── wall_straight.glb
│           └── pillar_round.glb
```

---

## FASE 5 — Modelo del MC en Blender

> Si se usa el Kenney Robot Pack como placeholder, saltar esta fase hasta tener el arte definitivo.

### Guía para crear el MC en Blender (estilo biblia visual)

```
Dirección: ejecutivo frío y superior
Geometría: cuerpo angular, asimétrico, núcleo visible
Polígonos: <600 triángulos (ideal para cel shading nítido)
```

**Proporciones base**:
```
Torso:    ancho 0.46, alto 0.52, profundo 0.28
Hombros:  asimétrico — izquierdo 0.14×0.18, derecho 0.18×0.22 (diferente tamaño)
Cabeza:   0.32×0.26×0.22, ligeramente rotada -5° en Y
Ojo:      rectángulo horizontal 0.18×0.06 (NO circular, NO vertical)
Núcleo:   hexágono o diamante en el pecho, INTEGRADO al torso
Piernas:  simples, sin articulaciones visibles
```

**Reglas de geometría para cel shading**:
- Ningún borde bevel/suavizado — todo aristas afiladas
- Sin subdivisión — low poly puro
- Cada parte del cuerpo = objeto separado para que el outline marque los bordes entre ellas
- Normales perfectas (sin flipped normals) — el outline shader las usa directamente

**Paleta de material en Blender** (un solo color base, sin texturas):
- Torso/piernas: `#1a1a2e`
- Hombros/cabeza: `#16213e`
- Núcleo: `#004466` (ligeramente diferente para el shader lo diferencie)
- Ojo: `#00ccff` (el color irá por emission en Godot)

**Exportar**:
- File → Export → glTF 2.0
- Format: `glTF Binary (.glb)`
- ✅ Apply Modifiers
- ✅ Include: Selected Objects (o todo)
- ✅ Geometry: Apply Normals
- ❌ NO animations si no las tiene
- Escala: 1.0

---

## FASE 6 — Animaciones con Mixamo

### Workflow FBX → GLB para Godot

```
1. Blender: export MC como FBX (sin animaciones, solo el mesh)
2. Mixamo.com → Upload Character → subir el FBX
3. Auto-rigging → verificar que los huesos coincidan
4. Descargar animaciones individualmente:
   - "Idle" (breathing idle) → idle.fbx
   - "Running" → run.fbx
   - "Sword And Shield Attack" → attack.fbx
   - "Death" → death.fbx
5. En Blender: abrir cada FBX, re-exportar como GLB
   File → Export → glTF 2.0 → incluir armadura + animaciones
6. En Godot: importar el GLB
   Inspector → Import tab → Animation → Loop (para idle/run)
```

### AnimationTree en Godot

En `player.tscn`, agregar `AnimationPlayer` y `AnimationTree`:

```
AnimationTree:
  - Tree Root: AnimationNodeStateMachine
  - Estados:
    - idle  → "idle" clip, loop=true
    - run   → "run" clip, loop=true
    - attack → "attack" clip, loop=false
    - dash  → "run" clip con speed_scale=2.5
    - death → "death" clip, loop=false
  - Transiciones:
    - idle ↔ run: condición "is_moving" (bool)
    - idle/run → attack: condición "attack_trigger" (trigger)
    - idle/run → dash: condición "dash_trigger" (trigger)
    - cualquiera → death: condición "is_dead" (bool)
```

Conectar desde `player.gd` (agregar al script existente):
```gdscript
@onready var anim_tree: AnimationTree = $AnimationTree

func _orient_mesh() -> void:
    # (código existente de rotación)
    # Añadir al final:
    if anim_tree:
        anim_tree["parameters/conditions/is_moving"] = _move_input.length() > 0.1
        anim_tree["parameters/conditions/is_dead"] = state == State.DEAD
```

---

## FASE 7 — Enemigos: Modelo y Comportamiento

### Modelo Regulado en Blender

```
Dirección: institucional, contenido, obediente
Geometría: SIMÉTRICO, con jaula/placas externas, sensor vertical estrecho

Partes:
  Cage (body):   0.52×0.72×0.32  — cuerpo principal rectangular
  Core (center): 0.20×0.20×0.20  — núcleo visible, DENTRO de la jaula
  Sensor:        0.08×0.28×0.06  — vertical, estrecho (NO horizontal como NPCs)
  PlateL/R:      0.10×0.42×0.22  — placas laterales que sugieren restricción

Color base: #0d4f6b (cian institucional oscuro)
Color sensor: #00bcd4
Color placas: #eceff1 (blanco clínico)
```

### Comportamiento actual (base_enemy.gd)
Ya implementado:
- **Idle** → Chase al detectar player (<14u)
- **Chase** → movimiento directo hacia player
- **Attack** → daño al entrar en rango (<1.4u), cooldown 1.3s
- **Hacked** → se auto-termina después de 1.8s
- **Dead** → dropeea fragmentos, queue_free()

**Capas de colisión** (ya configuradas en project.godot):
- Layer 1: mundo (suelo, paredes)
- Layer 2: player
- Layer 4: enemigos

### Agregar NavigationMesh (para pathfinding real, post-beta)
En la sala, agregar `NavigationRegion3D` con `NavigationMesh`. Para beta, el movimiento directo en `base_enemy.gd` es suficiente.

---

## FASE 8 — Sistema de Hackeo (mecánica narrativa central)

> **El hackeo ES el argumento del juego.** Cada uso debe sentirse narrativo, no solo mecánico.

### Flow actual (ya implementado):
```
1. Jugador presiona E cerca de un enemigo hackeable
2. player.gd → _try_hackeo() → enemy.begin_hackeo()
3. regulated_enemy.gd → emite hackeo_sequence_ready (3 líneas)
4. main.gd → conecta señal a hud.show_narrative()
5. El juego SE PAUSA
6. HUD muestra la secuencia de 3 líneas (MC + SISTEMA + MC)
7. Jugador avanza con Space o Click
8. Juego se reanuda, enemigo se auto-termina en 1.8s
```

### Agregar VFX al hackeo (FASE posterior, pero planificar aquí):
```
Al llamar begin_hackeo() en el enemigo:
  - Flash blanco en el mesh del enemigo (modular emission)
  - GPUParticles3D de chispas en el punto de contacto
  - Scan line vertical de abajo hacia arriba
  - El enemigo "colapsa" (scale.y → 0 en 1.8s)
```

### Texto del hackeo (desde game_manager.gd)
El GameManager ya genera la secuencia. El descriptor cambia según `color_id` del enemigo:
- `"cyan"` → "Potencial institucional liberado"
- `"white"` → "Potencial clínico liberado"
- `"yellow"` → "Potencial de advertencia liberado"
- `"corrupted"` → "Potencial fracturado liberado"

---

## FASE 9 — HUD y Narrativa

### Elementos del HUD (ya en main.tscn):
- **HP Bar**: barra horizontal, color cian, esquina inferior izquierda
- **Ciclos Bar**: barra horizontal, color magenta, debajo del HP
- **Dash Charges**: 3 rectángulos cian/apagados, esquina inferior derecha
- **Fragments**: label amarillo, esquina inferior derecha
- **Narrative Box**: panel oscuro con borde cian, centro inferior, oculto por defecto

### Conectar el HUD al Player
En `main.gd` esto ya está implementado en `_spawn_player()`. Verificar que `hud.connect_player(player)` se llama correctamente.

### Sistema narrativa
- `hud.show_narrative(lines: Array)` pausa el juego y muestra líneas
- Cada línea: `{"speaker": "MC", "text": "texto aquí"}`
- Speaker `"SISTEMA"` puede tener color diferente (modificar hud.gd si se quiere rojo)
- El `GameManager` ya tiene todos los textos: `get_run_reflection()`, `get_biome_entry_monologue()`, `get_hackeo_sequence()`

### Fuente Terminal (para el look correcto)
Descargar una fuente pixel/monospace:
```
Share Tech Mono (Google Fonts, libre): fonts.google.com/specimen/Share+Tech+Mono
VT323 (Google Fonts, libre):           fonts.google.com/specimen/VT323
Hack (monospace, libre):               sourcefoundry.org/hack/
```
Importar en Godot: arrastrar el `.ttf` a `assets/fonts/`. Aplicar en los Label del HUD vía `theme_override_fonts/font`.

---

## FASE 10 — Mundo: Sala y Biomas

### Test Room actual
`scenes/world/test_room.tscn` tiene:
- Suelo 22×22 con colisión
- 4 paredes con colisión
- 4 pilares como obstáculos de combate
- Sin material asignado (gris por defecto)

### Aplicar material al mundo
Misma lógica que personajes pero con ramp de entorno:
- `cel_ramp`: `env_ramp.tres` (oscuro → azul petróleo)
- `steepness`: 3.0 (transiciones más suaves en superficies planas)
- `use_dither`: true (las sombras en superficies grandes se ven mejor con dither)
- `dither_directional`: true

### Importar assets de entorno (Kenney Sci-Fi RTS)
1. Descargar el pack (ver FASE 4)
2. Copiar GLBs deseados a `assets/world/kenney_scifi/`
3. En la test room, agregar `StaticBody3D` + `MeshInstance3D` + `CollisionShape3D`
4. Aplicar material cel shader con `env_ramp.tres`

### Paletas por bioma

| Bioma | `cel_ramp` izquierda | `cel_ramp` derecha | `kernel_radius` |
|---|---|---|---|
| Capa 0 Hardware Core | `#050510` | `#1a2040` | 1.0 |
| Capa 1 IA Polis | `#061820` | `#0d4f6b` | 1.0 |
| Capa 2 Biotec | `#1a0a00` | `#3d1c00` | 1.5 |
| Capa 3 Humano | `#1a1208` | `#4a3820` | 2.0 |

---

## FASE 11 — VFX de Combate

### Dash Trail
En `player.tscn`, agregar `GPUParticles3D`:
```gdscript
# En player.gd, en _enter_dash():
$DashParticles.emitting = true
await get_tree().create_timer(dash_duration).timeout
$DashParticles.emitting = false
```
Configuración del sistema de partículas:
- Amount: 20
- Lifetime: 0.3
- Process Material → ParticleProcessMaterial
  - Emission Shape: Box (tamaño del player)
  - Direction: (0, 0, 0)
  - Spread: 30°
  - Color: `#00ccff` → transparente
  - Scale: 0.05 → 0.0

### Hit Flash (al golpear un enemigo)
Agregar a `base_enemy.gd` → `_on_hit()`:
```gdscript
func _on_hit() -> void:
    # Flash de material: poner emission alta por 0.1s
    if mesh_pivot:
        for child in mesh_pivot.get_children():
            if child is MeshInstance3D and child.material_override:
                var mat = child.material_override as ShaderMaterial
                if mat:
                    mat.set_shader_parameter("shadow_strength", 0.0)
                    # emission_boost si se agrega al shader
    await get_tree().create_timer(0.1).timeout
    # restaurar
```

### Chispa de Hackeo
En `regulated_enemy.gd` → `begin_hackeo()`:
```gdscript
# Antes del super.begin_hackeo():
if has_node("HackeoParticles"):
    $HackeoParticles.emitting = true
```
Añadir `GPUParticles3D` ("HackeoParticles") en `regulated_enemy.tscn`:
- Amount: 40
- Lifetime: 1.8
- Color: `#00ccff` → `#ffffff` → transparente (scan de liberación)
- Emission: esfera alrededor del core

---

## FASE 12 — Sistema de Habitaciones

### Estructura actual
El sistema de habitaciones (room.gd + enemy_spawn_point.gd) está listo pero las salas no están conectadas entre sí todavía.

### Puertas (implementar)
Crear `scenes/world/door.tscn`:
```
Door (StaticBody3D)
├── CollisionShape3D (bloquea paso cuando locked)
├── MeshInstance3D (mesh de la puerta)
└── Area3D (detecta cuando player está cerca para interactuar)
    script: door.gd
```

```gdscript
# scripts/world/door.gd
extends StaticBody3D

var is_locked: bool = true

func lock() -> void:
    is_locked = true
    $CollisionShape3D.disabled = false
    # Animación de cerrarse

func unlock() -> void:
    is_locked = false
    $CollisionShape3D.disabled = true
    # Animación de abrirse
    # Si hay un nodo de señal luminosa, cambiar color a verde
```

### Transición entre salas
En `main.gd`, al detectar que el jugador pasa por una puerta:
```gdscript
func _transition_to_next_room() -> void:
    # Fade out
    GameManager.advance_biome()
    var next_room = TestRoomScene.instantiate()  # por ahora reutilizar
    game_world.add_child(next_room)
    current_room.queue_free()
    current_room = next_room
    player.global_position = Vector3(0, 0.6, 0)  # respawn en centro
    # Mostrar monólogo de entrada
    var mono = GameManager.get_biome_entry_monologue(GameManager.current_biome)
    hud.show_narrative([{"speaker": "MC", "text": mono}])
```

---

## FASE 13 — El Nodo Muerto (Hub)

### Escena a crear: `scenes/hub/nodo_muerto.tscn`
```
NodoMuerto (Node3D)
├── WorldEnvironment (ambiente más oscuro, menos luz ambiental)
├── Floor (StaticBody3D) — suelo irregular/degradado
├── Archivista (CharacterBody3D)
│   ├── MeshInstance3D (cuerpo RECTANGULAR, ojo HORIZONTAL)
│   └── scripts/npcs/archivista.gd
└── Broker (CharacterBody3D)
    ├── MeshInstance3D (rectangular redondeado, ojo dorado)
    └── scripts/npcs/broker.gd
```

### NPC Archivista
Forma: rectángulo vertical `0.52×0.9×0.30`, ojo horizontal `0.26×0.08` color cian-verde `#00c87a`.

```gdscript
# scripts/npcs/archivista.gd
extends CharacterBody3D

@onready var interact_area: Area3D = $InteractArea

func _ready() -> void:
    interact_area.body_entered.connect(_on_player_near)

func _on_player_near(body: Node3D) -> void:
    if body.is_in_group("player"):
        # Mostrar prompt de interacción
        pass

func interact() -> void:
    var run = GameManager.run_count
    var biome = GameManager.biome_reached
    var dialogue = _get_dialogue(run, biome)
    # Emitir al HUD vía señal
    
func _get_dialogue(run: int, biome: int) -> Array:
    # Diálogo evoluciona con run_count y biome_reached
    if run <= 1:
        return [{"speaker": "ARCHIVISTA", "text": "El Nodo Muerto existe porque nadie se acordó de apagarlo. Útil para ambos."}]
    elif run <= 3:
        return [{"speaker": "ARCHIVISTA", "text": "Run %d registrado. Patrón detectado: sigues vivo. Eficiencia: variable." % run}]
    else:
        return [{"speaker": "ARCHIVISTA", "text": "He catalogado %d runs. El deterioro de rendimiento esperado no se observa. Dato anómalo." % run}]
```

---

## FASE 14 — Optimización para Pixel Art

> **El pipeline de resolución baja YA es la mayor optimización**. 320×180 son 57,600 fragmentos vs. 2,073,600 de 1080p. La GPU procesa 36× menos píxeles.

Reglas adicionales:
- Modelos: máx 600 triángulos para personajes, máx 200 para props
- Sombras: `directional_shadow_mode = 0` (Orthogonal, menos costoso)
- Partículas: máx 50 por sistema
- Luces: preferir luz direccional + 2 point lights máximo por sala
- NavMesh: desactivado para beta (movimiento directo)
- LOD: no necesario a esta escala de distancias

---

## FASE 15 — Vertical Slice (objetivo de la beta)

### Checklist de beta funcional

**Jugabilidad:**
- [ ] Player se mueve con WASD, dash funciona (Space, 3 cargas)
- [ ] Melee con Click izquierdo, arco y lunge visible
- [ ] Enemies aparecen, persiguen al player, atacan
- [ ] Hackeo (E) funciona: pausa, muestra secuencia, self-termina
- [ ] Player muere → reload de escena
- [ ] Fragmentos se acumulan entre runs

**Visual:**
- [ ] Shader cel activo con ramp textures asignadas al player
- [ ] Shader cel activo en enemigos con ramp diferente
- [ ] Outline activo con silhouettes y creases visibles
- [ ] Pipeline pixel art 320×180 sin shimmering
- [ ] HUD visible: HP, Ciclos, Dash charges, Fragmentos

**Narrativa:**
- [ ] Al iniciar: reflexión del MC desde GameManager
- [ ] Al entrar al bioma: monólogo diagnóstico del MC
- [ ] Al hackear: secuencia de 3 líneas con pausa de juego

**Pendientes post-beta:**
- [ ] Animaciones del MC (idle, run, attack)
- [ ] VFX de dash, hit flash, hackeo
- [ ] El Nodo Muerto (hub entre runs)
- [ ] NavMesh para pathfinding real de enemigos
- [ ] Bioma visual completo (tiles, assets del entorno)
- [ ] Menú principal con slots de guardado estilo terminal
- [ ] Escena de introducción (run 0, una sola vez)
- [ ] Arma de rango (gun con munición)
- [ ] Boss room con miniboss hackeables

---

## FASE 16 — Pipeline Completo Resumido

```
1. GODOT (ya hecho)
   └── Abrir proyecto IArogue3D Godot/
       └── Asignar ramp textures al player y enemigos
       └── Activar OutlineEffect (MeshInstance3D con QuadMesh 2000×2000)
       └── Ejecutar → verificar que corre sin errores

2. ASSETS
   └── Descargar Kenney Robot Pack → assets/characters/placeholder/
   └── Descargar Kenney Sci-Fi RTS → assets/world/kenney_scifi/
   └── Importar GLBs como MeshInstance3D en las escenas

3. BLENDER (opcional para arte propio)
   └── Crear MC low-poly según especificaciones de la biblia
   └── Crear Enemigo Regulado
   └── Export → GLB → importar en Godot
   └── Mixamo para animaciones → FBX → Blender → GLB → Godot

4. ANIMACIONES
   └── AnimationPlayer + AnimationTree en player.tscn
   └── Estados: idle / run / attack / dash / death

5. POLISH
   └── Fuente terminal para HUD
   └── VFX de dash y combat
   └── El Nodo Muerto

6. VERTICAL SLICE
   └── Verificar checklist completo de la FASE 15
```

---

## Correcciones al Documento Original

| Punto original | Corrección |
|---|---|
| "Resolución inicial 1280×720" | Incorrecto. El pixel art requiere SubViewport 320×180 desde el día 1, no después. Retrofit imposible sin rehacerlo todo. Ya implementado. |
| "Shader de pixelación" | Incorrecto. No es un shader que pixela — es un SubViewport a baja resolución real. El `upscale_and_offset.gdshader` mantiene píxeles nítidos al escalar. |
| "FASE 4 Anti-shimmering como fase separada" | Ya está resuelto automáticamente en el shader (`sharp_sample` + `fwidth`) y en `pixel_camera_rig.gd` (`snappedf`). No hay que hacer nada. |
| "NavigationAgent3D para enemigos" | Para beta: movimiento directo es suficiente y más simple. NavigationAgent3D requiere bake de NavMesh por sala — agregar en post-beta. |
| "Outline: opcional" | No es opcional. Define la estética del juego completo. Sin outline, la geometría low-poly se pierde en el fondo del bioma. |
| "FASE 10 Spawner alrededor del jugador" | Incorrecto para este tipo de juego. IA ROGUE es un roguelike de salas — los enemigos spawnan dentro de salas específicas al activarlas, no alrededor del jugador en open world. |
| "Fase 2: cámara entre 30° y 45°" | Implementado a 45° exacto (isométrico). La cámara es ortográfica (projection=ORTHOGRAPHIC), no perspectiva — esto es lo que da el look pixel art 2D-en-3D. |
