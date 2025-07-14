# Test del Modo Local en Super App

## Instrucciones para probar el flujo completo con modo local:

### 1. Ejecutar la aplicación en modo debug
```bash
flutter run --debug
```

### 2. En la pantalla de Login
- Verás un nuevo switch "Modo Local (Debug)" en la parte inferior
- Este switch solo aparece en modo debug
- Por defecto está desactivado (usa servidor remoto)

### 3. Activar el modo local
- Activa el switch "Modo Local (Debug)"
- Aparecerá un mensaje: "Modo local activado - Los datos se guardarán temporalmente"
- El switch se mostrará en color naranja

### 4. Crear una cuenta nueva
- Toca "Don't have an account? Register"
- Llena el formulario con:
  - Username: testuser
  - Email: test@example.com
  - Password: TestPassword123!
  - Confirm Password: TestPassword123!
- Toca "Register"
- Verás el mensaje "Registration successful! Please login."

### 5. Hacer login
- Serás redirigido automáticamente a la pantalla de login
- Ingresa las credenciales que acabas de crear:
  - Username: testuser
  - Password: TestPassword123!
- Toca "Login"

### 6. Pantalla principal
- Llegarás a la pantalla de notas
- En la barra superior verás:
  - Tu nombre de usuario
  - Un indicador naranja "LOCAL" que confirma que estás en modo local
  - Botón de logout

### 7. Funcionalidades disponibles en modo local
- ✅ Registro de usuarios
- ✅ Login/Logout
- ✅ Navegación completa
- ❌ Las notas no se guardan (requiere backend real)

### 8. Desactivar modo local
- Haz logout
- En la pantalla de login, desactiva el switch "Modo Local"
- Aparecerá el mensaje: "Modo remoto activado - Los datos se guardarán en el servidor"

## Notas importantes:
- El modo local solo está disponible en compilaciones debug
- Los datos se almacenan temporalmente en memoria
- Al cerrar la app, todos los datos locales se pierden
- Es perfecto para pruebas de desarrollo sin necesidad de backend

## Seguridad implementada:
- Validación de contraseñas fuertes (12+ caracteres, mayúsculas, minúsculas, números, especiales)
- Sanitización de entrada contra SQL injection y XSS
- Hashing de contraseñas con PBKDF2 y salt único
- Protección contra dispositivos comprometidos (desactivada en debug)