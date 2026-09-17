# Modelo de datos (propuesta)

Este modelo es un punto de partida para SwiftData. Se puede ajustar mientras respete las reglas de `requirements.md`.

## Entidades

### Client

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| fullName | String | Nombre completo |
| birthDate | Date | La edad se calcula, no se guarda |
| weightKg | Double | Peso vigente; se actualiza con cada InBody |
| planType | PlanType | `.individual` o `.shared` |
| isActive | Bool | Propuesta: desactivar en vez de borrar, para conservar el historial |

Relaciones: `planPeriods`, `weeklySlots`, `sessions`, `inBodyMeasurements`.

### PlanPeriod (renovación mensual)

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| client | Client | |
| startDate | Date | Inicio del período (regla de inicio: pregunta abierta 4) |
| endDate | Date | `startDate` + 4 semanas |
| classCount | Int | Solo 4, 8, 12 o 16 |

- Clases por semana del período = `classCount / 4`.
- Un cliente tiene plan vigente en una fecha si existe un `PlanPeriod` que la contiene.
- Marcar "renovó" en la interfaz equivale a crear un `PlanPeriod` nuevo.

### InBodyMeasurement

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| client | Client | |
| date | Date | Fecha del examen |
| weightKg | Double | |
| bodyFatPercent | Double? | Porcentaje de grasa |

Los demás campos del InBody están por definir (pregunta abierta 10).

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
| weekday | Int | 1 = lunes … 7 = domingo |
| startMinuteOfDay | Int | Minutos desde medianoche. De 360 (6:00) a 1260 (21:00), múltiplo de 30 |
| order | Int | Clase 1, 2, 3… dentro de la semana del cliente |
| routine | Routine | Rutina asociada a esa clase |

Un cliente debería tener tantos `WeeklySlot` como clases por semana indique su plan vigente.

### ClassSession (clase concreta)

Una hora agendada en una fecha específica. Es lo que dibuja el calendario.

| Campo | Tipo | Notas |
|---|---|---|
| id | UUID | |
| client | Client | |
| startsAt | Date | Fecha y hora de inicio. Minuto 0 o 30 |
| routine | Routine | Se copia del horario fijo y viaja con la clase si se reagenda |
| planPeriod | PlanPeriod | Período al que se descuenta la clase |
| sourceSlot | WeeklySlot? | Horario fijo del que nació |
| originalStartsAt | Date? | Solo si fue reagendada: inicio original |

- Duración fija de 60 minutos; el término se calcula.
- Una clase está "reagendada" cuando `originalStartsAt` no es nulo.
- Una clase está "realizada" cuando ya pasó su hora de término (supuesto). Cancelación y asistencia no se modelan todavía (preguntas abiertas 7 y 8).

## Generación de clases

- Al crear un `PlanPeriod` se generan sus `ClassSession` a partir de los `WeeklySlot` del cliente, para las 4 semanas del período. El total generado debe ser igual a `classCount`.
- Sin `PlanPeriod` vigente no se generan clases.
- La generación no debe duplicar clases existentes ni pisar clases reagendadas.
- Si se crea o cambia un `WeeklySlot`, se actualizan solo las clases futuras que no hayan sido reagendadas a mano.
- Si al generar hay un conflicto de cupos (el horario fijo ya está tomado esa semana), no se guarda nada en silencio: se informa al entrenador para que resuelva.
- El calendario muestra la semana actual y las 4 siguientes. Dentro de ese rango solo aparecen clases de períodos ya renovados (qué mostrar para los no renovados: pregunta abierta 5).

## Validación de cupos

Una única función pura decide si un cliente puede ocupar un horario. Se usa en todos lados: horarios fijos, Reagendar y generación de clases.

```
canPlace(client, startsAt, ignoring: session?) -> resultado
```

Devuelve si se puede y, si no, el motivo (para mostrarlo en la interfaz). Dos clases se cruzan si sus inicios están a menos de 60 minutos de distancia.

1. El minuto de `startsAt` no es 0 ni 30 → inválido.
2. Inicio antes de las 6:00 o después de las 21:00 → fuera del horario del gimnasio.
3. El cliente no tiene plan vigente en esa fecha → no permitido.
4. No hay clases que se crucen → permitido.
5. Alguna clase que se cruza es de un cliente individual → no permitido.
6. El cliente es individual y hay cualquier cruce → no permitido.
7. Todos compartidos:
   - Mismo inicio y un solo ocupante → permitido.
   - Mismo inicio y dos ocupantes → lleno.
   - Cruce a medias (inicio distinto) → no permitido (supuesto; pregunta abierta 3).
8. El mismo cliente ya tiene una clase que se cruza → no permitido.

El parámetro `ignoring` excluye la propia clase que se está reagendando, para que no se bloquee a sí misma.

El caso 7 debe quedar aislado en el código: si se decide permitir cruces a medias entre compartidos, la regla pasa a ser "en cada medio bloque de 30 minutos caben hasta 2 compartidos".

## Tests mínimos

- Cada fila de la tabla de cupos de `requirements.md`.
- Límites de hora: 5:30, 6:00, 21:00, 21:30 y un inicio a las 8:15.
- Cruces: individual 8:00 contra cualquiera a las 8:30; compartido 8:00 contra compartido 8:30; clases contiguas 8:00 y 9:00 (no se cruzan).
- Reagendar a un horario lleno, a uno con individual y a uno compartido con cupo; reagendar sin que la clase se bloquee a sí misma.
- Renovar con 4, 8, 12 y 16 genera exactamente esa cantidad de clases; un valor distinto se rechaza.
- Sin plan vigente no se generan clases.
- Generar dos veces no duplica; generar no pisa una clase reagendada.
- Cambio de semana y de año (la semana que cruza el 31 de diciembre) y cambio de hora de verano/invierno en Chile.
- La medición InBody más reciente actualiza el peso; una con fecha antigua no lo hace.
