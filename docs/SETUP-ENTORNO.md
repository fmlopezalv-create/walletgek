# 🛠️ SETUP DEL ENTORNO — walletgek

> Registro de herramientas instaladas y configuradas para el proyecto. Fecha: 2026-11.

## Herramientas instaladas/verificadas

| Herramienta | Versión | Nota |
|---|---|---|
| Git | 2.56.0 | Ya instalado (PATH de máquina). |
| Node.js | 24.19.0 | Ya instalado. |
| Python | 3.14.7 | Ya instalado. |
| VS Code | 1.144.1 | Ya instalado. |
| PostgreSQL | 16.15 | Instalado. Superusuario `postgres` / `postgres` (cambiar). |
| pgAdmin 4 | 9.19 | Instalado (GUI para PostgreSQL). |
| Postman | 12.35.4 | Instalado (probar APIs). |
| Flutter SDK | 3.47.9 (stable) | Instalado en `C:\Users\ACER\flutter`. |
| Dart | 3.13.7 | Incluido con Flutter. |
| Android Studio | — | Ya instalado (`C:\Program Files\Android\Android Studio`). |
| Android SDK | 36.0.0 | En `C:\Android\Sdk`; plataforma 36 + build-tools 36 instaladas. |
| Java (JBR) | OpenJDK 25.0.4 | Bundled con Android Studio; `JAVA_HOME` configurado. |

## Variables de entorno configuradas (persistentes, nivel usuario)

- `PATH` += `C:\Program Files\PostgreSQL\16\bin`
- `PATH` += `C:\Users\ACER\flutter\bin`
- `JAVA_HOME` = `C:\Program Files\Android\Android Studio\jbr`

> ⚠️ Para que surtan efecto en tu terminal, **abre una terminal nueva** (o reinicia VS Code/Android Studio).

## Estado de `flutter doctor`

- ✅ Flutter 3.47.9 stable
- ✅ Windows Version
- ✅ Android toolchain (Android SDK 36.0.0, licencias aceptadas, JDK encontrado)
- ✅ Chrome (web)
- ⚠️ Visual Studio — NO necesario (es para apps de escritorio Windows; nuestro objetivo es Android)

## Comandos útiles para el desarrollo

```powershell
flutter doctor          # verificar entorno
flutter devices         # ver dispositivos/emuladores
flutter create .        # crear proyecto
flutter run             # ejecutar en emulador/dispositivo
flutter build apk       # compilar APK de Android
```

## Notas

- Flutter se instaló vía zip oficial (el `git clone` de GitHub era demasiado lento).
- Para el emulador Android se usará un AVD de Android Studio o un dispositivo físico con depuración USB.
