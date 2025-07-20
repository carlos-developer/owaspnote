# 🔒 OWASP Dependency-Check para owaspnote

Este documento describe cómo utilizar las herramientas de análisis de dependencias para identificar vulnerabilidades en el proyecto owaspnote.

## 📋 Descripción General

Se han implementado dos herramientas complementarias para el análisis de seguridad de dependencias:

1. **OWASP Dependency-Check**: Escanea todas las dependencias del proyecto (incluyendo las nativas de Android) en busca de vulnerabilidades conocidas (CVEs)
2. **Flutter Dependency Analyzer**: Análisis específico de las dependencias de Flutter/Dart con recomendaciones de seguridad

## 🚀 Requisitos

### Para OWASP Dependency-Check
- **Docker** instalado en el sistema (recomendado)
- O descarga manual de Dependency-Check CLI

### Para Flutter Dependency Analyzer
- **Flutter SDK** instalado y configurado
- Proyecto Flutter con archivo `pubspec.yaml`

## 📦 Instalación

Los scripts ya están incluidos en el proyecto:
- `dependency-check.sh` - Script principal de OWASP Dependency-Check
- `flutter-dependency-analyzer.sh` - Analizador específico para Flutter

Asegúrate de que los scripts tengan permisos de ejecución:
```bash
chmod +x dependency-check.sh
chmod +x flutter-dependency-analyzer.sh
```

## 🔍 Uso

### 1. Ejecutar OWASP Dependency-Check

```bash
./dependency-check.sh
```

**Nota importante**: La primera ejecución descargará la base de datos de vulnerabilidades NVD (National Vulnerability Database), lo cual puede tomar entre 10-30 minutos dependiendo de tu conexión a internet.

### 2. Ejecutar Flutter Dependency Analyzer

```bash
./flutter-dependency-analyzer.sh
```

Este script se ejecuta rápidamente y proporciona un análisis inmediato de las dependencias de Flutter.

## 📊 Informes Generados

Todos los informes se generan en el directorio `dependency-check-report/`:

### Informes de OWASP Dependency-Check:
- **`dependency-check-report.html`** - Informe detallado en HTML con:
  - Lista de todas las dependencias analizadas
  - Vulnerabilidades detectadas (CVEs)
  - Puntuación CVSS de cada vulnerabilidad
  - Enlaces a la base de datos NVD para más información
- **`dependency-check-report.json`** - Datos en formato JSON para procesamiento automático

### Informes de Flutter Dependency Analyzer:
- **`flutter-dependencies-report.html`** - Informe HTML que incluye:
  - Lista de todas las dependencias de Flutter/Dart
  - Identificación de paquetes relacionados con seguridad
  - Verificación de paquetes desactualizados
  - Recomendaciones de seguridad específicas

## 👁️ Visualizar los Informes

### En Linux:
```bash
xdg-open dependency-check-report/dependency-check-report.html
xdg-open dependency-check-report/flutter-dependencies-report.html
```

### En macOS:
```bash
open dependency-check-report/dependency-check-report.html
open dependency-check-report/flutter-dependencies-report.html
```

### En Windows:
```bash
start dependency-check-report/dependency-check-report.html
start dependency-check-report/flutter-dependencies-report.html
```

## 🔄 Buenas Prácticas

1. **Ejecución Regular**: Ejecuta estos análisis al menos una vez por semana o antes de cada release
2. **CI/CD Integration**: Considera integrar estos scripts en tu pipeline de CI/CD (ya tienes Jenkinsfile)
3. **Actualizaciones**: Mantén las dependencias actualizadas ejecutando:
   ```bash
   flutter pub outdated
   flutter pub upgrade
   ```
4. **Revisión Manual**: No todas las vulnerabilidades reportadas son aplicables a tu contexto de uso

## ⚠️ Interpretación de Resultados

### Severidad de Vulnerabilidades (CVSS Score):
- **Crítica** (9.0-10.0): Requiere acción inmediata
- **Alta** (7.0-8.9): Debe abordarse pronto
- **Media** (4.0-6.9): Planificar actualización
- **Baja** (0.1-3.9): Monitorear

### Falsos Positivos:
OWASP Dependency-Check puede reportar falsos positivos. Verifica:
- Si la vulnerabilidad aplica a tu versión específica
- Si el componente vulnerable es realmente usado por tu aplicación
- El contexto de uso (algunas vulnerabilidades solo aplican en ciertos escenarios)

## 🛡️ Paquetes de Seguridad Detectados

El proyecto utiliza los siguientes paquetes relacionados con seguridad:
- `crypto`: Algoritmos criptográficos
- `encrypt`: Funcionalidad de encriptación/desencriptación
- `flutter_secure_storage`: Almacenamiento seguro
- `local_auth`: Autenticación biométrica
- `pointycastle`: Biblioteca criptográfica
- `dio`: Cliente HTTP con características de seguridad

## 📚 Recursos Adicionales

- [OWASP Dependency-Check Documentation](https://jeremylong.github.io/DependencyCheck/)
- [National Vulnerability Database (NVD)](https://nvd.nist.gov/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)

## 🤝 Soporte

Si encuentras problemas con los scripts o necesitas ayuda interpretando los resultados:
1. Verifica los logs en `dependency-check-report/`
2. Consulta la documentación oficial de OWASP Dependency-Check
3. Para problemas específicos de Flutter, revisa [pub.dev security](https://pub.dev/security)