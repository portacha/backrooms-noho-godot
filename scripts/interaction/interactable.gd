class_name Interactable
extends Node3D
## Objeto con el que el jugador interactúa por proximidad (docs/03, docs/13 §3.4).
## Su origen es el punto que el jugador debe tener a la vista y al alcance.

signal interacted

## Distancia máxima desde la cámara, en metros.
@export var interaction_range: float = 2.0
## 0 = toque instantáneo (documentos, puertas); > 0 = mantener (letras-altar, cuadro).
@export var hold_time: float = 0.0
@export var enabled: bool = true

const GROUP: StringName = &"interactable"


func _ready() -> void:
	add_to_group(GROUP)


func interact() -> void:
	interacted.emit()
