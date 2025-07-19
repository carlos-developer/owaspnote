# Implementación Domain-Driven Design en OWASP Note

Este proyecto demuestra una implementación completa de Domain-Driven Design (DDD) en Flutter, mostrando las mejores prácticas y patrones para construir aplicaciones seguras y mantenibles.

## Visión General de la Arquitectura

La implementación sigue una arquitectura en capas con clara separación de responsabilidades:

```
lib/
├── domain/           # Lógica de negocio central y reglas
├── application/      # Servicios de aplicación y casos de uso
├── infrastructure/   # Preocupaciones externas (BD, servicios)
└── presentation/     # Capa de UI (pantallas existentes)
```

## Capa de Dominio

### Bloques de Construcción Fundamentales

1. **Entity** (`domain/core/entity.dart`)
   - Clase base para todas las entidades
   - Igualdad basada en identidad

2. **Value Object** (`domain/core/value_object.dart`)
   - Objetos inmutables sin identidad
   - Auto-validación con mónada Either para manejo de errores

3. **Aggregate Root** (`domain/core/aggregate_root.dart`)
   - Punto de entrada al agregado
   - Gestiona eventos de dominio
   - Asegura límites de consistencia

4. **Domain Events** (`domain/core/domain_event.dart`)
   - Capturan cambios de estado importantes
   - Habilitan arquitectura dirigida por eventos

5. **Repository** (`domain/core/repository.dart`)
   - Interfaz abstracta para persistencia
   - Operaciones enfocadas en el dominio

6. **Specification** (`domain/core/specification.dart`)
   - Encapsulan reglas de negocio
   - Componibles con operaciones and/or/not

### Agregados del Dominio

#### Agregado Note
- **Raíz**: Clase `Note` con rica lógica de dominio
- **Value Objects**: `NoteId`, `NoteTitle`, `NoteContent`
- **Invariantes**:
  - El título debe tener 1-100 caracteres
  - El contenido máximo 10,000 caracteres
  - No se puede compartir consigo mismo
  - No se pueden modificar notas eliminadas
- **Eventos de Dominio**: Creada, Actualizada, Compartida, Eliminada, etc.

#### Agregado User
- **Raíz**: Clase `User` con lógica de autenticación
- **Value Objects**: `UserId`, `Email`, `Username`, `Password`
- **Invariantes**:
  - Requisitos de contraseña fuerte
  - Validación de formato de email
  - Restricciones de nombre de usuario
  - Bloqueo de cuenta después de intentos fallidos
- **Eventos de Dominio**: Registrado, InicióSesión, CambióContraseña, etc.

### Servicios de Dominio

1. **AuthenticationService**
   - Lógica compleja de autenticación
   - Autenticación de dos factores
   - Flujos de cambio de contraseña

2. **NoteSharingService**
   - Orquesta el compartir notas entre usuarios
   - Operaciones masivas
   - Validación de permisos

3. **PasswordHasher** (interfaz)
   - Hashing abstracto de contraseñas

4. **EncryptionService** (interfaz)
   - Operaciones abstractas de cifrado

## Capa de Aplicación

Los servicios de aplicación orquestan la lógica de dominio y coordinan entre agregados:

### NoteApplicationService
- Crear, actualizar, eliminar notas
- Manejar cifrado/descifrado
- Operaciones de búsqueda y listado
- Flujos de compartir

### UserApplicationService
- Registro de usuarios
- Flujos de autenticación
- Gestión de perfiles
- Operaciones administrativas

## Capa de Infraestructura

Implementaciones concretas de interfaces del dominio:

### Repositorios
- `SqliteNoteRepository`: Persistencia SQLite para notas
- `SqliteUserRepository`: Persistencia SQLite para usuarios

### Servicios
- `CryptoPasswordHasher`: Hashing de contraseñas PBKDF2
- `AesEncryptionService`: Cifrado AES-256

## Patrones DDD Clave Demostrados

### 1. Lenguaje Ubicuo
El código usa terminología específica del dominio:
- Los usuarios se "registran" y hacen "login"
- Las notas se "comparten" y "cifran"
- Las cuentas pueden estar "bloqueadas" y "verificadas"

### 2. Contextos Delimitados
Límites claros entre:
- Contexto de Usuario/Autenticación
- Contexto de Nota/Gestión de contenido

### 3. Diseño de Agregados
- Agregados pequeños y enfocados
- Límites de consistencia claros
- Las entidades raíz protegen invariantes

### 4. Value Objects
- Auto-validación
- Inmutables
- Expresan conceptos del dominio (no solo strings)

### 5. Eventos de Dominio
- Capturan ocurrencias significativas del negocio
- Habilitan pistas de auditoría
- Soportan consistencia eventual

### 6. Especificaciones
- Encapsulan consultas complejas
- Reglas de negocio reutilizables
- Componibles para flexibilidad

## Ejemplos de Uso

### Crear una Nota
```dart
final noteService = NoteApplicationService(/*dependencias*/);
final result = await noteService.createNote(
  userId: currentUser.id,
  title: "Mejores Prácticas de Seguridad",
  content: "Siempre usar HTTPS...",
  encrypt: true,
  tags: ["seguridad", "owasp"],
);

if (result.isSuccess) {
  print("Nota creada con ID: ${result.note!.id.value}");
  print("Clave de cifrado: ${result.encryptionKey}");
}
```

### Registro de Usuario
```dart
final userService = UserApplicationService(/*dependencias*/);
final result = await userService.registerUser(
  email: "usuario@ejemplo.com",
  username: "usuarioseguro",
  password: "MiContraseña!Fuerte123",
);

if (result.isSuccess) {
  print("Usuario registrado: ${result.user!.id.value}");
}
```

### Consultas Complejas con Especificaciones
```dart
// Encontrar todas las notas cifradas compartidas con un usuario creadas en los últimos 30 días
final spec = NoteEncryptedSpecification()
  .and(NoteSharedWithUserSpecification(userId))
  .and(NoteCreatedAfterSpecification(
    DateTime.now().subtract(Duration(days: 30))
  ));

final notes = allNotes.where((note) => spec.isSatisfiedBy(note)).toList();
```

## Consideraciones de Seguridad

La implementación DDD mejora la seguridad a través de:

1. **Tipado Fuerte**: Los value objects previenen ataques de inyección
2. **Protección de Invariantes**: Las reglas de negocio se aplican a nivel de dominio
3. **Encapsulación**: Los agregados ocultan el estado interno
4. **Validación**: Value objects auto-validantes
5. **Listo para Event Sourcing**: Los eventos de dominio habilitan pistas de auditoría

## Estrategia de Testing

La estructura DDD permite testing completo:

1. **Tests Unitarios**: Probar lógica de dominio aisladamente
2. **Tests de Integración**: Probar servicios de aplicación
3. **Tests de Especificación**: Verificar reglas de negocio
4. **Tests de Repositorio**: Probar capa de persistencia

## Beneficios de Este Enfoque

1. **Mantenibilidad**: Clara separación de responsabilidades
2. **Testabilidad**: Lógica de negocio aislada de la infraestructura
3. **Flexibilidad**: Fácil cambiar persistencia o UI
4. **Seguridad**: Los invariantes del dominio previenen estados inválidos
5. **Escalabilidad**: Arquitectura lista para eventos
6. **Documentación**: El código expresa claramente las reglas de negocio

## Próximos Pasos

Para integrar esta implementación DDD:

1. Reemplazar modelos existentes con entidades del dominio
2. Actualizar servicios para usar servicios de aplicación
3. Implementar manejadores para eventos de dominio
4. Agregar tests unitarios para lógica de dominio
5. Migrar código SQLite existente a repositorios

Esta implementación proporciona una base sólida para construir aplicaciones Flutter seguras y mantenibles siguiendo los principios de Domain-Driven Design.