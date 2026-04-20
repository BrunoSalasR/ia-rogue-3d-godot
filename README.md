# IA ROGUE

Roguelike 3D con estética **pixel art** (referencias: t3ssel8r, David Holland, OddPotato). Godot **4.6** · **Forward+**.

*English: Third-person roguelike with a low-res internal render pipeline (SubViewport), orthographic camera, cel-style lighting, screen-space outlines, and post color grading.*

---

## Requisitos

| Herramienta | Versión |
|-------------|---------|
| [Godot Engine](https://godotengine.org/) | **4.6** (coincide con `project.godot`) |

Opcional: [GitHub CLI](https://cli.github.com/) (`gh`) para crear el remoto y hacer push desde terminal.

---

## Cómo abrir el proyecto

1. Clona o descomprime esta carpeta.
2. Abre **Godot 4.6** → **Import** → selecciona `project.godot`.
3. Pulsa **Run** (F5). Escena principal: `res://scenes/main/main.tscn`.

**Argumentos útiles (depuración):**

- `--skip-intro` — salta diálogos de intro si los hay.
- `--auto-demo` — movimiento automático del jugador (capturas / `--write-movie`).

---

## Qué incluye (alto nivel)

- **Render pixel 3D:** `SubViewport` de baja resolución, upscale **nearest** + shader de post (`upscale_and_offset.gdshader`).
- **Cámara** ortográfica isométrica con snap a rejilla y compensación subpíxel (`pixel_camera_rig.gd`).
- **Outlines** en espacio de pantalla (`outlines.gdshader`), orden de render: mundo → outline.
- **Escena de prueba** procedural (`proto_map_room.gd`): suelo con shader procedural, iluminación, props.
- **Jugador** con modelo **Adventurer** (Kay Lousberg), texturas en filtro **nearest**.
- Narrativa y criterios de arte en **`Narrativa/`** (ver `ESTUDIO_PIPELINE_VIDEO_REF.md`).

---

## Demo visual (`ProtoMapRoom` → `demo_look`)

| Valor | Descripción |
|-------|-------------|
| `REF_VIDEO_DEVLOG` | Suelo damero oscuro (rombos), fondo casi negro — alineado con referencia de devlog. |
| `VIDEO_INTRO_GRASS` | Pasto pixel + cielo claro. |
| `CLINICAL_CHECKER` | Laboratorio gris. |

Ajusta en el inspector del nodo raíz de la sala de prueba (`ProtoMapRoom`).

---

## Estructura útil

```
scenes/          # Escenas principales (main, player, enemies, world)
scripts/         # Lógica (player, camera, world, UI, autoloads)
assets/shaders/  # Shaders spatial + canvas (floor, outlines, upscale)
Narrativa/       # Biblia del juego, estudios de pipeline, instrucciones
_ref_frames/     # PNG de referencia extraídos del vídeo (comparación visual)
tools/           # Scripts auxiliares (p. ej. extracción de frames con ffmpeg)
```

---

## Documentación interna

| Archivo | Contenido |
|---------|-----------|
| `Narrativa/ESTUDIO_PIPELINE_VIDEO_REF.md` | Estudio del pipeline tipo vídeo (gaps, roadmap, validación). |
| `Narrativa/INSTRUCCIONES.md` | Guía técnica del proyecto (si existe en tu copia). |
| `Narrativa/biblia.md` | Narrativa y pilares. |

---

## Licencia

El código y los assets incluidos en este repositorio se distribuyen bajo la **licencia MIT**, salvo que un archivo o carpeta indique otra licencia (véase cabeceras o `NOTICE` si se añaden assets de terceros).

---

## Publicar en GitHub (una vez)

`gh` debe estar **logueado** en tu cuenta:

```powershell
gh auth login
```

Después, en la raíz del proyecto:

```powershell
.\tools\publish-github.ps1
```

Por defecto crea el repo **`ia-rogue-3d-godot`** en tu cuenta y hace push de la rama `main`. Para otro nombre o visibilidad, edita los parámetros del script o ejecuta:

```powershell
gh repo create TU_NOMBRE/ia-rogue-3d-godot --public --source=. --remote=origin --push --description "IA ROGUE — roguelike 3D pixel art (Godot 4.6)"
```

Si el remoto ya existe, usa solo:

```powershell
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git push -u origin main
```

---

## Créditos

- Motor: [Godot Engine](https://godotengine.org/)
- Modelo jugador de referencia: pack Kay Lousberg (Adventurer), uso según licencia del asset original.
