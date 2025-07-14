# SuperApp - Aplicación Segura de Notas

Esta aplicación implementa las mejores prácticas de seguridad siguiendo las recomendaciones del OWASP Mobile Top 10.

## Mitigaciones Implementadas

### M1: Credenciales Débiles
**Archivo:** `lib/security/security_config.dart`
- Validación de contraseñas fuertes (mínimo 12 caracteres, mayúsculas, minúsculas, números y caracteres especiales)
- No permite contraseñas comunes o predecibles

### M2: Suministro de Código Inseguro
**Archivos:** `lib/security/certificate_pinning.dart`, `lib/main.dart`
- Validación de integridad de respuestas con HMAC
- Verificación de integridad del código al inicio
- No se hardcodean configuraciones sensibles

### M3: Comunicación Insegura
**Archivos:** `lib/security/certificate_pinning.dart`, `android/app/src/main/res/xml/network_security_config.xml`
- Certificate pinning implementado
- Solo se permite HTTPS
- Configuración de seguridad de red en Android

### M4: Autenticación Insegura
**Archivos:** `lib/services/auth_service.dart`, `lib/screens/login_screen.dart`
- Autenticación biométrica
- Límite de intentos de login (3 intentos, bloqueo de 15 minutos)
- Hashing seguro con PBKDF2 y salt único
- Tokens con expiración

### M5: Criptografía Insuficiente
**Archivos:** `lib/security/security_config.dart`, `lib/security/secure_storage.dart`
- Cifrado AES-256 para notas sensibles
- Almacenamiento seguro con flutter_secure_storage
- Generación de claves criptográficamente seguras

### M6: Autorización Insegura
**Archivos:** `lib/services/notes_service.dart`, `lib/security/secure_storage.dart`
- Verificación de permisos antes de cada operación
- Validación de propiedad de recursos
- Tokens con expiración automática

### M7: Mala Calidad del Código
**Archivos:** Todos los archivos de servicios y modelos
- Validación y sanitización de todas las entradas
- Manejo seguro de errores sin exponer información sensible
- Límites en campos de entrada

### M8: Manipulación del Código
**Archivos:** `lib/security/anti_tampering.dart`, `lib/main.dart`
- Detección de dispositivos rooteados/jailbroken
- Verificación de integridad del código
- Detección de debuggers y proxies

### M9: Ingeniería Inversa
**Archivos:** `lib/security/anti_tampering.dart`, `android/app/proguard-rules.pro`
- Ofuscación de strings sensibles
- Configuración de ProGuard para Android
- Deshabilitación de debugging en release

### M10: Funcionalidad Superflua
**Archivos:** `lib/main.dart`, `lib/screens/home_screen.dart`
- Oculta contenido sensible en app switcher
- Solo almacena datos necesarios
- Limpia memoria al pausar la app

## Configuración de Seguridad Adicional

### Android
1. Editar `android/app/build.gradle`:
```gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Certificados SSL
1. Agregar el certificado del servidor en `assets/certificates/api_cert.pem`
2. Actualizar el SHA-256 fingerprint en `network_security_config.xml`

## Herramientas de Pentesting Mitigadas

- **Burp Suite / OWASP ZAP**: Certificate pinning previene interceptación
- **Frida / Objection**: Detección de root y anti-debugging
- **APKTool / Jadx**: Ofuscación de código
- **Hydra / John the Ripper**: Contraseñas fuertes y límite de intentos
- **SQLMap**: Sanitización de entradas
- **MobSF**: Múltiples capas de seguridad implementadas

## Compilación Segura

```bash
# Para Android
flutter build apk --release --obfuscate --split-debug-info=debug-info

# Para Web
flutter build web --release
```

## Notas Importantes

1. Actualizar los certificados SSL antes de producción
2. Cambiar el hash de la aplicación en `AntiTamperingProtection`
3. Configurar las claves de API reales
4. Implementar un backend real con las mismas medidas de seguridad