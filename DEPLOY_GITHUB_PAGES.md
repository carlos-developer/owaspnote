# 🚀 Despliegue Rápido de OWASPNOTE en GitHub Pages

## Pasos para Desplegar AHORA

### 1️⃣ Preparar el Proyecto

```bash
# Navegar al proyecto
cd /home/juan/Escritorio/proyecto/3md/owaspnote

# Verificar Flutter
flutter --version

# Habilitar soporte web
flutter config --enable-web

# Obtener dependencias
flutter pub get
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
          flutter-version: '3.8.1'
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

---

**¡Listo!** Tu aplicación OWASPNOTE estará desplegada en GitHub Pages 🎉