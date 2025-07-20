# 🔐 Sistema de Permisos - OWASPNOTE

## 📋 Estado Actual

### Problema Identificado
Existe una inconsistencia entre los permisos asignados y los permisos verificados:

**Permisos Asignados en Registro:**
- `read`
- `write`

**Permisos Verificados en NotesService:**
- `read_notes`
- `create_notes` 
- `update_notes`
- `delete_notes`

## 🔧 Cómo Funciona el Sistema

### 1. Modelo de Usuario
```dart
class User {
  final List<String> permissions;
  
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}
```

### 2. Asignación de Permisos (MockAuthService)
```dart
// En registro y login
permissions: ['read', 'write']
```

### 3. Verificación de Permisos (NotesService)
```dart
if (!currentUser.hasPermission('create_notes')) {
  throw AuthorizationException('User does not have permission to create notes');
}
```

## ❌ El Problema

Los usuarios nuevos reciben permisos genéricos (`read`, `write`) pero el servicio de notas espera permisos específicos (`read_notes`, `create_notes`, etc.), causando que NINGÚN usuario pueda crear, leer, actualizar o eliminar notas.

## ✅ Soluciones

### Solución 1: Actualizar Permisos en Registro (RECOMENDADA)

Modificar `MockAuthService` para asignar los permisos correctos:

```dart
// En register() y login()
permissions: [
  'read_notes',
  'create_notes', 
  'update_notes',
  'delete_notes'
]
```

### Solución 2: Mapear Permisos Genéricos

Modificar `NotesService` para aceptar permisos genéricos:

```dart
// En lugar de verificar 'create_notes'
if (!currentUser.hasPermission('write')) {
  throw AuthorizationException('User does not have write permission');
}
```

### Solución 3: Sistema de Roles

Implementar un sistema de roles más robusto:

```dart
enum UserRole {
  admin,    // Todos los permisos
  user,     // CRUD de sus propias notas
  viewer    // Solo lectura
}

// Asignar rol en registro
role: UserRole.user

// Mapear rol a permisos
Map<UserRole, List<String>> rolePermissions = {
  UserRole.admin: ['read_notes', 'create_notes', 'update_notes', 'delete_notes', 'admin'],
  UserRole.user: ['read_notes', 'create_notes', 'update_notes', 'delete_notes'],
  UserRole.viewer: ['read_notes']
};
```

## 🔨 Implementación Rápida

Para habilitar permisos inmediatamente, actualiza estos archivos:

### 1. `lib/services/mock_auth_service.dart`

```dart
// Línea ~97 en register()
permissions: ['read_notes', 'create_notes', 'update_notes', 'delete_notes'],

// Línea ~133 en login()
permissions: ['read_notes', 'create_notes', 'update_notes', 'delete_notes'],
```

### 2. `lib/services/auth_service.dart`

```dart
// Líneas donde se crea el User (si aplica)
permissions: ['read_notes', 'create_notes', 'update_notes', 'delete_notes']
```

## 📝 Permisos Disponibles

| Permiso | Descripción |
|---------|-------------|
| `read_notes` | Ver notas propias |
| `create_notes` | Crear nuevas notas |
| `update_notes` | Editar notas existentes |
| `delete_notes` | Eliminar notas |
| `admin` | Acceso administrativo (futuro) |

## 🔒 Consideraciones de Seguridad

1. **Principio de Menor Privilegio**: Asignar solo los permisos necesarios
2. **Validación en Backend**: Siempre validar permisos en el servidor
3. **Auditoría**: Registrar cambios de permisos
4. **Revocación**: Poder quitar permisos si es necesario

## 🎯 Recomendación

Implementar **Solución 1** de inmediato para que la app funcione, y planificar la **Solución 3** (sistema de roles) para una gestión más escalable de permisos.

---

**Estado**: ⚠️ Requiere corrección inmediata
**Impacto**: Los usuarios no pueden realizar ninguna operación con notas