# Índice de pantallas de referencia

Las imágenes son la fuente de verdad visual. Están numeradas según el flujo de la app. Todas comparten:

- Fondo casi negro, tipografía condensada en títulos, acento verde lima para lo individual y lo primario, cian para lo compartido, coral para alertas y acciones destructivas.
- Barra de pestañas inferior con dos pestañas: **Agenda** (calendario) y **Alumnos** (lista de clientes). El término visible para los clientes es "Alumnos" (ver pregunta abierta 9).

## 01-week-calendar.png — Vista semana

**Qué muestra**
- Título con el rango de la semana ("14–20 sep") y un selector segmentado Día / Semana.
- Fila de navegación "Esta semana · 1 de 5" con flechas atrás/adelante (5 semanas: la actual y 4 más). La flecha atrás aparece deshabilitada en la semana actual.
- Leyenda: Individual (lima sólido), Compartido (cian sólido = lleno), Con 1 cupo (borde cian punteado).
- Cabecera de días L M X J V S D con el número de día; el día de hoy resaltado en lima y su columna sombreada.
- Grilla de horas desde las 06 (se desplaza hacia abajo hasta las 22). Cada clase es un bloque de 1 hora con las iniciales del alumno; una clase compartida llena muestra las dos iniciales apiladas. Los bloques pueden partir a la media hora (TH jue 10:30).
- Las clases ya pasadas se ven atenuadas (mismo color, menor opacidad).
- Hay una clase el sábado; el domingo aparece en la cabecera pero vacío.

**Acciones**
- Cambiar a vista Día. Navegar entre las 5 semanas. Tocar un día de la cabecera abre ese día en vista Día. Tocar un bloque abre el detalle de la clase (03).

**Navega a**: 02 (vista día), 03 (detalle de clase).

## 02-day-agenda.png — Vista día

**Qué muestra**
- Título con el día ("Jueves 17") y el mismo selector Día / Semana.
- Fila "Esta semana · 14–20 sep" con flechas para cambiar de semana.
- Tira de días L–D con el día seleccionado en lima.
- Regla de horas (06:00, 07:00…). Los inicios a la media hora se rotulan solo cuando hay una clase (10:30).
- Línea de hora actual en coral con la hora ("08:20").
- Clases realizadas: tarjeta solo con borde, un check y el nombre (o los dos nombres si es compartida).
- Clases pendientes: tarjeta rellena, punto de color según tipo de plan, nombre en negrita y la rutina debajo. A la derecha una anotación: "1 cupo libre" (cian) o "Movida desde mié 16" para una clase reagendada.

**Acciones**
- Tocar una clase (realizada o pendiente) abre su detalle (03). Cambiar de día o de semana. Volver a vista Semana.

**Navega a**: 01, 03.

## 03-class-detail.png — Detalle de clase

**Qué muestra**
- Botón atrás "Agenda". Hora en grande ("09:00 – 10:00") y fecha ("Hoy, jueves 17 de septiembre").
- Tarjeta con tres filas:
  1. Alumno y tipo de plan ("Plan compartido"), con chevron hacia su ficha.
  2. Rutina ("Espalda y hombros") y su posición en la semana ("Clase 3 de 3 de la semana"), con acción **Cambiar**.
  3. Estado del cupo ("1 cupo libre · Para otro alumno con plan compartido") con acción **Agregar**. Solo tiene sentido en clases compartidas con cupo.
- Nota "Horario fijo: todos los jueves a las 09:00".
- Botones: **Reagendar** (secundario), **Cancelar clase** (secundario en coral) y **Marcar como realizada** (primario en lima).

**Acciones**
- Ir a la ficha del alumno. Cambiar la rutina de esta clase. Agregar otro alumno compartido al mismo horario. Reagendar. Cancelar la clase. Marcar como realizada.

**Navega a**: 06 (ficha del alumno), 04 (reagendar). "Cambiar" y "Agregar" no tienen pantalla propia en el diseño.

## 04-reschedule.png — Reagendar clase

Se presenta como hoja modal.

**Qué muestra**
- "Cancelar" a la izquierda y título "Reagendar clase".
- Tarjeta resumen: alumno, etiqueta "PLAN COMPARTIDO", origen tachado y destino en lima ("jue 17 · 09:00 → vie 18 · 07:00"), la rutina con la nota "la rutina se mueve con la clase" y, si corresponde, "Compartirá la hora con Valentina Soto".
- Selector de día en chips horizontales: Hoy 17, Vie 18, Sáb 19, Lun 21, Mar 22. El domingo 20 no aparece.
- Grilla de horas de inicio cada 30 minutos desde las 06:00 (4 por fila, se desplaza), cada una con estado: **Libre**, **Ocupada** (atenuada, no seleccionable) o **c/ Nombre** (compartible con ese alumno). El seleccionado va en lima. Las 06:30 y 07:30 aparecen ocupadas por cruzarse con la clase compartida de las 07:00.
- Zona fija inferior: selector "Solo esta clase" / "De aquí en adelante", un texto que explica el alcance ("Se mueve solo la clase de hoy. Su horario fijo de los jueves a las 09:00 no cambia.") y el botón primario "Mover a vie 18 · 07:00 – 08:00".

**Acciones**
- Elegir día y hora. Elegir alcance del cambio. Confirmar o cancelar.

**Navega a**: vuelve a 03 (o a la agenda) al confirmar o cancelar.

## 05-client-list.png — Lista de alumnos

**Qué muestra**
- Título "Alumnos" y botón "+" en lima para crear uno.
- Campo de búsqueda "Buscar por nombre".
- Filtros: Todos, Individual, Compartido, "Por renovar · 1" (con contador).
- Lista ordenada alfabéticamente por nombre. Cada fila: nombre, "Tipo · N clases al mes" y, a la derecha, la próxima clase ("hoy 19:00", "lun 07:00") o la alerta de vencimiento en coral ("Vence dom 20").

**Acciones**
- Buscar, filtrar, crear alumno, abrir una ficha.

**Navega a**: 06 (ficha). El formulario de alta no tiene pantalla en el diseño.

## 06-client-profile.png — Ficha del alumno

**Qué muestra**
- Atrás "Alumnos" y "Editar" a la derecha.
- Nombre en grande y debajo "32 años · 12 mar 1994".
- Sección **Plan**: tarjeta "Compartido · 12 clases", rango del período ("14 sep – 11 oct") y avance ("van 2 de 12"), con botón **Renovar**.
- Sección **Horario fijo**: una fila por clase semanal con día y hora ("Lun 10:00"), rutina y chevron para editar.
- Sección **InBody · 7 sep** con acción **Nueva medición**: tarjeta con Peso (kg), Grasa (%) y Músculo (kg) de la última medición, y un gráfico de línea del peso con las últimas cuatro mediciones fechadas.

**Acciones**
- Editar datos del alumno. Renovar plan. Editar un horario fijo. Registrar una nueva medición InBody.

**Navega a**: 07 (renovar). Editar alumno, editar horario fijo y nueva medición no tienen pantalla en el diseño.

## 07-plan-renewal.png — Renovar plan

Hoja modal.

**Qué muestra**
- "Cancelar" y título "Renovar plan".
- Tarjeta con el alumno y "Su plan actual termina el dom 11 oct".
- **Tipo de plan**: segmentado Individual / Compartido (se elige en cada renovación).
- **Clases del mes**: 4, 8, 12 o 16 con su equivalente "N por sem.". Debajo, el texto: "Al renovar se agendan 12 clases entre el lun 12 oct y el dom 8 nov: 3 por semana durante 4 semanas." El nuevo período empieza el lunes siguiente al término del actual.
- **Horario fijo**: las mismas filas editables de la ficha.
- Botón primario "Renovar y agendar 12 clases".

**Acciones**
- Elegir tipo de plan y cantidad de clases, revisar o editar los horarios fijos, confirmar o cancelar.

**Navega a**: vuelve a 06.

## Nombres de archivo

Los siete archivos ya están en inglés y siguen el formato `NN-nombre.png`. No hace falta renombrar ninguno.
