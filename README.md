# MyCareer — v0.8

Aplicación académica personal desarrollada con Flutter para Android y Web.

MyCareer permite registrar y organizar la trayectoria académica de un estudiante, incluyendo materias actuales, materias históricas, años académicos, perfil académico y métricas iniciales de progreso.

## Estado actual

Versión: **0.8.0+8**

La v0.8 incluye todo lo anterior y además:

- Autenticación mediante correo electrónico y contraseña.
- Integración con Firebase Authentication.
- Creación y reparación automática del perfil al registrar, iniciar sesión o
  restaurar una sesión existente, preservando la configuración válida.
- Persistencia mediante Cloud Firestore.
- Perfil académico configurable.
- Gestión de años académicos.
- Protección contra creación de años académicos duplicados.
- Materias actuales.
- Materias históricas.
- Creación, edición y eliminación de materias.
- Eliminación atómica de materias junto con sus evaluaciones, desvinculación de
  sus actividades y eliminación de evaluaciones junto con sus recuperatorios,
  sin estados parciales.
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
- Agenda con pestañas `Calendario`, `Lista` y `Actividades`.
- Calendario académico mensual que distingue evaluaciones y actividades.
- Actividades tipo to-do asignadas a un día, sin hora ni calificación, con
  materia opcional y estados pendiente/completada.
- Alta contextual de actividades desde el detalle de cualquier día, además de
  edición y eliminación desde su lista.
- Eliminación en cascada de las evaluaciones al eliminar una materia.
- Reglas configurables de promoción y regularidad embebidas en cada materia.
- Seis tipos de condición: promedio mínimo, nota mínima por tipo, porcentaje y cantidad aprobada, todas aprobadas y evaluación obligatoria.
- Motor académico puro con estados cumplida, pendiente y no cumplida.
- Condición automática: sin datos, promocionando, regular, en riesgo o no regularizó.
- La condición académica se calcula en vivo como dato derivado y no se persiste,
  evitando resultados desactualizados.
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
- Horarios de cursado configurables por materia, con día, rango horario,
  modalidad, ubicación y enlace virtual opcional.
- Vista semanal y vista de las clases del día, detección visual de
  superposiciones y resumen del horario en Inicio.
- Selección de año académico compartida entre Inicio, Materias y Horario.
- Carga rápida de resultados y consulta del detalle de una evaluación desde
  Calendario y desde la materia, conservando el formulario completo de edición.
- Notificaciones locales y recordatorios configurables por evaluación.
- Activación y permiso explícitos, defaults globales y hora para evaluaciones sin horario.
- Reprogramación al editar, resolución o eliminación, y cancelación al desactivar o cerrar sesión.
- Timezone IANA obtenida del dispositivo mediante `flutter_timezone`.
- Navegación a la evaluación al tocar una notificación con payload válido.
- Scheduling inexacto Android restaurable tras reinicio y recordatorios runtime Web.

Todavía no se incluyen:

- Asistencia.

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
- flutter_local_notifications 22.3.0
- timezone 0.11.1
- flutter_timezone 5.1.0
- flutter_launcher_icons 0.14.4 (desarrollo)

El mínimo declarado continúa siendo Dart `>=3.4.0 <4.0.0`; el entorno validado
usa Flutter 3.47.0 y Dart 3.13.0.

## Branding e íconos

El nombre visible de la aplicación es `MyCareer` en Android, el título del
navegador y el manifiesto PWA Web. El logo oficial se conserva en
`assets/branding/mycareer_logo.png`.

Los launcher icons Android, el favicon y los iconos PWA Web se generan desde
ese único asset mediante `flutter_launcher_icons.yaml`:

```bash
dart run flutter_launcher_icons
```

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
│   ├── notifications/
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
│   ├── schedule/
│   ├── progress/
│   ├── notifications/
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
  settings.notifications

users/{uid}/academicYears/{year}

users/{uid}/subjects/{subjectId}
  scheduleBlocks[]
  promotionRules[]
  regularityRules[]

users/{uid}/evaluations/{evaluationId}
  reminders[]

users/{uid}/activities/{activityId}
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
    ├── evaluations
    │   ├── {evaluationId}
    │   └── ...
    │
    └── activities
        ├── {activityId}
        └── ...
```

No existen las colecciones (los recordatorios se embeben, no crean una colección):

```text
progress
dashboard
history
notifications
```

El historial se obtiene actualmente a partir de las propias materias.

Las evaluaciones y actividades se mantienen en colecciones planas bajo el
usuario. La aplicación observa cada colección una vez y filtra localmente por
materia, mes y día. Esto evita consultas por cada día del calendario y no
requiere índices compuestos en v0.8. Las actividades usan `schemaVersion: 1`,
guardan sólo el día y nunca contienen campos de calificación.

`settings.notifications` contiene `enabled`,
`defaultReminderOffsetsMinutes`, `allDayReminderHour` y
`allDayReminderMinute`. Los perfiles anteriores reciben defaults desactivados,
un día antes y 09:00. Cada Evaluation guarda una lista pequeña `reminders[]` y
usa `schemaVersion: 2`; el mapper sigue leyendo documentos v1 o sin versión.

## Notificaciones por plataforma

### Android

Los recordatorios se programan localmente con
`AndroidScheduleMode.inexactAllowWhileIdle`. Android puede mostrarlos aunque
MyCareer esté cerrada. El manifest declara `RECEIVE_BOOT_COMPLETED` y los
receivers oficiales del plugin para restaurarlos después de reiniciar. No se
solicitan `SCHEDULE_EXACT_ALARM` ni `USE_EXACT_ALARM`.

### Web

Los navegadores no ofrecen programación local futura equivalente. MyCareer
mantiene un único timer para el próximo recordatorio y muestra una notificación
inmediata al vencer, en modalidad best-effort, mientras la pestaña está abierta.
Con la pestaña o el navegador cerrados no existe garantía de aviso y nunca se
invoca `zonedSchedule` en Web.

El permiso solo se solicita al pulsar “Activar notificaciones”. El estado real
del sistema/navegador es la fuente de verdad y no se persiste en Firestore.

El dashboard se calcula dinámicamente. No existe una colección `dashboard` ni una
cache persistida de `progress`.

Las reglas académicas son listas pequeñas embebidas en `Subject`; no existe una
colección `academicRules`. Los documentos se guardan con `schemaVersion: 2` y el
mapper mantiene compatibilidad con documentos v1 o sin versión, interpretando las
listas ausentes como vacías. Los bloques de horario también se embeben en cada
materia y se validan individualmente, con un máximo de diez. `currentCondition` no se persiste: documentos
anteriores pueden conservar ese campo hasta su próxima edición, momento en que se
elimina, y la aplicación siempre lo ignora para calcular la condición en vivo.

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

Además del aislamiento por cuenta, cada colección valida su esquema, tipos,
rangos y relaciones. Por ejemplo, una materia debe referenciar un año académico
del mismo usuario y una evaluación debe pertenecer a una materia del mismo año.
Los campos inesperados y cualquier ruta no declarada se rechazan por defecto.

Las reglas se prueban contra el emulador local. Requiere Node.js 20 o superior
y Java 21:

```text
npm install
npm run test:firestore-rules
```

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
flutter build web
flutter build apk --debug
git diff --check
```

Estado de la v0.8:

```text
flutter analyze
No issues found

flutter test
149 tests aprobados

npm run test:firestore-rules
8 tests aprobados
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
✅ Completada

v0.7
Actividades to-do integradas con calendario y lista
✅ Completada

v0.8
Horarios de cursado por materia + vistas diaria y semanal + carga rápida de resultados
✅ Completada

Próximas mejoras: por definir
```

## Plataformas objetivo

- Android
- Web

Actualmente no se desarrollan versiones específicas para Windows, macOS, Linux o iOS.

## Mantenimiento de versiones

Antes de cerrar cada versión se revisan la versión, funcionalidades, estructura de
Firestore, arquitectura, rutas, dependencias, configuración, plataformas, tests y
roadmap de este README. Solo se documentan funciones efectivamente implementadas.
