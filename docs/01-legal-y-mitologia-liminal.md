# Análisis Legal y Mitología de Espacios Liminales

> Fuente: `investigacion.txt` — sección "Análisis Legal y Mitología de Espacios Liminales".
> **Enmendado 2026-10-09**: política de jump scares, uso del término "Backrooms" y licencias de assets.

## Origen de la mitología

La mitología de los Backrooms se originó como un ejercicio de **escritura colaborativa** basado en la premisa de los **espacios liminales**, es decir, áreas físicas transicionales que, al ser despojadas de su propósito original y de la presencia humana, generan una profunda incomodidad psicológica.

La narrativa fundacional postula que un individuo puede realizar un **"noclip"** (atravesar la materia sólida debido a un fallo en la estructura de la realidad) y caer en una dimensión de pasillos amarillos infinitos, caracterizados por:

- El olor a alfombra húmeda.
- El zumbido constante de luces fluorescentes.

## Gestión de derechos de propiedad intelectual (CRÍTICO)

Un aspecto absolutamente crítico en el desarrollo comercial de un videojuego basado en este concepto es la gestión de los derechos de propiedad intelectual. Las principales plataformas que alojan la narrativa de los Backrooms, específicamente **Wikidot** y **Fandom**, operan bajo la licencia de derechos de autor **Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)**.

Esta designación legal tiene implicaciones masivas para cualquier proyecto respaldado por una marca comercial registrada como **NOHO**.

### Riesgo de usar contenido de las wikis

El uso de cualquiera de los siguientes elementos de estas wikis obliga irrevocablemente a que el trabajo derivado (el videojuego completo) sea publicado bajo la misma licencia **CC BY-SA 3.0**:

- Niveles específicos documentados en estas wikis.
- Entidades con nombre propio (tales como **Smilers** o **Partygoers**).
- Grupos y facciones del "lore" (como la organización **M.E.G.**).

Publicar un producto comercial bajo esta licencia significa otorgar permiso legal a cualquier tercero para **copiar, redistribuir e incluso vender el juego modificado**, lo cual entraría en un conflicto catastrófico con la protección de la marca registrada NOHO y los intereses comerciales del ecosistema **NOHO**.

## Solución estratégica: canon original

La solución estratégica consiste en aprovechar que el **concepto abstracto de "espacios liminales"** y la idea de caer fuera de la realidad **no están sujetos a derechos de autor**, ya que constituyen ideas generales y de dominio público. En consecuencia, el diseño de este juego construirá un **canon completamente original e independiente**:

- **Se conserva** la estética fundamental que el público asocia con el género: papel tapiz amarillento y geometría arquitectónica irracional.
- **Se omite estrictamente** cualquier referencia a la nomenclatura oficial, a los niveles numerados o a las deidades documentadas en las wikis colaborativas.

### El término "Backrooms" en el título

"Nomenclatura oficial" se refiere a los nombres propios de las wikis (niveles numerados, entidades, facciones), no a la palabra genérica *Backrooms*, que nombra el género y se usa en el título comercial y en textos de marca. Dentro del juego la dimensión **no tiene nombre**.

> **Pendiente de validación legal** antes de publicar: confirmar que usar "Backrooms" en el título de un producto comercial no entra en conflicto con marcas registradas de terceros. Si el dictamen es negativo, el nombre de reserva es el interno: *Mictlán Corporativo*. El título comercial es **Backrooms NOHO** (antes *NOHO Backrooms Escape*, nombre que aún aparece en `investigacion.txt`).

### Licencias de assets de terceros

El mismo riesgo de "contagio" aplica a modelos y sonidos. Regla para todo asset externo:

| Licencia | ¿Se acepta? |
|---|---|
| CC0 / dominio público | Sí |
| CC BY | Sí, con atribución en `assets/CREDITS.md` |
| Royalty-free comercial (Sonniss, packs de pago, Sketchfab Standard) | Sí, guardando el comprobante de licencia |
| Generado con ElevenLabs | Sí, con un plan que incluya uso comercial |
| CC BY-SA, CC BY-NC, cualquier "NC" o "ND" | **No** |

Cada asset externo se registra en `assets/CREDITS.md` (origen, autor, licencia, URL) en el mismo commit en que entra al repositorio.

## Reglas psicológicas del diseño

El diseño del juego debe adherirse a reglas psicológicas muy específicas para garantizar la autenticidad de la experiencia.

### Presupuestos (obligatorios)

- **Aislamiento absoluto**: la ausencia total de otros seres humanos es el principal motor del terror psicológico. No hay personajes, voces que acompañen ni multitudes; nadie habla. Los únicos sonidos vocales son los jadeos y la respiración del protagonista y los de la entidad.
- **Geometría no euclidiana**: los pasillos deben parecer repetitivos pero contener sutiles mutaciones, rompiendo las expectativas espaciales del jugador. Técnica en `docs/07` (variantes de sector y pasillos en bucle).
- **Diseño sonoro de silencio opresivo**: solo interrumpido por zumbidos eléctricos o el eco de los pasos.

### Prohibiciones (evitar a toda costa)

- La sobreexposición del monstruo.
- Los **jump scares baratos o constantes**: sobresaltos gratuitos, sin preparación, o repetidos hasta romper la tensión sostenida.
- Cualquier intento de explicar científicamente la naturaleza de la dimensión: **el misterio absoluto es el catalizador del miedo**.

### Política de jump scares

Los jump scares **no están prohibidos; están racionados**. Uno bien preparado es el pago de la tensión acumulada.

- **Presupuesto**: como máximo **uno guionizado por nivel**, más la secuencia de captura de El Olvidado.
- Cada uno debe estar **ganado**: precedido de silencio o tensión creciente, y con sentido en la ficción (el chillido al iluminar a la entidad, la captura).
- Nunca dos seguidos, nunca al azar, nunca en los remansos de veladoras.
