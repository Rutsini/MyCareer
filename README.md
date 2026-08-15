# MyCareer — v0.5

Aplicación académica personal desarrollada con Flutter para Android y Web.

MyCareer permite registrar y organizar la trayectoria académica de un estudiante, incluyendo materias actuales, materias históricas, años académicos, perfil académico y métricas iniciales de progreso.

## Estado actual

Versión: **0.5.0+5**

La v0.5 incluye todo lo anterior y además:

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
- Evaluaciones asociadas a materias actuales, con CRUD, fechas y observaciones.
- Tipos y estados de evaluación, obligatoriedad y participación en el promedio.
- Notas, escalas, pesos y promedio actual ponderado por materia.
- Recuperatorios vinculados y políticas `replaceGrade`, `highestGrade` y `approvalOnly`.
- Próxima evaluación calculada dinámicamente en las tarjetas de materias.
- Calendario académico mensual con actividades por día y alta contextual.
- Eliminación en cascada de las evaluaciones al eliminar una materia.
- Reglas configurables de promoción y regularidad embebidas en cada materia.
- Seis tipos de condición: promedio mínimo, nota mínima por tipo, porcentaje y cantidad aprobada, todas aprobadas y evaluación obligatoria.
- Motor académico puro con estados cumplida, pendiente y no cumplida.
- Condición automática: sin datos, promocionando, regular, en riesgo o no regularizó.
- Resolución unificada de evaluaciones y recuperatorios, sin doble conteo.
- Requisitos faltantes y nota exacta requerida cuando el cálculo es determinístico.
- Pestaña Condiciones para crear, editar, habilitar, reordenar y eliminar reglas.
- Dashboard académico completo, responsive en Android y Web.
- Resumen del cursado calculado para el año académico seleccionado.
- Materias en promoción, regulares, en riesgo, sin datos y no regularizadas.
- Alertas académicas y evaluaciones vencidas pendientes priorizadas.
- Próximas evaluaciones y próxima evaluación por materia.
- Promedio general y progreso de puntos electivos compartidos con Progreso.
- Selector local de año y accesos rápidos a materias, evaluaciones, calendario y
  progreso.

Todavía no se incluyen:

- Asistencia.
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
│   ├── entities/
│   ├── models/
│   └── services/
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
│   ├── evaluations/
│   ├── calendar/
│   ├── progress/
│   └── profile/
│
├── firebase_options.dart
└── main.dart
```

Las entidades de dominio permanecen independientes de Firebase.

La UI no accede directamente a Firestore.

`DashboardCalculator` agrupa en memoria materias y evaluaciones ya observadas por
los providers, evalúa cada materia una sola vez con `AcademicEngine` y reutiliza
`EvaluationCalculator` para promedios y próximas fechas. `CareerProgressCalculator`
mantiene una única semántica para el promedio general y los puntos electivos en
Inicio y Progreso. No se persisten resultados derivados del dashboard.

## Firestore

La estructura utilizada actualmente es:

```text
users/{uid}

users/{uid}/academicYears/{year}

users/{uid}/subjects/{subjectId}
  promotionRules[]
  regularityRules[]

users/{uid}/evaluations/{evaluationId}
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
    ├── subjects
    │   ├── {subjectId}
    │   └── ...
    │
    └── evaluations
        ├── {evaluationId}
        └── ...
```

No existen las colecciones:

```text
progress
dashboard
history
```

El historial se obtiene actualmente a partir de las propias materias.

Las evaluaciones se mantienen en una colección plana bajo el usuario e incluyen
`subjectId`. La aplicación observa esa colección una vez y filtra localmente por
materia, mes y día. Esto evita consultas por cada día del calendario y no requiere
índices compuestos en v0.5.

El dashboard se calcula dinámicamente. No existe una colección `dashboard` ni una
cache persistida de `progress`.

Las reglas académicas son listas pequeñas embebidas en `Subject`; no existe una
colección `academicRules`. Los documentos se guardan con `schemaVersion: 2` y el
mapper mantiene compatibilidad con documentos v1 o sin versión, interpretando las
listas ausentes como vacías.

`Subject.recoveryPolicy` se persiste en cada materia. Los documentos anteriores a
v0.3 que no contienen el campo se leen con el valor técnico compatible
`highestGrade`.

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

Estado de la v0.5:

```text
flutter analyze
No issues found

flutter test
77 tests aprobados
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
✅ Completada

v0.4
Motor de promoción y regularidad
✅ Completada

v0.5
Dashboard académico completo
✅ Completada

v0.6
Notificaciones y recordatorios
```

## Plataformas objetivo

- Android
- Web

Actualmente no se desarrollan versiones específicas para Windows, macOS, Linux o iOS.

## Mantenimiento de versiones

Antes de cerrar cada versión se revisan la versión, funcionalidades, estructura de
Firestore, arquitectura, rutas, dependencias, configuración, plataformas, tests y
roadmap de este README. Solo se documentan funciones efectivamente implementadas.
