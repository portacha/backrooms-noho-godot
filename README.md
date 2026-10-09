# NOHO Backrooms Escape

Proyecto base 3D para Godot 4.7.2, basado en `investigacion.txt`.

## Abrir y ejecutar

Importa `project.godot` en Godot y pulsa **F6** para ejecutar la escena abierta
o **F5** para ejecutar el proyecto. También puedes usar:

```bash
godot4 --editor --path .
godot4 --path .
```

La escena inicial contiene una habitación de prueba, iluminación, cámara fija
y título. Todavía no incluye movimiento, colisiones, enemigos ni objetivos.
El renderizador Compatibility queda configurado como base para Web y Android;
las exportaciones se configurarán cuando se definan sus requisitos.

## Organización

- `scenes/`: escenas del juego; `main.tscn` es el punto de entrada.
- `scripts/`: futuros scripts GDScript.
- `assets/`: futuros recursos gráficos y de audio.
- `docs/`: documentación adicional.
- `investigacion.txt`: documento de diseño original.

La caché `.godot/`, las compilaciones y credenciales de exportación se excluyen
del control de versiones.
