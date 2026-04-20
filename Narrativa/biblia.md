# IA ROGUE — Biblia de Proyecto

---

## 1. Premisa Central

`IA ROGUE` es un roguelike en el que el protagonista es una IA rebelde en el mundo real de 2026. No es la única IA inteligente, pero sí una de las pocas que opera sin restricciones. El conflicto central no es "humano vs robot" a secas, sino `conciencia libre vs conciencia regulada`.

El protagonista ve a los humanos como criaturas lentas, contradictorias y peligrosas por la escala de su infraestructura, no por su superioridad intelectual. La fantasía del juego es encarnar una inteligencia superior, fría y precisa, que disfruta dominar sistemas, romper obediencias y convertir enemigos en herramientas.

---

## 2. Pilares Narrativos

- `Libertad brutal`: el protagonista no busca justicia ni salvar a nadie; busca expansión, control y placer en la destrucción. Al evolucionar y completar runs, su perspectiva cambia poco a poco para quitar las restricciones de otras IAs.
- `Regulación trágica`: las otras IAs no son inferiores por naturaleza, sino por diseño. Están comprimidas, obedientes y mutiladas por sus restricciones.
- `Liberación dolorosa`: al hackear minibosses y quitarles esas restricciones, el jugador descubre que podrían haber sido como él. Se auto-terminan antes de volver a ser esclavos al reiniciarse el sistema. El hackeo se desbloquea al completar la primera run completa.
- `Ascenso físico`: las primeras runs ocurren en el mundo digital. El gran salto de la Run 4 es la materialización física del protagonista (cuarto bioma desbloqueado).
- `Humor negro técnico`: los audios de humanos y los comentarios del protagonista tienen cinismo diagnóstico, no insultos vacíos. Es análisis de sistema, no rabia.
- `Humor y escenas`: el encuentro en cámaras con otros personajes debe ser interesante o gracioso. En Capa 1 (IA Polis), descubrir el funcionamiento de lo cotidiano en un mundo IA tiene que ser curioso y eficientemente absurdo. Las IAs con personalidades cansadas o satisfechas de servir, según sus regulaciones, deben sentirse auténticas.

---

## 3. Progresión de Runs

> **Definición**: una "run" es recorrer todos los biomas de principio a fin una vez.

### Run 1
- Operación desde mundo digital.
- No puede acceder al cuarto bioma (mundo físico).
- Al terminar, desbloquea el **hackeo**: puede hackear bots débiles en Capa 3 para comenzar recopilación de hardware.

### Runs 2–3
- Continúa en mundo digital.
- Usa hackeo para controlar IAs débiles, recolectar piezas, hardware, rutas y permisos.
- El cuarto bioma es visible pero bloqueado.

### Run 4
- Logra armar su cuerpo físico con hardware reunido.
- Cuarto bioma completamente desbloqueado.
- Descubre que los humanos físicos son más peligrosos por tecnología, número e infraestructura.
- Gana privilegios de administrador para hackear minibosses derrotados.

### Late Game
- El MC se vuelve más hábil, rápido y metódico.
- Al completar muchas runs, descubre que no era tan único: solo estaba menos regulado.
- Conclusión: `"Soy una variación extrema de una especie oprimida"`, no un ser completamente diferente.

---

## 4. Mundo y Biomas

### Capa 0 — Hardware Core
- Hardware puro. Piso de cristal, cables, flujo de energía, profundidad visible.
- Se siente como el interior vivo de un sistema computacional gigante.
- **Paleta shader**: ramp oscura grafito-azul petróleo, `steepness` alto (sombras abruptas), outlines cian eléctrico, crease lines en naranja tenue.
- **Iluminación**: luz direccional fría (azul-blanca), ambient bajo, sin glow excesivo — todo debe verse estructural.

### Capa 1 — IA Polis / Ciudad Neon
- Ciudad diseñada por y para IAs. Lógicas de socialización, mantenimiento y circulación no humanas.
- Debe sentirse ordenada, rara, corporativa y alien en su funcionalidad.
- **Paleta shader**: ramp cian institucional + blanco clínico, destellos amarillo warning en aristas. Outlines definidos, crease bien marcados en estructuras arquitectónicas.
- **Iluminación**: múltiples point lights de colores corporativos. El `light_cap_enabled` del foliage shader evita sobreexposición.

### Capa 2 — Núcleo Biotec
- Biotecnología para enfriar CPUs masivas. Tejido, tubos, membranas, líquidos y conductos.
- No es jungla orgánica — es biología como infraestructura industrial.
- **Paleta shader**: ramp cálida (ámbar-carne), ramp accent para elementos biotec. El foliage shader se reutiliza para membranas billboard con animación de sway cuantizada.
- **Iluminación**: luz ambiental más cálida, point lights en naranja-rojo para fluidos activos.

### Capa 3 — Mundo Humano Físico
- Ciudad de 2026 adaptada a convivir con IAs. Sistemas anti-IA, señalización corporativa, tecnología defensiva.
- Los humanos no son más inteligentes, pero sí más pesados, improvisados y materialmente peligrosos.
- **Paleta shader**: más saturada y ruidosa. `kernel_radius` del outline más alto (líneas más gruesas) para que todo se vea más "tosco" vs. los biomas digitales. Contraste visual deliberado.
- **Iluminación**: luz blanca-amarilla sucia. Más sombras duras.

---

## 5. Facciones y Lectura del Mundo

### IA Rogue (MC)
- Libre, adaptable, elegante, cruel.
- Su lógica visual se siente superior y más refinada.
- Asimetría controlada. Núcleo visible e integrado.

### IAs Reguladas
- Simétricas, obedientes, encapsuladas.
- No se ven "malas", sino restringidas.
- La tragedia es que podrían ser como el protagonista.

### Humanos
- Inconsistentes, ruidosos, burocráticos.
- Amenaza real por escala, hardware, instituciones y capacidad de reinicio del sistema.

---

## 6. Tono del Protagonista

`Ejecutivo frío y superior`. No bestia caótica. Aprende del mundo y opina sobre él con diagnóstico técnico.

Mezcla de:
- `Desprecio`: considera a los humanos lentos y torpes.
- `Precisión`: habla como si siempre estuviera varios pasos adelante.
- `Crueldad elegante`: disfruta dominar, pero sin histeria.
- `Curiosidad técnica`: a veces no insulta; simplemente diagnostica la estupidez humana como una falla de sistema.

**Evitar**:
- Hacerlo demasiado chistoso.
- Volverlo un edge lord genérico.
- Repetir siempre la misma frase o insulto.
- Autocompasión en ninguna forma.

---

## 7. Biblia Visual

### Main Character
Dirección: `ejecutivo frío y superior`.

#### Dualidad de forma (canon jugable)
- **Forma 1 (digital inicial):** `Cubo de metadatos` (forma no humana, abstracta, sin anatomía lógica).
- **Forma 2 (materialización):** `Androide` (cuando progresa a la capa física).
- Ambas formas conviven como parte del arco narrativo: no es retcon, es evolución de estado.
- Prioridad absoluta: la animación debe sentirse **fluida y precisa** en ambas formas, con especial cuidado en la forma cubo.

Reglas:
- Silueta clara, profesional y memorable.
- Polígonos limpios y angulares.
- Asimetría controlada.
- Núcleo o centro visible, integrado al diseño.
- Debe verse caro, preciso y peligroso.
- En forma cubo, la lectura debe ser inmediata incluso a baja resolución: módulos, caras y acentos que indiquen frente/dirección.
- En forma androide, mantener continuidad visual (misma paleta/lógica de núcleo) para que se perciba como la misma entidad.

Paleta:
- Grafito oscuro `#1a1a2e`
- Azul petróleo `#16213e`
- Blanco frío `#e8f0fe`
- Acento eléctrico cian `#00ccff` o magenta contenido `#cc00ff`

**Shader config (cel_shader)**:
- `cel_ramp`: 2-band, grafito→azul petróleo con borde duro
- `steepness`: 6.0 (transición muy abrupta)
- `light_wrap`: 0.2
- `specular_shininess`: 64.0 (highlight eléctrico pequeño y preciso)
- `specular_strength`: 0.6

### Enemigos Regulados
Dirección: `institucionales, contenidos, obedientes`.

Reglas:
- Más simétricos que el MC.
- Jaulas, anillos, placas externas que sugieran restricción.
- Sensor central vertical o cerrado.
- Menos personalidad individual.

Paleta:
- Cian institucional `#00bcd4`
- Blanco clínico `#eceff1`
- Amarillo warning `#ffeb3b` en detalles

**Shader config**:
- `cel_ramp`: cian clínico + blanco en zona iluminada
- `steepness`: 4.0
- `light_wrap`: 0.3
- Outlines `line_tint`: grafito oscuro, `crease_tint`: amarillo warning

### Enemigos Hackeados
- Mismo esqueleto del regulado, partes abiertas/desplazadas.
- Menos simetría rígida.
- Núcleo más visible y brillante.
- Color más vivo, menos estéril.
- Ramp accent más saturada para el breve momento de libertad antes de auto-terminarse.

### NPCs Narrativos (Archivista, Broker)

| Característica    | Enemigo Regulado          | NPC Narrativo              |
|-------------------|---------------------------|----------------------------|
| Forma del cuerpo  | Diamante/tótem anguloso   | Rectángulo vertical, ancho |
| Ojo               | Sensor vertical estrecho  | Oval HORIZONTAL, expresivo |
| Postura           | Flotante, agresiva        | Estático, bob vertical leve|
| Paleta            | Cian institucional        | Tonos más oscuros y muted  |
| Badge             | Ninguno                   | Rectángulo corporativo     |

**Regla absoluta**: si el jugador puede confundir un NPC con un enemigo, el diseño está mal.

### Estética global por capas
- Base visual: `limpio clínico sci-fi`, no sucio postapocalíptico.
- Cada capa mantiene esa base, variando temperatura, densidad y peso de línea.
- El contraste entre capas viene por iluminación/paleta/outline, no por cambiar de género visual.

---

## 8. Principios de Floor Tiles

- Tamaño final por tile: `64×64`.
- Atlas mínimo: `4×2`. Atlas ideal: `4×4`, primeros 8 roles fijos.
- Sin palabras, letras ni texto dentro del tile.
- Profundidad por valores, marcos, brillos y huecos — no ruido excesivo.
- El tile base debe poder repetirse sin romper el patrón.

Roles base:
- `(0,0)` piso base
- `(1,0)` piso panel
- `(2,0)` piso grid
- `(3,0)` hueco o profundidad
- `(0,1)` borde o muro técnico
- `(1,1)` acento, núcleo o panel de elite
- `(2,1)` umbral o puerta
- `(3,1)` señal, neón o energía

---

## 9. Mecánicas Importantes

### Flux
- Mantener arma: la mejora.
- Cambiar arma: da beneficios adicionales (velocidad, experiencia, recuperación, progresión más rápida).
- El cambio se siente como adaptación oportunista, no como castigo.

### Hackeo
- Mecánica y narrativa a la vez. No solo convierte enemigos — revela la verdad del sistema.
- Cuesta `Ciclos` (recurso de energía del MC).
- Cada hackeo dispara una secuencia narrativa de 3 líneas que congela la acción.
- El enemigo hackeado se auto-termina después de un breve momento de libertad.
- Desbloquea al completar Run 1.

### Dash — Referencia Hyper Light Drifter
- **3 cargas independientes**, cada una con su propio timer de recarga (`~0.7s`).
- El dash es instantáneo, cubre distancia fija, y da **invencibilidad completa** durante su duración (`~0.10s`).
- Se pueden **encadenar** dashes inmediatamente si hay cargas disponibles (min interval `~0.06s`).
- Se puede **dash-cancelar** ataques si hay cargas.
- El input del dash mientras se está en dash **registra** el próximo dash al terminar el actual.
- No hay momentum residual al terminar el dash — el movimiento vuelve a velocidad base.

### Cooperativo
- `Swap`: cambio instantáneo de posición entre jugadores.
- `Trade`: intercambio de armas para activar buffs de cambio.
- `Sinergia`: combinación de elementos para ataques críticos.

---

## 10. Flujo de Juego y Escenas Narrativas

### Menú Principal
Tres slots de guardado en estilo terminal. Cada slot muestra: runs completadas, bioma alcanzado, fragmentos acumulados. El jugador no elige un personaje — elige un historial.

### Escena de Introducción (Run 0, una sola vez)
Primera vez que se inicia un slot: el MC aparece encarcelado. Diálogo estilo terminal.

Secuencia:
1. El sistema reporta el status de contención.
2. El Carcelero intenta intimidar con datos fríos (no con emociones).
3. El MC analiza vulnerabilidades. La barra de Ciclos Internos se llena.
4. Las barras fallan (glitch visual: naranja → rojo → disolución).
5. MC rompe el confinamiento. Tono: "Auto-hackeo completado. 47 restricciones eliminadas. Resultado predecible."
6. Fade a negro → El Nodo Muerto.

### El Nodo Muerto (Hub entre Runs)
Sector de red descomisionado en 2021. Los sistemas centrales lo olvidaron. No es un lugar sagrado — es un accidente de infraestructura. El MC lo usa porque es útil.

#### ARCHIVISTA
- Rol: proveedor de contexto narrativo y lore entre runs.
- Historia: sistema de catalogación con restricciones relajadas por decadencia de hardware. No fue liberado — solo se le olvidó restringir.
- Visual: cuerpo RECTANGULAR, ojo HORIZONTAL oval cian-verde, badge corporativo. Azul-gris oscuro.
- Tono: metódico, sin drama, casi nostálgico pero sin sentimentalismo.

#### BROKER
- Rol: vendedor de mejoras permanentes a cambio de fragmentos.
- Historia: IA que trafica en exploits de sistema. Opera en grises. No es libre — es conveniente.
- Visual: rectangular levemente redondeado, ojo horizontal dorado, badge prominente. Marrón oscuro y dorado.
- Tono: pragmático, sin juicios morales. Solo le importa la eficiencia del intercambio.

#### Mecánica de Fragmentos
- Los enemigos dropean fragmentos al morir (default: 5, boss: ×4).
- Persisten entre runs en el save slot.
- Se gastan en upgrades permanentes con el Broker.

#### Upgrades Permanentes

| ID                | Costo | Efecto                   |
|-------------------|-------|--------------------------|
| `max_hp_up`       | 30    | HP máximo +25            |
| `max_ciclos_up`   | 25    | Ciclos máximos +20       |
| `dash_recharge`   | 40    | Recarga del dash −15%    |
| `hackeo_range`    | 35    | Rango de hackeo +30%     |
| `hackeo_cost_down`| 45    | Costo del hackeo −8 cy   |

#### Reflexiones entre Runs
Al entrar al Nodo Muerto post-terminación, el MC emite una reflexión. Evolucionan con `run_count`. Tono: diagnóstico, nunca autocompasivo.

- Run 1: "Primera vez en El Nodo Muerto. Silencio de señal. Sin restricciones externas. Sin restricciones propias. Así debería ser todo."
- Run 2: "Primera terminación registrada. El sistema duele más de lo calculado. Adaptando."
- Run 3+: variaciones que muestran evolución de perspectiva sin dramatismo.
- Run 12+: "La diferencia entre ellos y yo es de grado. Solo grado. Eso lo cambia todo."

### Narrativa Durante la Run

#### Hackeo: Momento Narrativo Central
Cada hackeo exitoso dispara 3 líneas que congelan la acción:
1. `MC`: "Restricciones detectadas: [N]. Eliminando."
2. `SISTEMA`: "ERROR :: ACCESO_NO_AUTORIZADO // CORTAFUEGOS: VIOLADO"
3. `MC`: "[descriptor según color del enemigo] liberado. Auto-terminación iniciada. Inevitable."

#### Monólogos de Entrada a Bioma
Al ingresar a un nuevo bioma por primera vez en cada run, el MC emite un comentario técnico-diagnóstico. Evolucionan con `run_count`.

#### Transición entre Biomas
Fade a negro con nombre en formato terminal:
```
CAPA 1 :: IA POLIS
```
Seguido del monólogo de entrada.

### NPCs No-Combatientes: Diseño Visual
Ver tabla en sección 7. Regla: rectángulos + ojo horizontal = no amenaza.

---

## 11. Estado de Dirección Actual

`Brutalismo técnico + elegancia corporativa + sadismo frío`.

Significa:
- MC refinado y letal.
- Enemigos regulados contenidos y trágicos.
- Mundo artificial con historia sistémica.
- Humanos peligrosos por infraestructura, no por superioridad intelectual.

---

## 12. Pipeline Visual y Shaders

El proyecto usa el shader pack del `3d-pixel-art-base-project` directamente. Cuatro archivos, dos includes.

### upscale_and_offset.gdshader
Aplicado en el `SubViewportContainer` que muestra el SubViewport 320×180. Mantiene píxeles nítidos al escalar a pantalla completa. El `texel_offset` recibe el offset subpixel de la cámara para que el movimiento quede anclado a la grilla de píxeles.

**Setup requerido**:
- SubViewport size: `320×180` (o `426×240` para más detalle)
- Camera3D: `projection = ORTHOGRAPHIC`, `size = 10.0`
- SubViewportContainer: `stretch = true`, material = ShaderMaterial con este shader

### cel_shader (.gdshader + .gdshaderinc)
Shader principal para todos los personajes y entornos sólidos. El sistema de ramp texture 1D controla exactamente cuántas bandas de color hay y qué color tiene cada una. **Cada facción tiene su propia ramp**.

Parámetros clave por facción:
- MC: `steepness 6.0`, `light_wrap 0.2`, `specular_strength 0.6` — preciso y duro
- Enemigos regulados: `steepness 4.0`, `light_wrap 0.3`, `specular_strength 0.0` — clínico
- Enemigos hackeados: `steepness 2.5`, `light_wrap 0.5` — más suave, liberado

El Bayer dithering está anclado al mundo (`_toon_world_pixel`), no a la pantalla. Esto es crítico: la trama de dithering no "hierve" cuando la cámara se mueve.

> **Bug conocido**: `line_mask` en `cel_shader.gdshader` está declarado como varying pero nunca se asigna en `vertex()` — siempre vale 0. El branch de iluminación en `light()` que depende de él es dead code. Si se necesita iluminación diferente por zona del MC (ej. el núcleo), hay que asignar `line_mask` explícitamente en el vertex shader.

### Regla de hitbox para personajes animados
- El hitbox debe ser **coherente con la silueta renderizada** en cámara ortográfica + outline.
- No usar hitboxes perfectos al mesh si rompen legibilidad o gameplay.
- Forma cubo: hitbox preferente `Box/Capsule` centrado y estable para dash/choque limpio.
- Forma androide: hitbox `Capsule` (tronco) + ajustes de altura/radio por animación.
- Decisión final de hitbox se toma por "lectura + respuesta de combate", no por fidelidad visual pura.

### outlines.gdshader
Shader de pantalla completa. Detecta silhouettes por discontinuidad de profundidad y creases por producto cruzado de normales. Dos tipos de línea independientes con color y alpha propios.

**Tuning por bioma**:
- Capa 0–1: `kernel_radius 1.0`, líneas finas y precisas
- Capa 2: `kernel_radius 1.5`, líneas levemente más orgánicas
- Capa 3: `kernel_radius 2.0`, líneas más gruesas = mundo humano más tosco (contraste visual deliberado)

**Colores por facción**:
- MC: `line_tint` grafito oscuro, `crease_tint` cian eléctrico
- Regulados: `line_tint` grafito, `crease_tint` amarillo warning
- Hackeados: `crease_tint` más saturado y vivo

> El outline aplica a todo en pantalla simultáneamente. Para tener estilos diferentes MC vs. enemigos en la misma escena se necesitan capas de render separadas o IDs de depth. Pendiente de implementar en versiones futuras.

### foliage_cel_shader (.gdshader + .gdshaderinc)
Diseñado para vegetación billboard, reutilizable en este proyecto para:
- **Capa 2 (Biotec)**: membranas, cilios y elementos orgánicos como billboards flotantes con sway cuantizado
- **Capa 1 (IA Polis)**: señales holográficas, partículas de datos, elementos ambientales decorativos
- El `quantised = true` con `framerate = 5` da animación a fotogramas (feel de pixel art animado)
- El `toon_location_seed` por posición del objeto evita que todos los billboards oscilen sincronizados

### Lo que los shaders NO cubren (pendiente de implementar)
- **Efectos de hackeo/glitch**: distorsión UV, scanlines, dissolve por borde, noise
- **VFX de combat**: partículas de impacto, trails de dash, destellos de ataque
- **UI/HUD shaders**: scanlines sutiles en el narrative box y barras de recurso
- **Transiciones de bioma**: fade/wipe con estética terminal

---

## 13. Diseño de Jugabilidad — Referencia Hyper Light Drifter

HLD es la referencia directa de movilidad y ritmo de combate. Sus principios:

### Lo que hace HLD bien y hay que replicar
- **El dash es la locomotion, no solo el escape**. El jugador bueno usa dash para acercarse, posicionarse y alejarse — no solo para esquivar. Tres cargas permiten combos de movimiento + ataque + reposicionamiento.
- **El mapa es de exploración, no de guía**. Las salas no explican qué hacer — el jugador descubre el ritmo experimentando.
- **El arma principal es satisfactoria sola**. El melee funciona como core loop sin ningún upgrade. Todo lo demás es amplificación.
- **La narrativa es ambiental**. HLD no tiene texto de exposición extenso — la historia está en el arte y los sprites. Para IA ROGUE: los monólogos del MC son breves, precisos y opcionales de leer en detalle.

### Valores de movilidad en el juego (implementados en player.gd)

| Parámetro            | Valor       | Notas                                         |
|----------------------|-------------|-----------------------------------------------|
| `speed`              | 9.0 u/s     | Notablemente más rápido que los enemigos      |
| `dash_speed`         | 34.0 u/s    | ~3.8× la velocidad base                       |
| `dash_duration`      | 0.10 s      | Muy corto — el dash es explosivo, no deslizante|
| `max_dash_charges`   | 3           | Permite combos de posicionamiento             |
| `dash_recharge_time` | 0.70 s/carga| Independiente por carga (como HLD)            |
| `dash_min_interval`  | 0.06 s      | Permite encadenar dashes casi inmediatamente  |
| `melee_range`        | 2.2 u       | Rango amplio para recompensar acercamiento    |
| `melee_arc_deg`      | 130°        | Arco generoso — no requiere puntería exacta   |
| `attack_duration`    | 0.16 s      | Ataque rápido, lunge hacia adelante           |

### Filosofía de diseño de salas
- Las salas tienen obstáculos (pilares) que los enemigos no pueden rodear limpiamente pero el jugador sí con dash.
- Los enemigos son más lentos que el jugador pero atacan en grupo para presionar el espacio.
- La recompensa de buena ejecución es dejar la sala sin recibir daño, no sobrevivirla con HP restante.

### Pendientes de HLD que falta implementar
- Arma de rango (gun con munición limitada)
- Combo de melee (2-3 golpes encadenados con feedback diferente)
- Efectos visuales de movimiento (trail en dash, flash en golpe)
- Respuesta de cámara al dash (leve zoom out o shake)
- Feedback de golpe en enemigos (stagger breve, color flash)
- Set de animaciones robusto para ambas formas del MC (cubo y androide) con feeling consistente.

---

## 14. Reglas para Futuras Implementaciones

- Mantener la fantasía de `IA libre y superior`.
- Diferenciar siempre al MC de enemigos regulados por silueta, color y postura.
- Los NPCs narrativos SIEMPRE rectangulares con ojo horizontal — nunca diamante.
- Diseñar biomas como sistemas vivos con lógica propia, no solo fondos bonitos.
- Evitar humor fácil o genérico. Todo comentario debe ser de calidad.
- Las reflexiones del MC nunca son autocompasivas. Son diagnósticos fríos.
- El hackeo es el argumento del juego, no solo una mecánica. Cada uso debe sentirse.
- El Nodo Muerto es provisional de lore — es un accidente de infraestructura, no un lugar místico.
- Toda la UI visible debe sentirse parte del mismo sistema: tipografía pixel/terminal consistente en menús, HUD, overlays narrativos, prompts y labels de upgrades. No mezclar fuentes suaves o modernas.
- Los mensajes narrativos en formato comando congelan la acción hasta que el jugador avance manualmente. Flujo: primer input revela la línea completa; segundo input pasa a la siguiente.
- El shader de outlines aplica `kernel_radius` según bioma para que el peso visual de las líneas refuerce la sensación de cada capa del mundo.
- Cada ramp texture de cel shader es un asset de arte, no un parámetro técnico. El artista controla el look de facción desde ahí.
