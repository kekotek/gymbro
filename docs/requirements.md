# Requisitos de Gymbro

Leyenda: lo que no tiene marca fue definido por el dueño del proyecto. **[Supuesto]** es una interpretación razonable que falta confirmar. **[Propuesta]** es una sugerencia de diseño que se puede cambiar.

## 1. Contexto

- El usuario de la app es un entrenador personal que trabaja en un gimnasio. Es el único usuario.
- Usa un iPhone 11. La app debe funcionar desde ese modelo en adelante.
- El gimnasio funciona entre las 6:00 y las 22:00.
- Los clientes no usan la app. Piden cambios por canales internos (WhatsApp, en persona) y es el entrenador quien los registra.

## 2. Clientes

Cada cliente se registra con:

- Nombre completo.
- Fecha de nacimiento.
- Edad. **[Supuesto]** Se calcula a partir de la fecha de nacimiento; no se guarda ni se edita.
- Peso.
- Tipo de plan: individual o compartido.

### InBody

- Periódicamente al cliente se le hace un examen InBody.
- Al registrar un InBody se actualiza el peso del cliente.
- Se pueden registrar otros datos del InBody, como el porcentaje de grasa.
- **[Propuesta]** Guardar cada medición con su fecha para poder ver la evolución, en lugar de sobrescribir el valor anterior.

## 3. Plan mensual y renovación

- Los clientes renuevan su plan todos los meses.
- El entrenador marca en la app si el cliente renovó y de cuántas clases es el plan: 4, 8, 12 o 16.
- Esa renovación es lo que habilita el calendario del cliente para las próximas 4 semanas, con esa cantidad de clases.
- **[Supuesto]** La cantidad mensual equivale a 1, 2, 3 o 4 clases por semana (clases del plan ÷ 4).
- Un cliente sin renovación vigente no genera clases nuevas en el calendario.

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
- **[Supuesto]** Una clase cuenta como realizada cuando ya pasó su hora de término.

## 7. Reagendar

Es el caso de uso más importante después de ver el calendario.

- El cliente pide el cambio por interno y el entrenador lo registra en la app.
- Se accede desde la clase (no arrastrando en el calendario).
- La pantalla de Reagendar debe permitir horarios en punto y a la media hora (ej. 9:30–10:30).
- Solo debe ofrecer o aceptar horarios que cumplan la regla de cupos y el horario del gimnasio.
- **[Supuesto]** La rutina se mueve junto con la clase (si la clase de piernas pasa del miércoles al jueves, sigue siendo piernas).
- **[Propuesta]** Al reagendar, preguntar el alcance del cambio:
  - "Solo esta clase": cambio puntual; las demás semanas no se tocan.
  - "De ahora en adelante": cambia el horario fijo del cliente y se actualizan las clases futuras ya generadas.
- **[Propuesta]** Una clase reagendada debe verse marcada como tal, con su horario original disponible en el detalle.

## 8. Diseño

- Estilo minimalista.
- La paleta de colores de las pantallas de referencia está aprobada.

## 9. Fuera de alcance en la v1

- App o acceso para los clientes.
- Login, cuentas y sincronización entre dispositivos.
- Pagos y cobros (la renovación solo se marca; no se registra dinero).
- Notificaciones o mensajes automáticos a clientes.

## 10. Preguntas abiertas

No implementar estas definiciones sin preguntar antes:

1. ¿Qué días de la semana atiende el entrenador? (¿lunes a viernes, sábado, domingo?)
2. ¿El reagendamiento es puntual, permanente, o ambos? (ver propuesta en la sección 7)
3. ¿Dos clientes compartidos pueden cruzarse a medias (uno a las 8:00 y otro a las 8:30), o solo comparten si parten a la misma hora?
4. ¿Cuándo empieza el período de 4 semanas de una renovación: el día que renueva, el lunes siguiente, o según el mes calendario?
5. Si el plan de un cliente vence dentro de las 5 semanas visibles y aún no renueva, ¿su horario fijo se muestra reservado ("por renovar") o queda libre para otro cliente?
6. ¿Una clase se puede reagendar a otra semana, o solo dentro de la misma? ¿Y fuera del período vigente del plan?
7. ¿Qué pasa si el cliente cancela o falta? ¿Se pierde la clase, se recupera, hay un plazo?
8. ¿Se registra asistencia, o basta con que la hora haya pasado para darla por realizada?
9. ¿Cómo se llama a las personas que entrena: clientes, alumnos u otro término?
10. ¿Qué datos del InBody se registran además del peso y el porcentaje de grasa?
11. Si un cliente cambia de plan compartido a individual y ya comparte horarios con otra persona, ¿qué se hace con esos horarios?
12. ¿El entrenador necesita bloquear horarios (vacaciones, feriados, horas personales)?
13. ¿Un cliente puede tener dos clases el mismo día?
14. Respaldo: los datos viven solo en el iPhone. Si se pierde o se cambia el teléfono, se pierde todo. ¿Se agrega respaldo con iCloud en una versión siguiente?
