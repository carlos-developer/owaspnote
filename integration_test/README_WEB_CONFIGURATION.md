# Configuración de Pruebas de Integración Web para OWASP Note

Este documento detalla el proceso de configuración de las pruebas de integración para ejecutarse en navegadores web (Chrome) siguiendo la documentación oficial de Flutter.

## Proceso de Configuración Realizado

### 1. Verificación de Prerrequisitos

El proyecto ya contaba con los elementos básicos necesarios:

- **Dependencia `integration_test`** en `pubspec.yaml`:
  ```yaml
  dev_dependencies:
    integration_test:
      sdk: flutter
  ```

- **Directorio `test_driver/`** con el archivo `integration_test.dart`:
  ```dart
  import 'package:integration_test/integration_test_driver.dart';
  
  Future<void> main() => integrationDriver();
  ```

- **Pruebas de integración** en el directorio `integration_test/`

### 2. Instalación y Configuración de ChromeDriver

#### Script Automatizado

Se creó `run_integration_tests_web.sh` que automatiza:

1. **Detección de ChromeDriver**:
   ```bash
   if ! command -v chromedriver &> /dev/null; then
       # Instalar ChromeDriver
   fi
   ```

2. **Instalación automática** usando npx:
   ```bash
   npx @puppeteer/browsers install chromedriver@stable
   ```

3. **Gestión del PATH**:
   ```bash
   # Agregar ChromeDriver local al PATH
   export PATH="$PATH:$(pwd)/chromedriver/linux-138.0.7204.94/chromedriver-linux64"
   ```

### 3. Scripts de Ejecución

#### `run_integration_tests_web.sh`

Script principal que:
- Verifica e instala ChromeDriver si es necesario
- Inicia ChromeDriver en el puerto 4444
- Ejecuta cada prueba individualmente para evitar timeouts
- Limpia recursos al finalizar
- Soporta modo headless con `--headless`

#### Actualización de `run_integration_tests.sh`

Se agregó soporte para web:
```bash
if [ "$1" == "--web" ] || [ "$1" == "--chrome" ]; then
    ./run_integration_tests_web.sh "${@:2}"
    exit $?
fi
```

### 4. Corrección de Problemas Encontrados

#### Error: "Undefined name 'main'"

**Problema**: El archivo `integration_test/integration_test.dart` no tenía una función `main()`.

**Solución**: Se agregó la función main requerida:
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}
```

#### ChromeDriver no en PATH

**Problema**: ChromeDriver se instaló localmente pero no estaba en el PATH del sistema.

**Solución**: El script detecta y agrega automáticamente ChromeDriver al PATH:
```bash
if [ -f "./chromedriver/linux-138.0.7204.94/chromedriver-linux64/chromedriver" ]; then
    export PATH="$PATH:$(pwd)/chromedriver/linux-138.0.7204.94/chromedriver-linux64"
fi
```

### 5. Estructura de Comandos Flutter

Las pruebas se ejecutan usando `flutter drive`:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome  # o 'web-server' para headless
```

Parámetros importantes:
- `--driver`: Archivo driver que inicia la prueba
- `--target`: Archivo de prueba a ejecutar
- `-d`: Dispositivo (chrome o web-server)
- `--web-port`: Puerto para el servidor web (default: 8080)
- `--browser-name`: Navegador a usar (chrome)

### 6. Modos de Ejecución

#### Modo Visual (con navegador)
```bash
./run_integration_tests.sh --web
```

#### Modo Headless (sin ventana del navegador)
```bash
./run_integration_tests.sh --web --headless
```

### 7. Documentación Creada

Se crearon tres documentos:

1. **`run_integration_tests_web.sh`**: Script ejecutable para pruebas web
2. **`WEB_INTEGRATION_TESTS.md`**: Guía completa de usuario
3. **Este README**: Documentación técnica del proceso

### 8. Consideraciones Web vs Mobile

Las pruebas de integración en web tienen particularidades:

- **Almacenamiento**: Usa localStorage del navegador en lugar de almacenamiento nativo
- **Seguridad**: Las políticas CORS y seguridad del navegador aplican
- **Performance**: Puede ser más lento que las pruebas nativas
- **Debugging**: Requiere Chrome DevTools en lugar de herramientas móviles

## Estructura Final

```
owaspnote/
├── integration_test/
│   ├── app_test.dart
│   ├── auth_flow_test.dart
│   ├── integration_test.dart (corregido con main())
│   ├── security_integration_test.dart
│   ├── user_registration_authentication_e2e_test.dart
│   └── README_WEB_CONFIGURATION.md (este archivo)
├── test_driver/
│   └── integration_test.dart
├── run_integration_tests.sh (actualizado con soporte web)
├── run_integration_tests_web.sh (nuevo)
├── WEB_INTEGRATION_TESTS.md (nueva documentación)
└── README_INTEGRATION_TESTS.md (actualizado)
```

## Comandos Útiles

```bash
# Verificar instalación de ChromeDriver
chromedriver --version

# Ejecutar prueba específica manualmente
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome

# Ver dispositivos disponibles
flutter devices

# Limpiar y reconstruir
flutter clean && flutter pub get
```

## Troubleshooting Común

1. **ChromeDriver no encontrado**: El script lo instala automáticamente
2. **Puerto 4444 ocupado**: Matar procesos ChromeDriver previos con `pkill chromedriver`
3. **Errores de compilación web**: Verificar que todos los archivos tengan función `main()`
4. **Timeouts**: Las pruebas se ejecutan individualmente para evitar este problema

## Resultados de Ejecución

Ver [WEB_INTEGRATION_TEST_RESULTS.md](../WEB_INTEGRATION_TEST_RESULTS.md) para los resultados detallados de la ejecución de pruebas.

### Resumen de Resultados
- ✅ `app_test.dart` - Pasó correctamente
- ❌ `auth_flow_test.dart` - Falló por RenderFlex overflow
- ✅ `integration_test.dart` - Pasó correctamente  
- ⏱️ `security_integration_test.dart` - Timeout
- ⏱️ `user_registration_authentication_e2e_test.dart` - Timeout

## Referencias

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Flutter Web Testing](https://docs.flutter.dev/testing/integration-tests#integration-testing-with-web)
- [ChromeDriver Documentation](https://chromedriver.chromium.org/)