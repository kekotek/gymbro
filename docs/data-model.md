# Modelo de datos

Implementado en SwiftData. Los modelos viven en `Gymbro/Gymbro/Models/`, las reglas puras (sin SwiftData) en `Gymbro/Gymbro/Domain/` y las operaciones que tocan la base (renovar, sincronizar, reagendar) en `Gymbro/Gymbro/Services/`. Los tests están en `Gymbro/GymbroTests/`.

Los supuestos de `requirements.md` están concentrados en `GymSchedule` (horario, días de atención, política de cruces) y en las funciones que se indican en cada sección, para poder cambiarlos sin tocar el resto.

## Entidades

### Client

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| fullName | String | Nombre completo |
| birthDate | Date | La edad se calcula, no se guarda |
| weightKg | Double | Peso vigente; se actualiza con cada InBody |
| planType | PlanType | Tipo propuesto para la próxima renovación. El tipo vigente de una clase sale de su `PlanPeriod` |
| isActive | Bool | Desactivar en vez de borrar, para conservar el historial |

Relaciones: `planPeriods`, `weeklySlots`, `sessions`, `inBodyMeasurements` (todas en cascada).

Helpers: `age(on:)`, `activePeriod(on:)`, `latestPeriod`, `sortedWeeklySlots`, `latestMeasurement`, `recordMeasurement(_:)`.

### PlanPeriod (renovación mensual)

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| client | Client | |
| startDate | Date | Lunes 00:00. Regla en `PlanPeriodRules.startDate` (supuesto de la pregunta 4) |
| endDate | Date | `startDate` + 4 semanas, exclusivo (el lunes siguiente a la última semana) |
| classCount | Int | Solo 4, 8, 12 o 16 |
| planType | PlanType | Tipo elegido en esa renovación |

- Clases por semana del período = `classCount / 4`.
- Un cliente tiene plan vigente en una fecha si existe un `PlanPeriod` que la contiene (`startDate <= fecha < endDate`).
- Marcar "renovó" en la interfaz equivale a llamar a `PlanRenewalService.renew`, que crea el período y sus clases.
- `completedCount(at:)` da el "van 2 de 12" de la ficha.

### InBodyMeasurement

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| client | Client | |
| date | Date | Fecha del examen |
| weightKg | Double | |
| bodyFatPercent | Double? | Porcentaje de grasa |
| muscleMassKg | Double? | Masa muscular ("Músculo" en la ficha) |

Los demás campos del InBody están por definir (pregunta abierta 10); agregarlos es un cambio aditivo.

Regla: al guardar una medición, si es la más reciente del cliente, `Client.weightKg` toma su peso.

### Routine

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| name | String | Ej. "Espalda-hombros", "Pecho", "Piernas" |

Propuesta: catálogo reutilizable entre clientes, para no escribir la misma rutina muchas veces.

### WeeklySlot (horario fijo)

El horario calendarizado del cliente, que se repite cada semana.

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| client | Client | |
| weekday | Weekday | Enum `monday` = 1 … `sunday` = 7 |
| startMinuteOfDay | Int | Minutos desde medianoche. De 360 (6:00) a 1260 (21:00), múltiplo de 30 |
| order | Int | Clase 1, 2, 3… dentro de la semana del cliente |
| routine | Routine? | Rutina asociada a esa clase |

Al renovar, el cliente debe tener exactamente tantos `WeeklySlot` como clases por semana indique el plan; si no, la renovación se rechaza (`slotCountMismatch`). Al borrar un horario fijo, sus clases quedan sin `sourceSlot` pero no se borran.

### ClassSession (clase concreta)

Una hora agendada en una fecha específica. Es lo que dibuja el calendario.

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| client | Client | |
| startsAt | Date | Fecha y hora de inicio. Minuto 0 o 30 |
| routine | Routine? | Se copia del horario fijo y viaja con la clase si se reagenda |
| planPeriod | PlanPeriod | Período al que se descuenta la clase |
| sourceSlot | WeeklySlot? | Horario fijo del que nació |
| weekIndex | Int | Semana del período (0 a 3). Permite no duplicar al regenerar aunque la clase se haya movido de semana |
| originalStartsAt | Date? | Solo si fue reagendada: inicio original |
| status | SessionStatus | `scheduled`, `completed` o `cancelled` |

- Duración fija de 60 minutos; el término se calcula.
- El tipo de plan de la clase (`planType`) es el de su período.
- Una clase está "reagendada" cuando `originalStartsAt` no es nulo.
- Estado efectivo (`state(at:)`, en `SessionState.resolve`): cancelada si `status == .cancelled`; realizada si `status == .completed` o si ya pasó su hora de término; pendiente en otro caso (supuesto de la pregunta 8).
- Una clase cancelada se pierde y deja de contar para los cupos (`booking` devuelve nil). Supuesto de la pregunta 7.

## Generación de clases

`SessionGenerator.plan` (puro) expande los horarios fijos en fechas concretas para las 4 semanas; `PlanRenewalService` los persiste.

- `renew(client:classCount:planType:on:)`: valida la cantidad, que haya tantos horarios fijos como clases por semana y que sus horas sean válidas; calcula el inicio con `PlanPeriodRules.startDate`; evalúa cada clase con `CapacityRule` contra lo que ya hay en la base y contra las clases del mismo período que se van planificando. Si alguna no cabe, lanza `conflicts` con todas las que fallaron y no guarda nada. Si todo cabe, crea el período y exactamente `classCount` clases, y actualiza `Client.planType`.
- Sin `PlanPeriod` no hay clases.
- `syncSessions(for:now:)` realinea las clases de un período con los horarios fijos actuales. Es idempotente (correrla dos veces no crea nada). Solo toca clases futuras, pendientes y no reagendadas: las mueve si el horario cambió y crea las que falten para un horario nuevo. Cualquier conflicto aborta sin cambiar nada.
- El calendario muestra la semana actual y las 4 siguientes (`Calendar.weeks(from:count:)`). Solo aparecen clases de períodos renovados; el horario de un cliente sin renovar queda libre (supuesto de la pregunta 5).

## Validación de cupos

Una única función pura decide si un cliente puede ocupar un horario. Se usa en todos lados: horarios fijos, Reagendar y generación de clases.

```
CapacityRule.evaluate(PlacementRequest, existing: [Booking], ignoring: sessionID?) -> PlacementResult
```

`Booking` es una clase ya agendada reducida a cliente, tipo de plan e inicio (`ClassSession.booking`; nil si está cancelada). `BookingRepository` las lee de la base para un rango de fechas. El resultado es `.allowed(sharingWith:)` con los clientes que ya están en la hora, o `.rejected(PlacementFailure)` con el motivo para la interfaz. Dos clases se cruzan si sus inicios están a menos de 60 minutos de distancia.

1. El minuto de `startsAt` no es 0 ni 30 → `invalidStartMinute`.
2. Inicio antes de las 6:00 o después de las 21:00 → `outsideGymHours`.
3. Día en que el entrenador no atiende → `outsideWorkingDays` (supuesto: domingo).
4. El cliente no tiene plan vigente en esa fecha → `noActivePlan`.
5. No hay clases que se crucen → permitido.
6. El mismo cliente ya tiene una clase que se cruza → `sameClientOverlap`.
7. Alguna clase que se cruza es de un cliente individual → `blockedByIndividual`.
8. El cliente es individual y hay cualquier cruce → `individualCannotShare`.
9. Todos compartidos (`sharedPlacement`, según `GymSchedule.sharedOverlapPolicy`):
   - `.sameStartOnly` (vigente): mismo inicio y un solo ocupante → permitido; mismo inicio y dos → `sharedFull`; inicio distinto → `sharedPartialOverlap`.
   - `.halfBlocks` (alternativa ya implementada): en cada medio bloque de 30 minutos caben hasta 2 compartidos.

El parámetro `ignoring` excluye la propia clase que se está reagendando, para que no se bloquee a sí misma.

## Reagendar

`RescheduleService.reschedule(session, to:, scope:)`:

- Solo clases pendientes; el destino debe estar dentro del período de la clase (supuesto de la pregunta 6) y pasar `CapacityRule` ignorando la propia clase.
- `.thisClassOnly`: mueve la clase y guarda `originalStartsAt` la primera vez.
- `.fromNowOn`: además cambia el `WeeklySlot` al nuevo día y hora, y mueve las clases posteriores del mismo período que sigan al horario fijo (no reagendadas, pendientes). Se validan todas antes de cambiar nada; un conflicto aborta con la lista.
- `evaluate(session, movingTo:)` da el estado de cada hora de la grilla de Reagendar sin cambiar nada.

## Tests

Implementados en `Gymbro/GymbroTests/` con Swift Testing, sobre un contenedor en memoria y con el calendario de Chile (`America/Santiago`). Cubren:

- Cada fila de la tabla de cupos de `requirements.md`.
- Límites de hora: 5:30, 6:00, 21:00, 21:30 y un inicio a las 8:15.
- Cruces: individual 8:00 contra cualquiera a las 8:30; compartido 8:00 contra compartido 8:30; clases contiguas 8:00 y 9:00 (no se cruzan).
- Reagendar a un horario lleno, a uno con individual y a uno compartido con cupo; reagendar sin que la clase se bloquee a sí misma.
- Renovar con 4, 8, 12 y 16 genera exactamente esa cantidad de clases; un valor distinto se rechaza.
- Sin plan vigente no se generan clases.
- Generar dos veces no duplica; generar no pisa una clase reagendada.
- Cambio de semana y de año (la semana que cruza el 31 de diciembre) y cambio de hora de verano/invierno en Chile.
- La medición InBody más reciente actualiza el peso; una con fecha antigua no lo hace.
