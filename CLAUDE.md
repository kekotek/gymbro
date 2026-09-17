# Gymbro

App iOS para un entrenador personal de gimnasio. Tiene un solo usuario: el entrenador. Le sirve para llevar la agenda de sus clases (esta semana y las próximas 4), la ficha de las personas que entrena y la renovación mensual de sus planes.

El problema central que resuelve: los clientes piden cambios de hora por WhatsApp o en persona y eso desordena la agenda. La app debe hacer que reagendar una clase sea rápido y que nunca quede un horario mal ocupado.

## Documentos del proyecto

- @docs/requirements.md — funcionalidades, reglas de negocio y preguntas abiertas.
- @docs/data-model.md — entidades propuestas y reglas de validación.
- `design/screens/` — pantallas de referencia, numeradas según el flujo de la app. Son la fuente de verdad visual: colores, espaciados, jerarquía y textos salen de ahí. No se empaquetan dentro de la app.

## Stack

- Swift + SwiftUI.
- iOS mínimo: 17.0. Dispositivo de referencia: iPhone 11 (6,1", 414 × 896 pt). Todo debe verse y usarse bien en ese tamaño antes que en cualquier otro.
- Persistencia: SwiftData, local en el dispositivo. Sin backend, sin login y sin red en la v1.
- Sin dependencias de terceros, salvo que se justifique y el usuario lo apruebe.
- Tests unitarios para todas las reglas de negocio (cupos, reagendar, renovación, generación de semanas).

## Convenciones

- Idioma, regla obligatoria:
  - **En inglés:** nombres de carpetas y archivos, y todo identificador del código: tipos, protocolos, funciones, variables, constantes, casos de enum, claves de strings, nombres de tests, ramas de Git. Ejemplos: `ClassSession`, `rescheduleSession()`, `startsAt`, `RescheduleView.swift`. Nunca `Clase`, `reagendarClase()` ni `horaInicio`.
  - **En español:** la documentación del proyecto (reglas de negocio, requisitos), los textos que ve el entrenador en la interfaz (español de Chile, en un String Catalog) y las conversaciones con el usuario.
  - Comentarios de código y mensajes de commit: en inglés.
- Glosario, para no confundir términos:
  - **Tipo de plan** (`PlanType`): individual o compartido. Define cuántas personas caben en un horario.
  - **Período del plan** (`PlanPeriod`): la renovación mensual, con 4, 8, 12 o 16 clases.
  - **Rutina** (`Routine`): el plan de entrenamiento de una clase (ej. espalda-hombros, pecho, piernas).
  - **Clase** (`ClassSession`): una hora concreta agendada, con fecha.
  - **Horario fijo** (`WeeklySlot`): el día y hora que el cliente tiene calendarizado cada semana.
  - **Reagendar** (`reschedule`): mover una clase a otro horario.
- El nombre para las personas que entrena todavía no está decidido (clientes, alumnos u otro). En código usar `Client`. En la interfaz, el término debe salir de un único lugar para poder cambiarlo sin tocar las vistas.
- Las reglas de negocio van en tipos puros, separados de las vistas, para poder testearlas sin UI.
- Semana de lunes a domingo. Horas en formato 24 h. Usar `Calendar` y `Date` correctamente; nunca aritmética manual de segundos para sumar días o semanas.

## Diseño

- Estilo minimalista: poca información por pantalla, sin adornos. Ante la duda, quitar.
- La paleta de colores de las pantallas de referencia está aprobada; respetarla.
- El calendario es solo de lectura: no hay arrastrar y soltar. Una clase se mueve únicamente con la opción Reagendar.

## Cómo trabajar

- Antes de implementar una vista, mirar su imagen en `design/screens/`.
- Si algo no está definido en los documentos, o aparece en "Preguntas abiertas", preguntar al usuario. No inventar reglas de negocio.
- Lo marcado como "propuesta" o "supuesto" en los documentos se puede implementar, pero debe quedar fácil de cambiar.
- Commits pequeños y con mensaje descriptivo.
- Después de cada cambio relevante, compilar y correr los tests con `xcodebuild`. Para saber qué simuladores hay instalados: `xcrun simctl list devices available`.
- No editar el `.xcodeproj` a mano. Si el proyecto de Xcode no existe todavía, pedir al usuario que lo cree desde Xcode (iOS App, interfaz SwiftUI, almacenamiento SwiftData, nombre `Gymbro`) en la raíz de esta carpeta.

## Orden de trabajo sugerido

1. Leer los documentos y mirar todas las imágenes de `design/screens/`. Escribir `design/screens/INDEX.md` con una descripción de cada pantalla (qué muestra, qué acciones tiene, a dónde navega) y confirmarla con el usuario.
2. Verificar que existe el proyecto de Xcode, inicializar Git y crear un `.gitignore` para Xcode/Swift.
3. Modelos de SwiftData y reglas de negocio con sus tests.
4. Calendario: vista semana y vista día, con navegación entre la semana actual y las 4 siguientes.
5. Detalle de clase y Reagendar.
6. Lista y ficha de clientes, incluyendo mediciones InBody.
7. Horarios fijos, rutinas y renovación mensual del plan.
