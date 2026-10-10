class_name Difficulty
extends Resource
## Perfil de dificultad (docs/12 §4.4 y §4.5). Solo constantes: nunca cambia contenido ni ritmo.

enum Id { EASY, NORMAL, HARD }

const LABELS: Array[String] = ["Casual", "Equilibrio", "Pesadilla"]

@export var id: Id = Id.NORMAL

@export_group("Resistencia")
@export var infinite_stamina: bool = false
@export var sprint_drain: float = 20.0
@export var regen_idle: float = 12.0
@export var regen_walking: float = 6.0
## Multiplicador del radio de ruido al hiperventilar (1 = no aplica).
@export var hyperventilation_factor: float = 1.5

@export_group("Linterna")
## Distancias a la entidad: parpadeo leve / caída al 50 % con apagados / apagado sostenido.
@export var light_flicker_distance: float = 12.0
@export var light_fail_distance: float = 6.0
@export var light_blackout_distance: float = 2.0
@export var light_blackout_seconds: float = 2.0
## Suelo de intensidad de la linterna (Fácil nunca baja del 40 %).
@export var light_min_ratio: float = 0.0
## Interferencia sostenida durante la persecución (0–1).
@export var light_chase_interference: float = 0.6

@export_group("Ruido")
@export var noise_walk: float = 5.0
@export var noise_sprint: float = 14.0
@export var noise_water_walk: float = 8.0
@export var noise_water_sprint: float = 22.0
@export var noise_crouch: float = 2.0

@export_group("Entidad")
@export var entity_wander_speed: float = 1.1
@export var entity_investigate_speed: float = 1.9
@export var entity_chase_speed: float = 4.0
@export var stimulus_noise_min: float = 10.0
@export var stimulus_noise_max: float = 25.0
@export var stimulus_light: float = 40.0
@export var stimulus_sight_per_second: float = 20.0
@export var stimulus_decay: float = 5.0
@export var threshold_investigate: float = 25.0
@export var threshold_chase: float = 60.0
## Segundos de haz central sobre la entidad antes del chillido y la reubicación (docs/12 §6).
@export var gaze_grace: float = 1.2
## Fracción de la distancia que recorta la reubicación.
@export var gaze_approach: float = 0.25
@export var ambush_soft_seconds: float = 60.0
@export var ambush_hard_seconds: float = 90.0
@export var final_chase_seconds: float = 18.0
@export var level2_manifestations: int = 3
@export var level3_chases_per_segment: int = 1

@export_group("Reintento")
@export var compassion_deaths: int = 3
## Fracción que sube el umbral de persecución al activarse la compasión.
@export var compassion_bonus: float = 0.2
@export var respawn_distance: float = 25.0
@export var fall_stimulus: float = 10.0
## Estímulo por segundo mientras se lee: < 0 congela la presión, 0 decaimiento natural.
@export var reading_stimulus_per_second: float = 0.0


static func make(profile: Id) -> Difficulty:
	var d: Difficulty = Difficulty.new()
	d.id = profile
	match profile:
		Id.EASY:
			d.infinite_stamina = true
			d.sprint_drain = 0.0
			d.hyperventilation_factor = 1.0
			d.light_flicker_distance = 18.0
			d.light_fail_distance = 10.0
			d.light_blackout_distance = 0.0
			d.light_blackout_seconds = 0.0
			d.light_min_ratio = 0.4
			d.light_chase_interference = 0.25
			d.noise_walk = 3.0
			d.noise_sprint = 8.0
			d.noise_water_walk = 5.0
			d.noise_water_sprint = 12.0
			d.noise_crouch = 1.0
			d.entity_wander_speed = 1.0
			d.entity_investigate_speed = 1.6
			d.entity_chase_speed = 3.6
			d.stimulus_noise_min = 8.0
			d.stimulus_noise_max = 18.0
			d.stimulus_light = 25.0
			d.stimulus_sight_per_second = 12.0
			d.stimulus_decay = 8.0
			d.threshold_investigate = 30.0
			d.threshold_chase = 70.0
			d.gaze_grace = 2.5
			d.gaze_approach = 0.1
			d.ambush_soft_seconds = 120.0
			d.ambush_hard_seconds = 180.0
			d.final_chase_seconds = 14.0
			d.compassion_deaths = 2
			d.compassion_bonus = 0.3
			d.respawn_distance = 30.0
			d.reading_stimulus_per_second = -1.0
		Id.HARD:
			d.sprint_drain = 24.0
			d.regen_idle = 8.0
			d.regen_walking = 4.0
			d.hyperventilation_factor = 1.8
			d.light_flicker_distance = 16.0
			d.light_fail_distance = 8.0
			d.light_blackout_distance = 3.0
			d.light_blackout_seconds = 3.0
			d.light_chase_interference = 0.85
			d.noise_walk = 7.0
			d.noise_sprint = 18.0
			d.noise_water_walk = 10.0
			d.noise_water_sprint = 28.0
			d.noise_crouch = 3.0
			d.entity_wander_speed = 1.3
			d.entity_investigate_speed = 2.2
			d.entity_chase_speed = 4.5
			d.stimulus_noise_min = 12.0
			d.stimulus_noise_max = 30.0
			d.stimulus_light = 50.0
			d.stimulus_sight_per_second = 28.0
			d.stimulus_decay = 3.0
			d.threshold_investigate = 20.0
			d.threshold_chase = 55.0
			d.gaze_grace = 0.8
			d.gaze_approach = 0.35
			d.ambush_soft_seconds = 45.0
			d.ambush_hard_seconds = 70.0
			d.final_chase_seconds = 22.0
			d.level2_manifestations = 4
			d.level3_chases_per_segment = 2
			d.compassion_deaths = 5
			d.compassion_bonus = 0.1
			d.respawn_distance = 20.0
			d.fall_stimulus = 25.0
			d.reading_stimulus_per_second = 5.0
	return d
