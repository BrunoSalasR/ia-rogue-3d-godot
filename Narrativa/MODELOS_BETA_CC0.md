# IA ROGUE - Shortlist de modelos beta (CC0)

Objetivo: integrar rapido modelos animados para probar jugabilidad, manteniendo estilo clinico sci-fi y lectura clara en 320x180.

---

## 1) Estrategia recomendada

Orden de uso:

1. Placeholder funcional inmediato (siempre jugable)
2. Modelo cubo animado (forma digital)
3. Modelo androide animado (forma materializada)
4. Enemigo regulado animado

Regla: nunca romper gameplay por perseguir arte.

---

## 2) Fuentes sugeridas (prioridad)

- [Poly Pizza](https://poly.pizza/) (buscar autor Quaternius y tag animated)
- [Kenney](https://kenney.nl/assets) (placeholder y mundo modular)
- [Mixamo](https://www.mixamo.com/) (animaciones adicionales para rig humanoide)

Licencia objetivo para beta: CC0 o equivalente libre para prototipo.

---

## 3) Queries practicas para buscar rapido

### MC cubo (forma digital)

Buscar en Poly Pizza:

- `quaternius robot animated`
- `floating drone animated`
- `cube robot`
- `sentinel low poly animated`

Criterio:

- silueta simple (macroformas)
- lectura del frente visible
- pocas piezas finas que desaparezcan en pixel scale

### MC androide (forma materializada)

Buscar:

- `quaternius android animated`
- `quaternius sci fi character animated`
- `low poly humanoid animated`

Criterio:

- idle/run/attack visibles
- volumen claro en torso y hombros
- rig humanoide compatible con Mixamo

### Enemigo regulado (clinico sci-fi)

Buscar:

- `quaternius guard animated`
- `robot guard animated`
- `security bot animated`

Criterio:

- simetrico, institucional
- menos carisma visual que el MC
- silueta distinta al MC

---

## 4) Estructura drop-in en el proyecto

```
assets/
└── characters/
    └── placeholder/
        ├── mc_cube/
        │   ├── mc_cube.glb
        │   └── anim/
        ├── mc_android/
        │   ├── mc_android.glb
        │   └── anim/
        └── enemy_regulated/
            ├── enemy_regulated.glb
            └── anim/
```

Animaciones minimas:

- MC cubo: idle, run, dash, attack, death
- MC androide: idle, run, dash, attack, death
- enemigo: idle, run, attack, death

---

## 5) Integracion ya preparada en codigo

`player.gd` ya permite cargar dos modelos:

- `cube_model_scene`
- `android_model_scene`

Y elegir con:

- `start_form = "cube"` o `start_form = "android"`

Mientras no asignes PackedScenes, usa el mesh placeholder actual.

---

## 6) Import settings recomendados (Godot)

- Root type: Node3D
- Generate tangents: ON
- Import animations: ON
- Remove immutable tracks: ON
- Mesh compression: OFF para pruebas iniciales

---

## 7) Decision de hitbox

No alinear hitbox al detalle del mesh. Alinearlo al gameplay:

- cubo: box/capsule compacta centrada
- androide: capsule de torso

Se ajusta por lectura de combate, no por precision visual absoluta.
