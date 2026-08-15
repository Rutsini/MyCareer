# App Académica — v0.1

Base responsive para gestionar una vida académica desde Android y Web. Esta versión incluye arquitectura, autenticación por correo y contraseña, navegación y pantallas iniciales. No incluye todavía materias, evaluaciones, calendario real ni progreso académico.

## Requisitos

- Flutter (canal estable)
- Firebase CLI
- FlutterFire CLI

## Instalación

Si el repositorio todavía no contiene los runners `android/` y `web/`, generarlos primero (el código existente en `lib/` no se reemplaza):

```bash
flutter create --platforms=android,web .
flutter pub get
```

## Configurar Firebase

No se incluyen credenciales ni un `firebase_options.dart` inventado. Ejecutar:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Seleccionar **Android** y **Web**. FlutterFire generará `lib/firebase_options.dart`. Luego actualizar `lib/main.dart`:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

En Firebase Console también se debe:

1. Habilitar **Authentication > Sign-in method > Email/Password**.
2. Crear la base de datos de Cloud Firestore.
3. Publicar las reglas con `firebase deploy --only firestore:rules`.

## Ejecutar

Web:

```bash
flutter run -d chrome
```

Android (con emulador o dispositivo conectado):

```bash
flutter run
```

## Verificar

```bash
flutter analyze
flutter test
```

## Arquitectura

La dependencia conceptual es `Presentation → Application → Repository → Service → Firebase`:

- `lib/features/`: presentación y controladores organizados por funcionalidad.
- `lib/domain/`: entidades independientes de Flutter y Firebase.
- `lib/data/`: repositorios y servicios que encapsulan Firebase.
- `lib/core/`: validaciones, errores y widgets compartidos.
- `lib/app/`: router, tema y composición de la aplicación.

`AuthRepository` es una interfaz para permitir tests sin Firebase real. `AuthService` es la única clase que usa `FirebaseAuth` directamente. El repositorio crea `users/{uid}` después del alta; si Firestore falla, conserva la cuenta de Authentication y devuelve un mensaje que explica que el perfil quedó pendiente, evitando una eliminación automática potencialmente destructiva.

El shell usa `StatefulShellRoute.indexedStack`: en móvil muestra `NavigationBar` y desde 720 px muestra `NavigationRail`, conservando el estado de cada rama.
