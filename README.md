# MyCareer — v0.2

Aplicación académica personal desarrollada con Flutter para Android y Web.

MyCareer permite registrar y organizar la trayectoria académica de un estudiante, incluyendo materias actuales, materias históricas, años académicos, perfil académico y métricas iniciales de progreso.

## Estado actual

Versión: **0.2.0**

La v0.2 incluye:

- Autenticación mediante correo electrónico y contraseña.
- Integración con Firebase Authentication.
- Persistencia mediante Cloud Firestore.
- Perfil académico configurable.
- Gestión de años académicos.
- Protección contra creación de años académicos duplicados.
- Materias actuales.
- Materias históricas.
- Creación, edición y eliminación de materias.
- Búsqueda y filtros de materias.
- Historial académico inicial.
- Promedio general de materias aprobadas/promocionadas.
- Seguimiento de puntos electivos obtenidos y en curso.
- Interfaz responsive para Android y Web.

Todavía no se incluyen:

- Evaluaciones y parciales.
- Trabajos prácticos y entregables.
- Recuperatorios.
- Calendario académico real.
- Motor de promoción y regularidad.
- Notificaciones.

Estas funcionalidades se incorporarán en versiones posteriores.

## Tecnologías

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Riverpod
- go_router
- Material 3

## Arquitectura

La dependencia conceptual utilizada es:

```text
Presentation
↓
Application / Controllers
↓
Repository
↓
Firebase Service
↓
Firebase
```

La estructura principal del proyecto es:

```text
lib/
├── app/
│   ├── router/
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── widgets/
│
├── domain/
│   └── entities/
│
├── data/
│   ├── firebase/
│   ├── repositories/
│   └── mappers/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── subjects/
│   ├── calendar/
│   ├── progress/
│   └── profile/
│
├── firebase_options.dart
└── main.dart
```

Las entidades de dominio permanecen independientes de Firebase.

La UI no accede directamente a Firestore.

## Firestore

La estructura utilizada actualmente es:

```text
users/{uid}

users/{uid}/academicYears/{year}

users/{uid}/subjects/{subjectId}
```

Ejemplo:

```text
users
└── {uid}
    ├── career
    ├── settings
    │
    ├── academicYears
    │   ├── 2024
    │   ├── 2025
    │   └── 2026
    │
    └── subjects
        ├── {subjectId}
        ├── {subjectId}
        └── ...
```

No existen todavía las colecciones:

```text
evaluations
progress
history
```

El historial se obtiene actualmente a partir de las propias materias.

## Seguridad

Todos los datos académicos están almacenados debajo del usuario autenticado:

```text
users/{uid}
```

Las reglas de Firestore permiten acceder al árbol del usuario únicamente cuando:

```text
request.auth.uid == userId
```

Esto mantiene los datos de cada cuenta aislados.

## Firebase

El proyecto está configurado para:

- Android
- Web

Firebase Authentication utiliza actualmente:

```text
Correo electrónico + contraseña
```

Cloud Firestore se utiliza como base de datos.

## Configuración inicial

Instalar las dependencias:

```bash
flutter pub get
```

Para configurar Firebase en un entorno nuevo:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Seleccionar:

```text
Android
Web
```

FlutterFire genera:

```text
lib/firebase_options.dart
```

La aplicación inicializa Firebase mediante:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Ejecutar

Web:

```bash
flutter run -d chrome
```

Android:

```bash
flutter devices
flutter run -d <device>
```

## Validación

Antes de cerrar una versión se ejecuta:

```bash
dart format lib test
flutter analyze
flutter test
```

Estado de la v0.2:

```text
flutter analyze
No issues found

flutter test
19 tests aprobados
```

## Roadmap

```text
v0.1
Base Flutter + Firebase + autenticación + navegación
✅ Completada

v0.2
Perfil académico + años + materias + historial inicial
✅ Completada

v0.3
Evaluaciones + fechas + notas + recuperatorios + calendario

v0.4
Motor de promoción y regularidad

v0.5
Dashboard académico completo

v0.6+
Notificaciones y mejoras adicionales
```

## Plataformas objetivo

- Android
- Web

Actualmente no se desarrollan versiones específicas para Windows, macOS, Linux o iOS.