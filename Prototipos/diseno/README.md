# Prototipos con diseño (paso 4)

Prototipos de baja fidelidad con el estilo del juego (low-poly, minimalista, colores cálidos) para las
pantallas del **núcleo de jugabilidad** y del **acceso con segundo factor**. Siguen la habilidad
`prototipos-gui-roblox`, adaptada a un juego de escritorio en 3D hecho en C# (ver «Adaptación»).

Los prototipos viven en dos lienzos de Claude Design (privados; para que José Eduardo los vea hay que
compartirlos desde el menú *Compartir* de cada lienzo):

| Lienzo | Tableros | Casos de uso |
|---|---|---|
| Bastión · Partida en línea (prototipo) — https://claude.ai/artifact/5QKnvmaExuYpocsAESv3er | 27 | CU-17…CU-26, CU-28, CU-44 |
| Bastión · Acceso con segundo factor (prototipo) — https://claude.ai/artifact/KRVaWmuKxs8CMaGirWn14b | 10 | CU-01…CU-04, CON-08 |

`capturas/` tiene cada tablero renderizado en local (lo mismo que se ve en el lienzo), por si el lienzo
no está a la mano o para citarlos en el documento.

## Estructura de cada lienzo

1. **En el juego y completo**: la GUI sobre el tablero 3D a 1366×768 con su etiqueta de cobertura, y la
   GUI completa, sin recortar, con sus partes numeradas.
2. **Partes y estados**: cada componente con todos sus estados (normal, encima, pulsado, foco,
   cargando, vacío, error, deshabilitado y el caso raro: nombre larguísimo, 4 jugadores, etc.).
3. **Interacciones (conceptos)**: tiras de pasos (mover, salto, colocar muro, turno y reloj,
   desconexión, tablas, meta; entrar con segundo factor).
4. **3b · En la pantalla real**: cada concepto congelado en su peor fotograma, sobre el render real.
5. **Computadora**: 1280×720 (peor caso, HUD escalado), 1920×1080 y modo ventana.

Cada tablero tiene su nota a la derecha (`QUÉ RESUELVE`, `ANIMACIÓN`/`FLUJO`, `QUÉ SE REVISA`,
`ERROR ENCONTRADO Y CORREGIDO`, `POR CONFIRMAR EN EL CÓDIGO`).

## Adaptación de la habilidad (Roblox → escritorio C#)

- No hay CoreGui de Roblox: lo único que dibuja el sistema encima es la barra de título en modo
  ventana (tablero `PC_Ventana`). No hay celular ni TV (el juego es de PC); el bloque 5 se sustituye por
  1280×720, 1920×1080 y ventana.
- El «mundo de fondo» es el tablero 3D real: renders de Blender (Cycles) de los modelos de
  `modelos-3d/` (tablero clásico 9×9 y 7×7, peón clásico, muro de madera). No se usó Higgsfield: los
  renders de los modelos reales enseñan la proporción exacta de la GUI contra el tablero, que es lo que
  el prototipo tiene que comprobar; una imagen generada no la garantiza.
- Paleta y tipografía salen de los modelos (madera `#F0C488`, tablero terracota `#9C4F3E`, fondo
  crema `#F6F1E6`; colores de jugador J1 `#D85A30`, J2 `#1D9E75`, J3 `#7F77DD`, J4 `#EF9F27`) y de la
  fuente redondeada Nunito (OFL). Textos de la GUI en español, como hablaría un jugador.
- Tiempos, nombres y cantidades son de ejemplo; los valores reales salen de la configuración y de las
  reglas de negocio de cada CU.

## Errores encontrados y corregidos al revisar

Partida en línea: nombres cortados en el panel (panel a 330 px, «tú» aparte); contador de muros
incoherente (7 vs 8); el HUD pisaba el tablero (cámara re-apuntada); chat 340×360 tapaba columnas h–i
(ahora 300×250); menú contextual encima del chat (sale a la izquierda y nombra al jugador); muro fantasma
en verde parecía del rival (ahora del color del jugador); el cartel del camino tapaba un muro (va arriba,
en la franja libre); camino «8→11» incoherente con el tablero («6→8»); peón del jugador que abandonó
seguía en el tablero (CU-25 FA-04, retirado); con 4 jugadores a 1280×720 el panel pisaba el tablero (HUD
escalado); la tarjeta de fin tapaba el peón que llegó (bajada); barra roja de urgencia tapaba la fila 9
(el aviso vive en la fila del jugador); la desconexión oscurecía la pantalla como pausa (la partida en
línea no se pausa); el jugador que abandonó salía fuera del orden de turno.

Acceso: tarjeta translúcida (ahora opaca) y demasiado alta; «2 intentos» repetido en el aviso y en la
vigencia; aviso de bloqueo que aplastaba los botones (alto mínimo); el registro con fecha inválida no
enseñaba el error (ahora campo en error y botón apagado); el registro no cabía en la tarjeta de 440 px.

## Cómo regenerar

Todo sale de los scripts; los `.dc.html` nunca se editan a mano.

```
cd Prototipos/diseno/fuente
npm install                       # fuente Nunito local para revisar sin red
pip install playwright bpy        # bpy = Blender como módulo (solo para los renders)
python ../escena/escena.py         # renders → escena/render/*.jpg (lee modelos-3d/)
python build_partida.py --render   # lienzo → project/, capturas de revisión → r/
python build_acceso.py --render    # lienzo → project_acceso/, capturas → r_acceso/
```

- `kit.py`: piezas neutras de la habilidad (marcos, notas, colocación de tableros, render y
  comprobaciones: anidados, desbordes, texto cortado).
- `lib_bastion.py`: el estilo del juego (tema, panel de jugadores, barra de acciones, chat, menú,
  carteles, botones).
- `build_partida.py`, `build_acceso.py`: un lienzo cada uno, con sus notas.
- `assets.json`, `assets_acceso.json`: nombre del render → URL del asset subido a cada lienzo. Para
  publicar una versión nueva, los archivos de `project*/` se suben al mismo lienzo (sube de versión, el
  enlace no cambia).
- `escena/escena.py`: escenas del tablero (posiciones de peones y muros, casillas resaltadas, muro
  fantasma, cámara); `escena/coords.py` proyecta las casillas a píxeles de pantalla (`coords.json`) para
  colocar anotaciones.
