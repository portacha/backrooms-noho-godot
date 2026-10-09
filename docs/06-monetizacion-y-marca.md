# Presencia de Marca

> Fuente: `investigacion.txt` — sección "Estrategia de Monetización y Presencia de Marca".
> **Enmendado 2026-10-09**: la publicidad es **solo de NOHO, mínima y no bloqueante**, al inicio y al final del juego. Sustituye a la "publicidad agresiva" de `investigacion.txt`. Donde difiera, gana este documento.

## Premisa fundamental

*Backrooms NOHO* es un advergame: su valor para la marca depende de la **protección absoluta de la inmersión**. Por eso la marca aparece poco y bien:

- **Solo NOHO / lovenoho.com.** No hay anuncios de terceros, redes publicitarias ni SDK de anuncios.
- **Mínima**: presente al **inicio** (menú) y al **final** (pantallas de resolución).
- **Nunca bloqueante**: nada retrasa ni condiciona "Jugar" o "Reintentar"; no hay esperas, contadores ni ventanas emergentes.
- **Colores NOHO como acento**: los colores del logotipo se usan para resaltar detalles, no para cubrir la pantalla.

### Paleta de marca

Los colores del logotipo NOHO son **azul, blanco y naranja**.

| Dónde | Uso |
|---|---|
| Menú y pantallas de resolución | Logotipo, botón principal, filetes, enlace y código promo. El fondo sigue siendo la oficina en penumbra. |
| Objetos de marca dentro del juego | El logotipo tal cual en el cuadro del prólogo, cajas, tazas y papelería. |
| Resto del juego | **No se usan.** La estética principal es la definida en `docs/02`: amarillo liminal, naranja de cempasúchil, magenta de papel picado y neón, negro. |

La paleta de marca **no sustituye ni tiñe** la dirección de arte: las letras-altar y el letrero final conservan sus materiales y su neón magenta. El naranja del logotipo y el del cempasúchil conviven, pero son tonos distintos y no se unifican.

> Pendiente: tomar los valores exactos (hex) y la tipografía del logotipo o del manual de marca de lovenoho.com.

## Durante la partida: integración diegética

Dentro del juego la marca solo existe como parte del mundo.

- NOHO se asocia con la **salvación y el escape**: en un entorno degradado, las únicas estructuras que proyectan luz, color brillante y acabado pulido son las letras **N, O, H, O**.
- En el prólogo, objetos de oficina sutilmente membretados con la tipografía de lovenoho.com: cajas de embalaje, tazas de café, papelería, y el cuadro corporativo.

Nada de esto es interactivo como anuncio ni enlaza fuera del juego.

## Menú principal

Encuadre estático de la oficina del prólogo como fondo 3D. Sobre él:

- **"Jugar"** es la acción principal y está disponible de inmediato.
- Logotipo NOHO y **un único enlace discreto** a lovenoho.com.
- Detalles de interfaz acentuados con los colores de la marca.

Sin banners, sin vídeos automáticos, sin enlaces a pasarela de pago.

## Pantallas de resolución

Tras el fundido a negro, una pantalla sobria con el mismo lenguaje visual del menú.

| Pantalla | Contenido |
|---|---|
| **Victoria** | Mensaje breve, logotipo NOHO, **código promocional** como recompensa y un enlace a lovenoho.com. Opción de volver al menú. |
| **Derrota** | **"Reintentar"** como acción principal e inmediata; logotipo NOHO discreto y enlace opcional a lovenoho.com. Sin código. |

Ejemplo de mensaje de victoria:

> "Has salido. Tu recompensa: código **NOHOSURVIVOR**, 20% de descuento en lovenoho.com."

Notas sobre el código:

- Es un **código público por diseño** (cualquiera puede extraerlo del build web); la tienda debe tratarlo como promoción general, con vigencia y límites definidos del lado de lovenoho.com.
- Se guarda en un `Resource` de configuración para poder cambiarlo sin tocar escenas.
- Los enlaces abren el navegador del dispositivo solo cuando el jugador los pulsa.

**Reintento**: morir devuelve al inicio del nivel actual conservando las letras ya obtenidas (detalle de checkpoints en `docs/12`). La pantalla de derrota no añade espera alguna.

## Resumen

| Capa | Formato | Ejemplos |
|---|---|---|
| Durante el juego | Diegética, sutil, nunca interactiva | Letras N-O-H-O como altares de luz; cuadro, cajas y tazas membretadas en el prólogo |
| Menú principal | Marca mínima, acentos en azul, blanco y naranja | Logotipo y un enlace a lovenoho.com; "Jugar" siempre disponible |
| Pantallas de resolución | Marca mínima, no bloqueante | Victoria: código `NOHOSURVIVOR` + enlace. Derrota: "Reintentar" + enlace opcional |
