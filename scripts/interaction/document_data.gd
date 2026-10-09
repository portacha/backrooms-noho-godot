class_name DocumentData
extends Resource
## Documento encontrado de la bóveda narrativa (docs/11 §7).

## La voz decide el papel y la tipografía del overlay (docs/11 §4).
enum Voice { CORPORATE, INTIMATE, ENGRAVED }

## El soporte decide cómo se presenta la lectura: hoja, nota adhesiva, pantalla de terminal o pared.
enum Medium { PAPER, STICKY_NOTE, SCREEN, WALL }

@export var medium: Medium = Medium.PAPER
## Solo para `SCREEN`: nombre del archivo en la barra de título del bloc de notas.
@export var file_name: String = ""
@export var id: StringName = &""
@export var voice: Voice = Voice.CORPORATE
@export var heading: String = ""
@export_multiline var body: String = ""
@export var signature: String = ""
