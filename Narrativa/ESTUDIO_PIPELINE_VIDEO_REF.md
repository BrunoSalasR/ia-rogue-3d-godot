# Estudio profundo: pipeline “video ref” (t3ssel8r / Holland / OddPotato) vs IA ROGUE

Este documento no busca “parecerse un poco”: define **qué es** el estilo en términos técnicos, **qué tenemos**, **qué falta**, y **qué no se resuelve** solo moviendo sliders. La base teórica pública más alineada con el vídeo que citas es el artículo de **David Holland** ([3D Pixel Art Rendering](https://www.davidhol.land/articles/3d-pixel-art-rendering/)), que explica explícitamente el trabajo de **t3ssel8r** y el pipeline que muchos confunden con “un filtro”.

**Frames de referencia:** en el repo, la carpeta `_ref_frames/` contiene PNG extraídos del vídeo del usuario (comando en `_ref_frames/README.md`). Úsalos para comparar con capturas `--write-movie` del proyecto.

---

## 1. Qué *es* el look (definición operativa)

No es “baja resolución + outlines”. Es la **superposición** de varias capas que deben cumplirse a la vez:

| Capa | Rol | Si falla, el juego “se ve 3D barato” |
|------|-----|--------------------------------------|
| **Muestreo interno** | Render 3D a un buffer pequeño (ej. 320×180, 426×240) con filtros **nearest** donde toca | Texturas suaves, “shimmer” al mover |
| **Cámara** | Posición **snapped** a la rejilla del mundo en **unidades = tamaño de píxel** + **compensación subpíxel** en post (offset UV) | “Crawl” de texturas, vibración de píxeles |
| **Iluminación** | Toon / bandas, sombras **legibles** a baja res; opcional ruido en normales (anti-popping) | Sombras borrosas o invisibles |
| **Outlines** | Detección **depth + normals**, vecinos 4-dir o kernel pequeño; convex vs silueta | Contornos gruesos, falsos positivos, o ausentes |
| **Post** | Upscale **nearest** (o nearest + grading controlado); cuantización **opcional** | Gradientes “HD” que rompen el pixel read |
| **Contenido** | Meshes **silueta clara**, UVs y texturas pensadas para **texel density** coherente | Modelos suaves + outline = “dibujo encima de plastilina” |

**Holland** insiste: no existe un único shader perfecto para todos los modelos y ángulos; hay que **ajustar por escena**.

---

## 2. Referencias públicas y qué aportan

- **David Holland (artículo):** outlines (depth/normals, convex), cámara snap + offset, toon, pasto (billboards, `LIGHT_VERTEX` / sombras), agua y *trade-offs* del pipeline transparente en Godot, volumetría costosa, partículas 2D pixel. Es la **hoja de ruta más cercana** a lo que describes.
- **OddPotato starter kit:** referencia de **proyecto Godot** (composición, materiales, viewport); sirve de benchmark de **integración**, no sustituye contenido propio.
- **Tu vídeo:** la fuente de verdad **estética**; sin frames extraídos no podemos medir contraste exacto, pero el checklist de arriba sigue siendo la herramienta de auditoría.

---

## 3. Auditoría honesta de IA ROGUE (estado técnico)

### 3.1 Lo que ya está alineado con el pipeline “serio”

- SubViewport interno + upscale en `SubViewportContainer` con shader **nearest** en UV.
- Cámara ortográfica + **snap** + **texel_offset** (`pixel_camera_rig.gd`).
- Outlines por pantalla (`outlines.gdshader`) con depth/normals y lógica tipo Holland (convex/crease).
- Materiales con **TEXTURE_FILTER_NEAREST** en personaje.
- Suelo procedural con bandas de luz en `light()` para sombras pixelables.

### 3.2 Bug / riesgo crítico corregido en código (abril 2026)

En `main.tscn`, el nodo **OutlineEffect** estaba **antes** que **GameWorld** en el árbol. En la práctica el mundo se dibujaba **encima** del paso de outline en muchas configuraciones, destruyendo la lectura “video ref”. El orden correcto es: **mundo primero, outline al final** (y material de outline con prioridad / profundidad coherentes).

### 3.3 Brechas reales (no se arreglan solo con “un shader más”)

Tomadas del artículo de Holland y de la práctica en Godot 4.x:

1. **Pasto / vegetación “como el vídeo”:** Holland usa **billboards**, sombras direccionales coherentes y a veces **acceso avanzado** a sombras / `LIGHT_VERTEX`. En Godot oficial esto es **factible** pero laborioso; parte del artículo menciona **límites del pipeline** y PRs concretas.
2. **Agua con refracción + outlines:** Los materiales que leen `screen_texture` / depth pueden caer en **transparent** y romper el orden; Holland describe el problema explícitamente.
3. **Volumetría tipo “god rays” barata:** Su implementación final es un **post costoso** (raymarching), no un `OmniLight3D` normal.
4. **Paridad 1:1 con Unity/t3ssel8r:** Distinto motor, distinto orden de passes; hay que **revalidar** cada efecto en Godot, no copiar parámetros.

---

## 4. Roadmap por fases (medible)

### Fase A — Paridad de **pipeline** (obligatoria)

- [ ] Orden de nodos: mundo → outline (hecho).
- [ ] Resolución interna **16:9 estándar** (p. ej. **320×180**) y `ortho_size` escalado para mantener **mismas unidades/píxel** que antes.
- [ ] **Glow** del `Environment` desactivado o casi cero en escena pixel (evita halos “HD”).
- [ ] Post: `posterize_mix` y `palette_steps` ajustados para **bloques de color** sin pulverizar el suelo en blanco puro.

**Criterio de éxito:** captura fija del personaje + suelo: bordes de sombra = **escalones** visibles, no gradiente suave.

### Fase B — Paridad de **contenido** “demo intro”

- [x] Suelo **pasto / exterior** procedural (`demo_look = VIDEO_INTRO_GRASS` en `proto_map_room.gd`: mismo shader de rejilla, colores verdes).
- [x] Cielo / ambiente coherentes (`_apply_demo_atmosphere()` ajusta `WorldEnvironment` + sol).
- [ ] Personaje con **silueta** legible a 320×180 (Kay + nearest + outlines; pendiente animación y props).

**Cambiar a laboratorio gris:** en el inspector del nodo `ProtoMapRoom`, `Demo Look` → `CLINICAL_CHECKER`.

**Criterio de éxito:** sin leer UI, un tercero dice “pixel 3D de escenario de prueba”, no “prototipo gris”.

### Fase C — **Arte** (donde está el techo de calidad)

- Animaciones **con intención** (idle/walk/dash) y **UV density** consistente.
- Set de props con **ángulos duros** (el outline premia geometría clara).

### Fase D — Efectos “Holland avanzado” (opcional, caro)

- Pasto billboard + sombras correctas.
- Agua / volúmenes según necesidad narrativa.

---

## 5. Cómo validar sin discutir “a ojo”

1. Misma resolución interna siempre al comparar.
2. Capturas PNG de la SubViewport **antes** del upscale y **después** (si depuras post).
3. `--write-movie` con movimiento lento: el **snap de cámara** debe eliminar crawl; si no, revisar `pixel_size` vs `ortho_size`.

---

## 6. Conclusión

Llegar al punto del **vídeo** no es un único parámetro: es **pipeline completo + contenido + orden de render + ausencia de efectos que suavicen**. Este documento debe usarse como **contrato** de implementación: cada PR de arte debería indicar qué filas del checklist de la sección 1 toca y cómo las valida.
