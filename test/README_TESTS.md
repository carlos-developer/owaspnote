# Tests de Seguridad - SuperApp

Este directorio contiene tests exhaustivos que validan todas las mitigaciones de seguridad implementadas según OWASP Mobile Top 10.

## Estructura de Tests

### Tests Unitarios

#### 1. `security/security_config_test.dart`
Prueba las implementaciones de seguridad core:

- **M1: Credenciales Débiles**
  - Validación de contraseñas fuertes (mínimo 12 caracteres, mayúsculas, minúsculas, números, caracteres especiales)
  - Rechazo de contraseñas comunes
  
- **M4: Autenticación Insegura**
  - Generación de salts únicos y aleatorios
  - Hash con PBKDF2 y 100,000 iteraciones
  - Protección contra timing attacks
  
- **M5: Criptografía Insuficiente**
  - Cifrado AES-256 con claves únicas
  - IV único para cada operación de cifrado
  - Fallo al descifrar con clave incorrecta
  
- **M7: Mala Calidad del Código**
  - Sanitización de entrada (elimina tags HTML, caracteres peligrosos)
  - Manejo seguro de entrada vacía

#### 2. `models/user_test.dart`
Valida el modelo de usuario:

- **M6: Autorización Insegura**
  - Sistema de permisos (hasPermission, hasAllPermissions, hasAnyPermission)
  - Prevención de escalación de privilegios
  
- **M7: Mala Calidad del Código**
  - Validación estricta de tipos
  - Sanitización de nombres de usuario
  - Validación de formato de email
  - Límites de longitud (máximo 50 caracteres)
  
- **M10: Funcionalidad Superflua**
  - No incluir información sensible innecesaria
  - Solo serializar campos necesarios

#### 3. `models/note_test.dart`
Prueba el modelo de notas:

- **M5: Criptografía Insuficiente**
  - Manejo correcto de notas cifradas
  - Preservación de estado de cifrado
  
- **M7: Mala Calidad del Código**
  - Sanitización de contenido (elimina scripts, tags HTML)
  - Límites de longitud (título: 100, contenido: 10,000)
  - Prevención de inyección JavaScript
  
- **M8: Code Tampering**
  - Cálculo y verificación de hash de integridad
  - Detección de modificaciones en título o contenido
  - Excepción al detectar integridad comprometida

### Tests de Widgets

#### 4. `widgets/login_screen_test.dart`
Valida la pantalla de login:

- **M4: Autenticación Insegura**
  - Ocultación de contraseña por defecto
  - Validación de campos vacíos
  - Límite de intentos de login
  - Mensajes de error genéricos (no revelan si usuario existe)
  
- **M7: Mala Calidad del Código**
  - Límite de longitud en username (50 caracteres)
  - Solo permite caracteres seguros
  
- **M8: Code Tampering**
  - Advertencia en dispositivos comprometidos

#### 5. `widgets/register_screen_test.dart`
Prueba el registro de usuarios:

- **M1: Credenciales Débiles**
  - Indicadores visuales de requisitos de contraseña
  - Validación en tiempo real
  - Rechazo de contraseñas débiles
  
- **M7: Mala Calidad del Código**
  - Validación de formato de email
  - Filtrado de caracteres peligrosos
  - Validación de coincidencia de contraseñas

### Tests de Integración

#### 6. `integration/security_integration_test.dart`
Tests end-to-end de seguridad:

- **Flujo completo de registro** (M1 + M4)
- **Cifrado y verificación de integridad** (M5 + M8)
- **Sanitización de entrada** (M3 + M7)
- **Control de acceso por permisos** (M6)
- **Verificación de integridad del código** (M2 + M9)
- **No exposición de funcionalidad superflua** (M10)
- **Almacenamiento seguro**
- **Protección contra timing attacks**

## Ejecutar Tests

### Tests Unitarios
```bash
flutter test
```

### Tests de Integración
```bash
flutter test integration_test
```

### Test Específico
```bash
flutter test test/security/security_config_test.dart
```

### Con Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Herramientas de Pentesting Mitigadas

Los tests validan protecciones contra:

1. **John the Ripper / Hashcat**: Contraseñas fuertes y hash PBKDF2
2. **Burp Suite**: Sanitización de entrada y validación
3. **SQLMap**: Prevención de inyección SQL
4. **XSSer**: Eliminación de scripts y tags HTML
5. **Frida**: Detección de dispositivos rooteados
6. **Hydra**: Límite de intentos de login
7. **APKTool**: Verificación de integridad
8. **Wireshark**: Solo comunicación HTTPS

## Métricas de Seguridad

- ✅ 100% de mitigaciones OWASP Mobile Top 10 cubiertas
- ✅ Validación de entrada en todos los formularios
- ✅ Cifrado de datos sensibles
- ✅ Control de acceso basado en permisos
- ✅ Protección contra timing attacks
- ✅ Detección de dispositivos comprometidos
- ✅ Mensajes de error genéricos
- ✅ Almacenamiento seguro con cifrado

## Notas Importantes

1. Los tests de integración requieren un dispositivo/emulador
2. Algunos tests de seguridad (biometría, certificate pinning) requieren configuración adicional en producción
3. Los tests simulan algunas verificaciones que en producción serían más estrictas
4. Se recomienda ejecutar tests de penetración adicionales en un entorno real