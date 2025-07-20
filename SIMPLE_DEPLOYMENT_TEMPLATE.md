# 🚀 PLANTILLA SIMPLE DE DESPLIEGUE - FLUTTER WEB A GITHUB PAGES

## 📌 Instrucciones de Uso
**Para Claude Code**: Cuando recibas esta plantilla, sigue estos pasos exactamente para configurar un despliegue exitoso.

## 1️⃣ INFORMACIÓN REQUERIDA
Obtén automáticamente del repositorio actual:

```bash
# Comando para obtener el nombre del repositorio
REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)

# Verificar si web está habilitado
flutter config | grep "enable-web"

# Verificar versión de flutter_lints
grep "flutter_lints:" pubspec.yaml
```

## 2️⃣ CREAR ESTRUCTURA BASE

```bash
# Comando 1: Habilitar web si es necesario
flutter config --enable-web

# Comando 2: Crear archivos necesarios
touch web/.nojekyll

# Comando 3: Crear 404.html con el nombre del repo correcto
REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)
cat > web/404.html << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Flutter App</title>
  <script>
    window.location.href = '/$REPO_NAME/';
  </script>
</head>
<body>
  Redirecting...
</body>
</html>
EOF
```

## 3️⃣ CREAR WORKFLOW MÍNIMO

```bash
# Obtener nombre del repositorio automáticamente
REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)

# Crear directorio si no existe
mkdir -p .github/workflows

# Crear workflow con el nombre correcto del repositorio
cat > .github/workflows/deploy.yml << EOF
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.3'
          
      - run: |
          # Auto-fix flutter_lints si es necesario
          if grep -q "flutter_lints: [\^~][5-9]\." pubspec.yaml; then
            sed -i 's/flutter_lints: .*/flutter_lints: 4.0.0/' pubspec.yaml
          fi
          flutter pub get
          flutter build web --release --base-href /$REPO_NAME/
          
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: \${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
EOF
```

## 4️⃣ VERIFICACIÓN AUTOMÁTICA

```bash
# Verificar que todo esté correcto
echo "Verificando configuración..."
echo "Repositorio: $(basename -s .git `git config --get remote.origin.url`)"
echo "Workflow creado: $(ls .github/workflows/deploy.yml 2>/dev/null && echo 'SÍ' || echo 'NO')"
echo "Web habilitado: $(flutter config | grep -q "enable-web: true" && echo 'SÍ' || echo 'NO')"
echo ".nojekyll creado: $(ls web/.nojekyll 2>/dev/null && echo 'SÍ' || echo 'NO')"
```

## 5️⃣ COMANDOS FINALES

```bash
git add .
git commit -m "feat: Add GitHub Pages deployment"
git push origin main
```

## 6️⃣ CONFIGURAR GITHUB

1. Ir a Settings → Pages
2. Source: "Deploy from a branch"
3. Branch: "gh-pages"
4. Save

## 🎯 RESULTADO
```bash
# Ver URL final
echo "Tu app estará en: https://$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\/\(.*\).git/\1/').github.io/$(basename -s .git `git config --get remote.origin.url`)/"
```

## ⚠️ SI FALLA
```bash
# Diagnóstico rápido
echo "=== DIAGNÓSTICO ==="
echo "1. Nombre del repo: $(basename -s .git `git config --get remote.origin.url`)"
echo "2. Flutter version: $(flutter --version | head -1)"
echo "3. Dart version: $(dart --version)"
echo "4. flutter_lints: $(grep flutter_lints pubspec.yaml)"
echo "5. Últimos logs: $(git log --oneline -5)"
```

---
**Tiempo estimado**: 10 minutos total
**Automatización**: 90% - Solo requiere configurar GitHub Pages manualmente