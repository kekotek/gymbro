# Gymbro

App iOS (Swift + SwiftUI) para que un entrenador personal lleve la agenda de sus clases, la ficha de sus clientes y la renovación mensual de sus planes.

## Estructura

```
gymbro/
├── CLAUDE.md             Contexto e instrucciones para Claude Code
├── README.md
├── docs/
│   ├── requirements.md   Funcionalidades, reglas de negocio y preguntas abiertas
│   └── data-model.md     Entidades y validaciones propuestas
├── design/
│   └── screens/          Pantallas de referencia, numeradas según el flujo
└── Gymbro/               Proyecto de Xcode (se crea desde Xcode)
```

Los nombres de carpetas, archivos y código van en inglés. Los textos de la interfaz van en español.

## Pantallas de referencia

Las imágenes de `design/screens/` son la fuente de verdad visual. Van numeradas según el flujo de la app y no forman parte del bundle. Nombres sugeridos:

```
01-week-calendar.png
02-day-agenda.png
03-class-detail.png
04-reschedule.png
05-client-list.png
06-client-profile.png
07-plan-renewal.png
```

## Requisitos para desarrollar

- Mac con Xcode.
- iOS mínimo 17.0. Dispositivo de referencia: iPhone 11.

## Cómo empezar

1. Crear el proyecto en Xcode dentro de esta carpeta: iOS App, interfaz SwiftUI, almacenamiento SwiftData, nombre `Gymbro`.
2. Abrir esta carpeta en Claude Code y pedirle que lea `CLAUDE.md` y siga el orden de trabajo sugerido.
