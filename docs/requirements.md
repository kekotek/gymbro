# Requisitos de Gymbro

Leyenda: lo que no tiene marca fue definido por el dueño del proyecto. **[Supuesto]** es una interpretación razonable que falta confirmar. **[Propuesta]** es una sugerencia de diseño que se puede cambiar.

## 1. Contexto

- El usuario de la app es un entrenador personal que trabaja en un gimnasio. Es el único usuario.
- Usa un iPhone 11. La app debe funcionar desde ese modelo en adelante.
- El gimnasio funciona entre las 6:00 y las 22:00.
- Los clientes no usan la app. Piden cambios por canales internos (WhatsApp, en persona) y es el entrenador quien los registra.
- **[Supuesto]** El entrenador atiende de lunes a sábado. Las pantallas muestran una clase el sábado y la pantalla de Reagendar omite el domingo. Está en `GymSchedule.workingWeekdays`.
- En las pantallas de referencia a las personas que entrena se les llama **alumnos**. En código se usa `Client`; el término visible sale de un único lugar (pregunta abierta 9).

## 2. Clientes

Cada cliente se registra con:

- Nombre completo.
- Fecha de nacimiento.
- Edad. **[Supuesto]** Se calcula a partir de la fecha de nacimiento; no se guarda ni se edita.
- Peso.
- Tipo de plan: individual o compartido. **[Supuesto]** El tipo se elige en cada renovación (la pantalla Renovar plan lo pide) y queda guardado en el período; el tipo del cliente es el que se propone por defecto en la próxima renovación.

### InBody

- Periódicamente al cliente se le hace un examen InBody.
- Al registrar un InBody se actualiza el peso del cliente.
- Se pueden registrar otros datos del InBody, como el porcentaje de grasa.
- La ficha del alumno muestra peso (kg), grasa (%) y músculo (kg) de la última medición, y un gráfico del peso de las últimas mediciones. Se registran esos tres datos; el resto está por definir (pregunta abierta 10).
- **[Propuesta]** Guardar cada medición con su fecha para poder ver la evolución, en lugar de sobrescribir el valor anterior.

## 3. Plan mensual y renovación

- Los clientes renuevan su plan todos los meses.
- El entrenador marca en la app si el cliente renovó y de cuántas clases es el plan: 4, 8, 12 o 16.
- Esa renovación es lo que habilita el calendario del cliente para las próximas 4 semanas, con esa cantidad de clases.
- **[Supuesto]** La cantidad mensual equivale a 1, 2, 3 o 4 clases por semana (clases del plan ÷ 4).
- Un cliente sin renovación vigente no genera clases nuevas en el calendario.
- **[Supuesto]** Inicio del período (pregunta abierta 4): siempre parte un lunes. Si el cliente tiene un período que todavía corre, el nuevo empieza el lunes en que termina el anterior (la pantalla muestra "lun 12 oct" para un plan que termina el "dom 11 oct"). Si no tiene período vigente, empieza el lunes de la semana en que se renueva.
- **[Supuesto]** Si al renovar algún horario fijo ya está tomado en alguna de las 4 semanas, no se guarda nada y se informan todos los conflictos.
- La ficha muestra el avance del período: "van 2 de 12" (clases realizadas sobre el total).

## 4. Clases y rutinas

- Cada clase dura 1 hora.
- Una clase puede partir a la hora en punto o a la media hora (ej. 8:00–9:00 o 8:30–9:30).
- **[Supuesto]** La primera clase posible parte a las 6:00 y la última a las 21:00, para terminar dentro del horario del gimnasio.
- Cada clase va asociada a una rutina (plan de entrenamiento). Ejemplo para un cliente de 3 clases semanales:
  - Clase 1: espalda-hombros.
  - Clase 2: pecho.
  - Clase 3: piernas.
- El cliente tiene sus horas calendarizadas: un horario fijo semanal (día y hora) para cada una de sus clases.

## 5. Tipos de plan y cupos

Hay dos tipos de plan:

- **Individual:** el cliente entrena solo en su horario.
- **Compartido:** el horario puede tener hasta dos personas, siempre que ambas tengan plan compartido.

Regla de cupos para un mismo horario:

| Estado del horario | ¿Puede entrar un cliente individual? | ¿Puede entrar un cliente compartido? |
|---|---|---|
| Vacío | Sí | Sí |
| Ocupado por 1 individual | No | No |
| Ocupado por 1 compartido | No | Sí |
| Ocupado por 2 compartidos | No | No |

Como las clases pueden partir en punto o y media, dos clases pueden cruzarse sin partir a la misma hora (ej. 8:00–9:00 y 8:30–9:30). Por eso la regla se evalúa por cruce de horario y no solo por hora de inicio:

- Una clase individual no puede cruzarse con ninguna otra clase.
- **[Supuesto]** Dos clientes compartidos comparten solo si parten a la misma hora. Dos clases compartidas que se cruzan a medias (8:00 y 8:30) no se permiten. Ver pregunta abierta 3.

Esta regla aplica siempre: al asignar horarios fijos, al reagendar y al generar las semanas futuras. La app nunca debe permitir guardar un horario que la viole.

## 6. Calendario (pantalla principal)

- Es lo principal de la app.
- El entrenador ve la semana actual y las próximas 4 (5 semanas en total).
- Tiene vista semana y vista día.
- Solo se muestran horas entre las 6:00 y las 22:00.
- El calendario es solo de lectura: desde la vista día o semana no se puede mover una clase. Para eso existe la opción Reagendar.
- Debe distinguirse a simple vista: horario vacío, ocupado por plan individual, compartido con 1 cupo libre y compartido lleno.

### Vista día

- Muestra la separación de todas las horas del día.
- Las clases ya realizadas muestran solo el nombre del cliente, para no sobrecargar la pantalla. Al seleccionarlas se abre su detalle.
- Las clases pendientes muestran además su rutina.
- **[Supuesto]** Una clase cuenta como realizada cuando ya pasó su hora de término, o antes si el entrenador la marcó con "Marcar como realizada" (pregunta abierta 8).
- Vista semana: cada clase es un bloque con las iniciales del alumno; una clase compartida llena muestra ambas iniciales. Las clases pasadas se ven atenuadas.

## 7. Reagendar

Es el caso de uso más importante después de ver el calendario.

- El cliente pide el cambio por interno y el entrenador lo registra en la app.
- Se accede desde la clase (no arrastrando en el calendario).
- La pantalla de Reagendar debe permitir horarios en punto y a la media hora (ej. 9:30–10:30).
- Solo debe ofrecer o aceptar horarios que cumplan la regla de cupos y el horario del gimnasio.
- **[Supuesto]** La rutina se mueve junto con la clase (si la clase de piernas pasa del miércoles al jueves, sigue siendo piernas).
- Al reagendar se pregunta el alcance del cambio (la pantalla lo muestra como "Solo esta clase" / "De aquí en adelante"):
  - "Solo esta clase": cambio puntual; el horario fijo y las demás semanas no se tocan.
  - "De aquí en adelante": cambia el horario fijo del cliente y las clases posteriores del mismo período que no hayan sido reagendadas a mano lo siguen. Si alguna de esas semanas no cabe, no se cambia nada y se informan los conflictos.
- **[Supuesto]** Una clase se puede mover a cualquier día dentro de su propio período de plan, incluida otra semana. No se puede mover fuera del período (pregunta abierta 6).
- Una clase reagendada se ve marcada ("Movida desde mié 16") y conserva su horario original.
- La pantalla muestra, para cada hora de inicio, si está Libre, Ocupada o compartible ("c/ Nombre"), y avisa con quién se compartirá la hora.

## 7b. Cancelar y marcar como realizada

El detalle de clase tiene "Cancelar clase" y "Marcar como realizada". Mientras no se respondan las preguntas 7 y 8:

- **[Supuesto]** Cancelar deja la clase en estado cancelada: se pierde (no se recupera ni se genera otra) y su horario queda libre para otros.
- **[Supuesto]** Marcar como realizada es opcional: una clase pendiente cuya hora de término ya pasó cuenta como realizada igual.
- Una clase cancelada o realizada no se puede reagendar.

## 8. Diseño

- Estilo minimalista.
- La paleta de colores de las pantallas de referencia está aprobada.

## 9. Fuera de alcance en la v1

- App o acceso para los clientes.
- Login, cuentas y sincronización entre dispositivos.
- Pagos y cobros (la renovación solo se marca; no se registra dinero).
- Notificaciones o mensajes automáticos a clientes.

## 10. Preguntas abiertas

Mientras no haya respuesta, el código usa el supuesto indicado en cada una. Todos están aislados para poder cambiarlos:

1. ¿Qué días de la semana atiende el entrenador? (¿lunes a viernes, sábado, domingo?)
   - Supuesto tomado: lunes a sábado (`GymSchedule.workingWeekdays`).
2. ¿El reagendamiento es puntual, permanente, o ambos? (ver propuesta en la sección 7)
   - Supuesto tomado: ambos, como muestra la pantalla de Reagendar (`RescheduleScope`).
3. ¿Dos clientes compartidos pueden cruzarse a medias (uno a las 8:00 y otro a las 8:30), o solo comparten si parten a la misma hora?
   - Supuesto tomado: solo a la misma hora (`GymSchedule.sharedOverlapPolicy = .sameStartOnly`). La pantalla de Reagendar marca 06:30 y 07:30 como ocupadas junto a una compartida de 07:00. La alternativa (`.halfBlocks`) ya está implementada.
4. ¿Cuándo empieza el período de 4 semanas de una renovación: el día que renueva, el lunes siguiente, o según el mes calendario?
   - Supuesto tomado: ver sección 3 (`PlanPeriodRules.startDate`).
5. Si el plan de un cliente vence dentro de las 5 semanas visibles y aún no renueva, ¿su horario fijo se muestra reservado ("por renovar") o queda libre para otro cliente?
   - Supuesto tomado: queda libre; no se generan clases sin renovación. La lista de alumnos avisa con "Vence dom 20" y el filtro "Por renovar".
6. ¿Una clase se puede reagendar a otra semana, o solo dentro de la misma? ¿Y fuera del período vigente del plan?
   - Supuesto tomado: a cualquier semana dentro del período; nunca fuera de él.
7. ¿Qué pasa si el cliente cancela o falta? ¿Se pierde la clase, se recupera, hay un plazo?
   - Supuesto tomado: se pierde y el horario se libera (`SessionStatus.cancelled`).
8. ¿Se registra asistencia, o basta con que la hora haya pasado para darla por realizada?
   - Supuesto tomado: ambas cosas; ver sección 7b (`SessionState.resolve`).
9. ¿Cómo se llama a las personas que entrena: clientes, alumnos u otro término?
   - Las pantallas usan "Alumnos". Pendiente de confirmar; no afecta al modelo.
10. ¿Qué datos del InBody se registran además del peso y el porcentaje de grasa?
   - Supuesto tomado: masa muscular en kg (`muscleMassKg`), como en la ficha. Agregar más campos es un cambio aditivo.
11. Si un cliente cambia de plan compartido a individual y ya comparte horarios con otra persona, ¿qué se hace con esos horarios?
   - Supuesto tomado: el tipo de plan vive en el período, así que el cambio aplica desde la próxima renovación. Si el horario fijo ya está compartido en esas semanas, la renovación se rechaza con los conflictos y el entrenador decide.
12. ¿El entrenador necesita bloquear horarios (vacaciones, feriados, horas personales)?
   - No implementado. Si la respuesta es sí, es una entidad nueva y una regla más en `CapacityRule`.
13. ¿Un cliente puede tener dos clases el mismo día?
   - Supuesto tomado: sí, mientras no se crucen entre sí. No hay regla que lo impida.
14. Respaldo: los datos viven solo en el iPhone. Si se pierde o se cambia el teléfono, se pierde todo. ¿Se agrega respaldo con iCloud en una versión siguiente?
   - Pendiente; no afecta a la v1.
