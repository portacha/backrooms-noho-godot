class_name Difficulty
extends Resource
## Ajuste estándar del juego (docs/12 §4): las constantes de linterna, ruido, entidad y
## reintento en un solo sitio. Hay una única dificultad; si más adelante se añaden perfiles,
## serán variantes de este recurso. Correr no gasta nada: no existe resistencia.

@export_group("Linterna")
## Distancias a la entidad: parpadeo leve / caída al 50 % con apagados / apagado sostenido.
@export var light_flicker_distance: float = 12.0
@export var light_fail_distance: float = 6.0
@export var light_blackout_distance: float = 2.0
@export var light_blackout_seconds: float = 2.0
## Suelo de intensidad de la linterna bajo amenaza (0 = puede apagarse del todo).
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

