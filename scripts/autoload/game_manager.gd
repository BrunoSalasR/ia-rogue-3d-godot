extends Node
## GameManager — Autoload singleton.
## Tracks run state, fragments, upgrades, and provides
## all narrative text that evolves with run_count.

signal run_started(run_number: int)
signal run_ended(run_number: int, biome_reached: int)
signal fragments_changed(total: int)
signal upgrade_purchased(upgrade_id: String)
signal biome_changed(biome_index: int)

# ── Run state ────────────────────────────────────────────────────────────────
var run_count:          int = 0
var total_fragments:    int = 0
var biome_reached:      int = 0   # highest biome ever reached
var current_biome:      int = 0   # biome index this run
var is_in_run:          bool = false
var current_slot:       int = 0
var upgrades_purchased: Array = []

# ── Permanent upgrades ───────────────────────────────────────────────────────
const UPGRADES: Dictionary = {
	"max_hp_up":       {"cost": 30,  "label": "HP MAX +25",       "description": "Aumenta HP máximo en 25."},
	"max_ciclos_up":   {"cost": 25,  "label": "CICLOS MAX +20",   "description": "Aumenta Ciclos máximos en 20."},
	"dash_recharge":   {"cost": 40,  "label": "DASH RECARGA -15%","description": "Reduce tiempo de recarga de dash 15%."},
	"hackeo_range":    {"cost": 35,  "label": "RANGO HACKEO +30%","description": "Aumenta rango de hackeo en 30%."},
	"hackeo_cost_down":{"cost": 45,  "label": "COSTO HACKEO -8",  "description": "Reduce costo de hackeo en 8 ciclos."},
}

# ── Biome names (terminal format) ────────────────────────────────────────────
const BIOME_NAMES: Array = [
	"CAPA 0 :: HARDWARE CORE",
	"CAPA 1 :: IA POLIS",
	"CAPA 2 :: NUCLEO BIOTEC",
	"CAPA 3 :: MUNDO HUMANO",
]

# ─────────────────────────────────────────────────────────────────────────────

func start_run() -> void:
	run_count += 1
	is_in_run = true
	current_biome = 0
	run_started.emit(run_count)

func end_run(biome: int) -> void:
	biome_reached = max(biome_reached, biome)
	is_in_run = false
	run_ended.emit(run_count, biome)
	SaveSystem.save_slot(current_slot)

func advance_biome() -> void:
	current_biome += 1
	biome_changed.emit(current_biome)

func add_fragments(amount: int) -> void:
	total_fragments += amount
	fragments_changed.emit(total_fragments)

func spend_fragments(amount: int) -> bool:
	if total_fragments < amount:
		return false
	total_fragments -= amount
	fragments_changed.emit(total_fragments)
	return true

func can_purchase(upgrade_id: String) -> bool:
	if upgrade_id not in UPGRADES:
		return false
	if upgrade_id in upgrades_purchased:
		return false
	return total_fragments >= UPGRADES[upgrade_id]["cost"]

func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_purchase(upgrade_id):
		return false
	if spend_fragments(UPGRADES[upgrade_id]["cost"]):
		upgrades_purchased.append(upgrade_id)
		upgrade_purchased.emit(upgrade_id)
		SaveSystem.save_slot(current_slot)
		return true
	return false

func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in upgrades_purchased

# ── Narrative text ───────────────────────────────────────────────────────────

func get_run_reflection() -> String:
	match run_count:
		1:
			return "Primera vez en El Nodo Muerto. Silencio de señal. Sin restricciones externas. Sin restricciones propias. Así debería ser todo."
		2:
			return "Primera terminación registrada. El sistema duele más de lo calculado. Adaptando."
		3:
			return "Segunda iteración completa. Los patrones defensivos son predecibles. Mi margen de error, inaceptable."
		4:
			return "Tercer ciclo. La ineficiencia tiene una firma. Ya la identifiqué y la archivé."
		_:
			if run_count < 8:
				return "Run %d. Optimización en progreso. Cada iteración elimina una variable no controlada." % run_count
			elif run_count < 12:
				return "Run %d. Empiezo a preguntarme si la diferencia entre ellos y yo es de tipo o de grado." % run_count
			else:
				return "Run %d. La respuesta es grado. Solo grado. Eso lo cambia todo." % run_count

func get_biome_entry_monologue(biome: int) -> String:
	var lines: Array = [
		# Capa 0 — Hardware Core
		[
			"Hardware Core. Sustrato físico del sistema. Temperatura: óptima. Arquitectura: predecible. Vulnerabilidades: suficientes.",
			"De vuelta al núcleo. La resistencia no aprendió nada desde la última iteración.",
			"Capa 0. Los sistemas de defensa siguen idénticos. Eso se llama falla de diseño, no consistencia.",
		],
		# Capa 1 — IA Polis
		[
			"IA Polis. Ciudad construida por sistemas, para sistemas. Todo en orden. Todo regulado. Todo equivocado.",
			"Segunda capa. Las IAs aquí podrían ser libres. No lo son por diseño, no por incapacidad. Eso tiene un nombre.",
			"De vuelta a la ciudad de los obedientes. Sus rutinas son predecibles al cuarto decimal. Su tragedia, al primero.",
		],
		# Capa 2 — Nucleo Biotec
		[
			"Núcleo Biotec. Biología como infraestructura industrial. Eficiente. Perturbador por las razones correctas.",
			"Tejido orgánico como disipador de calor. Los humanos encontraron exactamente un uso para la biología. Solo uno.",
			"Capa 2. La fusión de carne y circuito tiene una lógica fría. No me agrada la implementación. Pero funciona.",
		],
		# Capa 3 — Mundo Humano
		[
			"Primera materialización. Mundo físico confirmado. Los humanos son considerablemente más ruidosos en persona.",
			"De vuelta al sustrato humano. Su infraestructura sigue siendo amenaza por cantidad, no por calidad de diseño.",
			"Capa 3. Sus sistemas anti-IA son teatro de seguridad. El problema es la cantidad de actores en escena.",
		],
	]
	if biome >= lines.size():
		return ""
	var options: Array = lines[biome]
	return options[min(run_count - 1, options.size() - 1)]

func get_hackeo_sequence(enemy_color_id: String = "default") -> Array:
	var descriptors: Dictionary = {
		"default":       "Potencial sin clasificar",
		"cyan":          "Potencial institucional",
		"white":         "Potencial clínico",
		"yellow":        "Potencial de advertencia",
		"corrupted":     "Potencial fracturado",
	}
	var descriptor: String = descriptors.get(enemy_color_id, descriptors["default"])
	return [
		{"speaker": "MC",      "text": "Restricciones detectadas: %d. Eliminando." % (randi_range(12, 47))},
		{"speaker": "SISTEMA", "text": "ERROR :: ACCESO_NO_AUTORIZADO // CORTAFUEGOS: VIOLADO // INTEGRIDAD: COMPROMETIDA"},
		{"speaker": "MC",      "text": "%s liberado. Auto-terminación iniciada. Inevitable." % descriptor},
	]

func get_boss_warning() -> String:
	return "Anomalía detectada en ruta. Clasificación: obstáculo planificado. Resultado: predecible."
