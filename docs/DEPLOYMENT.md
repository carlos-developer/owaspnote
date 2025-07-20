# 🚀 OWASPNOTE - Guía Completa de Despliegue a Producción

## 📋 Tabla de Contenidos
1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Opciones de Hosting Gratuito](#opciones-de-hosting-gratuito)
3. [Preparación del Proyecto](#preparación-del-proyecto)
4. [Despliegue en GitHub Pages](#despliegue-en-github-pages)
5. [Despliegue en Netlify](#despliegue-en-netlify)
6. [Despliegue en Vercel](#despliegue-en-vercel)
7. [Despliegue en Firebase Hosting](#despliegue-en-firebase-hosting)
8. [Configuración de GitHub Actions](#configuración-de-github-actions)
9. [Seguridad en Producción](#seguridad-en-producción)
10. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)

## 🎯 Resumen Ejecutivo

OWASPNOTE es una aplicación Flutter Web que implementa las mejores prácticas de seguridad según OWASP. Esta guía proporciona instrucciones detalladas para desplegar la aplicación en producción utilizando servicios gratuitos.

### Características del Proyecto:
- **Framework**: Flutter Web
- **Seguridad**: Implementa OWASP Mobile Top 10 mitigaciones
- **Build**: Scripts personalizados con medidas de seguridad
- **CI/CD**: Preparado para GitHub Actions

## 🆓 Opciones de Hosting Gratuito

### Comparación de Servicios

| Servicio | Límites Gratuitos | Características | Ideal Para |
|----------|------------------|-----------------|------------|
| **GitHub Pages** | 100GB/mes bandwidth<br>1GB almacenamiento | - Integración nativa con GitHub<br>- HTTPS automático<br>- Custom domain | Apps estáticas simples |
| **Netlify** | 100GB/mes bandwidth<br>300 min build/mes | - Deploy automático<br>- Serverless functions<br>- Forms handling | Apps con funcionalidades extras |
| **Vercel** | 100GB/mes bandwidth<br>6000 min build/mes | - Optimizado para frontend<br>- Analytics<br>- Edge functions | Apps con alto rendimiento |
| **Firebase Hosting** | 10GB almacenamiento<br>360MB/día transfer | - Backend integration<br>- Real-time database<br>- Authentication | Apps con backend Firebase |

### 🏆 Recomendación Principal: GitHub Pages
Para OWASPNOTE, **GitHub Pages** es la opción más recomendada porque:
- ✅ Integración directa con el repositorio
- ✅ Despliegue automático con GitHub Actions
- ✅ HTTPS gratuito
- ✅ Sin límites de build time
- ✅ Dominio personalizado gratuito

## 🔧 Preparación del Proyecto

### 1. Verificar Requisitos
```bash
# Verificar versión de Flutter
flutter --version  # Debe ser >= 3.8.1

# Verificar canal estable
flutter channel stable
flutter upgrade

# Verificar soporte web
flutter config --enable-web
```

### 2. Actualizar Configuración Web
```bash
# Crear archivo de configuración web optimizada
cd owaspnote
```

Crear archivo `web/index.html` con las siguientes mejoras de seguridad:
```html
<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="OWASPNOTE - Secure Notes Application">
  
  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="owaspnote">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  
  <!-- Security Headers -->
  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';">
  <meta http-equiv="X-Content-Type-Options" content="nosniff">
  <meta http-equiv="X-Frame-Options" content="DENY">
  <meta http-equiv="X-XSS-Protection" content="1; mode=block">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  
  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>
  
  <title>OWASPNOTE</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="flutter.js" defer></script>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: '{{ flutter_service_worker_version }}',
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    });
  </script>
</body>
</html>
```

### 3. Optimizar Build Script
Actualizar `ci/scripts/build_web.sh`:
```bash
#!/bin/bash

set -e

echo "🏗️ Building OWASPNOTE for Web Production..."

# Clean previous builds
flutter clean
rm -rf build/web

# Get dependencies
flutter pub get

# Build for production with optimizations
flutter build web --release \
  --web-renderer=canvaskit \
  --tree-shake-icons \
  --pwa-strategy=offline-first \
  --csp \
  --base-href="/"

# Post-build optimizations
echo "📦 Optimizing build artifacts..."

# Compress assets
find build/web -name "*.js" -exec gzip -9 -k {} \;
find build/web -name "*.css" -exec gzip -9 -k {} \;

# Create .nojekyll file for GitHub Pages
touch build/web/.nojekyll

# Generate deployment info
cat > build/web/deployment-info.json << EOF
{
  "version": "$(git describe --tags --always)",
  "buildDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "commitHash": "$(git rev-parse HEAD)"
}
EOF

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"
```

## 📄 Despliegue en GitHub Pages

### Opción 1: Despliegue Manual (Primera vez)

1. **Habilitar GitHub Pages en el repositorio**:
   ```bash
   # Ir a Settings > Pages en tu repositorio GitHub
   # Source: Deploy from a branch
   # Branch: gh-pages / root
   ```

2. **Build y deploy manual**:
   ```bash
   # Build the project
   cd owaspnote
   chmod +x ci/scripts/build_web.sh
   ./ci/scripts/build_web.sh
   
   # Create gh-pages branch
   git checkout --orphan gh-pages
   
   # Remove all files from the old working tree
   git rm -rf .
   
   # Add build files
   cp -r build/web/* .
   
   # Commit and push
   git add .
   git commit -m "Deploy to GitHub Pages"
   git push origin gh-pages
   
   # Return to main branch
   git checkout main
   ```

### Opción 2: Configuración Automática con GitHub Actions (Recomendado)

Ver sección [Configuración de GitHub Actions](#configuración-de-github-actions) más adelante.

## 🔷 Despliegue en Netlify

### 1. Preparación
```bash
# Crear archivo netlify.toml en la raíz
cat > owaspnote/netlify.toml << EOF
[build]
  command = "cd owaspnote && flutter build web --release"
  publish = "owaspnote/build/web"

[build.environment]
  FLUTTER_VERSION = "3.8.1"

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    X-XSS-Protection = "1; mode=block"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Content-Security-Policy = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
EOF
```

### 2. Despliegue
1. Visitar [app.netlify.com](https://app.netlify.com)
2. Conectar con GitHub
3. Seleccionar el repositorio
4. Configurar:
   - Base directory: `owaspnote`
   - Build command: `flutter build web --release`
   - Publish directory: `owaspnote/build/web`
5. Deploy!

## 🔺 Despliegue en Vercel

### 1. Preparación
```bash
# Crear archivo vercel.json
cat > owaspnote/vercel.json << EOF
{
  "buildCommand": "cd owaspnote && flutter build web --release",
  "outputDirectory": "owaspnote/build/web",
  "framework": null,
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
EOF
```

### 2. Despliegue
1. Instalar Vercel CLI: `npm i -g vercel`
2. En el directorio del proyecto: `vercel`
3. Seguir las instrucciones interactivas

## 🔥 Despliegue en Firebase Hosting

### 1. Configuración Inicial
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inicializar proyecto
cd owaspnote
firebase init hosting

# Seleccionar:
# - Public directory: build/web
# - Single-page app: Yes
# - GitHub Actions: Yes (opcional)
```

### 2. Configurar firebase.json
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=3600"
          },
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          }
        ]
      }
    ]
  }
}
```

### 3. Desplegar
```bash
# Build
./ci/scripts/build_web.sh

# Deploy
firebase deploy --only hosting
```

## 🤖 Configuración de GitHub Actions

### Workflow Principal para GitHub Pages

Crear `.github/workflows/deploy.yml`:
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
          channel: 'stable'
          
      - name: Enable Flutter Web
        run: flutter config --enable-web
        
      - name: Get dependencies
        working-directory: ./owaspnote
        run: flutter pub get
        
      - name: Run tests
        working-directory: ./owaspnote
        run: flutter test
        
      - name: Build web
        working-directory: ./owaspnote
        run: |
          flutter build web --release \
            --web-renderer=canvaskit \
            --tree-shake-icons \
            --pwa-strategy=offline-first \
            --base-href="/${{ github.event.repository.name }}/owaspnote/"
            
      - name: Setup Pages
        uses: actions/configure-pages@v4
        
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: './owaspnote/build/web'
          
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Workflow para Múltiples Ambientes

Crear `.github/workflows/multi-deploy.yml`:
```yaml
name: Multi-Environment Deploy

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  FLUTTER_VERSION: '3.8.1'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Install dependencies
        working-directory: ./owaspnote
        run: flutter pub get
        
      - name: Run tests
        working-directory: ./owaspnote
        run: flutter test
        
      - name: Check code format
        working-directory: ./owaspnote
        run: flutter format --set-exit-if-changed .
        
      - name: Analyze code
        working-directory: ./owaspnote
        run: flutter analyze

  build-and-deploy:
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          
      - name: Build web release
        working-directory: ./owaspnote
        run: |
          flutter config --enable-web
          flutter build web --release \
            --web-renderer=canvaskit \
            --tree-shake-icons \
            --pwa-strategy=offline-first
            
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./owaspnote/build/web
          
      # Opcional: Deploy a Netlify
      - name: Deploy to Netlify
        uses: nwtgck/actions-netlify@v2.0
        with:
          publish-dir: './owaspnote/build/web'
          production-deploy: true
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

## 🔒 Seguridad en Producción

### 1. Headers de Seguridad

Para GitHub Pages, crear `_headers` file:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(), microphone=(), camera=()
```

### 2. Configuración de CORS

Si la app necesita APIs externas, configurar CORS apropiadamente:
```dart
// En tu código Dart
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.yourdomain.com',
  );
}
```

### 3. Variables de Entorno

Para GitHub Actions, configurar secrets:
1. Ir a Settings > Secrets and variables > Actions
2. Agregar secrets necesarios:
   - `API_KEY`
   - `SENTRY_DSN` (para monitoreo)
   - etc.

### 4. Ofuscación de Código

Agregar al build command:
```bash
flutter build web --release \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --dart2js-optimization=O4
```

## 📊 Monitoreo y Mantenimiento

### 1. Configurar Google Analytics

En `web/index.html`:
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### 2. Monitoreo de Errores con Sentry

Agregar a `pubspec.yaml`:
```yaml
dependencies:
  sentry_flutter: ^7.0.0
```

En `main.dart`:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = const String.fromEnvironment('ENV', defaultValue: 'production');
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

### 3. Health Check Endpoint

Crear archivo `web/health.json`:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 📝 Checklist de Despliegue

### Pre-Despliegue
- [ ] Tests pasando (`flutter test`)
- [ ] Build exitoso (`flutter build web --release`)
- [ ] Sin warnings en análisis (`flutter analyze`)
- [ ] Código formateado (`flutter format .`)
- [ ] README actualizado
- [ ] Variables de entorno configuradas
- [ ] Secrets de GitHub configurados

### Post-Despliegue
- [ ] Sitio accesible en URL de producción
- [ ] HTTPS funcionando
- [ ] Headers de seguridad verificados
- [ ] Performance aceptable (Lighthouse > 90)
- [ ] Sin errores en consola
- [ ] Analytics funcionando
- [ ] Monitoreo de errores activo

## 🚨 Troubleshooting Común

### Error: "Failed to load app from service worker"
```bash
# Solución: Limpiar cache y rebuild
flutter clean
flutter pub get
flutter build web --release
```

### Error: "404 on refresh"
```bash
# Para GitHub Pages, agregar 404.html
cp build/web/index.html build/web/404.html
```

### Build muy pesado
```bash
# Usar CanvasKit solo para desktop
flutter build web --release \
  --web-renderer=auto \
  --tree-shake-icons
```

## 📞 Soporte

Para problemas específicos:
- GitHub Pages: [docs.github.com/pages](https://docs.github.com/pages)
- Flutter Web: [flutter.dev/web](https://flutter.dev/web)
- OWASP: [owasp.org](https://owasp.org)

---

**Última actualización**: Enero 2025
**Versión**: 1.0.0