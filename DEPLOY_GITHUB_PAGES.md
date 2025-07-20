# 🚀 Despliegue Rápido de OWASPNOTE en GitHub Pages

## ✅ Estado del Proyecto

El proyecto está **LISTO PARA DESPLIEGUE** con:
- ✅ Todos los errores de compilación corregidos
- ✅ Tests pasando exitosamente
- ✅ Build web funcionando correctamente
- ✅ GitHub Actions configurado
- ✅ Archivos de seguridad web configurados

## Pasos para Desplegar AHORA

### 1️⃣ Preparar el Proyecto

```bash
# Navegar al proyecto (ajusta la ruta según tu sistema)
cd owaspnote

# Verificar Flutter
flutter --version

# Habilitar soporte web
flutter config --enable-web

# Obtener dependencias
flutter pub get

# Verificar que no hay errores
flutter analyze
```

### 2️⃣ Construir la Aplicación Web

```bash
# Build optimizado para producción
flutter build web --release \
  --web-renderer=canvaskit \
  --tree-shake-icons \
  --pwa-strategy=offline-first

# Crear archivo .nojekyll (necesario para GitHub Pages)
touch build/web/.nojekyll
```

### 3️⃣ Configurar GitHub Pages en tu Repositorio

1. Ve a tu repositorio en GitHub
2. Click en **Settings** (Configuración)
3. En el menú lateral, busca **Pages**
4. En **Source**, selecciona:
   - **Deploy from a branch**
   - Branch: **gh-pages**
   - Folder: **/ (root)**
5. Click **Save**

### 4️⃣ Crear y Subir a la Rama gh-pages

```bash
# Crear rama gh-pages
git checkout --orphan gh-pages

# Eliminar todos los archivos del árbol de trabajo anterior
git rm -rf .

# Copiar los archivos build
cp -r build/web/* .

# Agregar todos los archivos
git add .

# Commit
git commit -m "Deploy OWASPNOTE to GitHub Pages"

# Push a GitHub
git push origin gh-pages --force

# Volver a la rama main
git checkout main
```

### 5️⃣ Verificar el Despliegue

Tu aplicación estará disponible en:
```
https://[tu-usuario].github.io/[nombre-repositorio]/
```

El despliegue puede tardar 5-10 minutos la primera vez.

## 🤖 Automatización con GitHub Actions

**⚠️ IMPORTANTE**: El proyecto ya tiene configurados DOS workflows de GitHub Actions:
1. `.github/workflows/deploy.yml` - Workflow básico
2. `.github/workflows/deploy-to-github-pages.yml` - Workflow completo con tests

**Se recomienda usar `deploy-to-github-pages.yml` que ya está configurado correctamente.**

Para desplegar automáticamente cada vez que hagas push a main:

### 1. Crear el archivo de workflow

```bash
# Crear directorio
mkdir -p .github/workflows
```

### 2. Crear archivo `.github/workflows/deploy.yml`:

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
          flutter-version: '3.24.0'
          channel: 'stable'
          
      - name: Build Web
        run: |
          flutter config --enable-web
          flutter pub get
          flutter build web --release \
            --web-renderer=canvaskit \
            --tree-shake-icons \
            --pwa-strategy=offline-first
            
      - name: Add .nojekyll
        run: touch build/web/.nojekyll
        
      - name: Setup Pages
        uses: actions/configure-pages@v4
        
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: 'build/web'
          
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

### 3. Configurar GitHub Pages para Actions

1. Ve a **Settings** > **Pages**
2. En **Source**, selecciona: **GitHub Actions**

### 4. Hacer commit y push

```bash
git add .github/workflows/deploy.yml
git commit -m "Add GitHub Pages deployment workflow"
git push origin main
```

## ✅ Verificación Final

1. Ve a la pestaña **Actions** en tu repositorio
2. Verifica que el workflow se ejecute correctamente
3. Una vez completado, tu app estará en:
   ```
   https://[tu-usuario].github.io/[nombre-repositorio]/
   ```

## 🔧 Solución de Problemas

### Si la página no carga:
1. Verifica que GitHub Pages esté habilitado
2. Espera 10 minutos (primera vez)
3. Revisa la pestaña Actions por errores

### Si hay error 404:
1. Asegúrate de que el archivo `.nojekyll` existe
2. Verifica la URL correcta
3. Limpia caché del navegador

### Si el build falla:
```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
flutter build web --release
```

## 📋 Checklist Pre-Despliegue

Antes de desplegar, verifica:

```bash
# 1. No hay errores de análisis
flutter analyze
# ✅ Resultado esperado: "No issues found!"

# 2. Los tests pasan
flutter test
# ✅ Resultado esperado: "All tests passed!"

# 3. El build web funciona
flutter build web --release
# ✅ Resultado esperado: "✓ Built build/web"

# 4. Los archivos de seguridad existen
ls web/_headers
# ✅ Debe existir el archivo

# 5. El workflow está configurado
ls .github/workflows/deploy-to-github-pages.yml
# ✅ Debe existir el archivo
```

## 🚨 Notas Importantes

1. **Working Directory**: Si tu proyecto está en un subdirectorio, ajusta el `working-directory` en el workflow
2. **Base HREF**: Para GitHub Pages, necesitas configurar el base-href con el nombre de tu repositorio
3. **Branch Protection**: Considera proteger la rama `main` para evitar despliegues accidentales
4. **Secrets**: No subas archivos con claves o secretos al repositorio

---

**¡Listo!** Tu aplicación OWASPNOTE estará desplegada en GitHub Pages 🎉